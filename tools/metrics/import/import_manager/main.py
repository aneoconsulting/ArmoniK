import shutil
import tarfile
import pathlib
import json
import os
import subprocess
import gzip
import time

from typing import List

import boto3
import botocore
import botocore.exceptions
import click
import filetype
import requests
import randomname
from tabulate import tabulate

from dacite import from_dict
from tinydb import TinyDB, Query, where
import tinydb.operations as tdb_op

class Tables:
    Triplets = "triplets"
    Metrics = "metrics"
    Logs = "logs"
    Databases = "databases"


LOCAL_DATABASE_PATH = "importdb.json"
MAX_DOWNLOAD_ATTEMPTS = 3
TERRAFORM_DIR = "../import_environment/"
SQS_URL = "http://localhost:9341/api/events/raw?clef"
CACHE_DIR = pathlib.Path("importcache/")
MAX_NUM_RETRIES = 5
RETRY_WAIT = 10 



def download_dir_from_s3(bucket_name: str, prefix: str, download_dir: pathlib.Path) -> List[pathlib.Path]:

    s3_resource = boto3.resource("s3")
    bucket = s3_resource.Bucket(bucket_name)
    file_list = []
    for obj in bucket.objects.filter(Prefix=prefix):
        local_path = download_dir / pathlib.Path(obj.key).relative_to(prefix)
        local_path.parent.mkdir(parents= True, exist_ok=True)
        if obj.key[-1] == "/":
            continue 
        for attempt in range(MAX_DOWNLOAD_ATTEMPTS):
            try:
                bucket.download_file(obj.key, local_path)
                file_list.append(local_path)
            except botocore.exceptions.ClientError as e:
                click.echo(click.style(f"Attempt {attempt} at downloading log file {obj.key} failed with error: \n {json.dumps(e.response['Error'], indent=4)}"))
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
                click.echo(click.style(f"Failed to parse JSON: {e}", fg="yellow"))

    def __exit__(self, exception_type, exception_value, traceback):
        """
        Logs left in the batch are sent and exiting the context
        """
        if self.batch != b"":
            requests.post(self.url, data=self.batch)
        click.echo(f"Remaining {self.ctr} elements sent, exiting a LogSender context")

def process_json_log(url: str, file_path: pathlib.Path):
    """
    Process a JSON log file and send its contents to a Seq server

    Args:
        url (str): The URL of the Seq server where log messages should be sent
        file_path (Path): The path to the JSON log file
    """
    with open(file_path, "r") as file:
        with LogSender(url) as log_sender:
            for line in file.readlines():
                log_sender.sendlog(line)


def process_jsongz_log(url: str, file_path: pathlib.Path):
    """
    Process a gzipped JSON log file and send its contents to a Seq server

    Args:
        url (str): The URL of the Seq server where log messages should be sent
        file_path (Path): The path to the gzipped JSON log file
    """
    with gzip.open(file_path, "r") as file:
        with LogSender(url) as log_sender:
            for line in file.read().decode("utf-8").split("\n"):
                log_sender.sendlog(line)


def tfvars_for_triplet(triplet_name: str):
    db = TinyDB(LOCAL_DATABASE_PATH)
    triplet = db.table(Tables.Triplets).get(Query().name == triplet_name)
    triplet_folder = CACHE_DIR/pathlib.Path(f"triplets/{triplet_name}")
    database_folder = triplet_folder/pathlib.Path("databases")
    terraform_variables = {
        "TF_VAR_database_data_directory": str(database_folder.absolute()),
        "TF_VAR_environment_name": triplet_name,
        "TF_VAR_notebook_volume": str((triplet_folder / pathlib.Path("volume/")).absolute() )
    }
    if "metric_id" in triplet:
        terraform_variables["TF_VAR_prometheus_data_directory"] = str(
            (
                CACHE_DIR/ pathlib.Path(f"metrics/{str(triplet['metric_id'])}/prometheus")
             ).absolute()
            )
    return terraform_variables


@click.group()
def cli():
    pass

@cli.command()
def list_environments():
    db = TinyDB(LOCAL_DATABASE_PATH)
    triplets_table = db.table(Tables.Triplets)
    triplets = triplets_table.all()

    if not triplets:
        click.echo("No triplets found.")
        return

    # Extract data for tabulate
    formatted_triplets = [
        {"Name": triplet["name"], "Metrics": triplet["metric_urls"], "Logs": triplet["log_urls"], "Database": triplet["database_urls"]}
        for triplet in triplets
    ]

    # Create a table using tabulate
    table = tabulate(formatted_triplets, headers="keys", tablefmt="grid")

    click.echo(table)

# TODO:
@cli.command()
@click.argument("triplet_name")
def delete_environment(triplet_name:str):
    db = TinyDB(LOCAL_DATABASE_PATH)
    # TODO: delete local folders and remove any associated/deployed environment
    pass

def _deploy_environment(triplet_name: str):
    db = TinyDB(LOCAL_DATABASE_PATH)
    triplet = db.table(Tables.Triplets).get(Query().name == triplet_name)
    triplet_folder = CACHE_DIR/pathlib.Path(f"triplets/{str(triplet.doc_id)}")
    terraform_variables = tfvars_for_triplet(triplet_name)
    env = os.environ.copy()
    env.update(terraform_variables)

    original_dir = os.getcwd()
    try:
        os.chdir(TERRAFORM_DIR)
        subprocess.run(["terraform", "init"], check=True, env=env)
        subprocess.run(["terraform", "apply", "-auto-approve"], check=True, env=env)
        click.echo("Terraform deploy was successful")
    except subprocess.CalledProcessError as e: 
        click.echo(click.style(f"Terraform deployment failed with : \n {e}", fg="red", bg="white"))

    finally:
        os.chdir(original_dir) 
    try:
        env_file_path = CACHE_DIR/pathlib.Path("current_env")
        with env_file_path.open('w') as lock_file_handle:
            lock_file_handle.write(json.dumps(terraform_variables))
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


    # Pump logs to seq
    if "logs_id" in triplet:
        time.sleep(5) # Waiting for Seq to start
        log_doc = db.table(Tables.Logs).get(doc_id=triplet["logs_id"])
        log_files = log_doc.get("log_files")
        is_gzip = filetype.is_archive(log_files[0]) # We assume that all of the files have the same extension, so we only need to check one
        process = process_jsongz_log if is_gzip else process_json_log
        for i in range(MAX_NUM_RETRIES):
            try:
                for file_name in log_files:
                    process(SQS_URL,pathlib.Path(file_name))
                break
            except Exception as e:
                click.echo(f"Failed in retry={i}, max retries={MAX_NUM_RETRIES}, waiting for {RETRY_WAIT} seconds")
                time.sleep(RETRY_WAIT)

    # TODO: print out the urls to the different services

@cli.command()
@click.argument("triplet_name")
def deploy_environment(triplet_name: str):
    _deploy_environment(triplet_name)

@cli.command()
@click.option("--profile", default="default", help="AWS profile to use")
@click.option("--metrics", default=None, help="path to a metrics object (s3/local)")
@click.option("--logs", default=None, help="S3 URI to the prefix containing logs (s3/local)")
@click.option("--database", default=[], help="path to json files to be imported into a database (s3/local)", multiple=True)
@click.option("--no_deploy", help="If enabled, will just create the environment but won't deploy it", is_flag=True) 
@click.option("--no_cache", help="If set to true then the download is forced even if the files exist",is_flag=True)
def create_environment(profile: str, metrics: str|None, logs: str|None, database: List[str], no_deploy: bool, no_cache: bool):
    db = TinyDB(LOCAL_DATABASE_PATH)
    try:
        boto3.setup_default_session(profile_name= profile)
        s3 = boto3.client("s3")
    except botocore.exceptions.NoCredentialsError:
        click.echo(click.style("Failed to create S3 client, no credentials were found. ", fg="red", bg="white"), err=True)
    

    triplet_already_exists = db.table(Tables.Triplets).search(Query().metric_urls == metrics and Query().log_urls == logs and Query().database_urls.all(database))
    if len(triplet_already_exists) > 0:
        if not click.confirm(f'The supplied environment already exists with the name {triplet_already_exists[0]["name"]}, are you sure you want to proceed', abort=True):
            click.echo("Environment creation aborted.\nHint: use deploy-environment <triplet-name> to deploy this triplet")
            exit()
    triplet_name = randomname.get_name()
    triplet_id = db.table(Tables.Triplets).insert({"name":triplet_name, "metric_urls":metrics, "log_urls":logs, "database_urls":database})

    click.echo(f"Creating triplet with name {triplet_name}")

    if metrics:
        metric_id = db.table(Tables.Metrics).upsert({"path": metrics}, Query().path == metrics)[0]
        download_folder = CACHE_DIR/ pathlib.Path(f"metrics/{str(metric_id)}/")
        download_folder.mkdir(parents=True, exist_ok=True)
        if metrics[0:2] == "s3":
            # check if they've already been downloaded
            if not any(download_folder.iterdir()) or no_cache:
                bucket_name, prefix = metrics[5:].split("/", 1)
                file_name = metrics.split("/")[-1]
                try:
                    file_path = download_folder / pathlib.Path(file_name)
                    s3.download_file(bucket_name, prefix, str(file_path))
                    if tarfile.is_tarfile(file_path):
                        with tarfile.open(file_path, "r:*") as tar:
                            tar.extractall(path=download_folder)
                            click.echo(f"Extracted contents of {file_name} to {download_folder}")
                        
                        file_path.unlink() # Delete the tar file
                    else:
                        click.echo(f"Downloaded file {file_name} is not a tar archive.")
                except botocore.exceptions.BotoCoreError as e:
                    click.echo(click.style(f"Failed to download metrics file from S3, got exception: \n{e} ", fg="red", bg="white"), err=True)
                    exit() #fail
            db.table(Tables.Triplets).update(tdb_op.set("metric_id", metric_id), doc_ids=[triplet_id]) # TODO: should look into this logic? (not add metrics if no metrics are there.. failure)
        else:
            raise NotImplementedError() #TODO: from local
    if logs:
        log_id = db.table(Tables.Logs).upsert({"path": logs}, Query().path == logs)[0]
        download_folder = CACHE_DIR/pathlib.Path(f"logs/{str(log_id)}/")
        download_folder.mkdir(parents=True, exist_ok=True)
        if logs[0:2] == "s3":
            if not any(download_folder.iterdir()) or no_cache:
                bucket_name, prefix = logs[5:].split("/", 1)
                log_files = download_dir_from_s3(bucket_name, prefix, download_folder)
                db.table(Tables.Logs).update({"path": logs, "log_files": list(map(lambda file: str(file.absolute()),log_files))}, doc_ids=[log_id])
            db.table(Tables.Triplets).update(tdb_op.set("logs_id", log_id), doc_ids=[triplet_id])
        else:
            raise NotImplementedError() #TODO: from local

    if len(database) > 0:
        database_ids = []
        for db_file in database:
            database_id = db.table("databases").upsert({"path": db_file}, Query().path == db_file)[0]
            download_folder = CACHE_DIR/pathlib.Path(f"databases/{str(database_id)}/")
            download_folder.mkdir(parents=True, exist_ok=True)
            if db_file[0:2] == "s3":
                if any(download_folder.iterdir()) and not no_cache:
                    pass #TODO: just copy stuff over.. write a function that copies stuff over
                else:
                    bucket_name, prefix = db_file[5:].split("/", 1)
                    file_name = db_file.split("/")[-1]
                    try: 
                        s3.download_file(bucket_name, prefix, download_folder / pathlib.Path(file_name))
                        database_ids.append(database_id)
                    except botocore.exceptions.BotoCoreError as e:
                        click.echo(click.style(f"Failed to download database file '{db_file}' from S3, failed with error: \n {json.dumps(e.response['Error'], indent = 4)}", fg="red", bg="white"), err=True)
            else:
                raise NotImplementedError() #TODO: from local
        db.table(Tables.Triplets).update(tdb_op.set("database_ids", database_ids), doc_ids=[triplet_id])

    triplet_folder = CACHE_DIR/pathlib.Path(f"triplets/{triplet_name}")
    triplet_folder.mkdir(parents=True, exist_ok=True)
    notebook_volume = triplet_folder / pathlib.Path("volume/")
    notebook_volume.mkdir(parents=True, exist_ok=True)


    # metrics_folder = ""
    database_folder = triplet_folder/pathlib.Path("databases")
    if len(list(triplet_folder.iterdir())) <= 1:
        triplet_data = db.table(Tables.Triplets).get(doc_id=triplet_id)
        if "database_ids" in triplet_data and len(triplet_data["database_ids"]) > 0:
            for db_id in triplet_data["database_ids"]:
                shutil.copy(CACHE_DIR/pathlib.Path(f"databases/{str(db_id)}"), database_folder/pathlib.Path(str(db_id)))
    else:
        click.echo("Folder for environment already exists and contains files")
    if no_deploy:
        return

    #     # Get triplet, get ids of resources that are not "None", copy them to folder (Logs will be populated after terraform deploy)

    # Terraform deploy it:
    try:
        click.echo("Checking if environment already exists")
        with open(CACHE_DIR/pathlib.Path("current_env")) as env_file: 
            env_file_contents = json.load(env_file)
            if "TF_VAR_environment_name" in env_file_contents:
                click.echo(f"Found that an environment with the name {env_file_contents["TF_VAR_environment_name"]} is already deployed. Destroying it...")
                _destroy_current_environment()
    except Exception: 
        pass
    _deploy_environment(triplet_name)

    # TODO: On failure, delete everything ? Or should I just suggest to the user to redownload using a "--nocache" option
    # Big try catch maybe?

@cli.command()
@click.argument("triplet_name")
def destroy_environment(triplet_name: str):
    tf_vars = tfvars_for_triplet(triplet_name) # This will fail if triplet doesn't exist 
    env = os.environ.copy()
    env.update(tf_vars)
    original_dir = os.getcwd()
    try:
        os.chdir(TERRAFORM_DIR)
        subprocess.run(["terraform", "init"], check=True, env=env)
        subprocess.run(["terraform", "destroy", "-auto-approve"], check=True, env=env)
        click.echo("Terraform destroy was successful")
    except subprocess.CalledProcessError as e: 
        click.echo(click.style(f"Terraform destroy failed with : \n {e}", fg="red", bg="white"))

    finally:
        os.chdir(original_dir) 

# share_environment command that generates a json with data, uploads volume to S3, env can be then imported to another machine 

def _destroy_current_environment():
    try:
        with open(CACHE_DIR/pathlib.Path("current_env")) as env_file: 
            tf_vars = json.load(env_file)
            env = os.environ.copy()
            env.update(tf_vars)
            original_dir = os.getcwd()
            try:
                os.chdir(TERRAFORM_DIR)
                subprocess.run(["terraform", "init"], check=True, env=env)
                subprocess.run(["terraform", "destroy", "-auto-approve"], check=True, env=env)
                click.echo("Terraform destroy was successful")
            except subprocess.CalledProcessError as e: 
                click.echo(click.style(f"Terraform destroy failed with : \n {e}", fg="red", bg="white"))
            finally:
                os.chdir(original_dir) 

            try:
                with open(CACHE_DIR/"current_env") as lock_file_handle:
                    lock_file_handle.write(json.dumps(tf_vars))
            except Exception as e:
                print(f"An unexpected error occurred: {e}")

    except Exception as e: # TODO: more specific exception
        click.echo(f"Failed to destroy environment, failed with:\n{e}")


@cli.command()
def destroy_current_environment():
    _destroy_current_environment()

@cli.command()
def purge():
    # TODO
    pass
    # os.remove(CACHE_DIR)
    # pathlib.Path(LOCAL_DATABASE_PATH).unlink()

if __name__ == "__main__":
    cli()
