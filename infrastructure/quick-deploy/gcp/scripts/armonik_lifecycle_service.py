#!/usr/bin/env python3
"""
ArmoniK Windows Lifecycle Management Service

This service manages ArmoniK Docker containers (polling agent and workers) on Windows VMs
in GCP Managed Instance Groups. It provides health checks, process monitoring,
exponential backoff restart logic, and automatic VM shutdown on repeated failures.

Author: ArmoniK Infrastructure Team
Version: 2.1.0
"""

import json
import logging
import os
import signal
import subprocess
import sys
import threading
import time
from dataclasses import dataclass
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
from typing import Any, Dict, List, Optional


@dataclass
class ProcessConfig:
    """Configuration for a managed process"""

    name: str
    docker_image: str
    docker_tag: str
    container_name: str
    command: List[str]
    environment: Dict[str, str]
    restart_policy: str = "always"
    max_restarts: int = 5
    health_check_port: Optional[int] = None
    health_check_path: str = "/health"


@dataclass
class ProcessState:
    """State tracking for a managed process"""

    config: ProcessConfig
    container_id: Optional[str] = None
    pid: Optional[int] = None
    start_time: Optional[datetime] = None
    restart_count: int = 0
    last_restart: Optional[datetime] = None
    status: str = "stopped"  # stopped, starting, running, failed
    failure_count: int = 0
    backoff_delay: float = 1.0
    last_health_check: Optional[datetime] = None
    health_status: str = "unknown"  # unknown, healthy, unhealthy


class ArmoniKLifecycleService:
    """Main lifecycle management service for ArmoniK components"""

    def __init__(self, config_file: str = "armonik_config.json") -> None:
        self.config_file = config_file
        self.processes: Dict[str, ProcessState] = {}
        self.running = False
        self.health_server: Optional[HTTPServer] = None
        self.monitor_thread: Optional[threading.Thread] = None
        self.health_thread: Optional[threading.Thread] = None
        self.gcp_metadata_base = "http://metadata.google.internal/computeMetadata/v1"

        # Configure logging
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            handlers=[
                logging.FileHandler("armonik_lifecycle.log"),
                logging.StreamHandler(sys.stdout),
            ],
        )
        self.logger = logging.getLogger(__name__)

        # Load configuration
        self.load_configuration()

        # Set up signal handlers
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)

    def load_configuration(self) -> None:
        """Load ArmoniK configuration from file or create default"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, "r", encoding="utf-8") as f:
                    config_data = json.load(f)
                self.logger.info("Loaded configuration from %s", self.config_file)
            else:
                config_data = self._create_default_config()
                self.logger.info("Created default configuration")

            self._setup_processes(config_data)

        except Exception as e:
            self.logger.error("Failed to load configuration: %s", e)
            raise

    def _create_default_config(self) -> dict:
        """Create default ArmoniK configuration"""
        # Get versions from metadata or use defaults
        armonik_version = self._get_metadata("armonik-version", "0.33.1")

        config = {
            "armonik": {
                "version": armonik_version,
                "images": {
                    "polling_agent": "dockerhubaneo/armonik_pollingagent",
                    "worker": "dockerhubaneo/armonik_worker_dll",
                },
                "environment": {
                    "ASPNETCORE_ENVIRONMENT": "Production",
                    "Logging__LogLevel__Default": "Information",
                    "GrpcClient__Endpoint": self._get_metadata(
                        "grpc-endpoint", "http://armonik-control:5001"
                    ),
                    "Redis__EndpointUrl": self._get_metadata(
                        "redis-endpoint", "localhost:6379"
                    ),
                    "MongoDB__Host": self._get_metadata("mongodb-host", "localhost"),
                    "MongoDB__Port": self._get_metadata("mongodb-port", "27017"),
                    "MongoDB__DatabaseName": "ArmoniK",
                    "MongoDB__DataRetention": "10.00:00:00",
                    "MongoDB__TableStorage__PollingDelayMin": "00:00:01",
                    "MongoDB__TableStorage__PollingDelayMax": "00:00:10",
                },
                "health_check": {"enabled": True, "port": 8080, "interval": 30},
                "restart_policy": {
                    "max_restarts": 5,
                    "backoff_base": 2.0,
                    "backoff_max": 300.0,
                    "failure_threshold": 10,
                },
                "partitions": {
                    "default": {
                        "image": "dockerhubaneo/armonik_worker_dll",
                        "tag": armonik_version,
                        "environment": {},
                    }
                },
            }
        }

        # Save default config
        with open(self.config_file, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)

        return config

    def _setup_processes(self, config_data: dict) -> None:
        """Setup process configurations from config data, supporting partition-specific workers"""
        armonik_config = config_data.get("armonik", {})
        images = armonik_config.get("images", {})
        environment = armonik_config.get("environment", {})
        version = armonik_config.get("version", "latest")
        partitions_raw = armonik_config.get("partitions", {})

        # Ensure partitions is treated as a dictionary
        partitions: Dict[str, Any] = dict(partitions_raw) if partitions_raw else {}

        # Polling Agent Process (global, not per-partition)
        polling_agent = ProcessConfig(
            name="armonik-polling-agent",
            docker_image=images.get(
                "polling_agent", "dockerhubaneo/armonik_pollingagent"
            ),
            docker_tag=version,
            container_name="armonik-polling-agent",
            command=[],
            environment=environment.copy(),
            health_check_port=8080,
        )

        self.processes = {"polling-agent": ProcessState(config=polling_agent)}

        # Partition-specific workers
        for partition, worker_cfg in partitions.items():
            image = worker_cfg.get(
                "image", images.get("worker", "dockerhubaneo/armonik_worker_dll")
            )
            tag = worker_cfg.get("tag", version)
            env = environment.copy()
            env.update(worker_cfg.get("environment", {}))
            container_name = f"armonik-worker-{partition}"
            health_port = worker_cfg.get(
                "health_check_port", 8081 + len(self.processes)
            )

            self.processes[f"worker-{partition}"] = ProcessState(
                config=ProcessConfig(
                    name=f"armonik-worker-{partition}",
                    docker_image=image,
                    docker_tag=tag,
                    container_name=container_name,
                    command=[],
                    environment=env,
                    health_check_port=health_port,
                )
            )

    def _get_metadata(self, key: str, default: str = "") -> str:
        """Get metadata from GCP metadata server"""
        try:
            url = f"{self.gcp_metadata_base}/instance/attributes/{key}"
            headers = {"Metadata-Flavor": "Google"}

            # Use urllib for HTTP requests to avoid external dependencies
            import urllib.error
            import urllib.request

            req = urllib.request.Request(url)
            for k, v in headers.items():
                req.add_header(k, v)

            with urllib.request.urlopen(req, timeout=5) as response:
                if response.getcode() == 200:
                    return response.read().decode("utf-8").strip()
        except (urllib.error.URLError, Exception) as e:
            self.logger.debug("Failed to get metadata %s: %s", key, e)
        return default

    def start(self) -> bool:
        """Start the lifecycle service"""
        self.logger.info("Starting ArmoniK Lifecycle Service")
        self.running = True

        # Ensure Docker is available
        if not self._check_docker():
            self.logger.error("Docker is not available")
            return False

        # Start health check server
        self._start_health_server()

        # Start monitoring thread
        self.monitor_thread = threading.Thread(target=self._monitor_processes)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()

        # Start health check thread
        self.health_thread = threading.Thread(target=self._health_check_loop)
        self.health_thread.daemon = True
        self.health_thread.start()

        # Start all processes
        for name in self.processes.keys():
            self._start_process(name)

        self.logger.info("ArmoniK Lifecycle Service started successfully")
        return True

    def stop(self) -> None:
        """Stop the lifecycle service"""
        self.logger.info("Stopping ArmoniK Lifecycle Service")
        self.running = False

        # Stop all processes
        for name in self.processes.keys():
            self._stop_process(name)

        # Stop health server
        if self.health_server:
            self.health_server.shutdown()

        self.logger.info("ArmoniK Lifecycle Service stopped")

    def _check_docker(self) -> bool:
        """Check if Docker is available and running"""
        try:
            result = subprocess.run(
                ["docker", "version"],
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
            )
            return result.returncode == 0
        except Exception as e:
            self.logger.error("Docker check failed: %s", e)
            return False

    def _start_process(self, name: str) -> bool:
        """Start a managed process"""
        if name not in self.processes:
            self.logger.error("Unknown process: %s", name)
            return False

        process_state = self.processes[name]
        config = process_state.config

        try:
            # Stop existing container if running
            self._stop_container(config.container_name)

            # Build Docker command
            docker_cmd = [
                "docker",
                "run",
                "-d",
                "--name",
                config.container_name,
                "--restart",
                "no",  # We handle restarts ourselves
            ]

            # Add port mappings
            if config.health_check_port:
                docker_cmd.extend(
                    ["-p", f"{config.health_check_port}:{config.health_check_port}"]
                )

            # Add environment variables
            for key, value in config.environment.items():
                docker_cmd.extend(["-e", f"{key}={value}"])

            # Add image
            image_with_tag = f"{config.docker_image}:{config.docker_tag}"
            docker_cmd.append(image_with_tag)

            # Add command if specified
            if config.command:
                docker_cmd.extend(config.command)

            # Start container
            self.logger.info("Starting %s container: %s", name, " ".join(docker_cmd))
            result = subprocess.run(
                docker_cmd, capture_output=True, text=True, timeout=60, check=False
            )

            if result.returncode == 0:
                container_id = result.stdout.strip()
                process_state.container_id = container_id
                process_state.start_time = datetime.now()
                process_state.status = "starting"
                self.logger.info("Started %s container: %s", name, container_id[:12])

                # Wait a moment for container to start
                time.sleep(2)

                # Check if container is still running
                if self._is_container_running(container_id):
                    process_state.status = "running"
                    return True
                else:
                    process_state.status = "failed"
                    self.logger.error("Container %s failed to start properly", name)
                    return False
            else:
                self.logger.error("Failed to start %s: %s", name, result.stderr)
                process_state.status = "failed"
                return False

        except Exception as e:
            self.logger.error("Exception starting %s: %s", name, e)
            process_state.status = "failed"
            return False

    def _stop_process(self, name: str) -> None:
        """Stop a managed process"""
        if name not in self.processes:
            return

        process_state = self.processes[name]
        config = process_state.config

        if process_state.container_id:
            self._stop_container(config.container_name)
            process_state.container_id = None

        process_state.status = "stopped"
        self.logger.info("Stopped %s", name)

    def _stop_container(self, container_name: str) -> None:
        """Stop and remove a Docker container"""
        try:
            # Stop container
            subprocess.run(
                ["docker", "stop", container_name],
                capture_output=True,
                timeout=30,
                check=False,
            )

            # Remove container
            subprocess.run(
                ["docker", "rm", container_name],
                capture_output=True,
                timeout=30,
                check=False,
            )
        except Exception as e:
            self.logger.debug("Error stopping container %s: %s", container_name, e)

    def _is_container_running(self, container_id: str) -> bool:
        """Check if a container is running"""
        try:
            result = subprocess.run(
                ["docker", "inspect", "--format={{.State.Running}}", container_id],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            return result.returncode == 0 and result.stdout.strip() == "true"
        except Exception:
            return False

    def _monitor_processes(self) -> None:
        """Monitor process health and restart if needed"""
        while self.running:
            try:
                for name, process_state in self.processes.items():
                    if not self.running:
                        break
                    self._check_process_health(name, process_state)
                time.sleep(10)  # Check every 10 seconds
            except Exception as e:
                self.logger.error("Error in process monitor: %s", e)
                time.sleep(30)

    def _check_process_health(self, name: str, process_state: ProcessState) -> None:
        """Check health of a specific process"""
        config = process_state.config

        # Check if container is running
        if process_state.container_id and not self._is_container_running(
            process_state.container_id
        ):
            self.logger.warning("Container %s is not running", name)
            process_state.status = "failed"
            process_state.failure_count += 1

            # Implement exponential backoff restart
            if process_state.failure_count <= config.max_restarts:
                delay = min(process_state.backoff_delay, 300.0)  # Max 5 minutes
                self.logger.info(
                    "Restarting %s after %.1fs delay (attempt %d)",
                    name,
                    delay,
                    process_state.failure_count,
                )

                time.sleep(delay)

                if self._start_process(name):
                    process_state.restart_count += 1
                    process_state.last_restart = datetime.now()
                    process_state.backoff_delay = 1.0  # Reset backoff on success
                else:
                    process_state.backoff_delay *= 2.0  # Exponential backoff
            else:
                self.logger.error(
                    "Process %s exceeded max restarts (%d)", name, config.max_restarts
                )

    def _health_check_loop(self) -> None:
        """Perform periodic health checks on processes"""
        while self.running:
            try:
                for name, process_state in self.processes.items():
                    if not self.running:
                        break

                    if (
                        process_state.status == "running"
                        and process_state.config.health_check_port
                    ):
                        self._perform_health_check(name, process_state)

                time.sleep(30)  # Health check every 30 seconds
            except Exception as e:
                self.logger.error("Error in health check loop: %s", e)
                time.sleep(60)

    def _perform_health_check(self, name: str, process_state: ProcessState) -> None:
        """Perform health check on a specific process"""
        config = process_state.config
        try:
            url = (
                f"http://localhost:{config.health_check_port}{config.health_check_path}"
            )

            # Simple HTTP check using urllib
            import urllib.error
            import urllib.request

            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.getcode() == 200:
                    process_state.health_status = "healthy"
                    process_state.last_health_check = datetime.now()
                else:
                    process_state.health_status = "unhealthy"
                    self.logger.warning(
                        "Health check failed for %s: HTTP %d", name, response.getcode()
                    )
        except Exception as e:
            process_state.health_status = "unhealthy"
            self.logger.warning("Health check failed for %s: %s", name, e)

    def _start_health_server(self) -> None:
        """Start HTTP health check server"""
        try:
            server_address = ("", 8090)  # Listen on all interfaces, port 8090
            self.health_server = ThreadingHTTPServer(server_address, HealthCheckHandler)
            self.health_server.lifecycle_service = self

            server_thread = threading.Thread(target=self.health_server.serve_forever)
            server_thread.daemon = True
            server_thread.start()

            self.logger.info("Health check server started on port 8090")
        except Exception as e:
            self.logger.error("Failed to start health server: %s", e)

    def get_service_status(self) -> dict:
        """Get current status of all services"""
        status: Dict = {
            "timestamp": datetime.now().isoformat(),
            "service_status": "running" if self.running else "stopped",
            "processes": {},
        }

        for name, process_state in self.processes.items():
            status["processes"][name] = {
                "status": process_state.status,
                "health": process_state.health_status,
                "restart_count": process_state.restart_count,
                "failure_count": process_state.failure_count,
                "last_health_check": (
                    process_state.last_health_check.isoformat()
                    if process_state.last_health_check
                    else None
                ),
                "start_time": (
                    process_state.start_time.isoformat()
                    if process_state.start_time
                    else None
                ),
                "container_id": (
                    process_state.container_id[:12]
                    if process_state.container_id
                    else None
                ),
            }

        return status

    def _signal_handler(self, signum: int, frame: Any) -> None:
        """Handle shutdown signals"""
        self.logger.info("Received signal %d, shutting down...", signum)
        self.stop()
        sys.exit(0)


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    """Thread-based HTTP server with lifecycle service attribute"""

    def __init__(self, server_address: tuple, RequestHandlerClass: type) -> None:
        super().__init__(server_address, RequestHandlerClass)
        self.lifecycle_service: Optional["ArmoniKLifecycleService"] = None


class HealthCheckHandler(BaseHTTPRequestHandler):
    """HTTP handler for health checks"""

    def do_GET(self) -> None:
        lifecycle_service = getattr(self.server, "lifecycle_service", None)

        if self.path == "/health":
            self._handle_health_check(lifecycle_service)
        elif self.path == "/status":
            self._handle_status_check(lifecycle_service)
        else:
            self.send_error(404)

    def _handle_health_check(
        self, lifecycle_service: Optional["ArmoniKLifecycleService"]
    ) -> None:
        """Handle /health endpoint"""
        try:
            if not lifecycle_service:
                self.send_error(500)
                return

            # Check if all processes are healthy
            all_healthy = True
            for process_state in lifecycle_service.processes.values():
                if (
                    process_state.status != "running"
                    or process_state.health_status != "healthy"
                ):
                    all_healthy = False
                    break

            if all_healthy and lifecycle_service.running:
                self.send_response(200)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "healthy"}')
            else:
                self.send_response(500)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "unhealthy"}')
        except Exception as e:
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(f'{{"status": "error", "message": "{str(e)}"}}'.encode())

    def _handle_status_check(
        self, lifecycle_service: Optional["ArmoniKLifecycleService"]
    ) -> None:
        """Handle /status endpoint"""
        try:
            if not lifecycle_service:
                self.send_error(500)
                return

            status = lifecycle_service.get_service_status()
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(status, indent=2).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(f'{{"status": "error", "message": "{str(e)}"}}'.encode())

    def log_message(self, format_str: str, *args: Any) -> None:
        """Override to reduce log noise"""
        pass


def main() -> None:
    """Main entry point"""
    service = ArmoniKLifecycleService()

    try:
        if service.start():
            # Keep the service running
            while service.running:
                time.sleep(1)
        else:
            sys.exit(1)
    except KeyboardInterrupt:
        service.logger.info("Received keyboard interrupt")
    except Exception as e:
        service.logger.error("Unexpected error: %s", e)
        sys.exit(1)
    finally:
        service.stop()


if __name__ == "__main__":
    main()
