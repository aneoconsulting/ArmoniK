#!/usr/bin/env python3
"""
ArmoniK Lifecycle Service - Final Production Version

Simplified, robust lifecycle service for Windows/GCP deployment.
Correctly handles armonik_config from GCP metadata or local file.
"""

import argparse
import asyncio
import json
import logging
import os
import signal
import sys
import threading
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional


def setup_logging() -> logging.Logger:
    """Setup logging configuration"""
    logger = logging.getLogger("armonik_lifecycle")
    logger.setLevel(logging.INFO)

    if not logger.handlers:
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )

        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        # File handler for Windows
        if sys.platform == "win32":
            try:
                log_dir = Path("C:/ArmoniK/logs")
                log_dir.mkdir(parents=True, exist_ok=True)
                file_handler = logging.FileHandler(log_dir / "armonik_lifecycle.log")
                file_handler.setFormatter(formatter)
                logger.addHandler(file_handler)
            except OSError:
                pass  # Continue without file logging

    return logger


class ServiceManager:
    """Manages ArmoniK service lifecycle with Docker"""

    def __init__(self, logger: logging.Logger) -> None:
        self.logger = logger
        self.services: Dict[str, Dict[str, Any]] = {}

    async def start_service(self, service_name: str, config: Dict[str, Any]) -> bool:
        """Start a service using Docker"""
        try:
            # Build Docker command
            cmd = self._build_docker_command(service_name, config)

            # Stop existing container first
            await self._stop_container(service_name)

            # Start new container
            self.logger.info("Starting service: %s", service_name)
            result = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                container_id = stdout.decode().strip()
                self.services[service_name] = {
                    "id": container_id,
                    "config": config,
                    "status": "running",
                }
                self.logger.info(
                    "Started service %s: %s", service_name, container_id[:12]
                )
                return True
            else:
                self.logger.error(
                    "Failed to start %s: %s", service_name, stderr.decode()
                )
                return False

        except OSError as e:
            self.logger.error("Error starting service %s: %s", service_name, e)
            return False

    async def stop_service(self, service_name: str) -> bool:
        """Stop a service"""
        try:
            if service_name in self.services:
                await self._stop_container(service_name)
                del self.services[service_name]
                self.logger.info("Stopped service: %s", service_name)
                return True
            return False
        except OSError as e:
            self.logger.error("Error stopping service %s: %s", service_name, e)
            return False

    async def restart_service(self, service_name: str) -> bool:
        """Restart a service"""
        if service_name not in self.services:
            self.logger.warning("Service %s not found for restart", service_name)
            return False

        config = self.services[service_name]["config"]
        self.logger.info("Restarting service: %s", service_name)

        await self.stop_service(service_name)
        await asyncio.sleep(2)
        return await self.start_service(service_name, config)

    async def _stop_container(self, service_name: str) -> bool:
        """Stop and remove Docker container"""
        try:
            # Stop container
            stop_result = await asyncio.create_subprocess_exec(
                "docker",
                "stop",
                service_name,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            await stop_result.communicate()

            # Remove container
            rm_result = await asyncio.create_subprocess_exec(
                "docker",
                "rm",
                service_name,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            await rm_result.communicate()

            return True

        except OSError:
            return False

    def _build_docker_command(
        self, service_name: str, config: Dict[str, Any]
    ) -> List[str]:
        """Build Docker run command"""
        cmd = ["docker", "run", "-d", "--name", service_name]

        # Add port mappings
        if "ports" in config:
            for port_mapping in config["ports"]:
                cmd.extend(["-p", port_mapping])

        # Add environment variables
        if "environment" in config:
            if isinstance(config["environment"], dict):
                # Handle dict format (new partition-based config)
                for key, value in config["environment"].items():
                    cmd.extend(["-e", f"{key}={value}"])
            elif isinstance(config["environment"], list):
                # Handle list format (legacy config)
                for env_var in config["environment"]:
                    cmd.extend(["-e", env_var])

        # Add volumes
        if "volumes" in config:
            for volume_mapping in config["volumes"]:
                cmd.extend(["-v", volume_mapping])

        # Add network
        if "network" in config:
            cmd.extend(["--network", config["network"]])

        # Add restart policy
        cmd.extend(["--restart", "unless-stopped"])

        # Add health check if available
        if "health_check" in config:
            health_config = config["health_check"]
            if health_config.get("enabled", True):
                cmd.extend(
                    [
                        "--health-cmd",
                        health_config.get(
                            "cmd", "curl -f http://localhost:8080/health || exit 1"
                        ),
                        "--health-interval",
                        f"{health_config.get('interval', 30)}s",
                        "--health-timeout",
                        f"{health_config.get('timeout', 10)}s",
                        "--health-retries",
                        str(health_config.get("retries", 3)),
                    ]
                )

        # Add labels for service identification
        cmd.extend(["--label", f"armonik.service={service_name}"])

        # Add partition label if available
        partition_name = config.get("partition_name")
        if partition_name:
            cmd.extend(["--label", f"armonik.partition={partition_name}"])

        # Add image
        image = f"{config['image']}:{config.get('tag', 'latest')}"
        cmd.append(image)

        # Add command if specified
        if "command" in config and config["command"]:
            cmd.extend(config["command"].split())

        return cmd


class ArmoniKLifecycleService:
    """Main lifecycle service with proper configuration handling"""

    def __init__(self, config_path: Optional[str] = None) -> None:
        self.logger = setup_logging()
        self.config_path = Path(config_path or self._get_default_config_path())
        self.config: Dict[str, Any] = {}
        self.service_manager = ServiceManager(self.logger)
        self.shutdown_event = threading.Event()

        # Settings
        self.health_check_interval = 30
        self.max_failures = 3
        self.restart_delay = 10

    def _get_default_config_path(self) -> str:
        """Get default config path based on platform"""
        if sys.platform == "win32":
            return "C:/ArmoniK/config/armonik_config.json"
        else:
            return "/etc/armonik/armonik_config.json"

    def load_configuration(self) -> bool:
        """Load configuration from file or GCP metadata"""
        try:
            # Try GCP metadata first
            if self._load_from_gcp_metadata():
                self._apply_config_settings()
                return True

            # Try local file
            if self.config_path.exists():
                with open(self.config_path, "r", encoding="utf-8") as f:
                    raw_config: Dict[str, Any] = json.load(f)

                # Handle nested structure
                if "armonik_config" in raw_config:
                    self.config = raw_config["armonik_config"]
                else:
                    self.config = raw_config

                self.logger.info("Loaded configuration from file: %s", self.config_path)
                self._apply_config_settings()
                return True

            # Create default config
            self.logger.warning("No configuration found, creating default")
            self._create_default_config()
            self._apply_config_settings()
            return True

        except (OSError, json.JSONDecodeError) as e:
            self.logger.error("Failed to load configuration: %s", e)
            self._create_default_config()
            self._apply_config_settings()
            return True

    def _load_from_gcp_metadata(self) -> bool:
        """Load configuration from GCP metadata"""
        try:
            req = urllib.request.Request(
                "http://metadata.google.internal/computeMetadata/v1/instance/attributes/armonik-config-json"
            )
            req.add_header("Metadata-Flavor", "Google")

            with urllib.request.urlopen(req, timeout=10) as response:
                config_json = response.read().decode("utf-8")
                raw_config: Dict[str, Any] = json.loads(config_json)

                # Handle nested structure
                if "armonik_config" in raw_config:
                    self.config = raw_config["armonik_config"]
                else:
                    self.config = raw_config

                self.logger.info("Loaded configuration from GCP metadata")
                return True

        except (urllib.error.URLError, json.JSONDecodeError) as e:
            self.logger.debug("GCP metadata not available: %s", e)
            return False

    def _apply_config_settings(self) -> None:
        """Apply configuration settings"""
        settings = self.config.get("settings", {})
        self.health_check_interval = settings.get("health_check_interval", 30)
        self.max_failures = settings.get("max_failures", 3)
        self.restart_delay = settings.get("restart_delay", 10)

    def _create_default_config(self) -> None:
        """Create default configuration"""
        self.config = {
            "services": {
                "armonik-polling-agent": {
                    "image": "dockerhubaneo/armonik_pollingagent",
                    "tag": "latest",
                    "ports": ["8080:8080"],
                    "environment": [
                        "ASPNETCORE_ENVIRONMENT=Production",
                        "ASPNETCORE_URLS=http://+:8080",
                        "Logging__LogLevel__Default=Information",
                    ],
                    "volumes": [
                        "C:/ArmoniK/shared:/shared",
                        "C:/ArmoniK/logs:/app/logs",
                    ],
                },
                "armonik-worker": {
                    "image": "dockerhubaneo/armonik_core_htcmock_test_client",
                    "tag": "latest",
                    "ports": ["8090:8090"],
                    "environment": [
                        "ASPNETCORE_ENVIRONMENT=Production",
                        "ASPNETCORE_URLS=http://+:8090",
                        "Logging__LogLevel__Default=Information",
                    ],
                    "volumes": [
                        "C:/ArmoniK/shared:/shared",
                        "C:/ArmoniK/logs:/app/logs",
                    ],
                },
            },
            "settings": {
                "health_check_interval": 30,
                "max_failures": 3,
                "restart_delay": 10,
            },
        }
        self.logger.info("Created default configuration")

    async def start_services(self) -> bool:
        """Start all configured services"""
        services = self.config.get("services", {})
        if not services:
            self.logger.warning("No services configured")
            return False

        success_count = 0
        for service_name, service_config in services.items():
            if await self.service_manager.start_service(service_name, service_config):
                success_count += 1
            else:
                self.logger.error("Failed to start service: %s", service_name)

        self.logger.info("Started %d/%d services", success_count, len(services))
        return success_count > 0

    async def stop_services(self) -> None:
        """Stop all services"""
        for service_name in list(self.service_manager.services.keys()):
            await self.service_manager.stop_service(service_name)

    async def health_check_loop(self) -> None:
        """Monitor service health and restart if needed"""
        failure_counts: Dict[str, int] = {}

        while not self.shutdown_event.is_set():
            try:
                for service_name in self.service_manager.services:
                    # Check if container is running
                    result = await asyncio.create_subprocess_exec(
                        "docker",
                        "ps",
                        "--filter",
                        f"name={service_name}",
                        "--format",
                        "{{.Names}}",
                        stdout=asyncio.subprocess.PIPE,
                        stderr=asyncio.subprocess.PIPE,
                    )
                    stdout, _ = await result.communicate()

                    if result.returncode == 0 and service_name in stdout.decode():
                        # Service is healthy, reset failure count
                        failure_counts[service_name] = 0
                        self.logger.debug("Service %s is healthy", service_name)
                    else:
                        # Service is unhealthy
                        failure_counts[service_name] = (
                            failure_counts.get(service_name, 0) + 1
                        )
                        self.logger.warning(
                            "Service %s is unhealthy (failures: %d)",
                            service_name,
                            failure_counts[service_name],
                        )

                        # Restart if max failures reached
                        if failure_counts[service_name] >= self.max_failures:
                            self.logger.info(
                                "Restarting failed service: %s", service_name
                            )
                            await self.service_manager.restart_service(service_name)
                            failure_counts[service_name] = 0
                            await asyncio.sleep(self.restart_delay)

                await asyncio.sleep(self.health_check_interval)

            except OSError as e:
                self.logger.error("Health check error: %s", e)
                await asyncio.sleep(5)

    def get_service_status(self) -> Dict[str, Any]:
        """Get status of all services"""
        return {
            "services": self.service_manager.services,
            "config": self.config,
            "health_interval": self.health_check_interval,
        }

    async def run(self) -> None:
        """Main service loop"""
        self.logger.info("Starting ArmoniK Lifecycle Service")

        # Load configuration
        if not self.load_configuration():
            self.logger.error("Failed to load configuration")
            return

        # Start services
        if not await self.start_services():
            self.logger.error("Failed to start services")
            return

        self.logger.info("ArmoniK Lifecycle Service started successfully")

        # Setup signal handlers
        def signal_handler(signum: int, _: Any) -> None:
            self.logger.info("Received signal %s, shutting down...", signum)
            self.shutdown_event.set()

        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGINT, signal_handler)

        try:
            # Health check loop
            await self.health_check_loop()
        finally:
            self.logger.info("Stopping services...")
            await self.stop_services()
            self.logger.info("ArmoniK Lifecycle Service stopped")


def main() -> None:
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="ArmoniK Lifecycle Service")
    parser.add_argument("--config", "-c", help="Configuration file path")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")

    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    service = ArmoniKLifecycleService(args.config)

    try:
        asyncio.run(service.run())
    except KeyboardInterrupt:
        print("\nService interrupted by user")
    except Exception as e:
        print(f"Service error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
