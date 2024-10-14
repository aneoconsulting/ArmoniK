import datetime
import time
import grpc
import argparse
from armonik.client import ArmoniKTasks, ArmoniKSessions
from armonik.common import Task, TaskStatus, Session, SessionStatus, Direction


def get_session_id_by_name(session_name: str, grpc_channel) -> str:
    sessions_client = ArmoniKSessions(grpc_channel)
    return sessions_client.list_sessions(
        Session.options["SessionName"] == session_name
    )[1][-1].session_id


def get_session_throughput(session_id: str, grpc_channel: grpc.Channel):
    tasks_client = ArmoniKTasks(grpc_channel)

    class ThroughputGetterHelper:
        FIRST = Direction.ASC
        LAST = Direction.DESC

    def get_first_or_last_task(
        which: ThroughputGetterHelper, return_count: bool = False
    ):
        count, task = tasks_client.list_tasks(
            (Task.status == TaskStatus.COMPLETED) & (Task.session_id == session_id),
            page=0,
            page_size=1,
            sort_field=Task.processed_at,
            sort_direction=which,
        )
        if return_count:
            return count, task[0]
        else:
            return task[0]

    first_task = get_first_or_last_task(ThroughputGetterHelper.FIRST)
    tasks_nb, last_task = get_first_or_last_task(
        ThroughputGetterHelper.LAST, return_count=True
    )

    print(
        f"Nb of tasks: {tasks_nb}, First task started at: {first_task.started_at}, Last task ended at: {last_task.ended_at}"
    )

    return tasks_nb / (last_task.ended_at - first_task.started_at).total_seconds()


def poll_session_ending(
    session_id: str, grpc_channel: grpc.Channel, polling_limit: float
):
    sessions_client = ArmoniKSessions(grpc_channel)
    timeout_date = datetime.datetime.now() + datetime.timedelta(seconds=polling_limit)
    print(
        f"Starting to wait for session {session_id} to end at : {datetime.datetime.now()}, will end polling at {timeout_date}."
    )

    while datetime.datetime.now() < timeout_date:
        session_status = sessions_client.get_session(session_id).status
        if session_status != SessionStatus.PURGED:
            print(
                f"{datetime.datetime.now()} : Waiting for session {session_id} to end"
            )
            time.sleep(5)
        else:
            print(f"Session {session_id} finished.")
            return
    print("Timeout date has been exceeded.")


def main(session_name: str, grpc_endpoint: str, polling_limit: float):
    try:
        with grpc.insecure_channel(f"{grpc_endpoint}:5001") as channel:
            session_id = get_session_id_by_name(session_name, channel)
            poll_session_ending(session_id, channel, polling_limit)
            throughput = get_session_throughput(session_id, channel)
            print(
                f"Throughput for session named '{session_name}' with id {session_id}: {throughput} Tasks per second"
            )
    except:  # noqa: E722
        print(
            f"Session {session_name} was not found or gRPC channel located at {grpc_endpoint} cannot be reached."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("grpc_endpoint", type=str)
    parser.add_argument("session_name", type=str)
    parser.add_argument("--polling-limit", type=float, default=300)

    args = parser.parse_args()

    main(args.session_name, args.grpc_endpoint, args.polling_limit)
