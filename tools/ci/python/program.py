import datetime
import time
from typing import Any
import grpc
import argparse
import json
import sys
from logging import Filter, LogRecord
import logging.config
from pathlib import Path
from armonik.client import ArmoniKTasks, ArmoniKSessions
from armonik.common import Task, TaskStatus, Session, SessionStatus, Direction


class LogMsgStripFilter(Filter):
    """Return a copy of the string with leading and trailing whitespace removed."""

    def filter(self, record: LogRecord) -> bool:
        try:
            record.msg = record.msg.strip()
        except AttributeError:
            pass
        return True


class ContextFilter(Filter):
    """Process context and return and empty dict when not provided"""

    def filter(self, record: Any) -> bool:
        try:
            _ = record.context
            if isinstance(_, dict):
                record.context = json.dumps(_)
        except AttributeError:
            record.context = {}
        return True


class SessionNotFoundError(Exception):
    """Exception raised when a session cannot be found"""

    pass


LEVEL = "INFO"
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "console": {
            "datefmt": "%Y-%m-%dT%H:%M:%S",
            "format": "%(asctime)s.%(msecs)03dZ%(levelname)s [%(funcName)s] | {"
            '"message": "%(message)s", "filename": "%(filename)s", "line": %(lineno)d, '
            '"context": %(context)s}',
        }
    },
    "filters": {
        "log_msg_strip_filter": {"()": LogMsgStripFilter},
        "context_filter": {"()": ContextFilter},
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": LEVEL,
            "formatter": "console",
            "filters": ["log_msg_strip_filter", "context_filter"],
        }
    },
    "loggers": {"my_logger": {"handlers": ["console"], "level": "INFO"}},
}

logging.config.dictConfig(LOGGING)
logger = logging.getLogger("my_logger")


def get_session_id_by_name(session_name: str, grpc_channel) -> str:
    """
    Retrieves a session id by its name defined as HtcMock.Options.SessionName .
    If multiple sessions have the same name, the one retrieved is the last from the list returned by the API

    Args:
        session_name: name of the session
        grpc_channel: gRPC channel with ArmoniK's control plane

    Returns:
        Session id

    Exception:
        SessionNotFoundError: When session_name cannot match any session's SessionName
    """

    sessions_client = ArmoniKSessions(grpc_channel)

    try:
        session_id = sessions_client.list_sessions(
            Session.options["SessionName"] == session_name
        )[1][-1].session_id
        return session_id
    except IndexError:
        raise SessionNotFoundError


def get_session_stats(session_id: str, grpc_channel: grpc.Channel) -> dict:
    """
    Retrieves stats for a session.
    For now retrieves throughput and number of tasks completed.

    Args:
        session_id: id of the session
        grpc_channel: gRPC channel with ArmoniK's control plane

    Returns:
        Dictionnary with metric name as key and metric value as value.
    """

    tasks_client = ArmoniKTasks(grpc_channel)

    tasks_count, tasks_list = tasks_client.list_tasks(
        (Task.status == TaskStatus.COMPLETED) & (Task.session_id == session_id),
        page=0,
        page_size=1,
        sort_field=Task.processed_at,
        sort_direction=Direction.ASC,
    )
    first_processed_task = tasks_list[0]

    last_ended_task = tasks_client.list_tasks(
        (Task.status == TaskStatus.COMPLETED) & (Task.session_id == session_id),
        page=0,
        page_size=1,
        sort_field=Task.ended_at,
        sort_direction=Direction.DESC,
    )[1][0]

    logger.info(
        "Session stats summary",
        extra={
            "context": {
                "Task count:": tasks_count,
                "First task started at": first_processed_task.started_at.strftime(
                    "%m/%d/%Y, %H:%M:%S"
                ),
                "Last task to end ended at": last_ended_task.ended_at.strftime(
                    "%m/%d/%Y, %H:%M:%S"
                ),
            }
        },
    )

    return {
        "tasks_count": tasks_count,
        "throughput": tasks_count
        / (last_ended_task.ended_at - first_processed_task.started_at).total_seconds(),
    }


def poll_session_ending(
    session_id: str, grpc_channel: grpc.Channel, polling_limit: float
):
    """
    Polls for a session to be completed (CANCELLED status).

    Args:
        session_id: name of the session
        grpc_channel: gRPC channel with ArmoniK's control plane
        polling_limit: number of seconds to poll before timeout

    Exception:
        If the session isn't completed in time, raises Timeout Error
    """

    sessions_client = ArmoniKSessions(grpc_channel)

    timeout_date = datetime.datetime.now() + datetime.timedelta(seconds=polling_limit)

    logger.info(
        "Session polling",
        extra={
            "context": {
                "Session polled": session_id,
                "Started to poll at": datetime.datetime.now().strftime(
                    "%m/%d/%Y, %H:%M:%S"
                ),
                "Will end polling at": timeout_date.strftime("%m/%d/%Y, %H:%M:%S"),
            }
        },
    )

    while datetime.datetime.now() < timeout_date:
        session_status = sessions_client.get_session(session_id).status
        if session_status != SessionStatus.CLOSED:
            logger.info(
                "Waiting for session to end",
                extra={"context": {"Session id": session_id}},
            )
            time.sleep(5)
        else:
            logger.info(
                "Session finished", extra={"context": {"Session id": session_id}}
            )
            return

    logger.error(
        "Polling timeout exceeded", extra={"context": {"Session id": session_id}}
    )

    raise TimeoutError("Polling duration was exceeded.")


def main(session_name: str, grpc_endpoint: str, polling_limit: float) -> list[dict]:
    """
    Retrieves a session's stats by its name.

    Args:
        session_id: name of the session
        grpc_channel: gRPC channel with ArmoniK's control plane
        polling_limit: number of seconds to poll before timeout

    Returns:
        The path to the JSON file containing the session's stats
    """

    with grpc.insecure_channel(f"{grpc_endpoint}:5001") as channel:
        session_id = get_session_id_by_name(session_name, channel)
        poll_session_ending(session_id, channel, polling_limit)
        session_stats = get_session_stats(session_id, channel)

    session_stats_json = [
        {
            "metadata": {"session_id": session_id, "session_name": session_name},
            "metrics": {
                "throughput": {
                    "name": "Throughput",
                    "unit": "Task per second",
                    "value": session_stats["throughput"],
                },
                "tasks_count": {
                    "name": "Total number of tasks",
                    "unit": "Task",
                    "value": session_stats["tasks_count"],
                },
            },
        }
    ]

    logger.debug(
        "Session stats",
        extra={
            "context": {
                "Session name": session_name,
                "Session id": session_id,
                "Bench Results": session_stats_json,
            }
        },
    )

    return session_stats_json


def write_json_output(session_stats_json: dict, path: str = "") -> str:
    """
    Writes a session stats file in JSON.

    Args:
        session_id: name of the session
        grpc_channel: gRPC channel with ArmoniK's control plane
        polling_limit: number of seconds to poll before timeout
        path: relative path where to store session's stats

    Returns:
        Absolute path to the JSON file containing the session's stats.
    """

    file_directory = Path(path)
    file_directory.mkdir(parents=True, exist_ok=True)

    file_name = f"session_{session_stats[0]['metadata']['session_id']}_benchmark_{session_stats[0]['metrics']['tasks_count']['value']}tasks.json"

    absolute_file_path = file_directory.resolve() / file_name

    content = json.dumps(session_stats)

    logger.debug(
        "JSON file to be written",
        extra={
            "context": {
                "directory": file_directory,
                "filename": file_name,
                "path": absolute_file_path,
                "content": content,
            }
        },
    )

    with open(absolute_file_path, "w") as output_file:
        output_file.write(content)

    return absolute_file_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("grpc_endpoint", type=str)
    parser.add_argument("-n", "--session-name", type=str, default="")
    parser.add_argument("-l", "--polling-limit", type=float, default=300)
    parser.add_argument("-p", "--output-path", type=str, default="")

    args = parser.parse_args()

    try:
        session_stats = main(args.session_name, args.grpc_endpoint, args.polling_limit)
        output_path = write_json_output(session_stats)
        print(output_path, file=sys.stdout)
    except SessionNotFoundError:
        logger.error(
            "Session not found",
            extra={"context": {"Session name provided": args.session_name}},
        )
        sys.exit(1)
    except TimeoutError:
        logger.error(
            "Session exceeded polling duration",
            extra={"context": {"Session name provided": args.session_name}},
        )
        sys.exit(1)