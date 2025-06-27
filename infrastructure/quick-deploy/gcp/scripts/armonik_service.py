#!/usr/bin/env python3
"""
ArmoniK Service for GCE Windows - Enhanced with Docker Compatibility

Robust service that automatically detects Docker mode and adapts accordingly.
Handles both Linux containers (preferred) and Windows compatibility mode.
"""

import asyncio
import json
import logging
import signal
import sys
import threading
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def setup_logging() -> logging.Logger:
    """Setup logging for Windows"""
    logger = logging.getLogger("armonik_service_enhanced")
    logger.setLevel(logging.INFO)

    if not logger.handlers:
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )

        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        # File handler
        try:
            log_dir = Path("C:/ArmoniK/logs")
            log_dir.mkdir(parents=True, exist_ok=True)
            file_handler = logging.FileHandler(log_dir / "armonik_service_enhanced.log")
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
        except OSError:
            pass

    return logger


class DockerModeDetector:
    """Detects Docker mode and compatibility"""

    def __init__(self, logger: logging.Logger):
        self.logger = logger

    async def check_docker_mode(self) -> str:
        """Check if Docker is running in Linux or Windows mode"""
        try:
            result = await asyncio.create_subprocess_exec(
                "docker",
                "info",
                "--format",
                "json",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                info = json.loads(stdout.decode())
                os_type = info.get("OSType", "").lower()
                self.logger.info(f"Docker OS Type: {os_type}")
                return os_type
            else:
                self.logger.error(f"Failed to get Docker info: {stderr.decode()}")
                return "unknown"

        except Exception as e:
            self.logger.error(f"Error checking Docker mode: {e}")
            return "unknown"

    async def test_linux_container_support(self) -> bool:
        """Test if we can run Linux containers"""
        try:
            self.logger.info("Testing Linux container support...")
            result = await asyncio.create_subprocess_exec(
                "docker",
                "run",
                "--rm",
                "hello-world",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                self.logger.info("Linux containers are supported")
                return True
            else:
                self.logger.warning(f"Linux container test failed: {stderr.decode()}")
                return False

        except Exception as e:
            self.logger.error(f"Failed to test Linux containers: {e}")
            return False

    async def check_image_availability(self, image: str) -> bool:
        """Check if a Docker image can be pulled"""
        try:
            self.logger.info(f"Checking image availability: {image}")
            result = await asyncio.create_subprocess_exec(
                "docker",
                "manifest",
                "inspect",
                image,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await result.communicate()

            return result.returncode == 0

        except Exception as e:
            self.logger.error(f"Error checking image {image}: {e}")
            return False


class ArmoniKEnhancedService:
    """Enhanced ArmoniK service with Docker compatibility handling"""

    def __init__(self) -> None:
        self.logger = setup_logging()
        self.config: Dict[str, Any] = {}
        self.containers: Dict[str, Dict[str, Any]] = {}
        self.shutdown_event = threading.Event()
        self.health_check_interval = 30
        self.docker_detector = DockerModeDetector(self.logger)
        self.docker_mode = "unknown"
        self.linux_containers_supported = False

    async def detect_docker_environment(self) -> bool:
        """Detect Docker environment and capabilities"""
        self.logger.info("Detecting Docker environment...")

        self.docker_mode = await self.docker_detector.check_docker_mode()
        self.linux_containers_supported = (
            await self.docker_detector.test_linux_container_support()
        )

        self.logger.info(f"Docker mode: {self.docker_mode}")
        self.logger.info(
            f"Linux containers supported: {self.linux_containers_supported}"
        )

        return self.docker_mode != "unknown"

    def load_configuration(self) -> bool:
        """Load configuration from GCP metadata or local file"""
        try:
            # Try GCP metadata first
            if self._load_from_gcp_metadata():
                return True

            # Fall back to local file
            config_path = Path("C:/ArmoniK/config/armonik_config.json")
            if config_path.exists():
                with open(config_path, "r") as f:
                    config_data = json.load(f)

                if "armonik" in config_data:
                    self.config = config_data
                else:
                    self.config = self._convert_services_to_armonik_config(config_data)

                self.logger.info("Configuration loaded from local file")
                return True

            # Create default config
            self._create_default_config()
            return True

        except (OSError, json.JSONDecodeError) as e:
            self.logger.error("Failed to load configuration: %s", e)
            self._create_default_config()
            return True

    def _load_from_gcp_metadata(self) -> bool:
        """Load configuration from GCP metadata"""
        try:
            headers = {"Metadata-Flavor": "Google"}

            # Try armonik_config first
            try:
                req = urllib.request.Request(
                    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/armonik_config",
                    headers=headers,
                )
                with urllib.request.urlopen(req, timeout=10) as response:
                    config_str = response.read().decode()
                    self.config = json.loads(config_str)
                    self.logger.info(
                        "Configuration loaded from GCP metadata (armonik_config)"
                    )
                    return True
            except (urllib.error.URLError, json.JSONDecodeError):
                pass

            # Try armonik-config-json
            try:
                req = urllib.request.Request(
                    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/armonik-config-json",
                    headers=headers,
                )
                with urllib.request.urlopen(req, timeout=10) as response:
                    config_str = response.read().decode()
                    config_data = json.loads(config_str)

                    if "armonik" in config_data:
                        self.config = config_data
                    else:
                        self.config = self._convert_services_to_armonik_config(
                            config_data
                        )

                    self.logger.info(
                        "Configuration loaded from GCP metadata (armonik-config-json)"
                    )
                    return True
            except (urllib.error.URLError, json.JSONDecodeError):
                pass

            return False

        except Exception as e:
            self.logger.error("Error loading from GCP metadata: %s", e)
            return False

    def _convert_services_to_armonik_config(
        self, services_config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Convert services-based config to armonik format"""
        armonik_config: Dict[str, Any] = {
            "armonik": {
                "images": {
                    "polling_agent": "dockerhubaneo/armonik_pollingagent:latest",
                    "worker": "dockerhubaneo/armonik_core_htcmock_test_client:latest",
                },
                "environment": {
                    "ASPNETCORE_ENVIRONMENT": "Production",
                    "ASPNETCORE_URLS": "http://+:8090",
                    "Logging__LogLevel__Default": "Information",
                    "ARMONIK_SHARED_VOLUME": "C:/ArmoniK/shared",
                },
                "docker_config": {
                    "shared_volume_host_path": "C:\\ArmoniK\\shared",
                    "shared_volume_container_path": "/shared",
                },
            },
            "deployment": {"partition_name": "windows-partition"},
        }

        # Extract polling agent and worker from services
        services: Dict[str, Any] = services_config.get("services", {})
        for service_name, service_config in services.items():
            if "polling" in service_name.lower():
                armonik_config["armonik"]["images"][
                    "polling_agent"
                ] = f"{service_config.get('image', 'dockerhubaneo/armonik_pollingagent')}:{service_config.get('tag', 'latest')}"
            elif "worker" in service_name.lower():
                armonik_config["armonik"]["images"][
                    "worker"
                ] = f"{service_config.get('image', 'dockerhubaneo/armonik_core_htcmock_test_client')}:{service_config.get('tag', 'latest')}"

        return armonik_config

    def _create_default_config(self) -> None:
        """Create default configuration"""
        self.config = {
            "armonik": {
                "images": {
                    "polling_agent": "dockerhubaneo/armonik_pollingagent:latest",
                    "worker": "dockerhubaneo/armonik_core_htcmock_test_client:latest",
                },
                "environment": {
                    "ASPNETCORE_ENVIRONMENT": "Production",
                    "ASPNETCORE_URLS": "http://+:8090",
                    "Logging__LogLevel__Default": "Information",
                    "ARMONIK_SHARED_VOLUME": "C:/ArmoniK/shared",
                },
                "docker_config": {
                    "shared_volume_host_path": "C:\\ArmoniK\\shared",
                    "shared_volume_container_path": "/shared",
                },
            },
            "deployment": {"partition_name": "windows-partition"},
        }
        self.logger.info("Using default configuration")

    async def start_containers(self) -> bool:
        """Start ArmoniK containers with compatibility handling"""
        try:
            armonik = self.config.get("armonik", {})
            images = armonik.get("images", {})
            environment = armonik.get("environment", {})
            docker_config = armonik.get("docker_config", {})

            # Create directories
            shared_path = Path(
                docker_config.get("shared_volume_host_path", "C:/ArmoniK/shared")
            )
            logs_path = Path("C:/ArmoniK/logs")
            shared_path.mkdir(parents=True, exist_ok=True)
            logs_path.mkdir(parents=True, exist_ok=True)

            # Check image availability for Linux containers
            if self.linux_containers_supported:
                polling_available = await self.docker_detector.check_image_availability(
                    images.get("polling_agent", "")
                )
                worker_available = await self.docker_detector.check_image_availability(
                    images.get("worker", "")
                )

                if polling_available and worker_available:
                    self.logger.info("Starting ArmoniK with Linux containers")
                    return await self._start_linux_containers(
                        images, environment, shared_path, logs_path
                    )
                else:
                    self.logger.warning(
                        "ArmoniK images not available, falling back to compatibility mode"
                    )

            # Fallback to compatibility mode
            self.logger.info("Starting ArmoniK in compatibility mode")
            return await self._start_compatibility_mode()

        except Exception as e:
            self.logger.error("Error starting containers: %s", e)
            return False

    async def _start_linux_containers(
        self, images: Dict, environment: Dict, shared_path: Path, logs_path: Path
    ) -> bool:
        """Start actual ArmoniK Linux containers"""
        success_count = 0

        # Create Docker network
        await self._create_docker_network()

        # Start polling agent
        if await self._start_polling_agent_linux(
            images, environment, shared_path, logs_path
        ):
            success_count += 1
            await asyncio.sleep(10)  # Wait for startup

            # Start worker
            if await self._start_worker_linux(
                images, environment, shared_path, logs_path
            ):
                success_count += 1

        return success_count > 0

    async def _start_compatibility_mode(self) -> bool:
        """Start health server for compatibility when Linux containers don't work"""
        try:
            # Start the health server process
            health_server_path = Path("C:/ArmoniK/scripts/health_server_external.py")

            if not health_server_path.exists():
                self.logger.error("Health server script not found")
                return False

            self.logger.info("Starting health server in compatibility mode...")

            # Use the existing health server
            process = await asyncio.create_subprocess_exec(
                "python",
                str(health_server_path),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )

            # Track the process
            self.containers["health-server"] = {
                "process": process,
                "type": "health-server",
                "port": 8080,
            }

            self.logger.info("Health server started in compatibility mode")
            return True

        except Exception as e:
            self.logger.error(f"Failed to start compatibility mode: {e}")
            return False

    async def _start_polling_agent_linux(
        self, images: Dict, environment: Dict, shared_path: Path, logs_path: Path
    ) -> bool:
        """Start polling agent Linux container with dynamic configuration"""
        container_name = "armonik-polling-agent"

        # Get partition configuration
        partition_name = self.config.get("deployment", {}).get(
            "partition_name", "htcmock"
        )
        partition_config = (
            self.config.get("armonik", {}).get("partitions", {}).get(partition_name, {})
        )

        # Determine polling agent image from partition config or fallback
        if partition_config.get("polling_agent_image") and partition_config.get(
            "polling_agent_tag"
        ):
            image = f"{partition_config['polling_agent_image']}:{partition_config['polling_agent_tag']}"
        else:
            image = images.get(
                "polling_agent", "dockerhubaneo/armonik_pollingagent:0.33.1"
            )

        # Build comprehensive environment variables
        polling_env = self._build_polling_agent_environment(
            environment, partition_config, partition_name
        )

        # Format paths for Linux containers
        shared_volume = f"{shared_path}:/shared:rw"
        logs_volume = f"{logs_path}:/app/logs:rw"

        cmd = [
            "docker",
            "run",
            "-d",
            "--name",
            container_name,
            "--network",
            "armonik-network",
            "--restart",
            "unless-stopped",
            "-p",
            "8080:8080",
            "-v",
            shared_volume,
            "-v",
            logs_volume,
            "--health-cmd",
            "curl -f http://localhost:8080/health || exit 1",
            "--health-interval",
            "30s",
            "--health-timeout",
            "10s",
            "--health-retries",
            "3",
            "--label",
            "armonik.service=polling-agent",
            "--label",
            f"armonik.partition={partition_name}",
        ]

        # Add environment variables
        for key, value in polling_env.items():
            cmd.extend(["-e", f"{key}={value}"])

        cmd.append(image)

        return await self._execute_docker_command(container_name, cmd)

    async def _start_worker_linux(
        self, images: Dict, environment: Dict, shared_path: Path, logs_path: Path
    ) -> bool:
        """Start worker Linux container with dynamic configuration"""
        container_name = "armonik-worker"

        # Get partition configuration
        partition_name = self.config.get("deployment", {}).get(
            "partition_name", "htcmock"
        )
        partition_config = (
            self.config.get("armonik", {}).get("partitions", {}).get(partition_name, {})
        )

        # Determine worker image from partition config or fallback
        if partition_config.get("image") and partition_config.get("tag"):
            image = f"{partition_config['image']}:{partition_config['tag']}"
        else:
            image = images.get(
                "worker", "dockerhubaneo/armonik_core_htcmock_test_worker:0.33.1"
            )

        # Build comprehensive environment variables
        worker_env = self._build_worker_environment(
            environment, partition_config, partition_name
        )

        # Format paths for Linux containers
        shared_volume = f"{shared_path}:/shared:rw"
        logs_volume = f"{logs_path}:/app/logs:rw"

        cmd = [
            "docker",
            "run",
            "-d",
            "--name",
            container_name,
            "--network",
            "armonik-network",
            "--restart",
            "unless-stopped",
            "-p",
            "8090:8090",
            "-v",
            shared_volume,
            "-v",
            logs_volume,
            "--health-cmd",
            "curl -f http://localhost:8090/health || exit 1",
            "--health-interval",
            "30s",
            "--health-timeout",
            "10s",
            "--health-retries",
            "3",
            "--label",
            "armonik.service=worker",
            "--label",
            f"armonik.partition={partition_name}",
            "--link",
            "armonik-polling-agent:polling-agent",
        ]

        # Add environment variables
        for key, value in worker_env.items():
            cmd.extend(["-e", f"{key}={value}"])

        cmd.append(image)

        return await self._execute_docker_command(container_name, cmd)

    def _build_worker_environment(
        self, base_environment: Dict, partition_config: Dict, partition_name: str
    ) -> Dict[str, str]:
        """Build comprehensive worker environment variables from base config and partition-specific settings"""
        worker_env = {}

        # Set essential worker environment variables (common to all workers)
        essential_vars = {
            "ASPNETCORE_URLS": "http://+:8090",
            "PollingAgent__Endpoint": "http://armonik-polling-agent:8080",
            "ASPNETCORE_ENVIRONMENT": "Production",
            "Logging__LogLevel__Default": "Information",
            "Logging__LogLevel__Microsoft": "Warning",
            "Logging__LogLevel__System": "Warning",
            "ARMONIK_SHARED_VOLUME": "/shared",
            "Partition": partition_name,
        }
        worker_env.update(essential_vars)

        # Add core worker environment variables from base (those not worker-type specific)
        core_worker_vars = {
            "ComputePlane__WorkerChannel__Address": base_environment.get(
                "ComputePlane__WorkerChannel__Address", "localhost:5555"
            ),
            "ComputePlane__WorkerChannel__SocketType": base_environment.get(
                "ComputePlane__WorkerChannel__SocketType", "Tcp"
            ),
            "ComputePlane__AgentChannel__Address": base_environment.get(
                "ComputePlane__AgentChannel__Address", "localhost:5556"
            ),
            "ComputePlane__AgentChannel__SocketType": base_environment.get(
                "ComputePlane__AgentChannel__SocketType", "Tcp"
            ),
            "Pollster__SharedCacheFolder": base_environment.get(
                "Pollster__SharedCacheFolder", "/shared/cache"
            ),
            "Pollster__InternalCacheFolder": base_environment.get(
                "Pollster__InternalCacheFolder", "/shared/internal"
            ),
            "InitWorker__WorkerCheckDelay": base_environment.get(
                "InitWorker__WorkerCheckDelay", "00:00:01"
            ),
            "InitWorker__WorkerCheckRetries": base_environment.get(
                "InitWorker__WorkerCheckRetries", "10"
            ),
        }
        worker_env.update(core_worker_vars)

        # Add partition-specific environment variables (highest priority)
        partition_env = partition_config.get("environment", {})
        worker_env.update(partition_env)

        # For HTC Mock, ensure all required variables are present with defaults
        if "htcmock" in partition_name.lower():
            htc_defaults = {
                "HtcMock__NTasks": "100",
                "HtcMock__TotalCalculationTime": "00:00:00.100",
                "HtcMock__DataSize": "1",
                "HtcMock__MemorySize": "1",
                "HtcMock__EnableFastCompute": "true",
                "HtcMock__EnableUseLowMem": "true",
                "HtcMock__EnableSmallOutput": "true",
                "HtcMock__SubTasksLevels": "4",
                "HtcMock__Partition": partition_name,
                "HtcMock__TaskRpcException": "",
                "HtcMock__TaskError": "",
            }

            # Add defaults only if not already set
            for key, default_value in htc_defaults.items():
                if key not in worker_env:
                    worker_env[key] = default_value

        self.logger.info(
            f"Built worker environment for partition '{partition_name}' with {len(worker_env)} variables"
        )

        return worker_env

    def _build_polling_agent_environment(
        self, base_environment: Dict, partition_config: Dict, partition_name: str
    ) -> Dict[str, str]:
        """Build comprehensive polling agent environment variables from base config and partition-specific settings"""
        polling_env = dict(base_environment)

        # Set essential polling agent environment variables
        polling_env.update(
            {
                "ASPNETCORE_URLS": "http://+:8080",
                "ASPNETCORE_ENVIRONMENT": "Production",
                "Logging__LogLevel__Default": "Information",
                "Logging__LogLevel__Microsoft": "Warning",
                "Logging__LogLevel__System": "Warning",
            }
        )

        # Add polling agent-specific environment from main config
        polling_agent_env = self.config.get("armonik", {}).get(
            "polling_agent_environment", {}
        )
        polling_env.update(polling_agent_env)

        # Override partition-specific settings
        if "Amqp__PartitionId" not in polling_env:
            polling_env["Amqp__PartitionId"] = partition_name

        self.logger.info(
            f"Built polling agent environment for partition '{partition_name}' with {len(polling_env)} variables"
        )

        return polling_env

    async def _execute_docker_command(
        self, container_name: str, cmd: List[str]
    ) -> bool:
        """Execute Docker command and track container"""
        try:
            # Stop existing container first
            await self._stop_container(container_name)

            self.logger.info("Starting container: %s", container_name)
            self.logger.debug("Docker command: %s", " ".join(cmd))

            result = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                container_id = stdout.decode().strip()
                self.containers[container_name] = {
                    "id": container_id,
                    "type": "docker-container",
                }
                self.logger.info(
                    "Container %s started with ID: %s",
                    container_name,
                    container_id[:12],
                )
                return True
            else:
                error_msg = stderr.decode()
                self.logger.error(
                    "Failed to start container %s: %s", container_name, error_msg
                )

                # Check for specific Docker issues
                if "no matching manifest" in error_msg.lower():
                    self.logger.error(
                        "Image is not compatible with current Docker mode"
                    )
                elif "image operating system" in error_msg.lower():
                    self.logger.error("Linux image cannot run on Windows Docker mode")

                return False

        except Exception as e:
            self.logger.error(
                "Error executing Docker command for %s: %s", container_name, e
            )
            return False

    async def _stop_container(self, container_name: str) -> bool:
        """Stop and remove a container"""
        try:
            # Stop container
            stop_result = await asyncio.create_subprocess_exec(
                "docker",
                "stop",
                container_name,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            await stop_result.communicate()

            # Remove container
            rm_result = await asyncio.create_subprocess_exec(
                "docker",
                "rm",
                container_name,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            await rm_result.communicate()

            return True

        except Exception:
            return False

    async def _create_docker_network(self) -> bool:
        """Create Docker network for ArmoniK containers"""
        try:
            # Check if network exists
            check_result = await asyncio.create_subprocess_exec(
                "docker",
                "network",
                "inspect",
                "armonik-network",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await check_result.communicate()

            if check_result.returncode == 0:
                self.logger.info("Docker network 'armonik-network' already exists")
                return True

            # Create network
            create_result = await asyncio.create_subprocess_exec(
                "docker",
                "network",
                "create",
                "armonik-network",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await create_result.communicate()

            if create_result.returncode == 0:
                self.logger.info("Created Docker network 'armonik-network'")
                return True
            else:
                self.logger.error(
                    "Failed to create Docker network: %s", stderr.decode()
                )
                return False

        except Exception as e:
            self.logger.error("Error creating Docker network: %s", e)
            return False

    async def health_check_loop(self) -> None:
        """Monitor container/process health"""
        while not self.shutdown_event.is_set():
            try:
                for name, container_info in self.containers.items():
                    if container_info["type"] == "docker-container":
                        # Check Docker container health
                        await self._check_docker_container_health(name)
                    elif container_info["type"] == "health-server":
                        # Check health server process
                        await self._check_health_server_process(name, container_info)

                await asyncio.sleep(self.health_check_interval)

            except Exception as e:
                self.logger.error("Error in health check loop: %s", e)
                await asyncio.sleep(self.health_check_interval)

    async def _check_docker_container_health(self, container_name: str) -> bool:
        """Check Docker container health"""
        try:
            result = await asyncio.create_subprocess_exec(
                "docker",
                "inspect",
                "--format",
                "{{.State.Health.Status}}",
                container_name,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await result.communicate()

            if result.returncode == 0:
                health_status = stdout.decode().strip()
                if health_status in ["healthy", "starting"]:
                    return True
                else:
                    self.logger.warning(
                        "Container %s health status: %s", container_name, health_status
                    )
                    return False
            else:
                self.logger.warning(
                    "Failed to check health for %s: %s", container_name, stderr.decode()
                )
                return False

        except Exception as e:
            self.logger.error(
                "Error checking container health for %s: %s", container_name, e
            )
            return False

    async def _check_health_server_process(
        self, name: str, container_info: Dict
    ) -> bool:
        """Check if health server process is still running"""
        try:
            process = container_info.get("process")
            if process and process.returncode is None:
                return True
            else:
                self.logger.warning("Health server process %s has stopped", name)
                return False
        except Exception as e:
            self.logger.error("Error checking health server process %s: %s", name, e)
            return False

    async def stop_containers(self) -> None:
        """Stop all containers and processes"""
        for name, container_info in list(self.containers.items()):
            if container_info["type"] == "docker-container":
                await self._stop_container(name)
            elif container_info["type"] == "health-server":
                process = container_info.get("process")
                if process:
                    try:
                        process.terminate()
                        await process.wait()
                    except Exception as e:
                        self.logger.error("Error stopping health server process: %s", e)

            del self.containers[name]

    async def run(self) -> None:
        """Main service loop"""
        self.logger.info("Starting Enhanced ArmoniK GCE Service")

        # Detect Docker environment
        if not await self.detect_docker_environment():
            self.logger.error("Failed to detect Docker environment")
            return

        # Load configuration
        if not self.load_configuration():
            self.logger.error("Failed to load configuration")
            return

        # Start containers
        if not await self.start_containers():
            self.logger.error("Failed to start any containers")
            return

        self.logger.info("Enhanced ArmoniK GCE Service started successfully")

        # Setup signal handlers
        def signal_handler(signum: int, _: Any) -> None:
            self.logger.info("Received signal %d, shutting down...", signum)
            self.shutdown_event.set()

        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGINT, signal_handler)

        try:
            # Start health check loop
            await self.health_check_loop()
        finally:
            self.logger.info("Stopping containers...")
            await self.stop_containers()
            self.logger.info("Enhanced ArmoniK GCE Service stopped")

    def generate_docker_run_command(self, partition_name: str = None) -> str:
        """Generate the complete Docker run command for a specific worker type for debugging/validation"""
        if not partition_name:
            partition_name = self.config.get("deployment", {}).get(
                "partition_name", "htcmock"
            )

        partition_config = (
            self.config.get("armonik", {}).get("partitions", {}).get(partition_name, {})
        )

        if not partition_config:
            self.logger.error(
                f"Partition '{partition_name}' not found in configuration"
            )
            return None

        # Get worker image
        if partition_config.get("image") and partition_config.get("tag"):
            image = f"{partition_config['image']}:{partition_config['tag']}"
        else:
            image = "dockerhubaneo/armonik_core_htcmock_test_worker:0.33.1"

        # Build environment
        base_env = self.config.get("armonik", {}).get("worker_environment", {})
        worker_env = self._build_worker_environment(
            base_env, partition_config, partition_name
        )

        # Build the command
        cmd_parts = [
            "docker run -d",
            "--name armonik-worker",
            "--network armonik-network",
            "--restart unless-stopped",
            "-p 8090:8090",
            "-v /shared:/shared:rw",
            "-v /logs:/app/logs:rw",
            "--health-cmd 'curl -f http://localhost:8090/health || exit 1'",
            "--health-interval 30s",
            "--health-timeout 10s",
            "--health-retries 3",
            "--label armonik.service=worker",
            f"--label armonik.partition={partition_name}",
            "--link armonik-polling-agent:polling-agent",
        ]

        # Add environment variables
        for key, value in worker_env.items():
            cmd_parts.append(f"-e {key}={value}")

        cmd_parts.append(image)

        full_command = " \\\n  ".join(cmd_parts)
        self.logger.info(
            f"Generated Docker run command for partition '{partition_name}'"
        )

        return full_command


def main() -> None:
    """Main entry point"""
    service = ArmoniKEnhancedService()

    try:
        asyncio.run(service.run())
    except KeyboardInterrupt:
        print("\nService interrupted by user")
    except Exception as e:
        print(f"Service error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
