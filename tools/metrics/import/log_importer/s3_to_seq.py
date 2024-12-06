import argparse
import gzip
import json
import logging
import shutil
from pathlib import Path
from typing import List

import boto3
import botocore
import botocore.exceptions
import filetype
import requests
from colorama import Back, Fore, Style, init


init(autoreset=True)


class ColoredFormatter(logging.Formatter):
    """
    A custom logging formatter that adds color to log level names based on severity.

    Attributes:
        COLORS (dict): Maps log levels to ANSI color codes for formatted output.
    """

    COLORS = {
        "DEBUG": Fore.CYAN,
        "INFO": Fore.GREEN,
        "WARNING": Fore.YELLOW,
        "ERROR": Fore.RED,
        "CRITICAL": Fore.RED + Back.WHITE + Style.BRIGHT,
    }

    def format(self, record):
        levelname = record.levelname
        if levelname in self.COLORS:
            levelname_color = self.COLORS[levelname] + levelname + Style.RESET_ALL
            record.levelname = levelname_color
        return super().format(record)


def create_logger(log_level: str) -> logging.Logger:
    logger = logging.getLogger(Path(__file__).name)
    logger.setLevel(log_level)  # later on set to lower level and add verbose option

    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)
    console_formatter = ColoredFormatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    return logger


class Config:
    """
    Class containing certain configuration options

    Attributes:
        temp_folder (str): Temporary folder where to store downloaded files.
        nattempts (int): Number of times to attempt to download a certain log file before skipping it.
    """

    def __init__(self, temp_folder: str, nattempts: int):
        self.temp_folder = temp_folder
        self.nattempts = nattempts


class Context:
    """
    Context class that follows the singleton pattern to make certain values/objects global

    Attributes:
        logger (LoggingWrapper): logging wrapper instance.
        config (Config): configuration options for currently running script.
    """

    _instance = None

    def __new__(cls, logger=None, config=None):
        if cls._instance is None:
            if logger is None and config is None:
                raise ValueError(
                    "Logger and Config must be provided for the initial instantiation."
                )
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, logger: logging.Logger | None = None, config: Config | None = None):
        if not self._initialized:  # Ensure __init__ only runs once
            self.logger: logging.Logger = logger
            self.config: Config = config
            self._initialized = True


def download_dir_from_s3(bucket_name: str, remote_prefix: str) -> List[Path]:
    """
    Downloads all files from a specific directory in an S3 bucket to a local temporary folder.

    Args:
        bucket_name (str): The name of the S3 bucket from which files are to be downloaded.
        remote_prefix (str): The prefix (directory path) in the S3 bucket to filter the objects.

    Returns:
        list: A list of local file paths for the successfully downloaded files.

    Raises:
        botocore.exceptions.ClientError: If the S3 operation encounters unrecoverable issues.
    """
    ctx = Context()
    s3_resource = boto3.resource("s3")
    bucket = s3_resource.Bucket(bucket_name)
    file_list = []
    for obj in bucket.objects.filter(Prefix=remote_prefix):
        local_path = Path(ctx.config.temp_folder) / Path(obj.key).relative_to(remote_prefix)
        local_path.parent.mkdir(parents=True, exist_ok=True)
        if obj.key[-1] == "/":
            continue
        for attempt in range(1, ctx.config.nattempts + 1):
            try:
                bucket.download_file(obj.key, local_path)
                if attempt == 1:
                    ctx.logger.debug(f"Successfully downloaded log file {obj.key} in attempt 1")
                else:
                    ctx.logger.info(
                        f"Successfully downloaded log file {obj.key} in attempt {attempt}"
                    )
                file_list.append(local_path)
                break
            except botocore.exceptions.ClientError as e:
                ctx.logger.error(
                    f"Attempt {attempt} at downloading file {obj.key} failed with error: \n {json.dumps(e.response['Error'])} "
                )
            ctx.logger.warning(f"All attempts at downloading {obj.key} failed, skipping..")
    return file_list


class LogSender:
    """
    LogSender is a class for sending log messages to a Seq server

    Args:
        url (str): The URL of the Seq server where log messages should be sent

    Attributes:
        url (str): The URL of the Seq server
        batch (bytes): A batch of log messages waiting to be sent
        ctr (int): A counter for the number of log messages sent
    """

    def __init__(self, url: str):
        self.url = url
        self.batch = b""
        self.ctr = 0

    def __enter__(self):
        """
        Enter a context and return the LogSender instance

        Returns:
            LogSender: Instance that support the with statement
        """
        return self

    def sendlog(self, line: str):
        """
        Send a log message to the Seq server. The message is expected to be in JSON format
        Logs are sent to the server when the batch size exceeds 100,000 bytes

        Args:
            line (str): A log message in JSON format
        """
        ctx = Context()
        if line.startswith("{"):
            try:
                parsed = json.loads(line)
                if "@t" not in parsed:
                    return
                self.ctr = self.ctr + 1
                log_message = bytes(line + "\n", "utf-8")
                if len(self.batch) + len(log_message) > 100000:
                    requests.post(self.url, data=self.batch)
                    self.batch = log_message
                else:
                    self.batch += log_message
            except json.JSONDecodeError as e:
                ctx.logger.warning(f"Failed to parse JSON: {e}")

    def __exit__(self, exception_type, exception_value, traceback):
        """
        Logs left in the batch are sent and exiting the context
        """
        ctx = Context()
        if self.batch != b"":
            requests.post(self.url, data=self.batch)
        ctx.logger.debug(f"Remaining {self.ctr} elements sent, exiting a LogSender context")


def process_json_log(url: str, file_path: Path):
    """
    Process a JSON log file and send its contents to a Seq server

    Args:
        url (str): The URL of the Seq server where log messages should be sent
        file_path (Path): The path to the JSON log file
    """
    ctx = Context()
    ctx.logger.debug("Sending json file : " + str(file_path))
    with open(file_path, "r") as file:
        with LogSender(url) as log_sender:
            for line in file.readlines():
                log_sender.sendlog(line)


def process_jsongz_log(url: str, file_path: Path):
    """
    Process a gzipped JSON log file and send its contents to a Seq server

    Args:
        url (str): The URL of the Seq server where log messages should be sent
        file_path (Path): The path to the gzipped JSON log file
    """
    ctx = Context()
    ctx.logger.debug("Sending gzipped json file : " + str(file_path))
    with gzip.open(file_path, "r") as file:
        with LogSender(url) as log_sender:
            for line in file.read().decode("utf-8").split("\n"):
                log_sender.sendlog(line)


def main(
    bucket_name: str,
    log_folder: str,
    seq_url: str,
    profile: str,
    log_level: str,
    temp_path: str,
    nattempts: str,
    noclear: str,
):
    logger = create_logger(log_level)
    logger.info("S3 to Seq started")
    context = Context(logger, Config(temp_path, nattempts))

    logger.info("Temporary download directory set to " + temp_path)

    try:
        try:
            boto3.setup_default_session(profile_name=profile)
            s3 = boto3.client("s3")
        except botocore.exceptions.NoCredentialsError:
            logger.error(
                f"Couldn't create S3 Client. Make sure to have either exported your AWS Credentials as an environment variable or that you've ran the AWS configure command before using this utility: \n {Fore.CYAN} aws configure {Style.RESET_ALL} \n"
            )
        # NOTE: Need to look into NextContinuationToken for buckets of bigger size : https://stackoverflow.com/questions/31918960/boto3-to-download-all-files-from-a-s3-bucket
        logger.info("Downloading logs from S3 stored in " + log_folder)
        log_files = download_dir_from_s3(bucket_name, log_folder)

        if len(log_files) == 0:
            logger.info("No files were downloaded, nothing to upload, exiting..")
            exit()

        is_gzip = filetype.is_archive(log_files[0])
        process = process_jsongz_log if is_gzip else process_json_log
        logger.info(
            "Sending gzipped files onto Seq" if is_gzip else "Sending json log files onto Seq"
        )
        for file_name in log_files:
            process(seq_url, file_name)
    finally:
        if not noclear:
            shutil.rmtree(temp_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Utility to Upload ArmoniK logs stored in AWS S3 to Seq"
    )
    parser.add_argument("bucket_name", help="Name of the bucket to retrieve logs from", type=str)
    parser.add_argument(
        "log_folder", help="Folder containing your log files in S3 storage ", type=str
    )
    parser.add_argument(
        "seq_url",
        help="URL to your Seq's Clef utility. Example: http://localhost:9341/api/events/raw?clef",
        type=str,
        default="http://localhost:9341/api/events/raw?clef",
    )

    parser.add_argument(
        "--profile",
        help="Optionally set the AWS profile to use",
        type=str,
        default="default",
    )
    parser.add_argument(
        "--log_level",
        help="Optionally set the log level to a value of your choice (DEBUG, INFO, WARM, ERROR, CRITICAL)",
        type=str,
        default="INFO",
    )
    parser.add_argument(
        "--temp_path",
        help="Temporary folder where the downloaded logs will be stored before upload to S3",
        type=str,
        default="/tmp/s3_seq/",
    )
    parser.add_argument(
        "--nattempts",
        help="Number of times to attempt to download the files from the S3 bucket before skipping",
        type=int,
        default=3,
    )

    parser.add_argument(
        "--noclear",
        help="If set to true, won't automatically delete the downloaded log files after they're uploaded to seq",
        action="store_true",
    )

    args = parser.parse_args()

    main(**vars(args))