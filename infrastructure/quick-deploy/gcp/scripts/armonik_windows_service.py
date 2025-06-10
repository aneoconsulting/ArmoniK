#!/usr/bin/env python3
"""
Windows Service wrapper for ArmoniK Lifecycle Service

This module provides a Windows service wrapper that manages the ArmoniK
lifecycle service as a proper Windows service with proper logging and
error handling.

Author: ArmoniK Infrastructure Team
Version: 2.1.0
"""

import logging
import os
import sys
import threading
import time
from logging.handlers import RotatingFileHandler
from typing import Any, Optional

try:
    import servicemanager
    import win32event
    import win32service
    import win32serviceutil
except ImportError:
    print("Windows service modules not available. This script requires pywin32.")
    sys.exit(1)

# Add the script directory to Python path
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

try:
    from armonik_lifecycle_service import ArmoniKLifecycleService
except ImportError:
    print("Could not import ArmoniK lifecycle service")
    sys.exit(1)


class ArmoniKWindowsService(win32serviceutil.ServiceFramework):
    """Windows service wrapper for ArmoniK Lifecycle Service"""

    _svc_name_ = "ArmoniKLifecycle"
    _svc_display_name_ = "ArmoniK Lifecycle Management Service"
    _svc_description_ = (
        "Manages ArmoniK polling agent and worker processes with health monitoring"
    )

    def __init__(self, args: Any) -> None:
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        self.lifecycle_service: Optional[ArmoniKLifecycleService] = None
        self.logger: Optional[logging.Logger] = None
        self.service_thread: Optional[threading.Thread] = None

    def SvcStop(self) -> None:
        """Handle service stop"""
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)

        if self.logger:
            self.logger.info("ArmoniK Windows Service is stopping...")

        if self.lifecycle_service:
            try:
                self.lifecycle_service.stop()
            except Exception as e:
                if self.logger:
                    self.logger.error("Error stopping lifecycle service: %s", e)

        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self) -> None:
        """Main service execution"""
        try:
            self.setup_service_logging()
            if self.logger:
                self.logger.info("ArmoniK Windows Service is starting...")

            # Start the lifecycle service in a separate thread
            self.service_thread = threading.Thread(target=self.run_lifecycle_service)
            self.service_thread.daemon = False
            self.service_thread.start()

            # Wait for stop event
            win32event.WaitForSingleObject(self.hWaitStop, win32event.INFINITE)

            if self.logger:
                self.logger.info("ArmoniK Windows Service stopped")

        except Exception as e:
            if self.logger:
                self.logger.error("Error in service execution: %s", e)
            else:
                servicemanager.LogErrorMsg(f"Error in service execution: {e}")
        finally:
            if self.lifecycle_service:
                try:
                    self.lifecycle_service.stop()
                except Exception as e:
                    if self.logger:
                        self.logger.error("Error in final cleanup: %s", e)

    def run_lifecycle_service(self) -> None:
        """Run the lifecycle service"""
        try:
            config_file = os.path.join(script_dir, "armonik_config.json")
            self.lifecycle_service = ArmoniKLifecycleService(config_file)

            if self.lifecycle_service.start():
                if self.logger:
                    self.logger.info("ArmoniK Lifecycle Service started successfully")

                # Keep the service running
                while self.lifecycle_service.running:
                    time.sleep(1)

                    # Check if we should stop
                    if (
                        win32event.WaitForSingleObject(self.hWaitStop, 100)
                        == win32event.WAIT_OBJECT_0
                    ):
                        break
            else:
                if self.logger:
                    self.logger.error("Failed to start ArmoniK Lifecycle Service")
                self.SvcStop()

        except Exception as e:
            if self.logger:
                self.logger.error("Error running lifecycle service: %s", e)
            self.SvcStop()

    def setup_service_logging(self) -> None:
        """Setup logging for Windows service"""
        log_dir = r"C:\ArmoniK\logs"
        os.makedirs(log_dir, exist_ok=True)

        log_file = os.path.join(log_dir, "armonik_windows_service.log")

        self.logger = logging.getLogger("armonik_windows_service")
        self.logger.setLevel(logging.INFO)

        # Clear any existing handlers
        for handler in self.logger.handlers[:]:
            self.logger.removeHandler(handler)

        # File handler with rotation
        max_size = 10 * 1024 * 1024  # 10MB
        backup_count = 5

        file_handler = RotatingFileHandler(
            log_file, maxBytes=max_size, backupCount=backup_count
        )

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        file_handler.setFormatter(formatter)
        self.logger.addHandler(file_handler)

        # Also log to Windows Event Log
        try:
            event_handler = logging.handlers.NTEventLogHandler(
                "ArmoniK Lifecycle Service"
            )
            event_handler.setFormatter(formatter)
            self.logger.addHandler(event_handler)
        except Exception:
            # If event log handler fails, continue without it
            pass

        self.logger.info("Service logging initialized")


def install_service() -> bool:
    """Install the Windows service"""
    try:
        win32serviceutil.InstallService(
            ArmoniKWindowsService._svc_reg_class_,
            ArmoniKWindowsService._svc_name_,
            ArmoniKWindowsService._svc_display_name_,
            description=ArmoniKWindowsService._svc_description_,
        )
        print(
            f"Service '{ArmoniKWindowsService._svc_display_name_}' installed successfully"
        )
    except Exception as e:
        print(f"Failed to install service: {e}")
        return False
    return True


def remove_service() -> bool:
    """Remove the Windows service"""
    try:
        win32serviceutil.RemoveService(ArmoniKWindowsService._svc_name_)
        print(
            f"Service '{ArmoniKWindowsService._svc_display_name_}' removed successfully"
        )
    except Exception as e:
        print(f"Failed to remove service: {e}")
        return False
    return True


def start_service() -> bool:
    """Start the Windows service"""
    try:
        win32serviceutil.StartService(ArmoniKWindowsService._svc_name_)
        print(
            f"Service '{ArmoniKWindowsService._svc_display_name_}' started successfully"
        )
    except Exception as e:
        print(f"Failed to start service: {e}")
        return False
    return True


def stop_service() -> bool:
    """Stop the Windows service"""
    try:
        win32serviceutil.StopService(ArmoniKWindowsService._svc_name_)
        print(
            f"Service '{ArmoniKWindowsService._svc_display_name_}' stopped successfully"
        )
    except Exception as e:
        print(f"Failed to stop service: {e}")
        return False
    return True


def main() -> None:
    """Main entry point for service management"""
    if len(sys.argv) == 1:
        # Run as service
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(ArmoniKWindowsService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        # Handle service management commands
        if len(sys.argv) == 2:
            command = sys.argv[1].lower()
            if command == "install":
                install_service()
            elif command == "remove":
                remove_service()
            elif command == "start":
                start_service()
            elif command == "stop":
                stop_service()
            elif command == "debug":
                # Run in debug mode (not as service)
                print("Running in debug mode...")
                config_file = os.path.join(script_dir, "armonik_config.json")
                service = ArmoniKLifecycleService(config_file)
                try:
                    if service.start():
                        print("Service started. Press Ctrl+C to stop.")
                        while service.running:
                            time.sleep(1)
                    else:
                        print("Failed to start service")
                except KeyboardInterrupt:
                    print("Stopping service...")
                    service.stop()
            else:
                print(f"Unknown command: {command}")
                print(
                    "Usage: python armonik_windows_service.py [install|remove|start|stop|debug]"
                )
        else:
            # Default service management
            win32serviceutil.HandleCommandLine(ArmoniKWindowsService)


if __name__ == "__main__":
    main()
