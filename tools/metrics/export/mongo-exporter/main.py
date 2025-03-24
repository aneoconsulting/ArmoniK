#!/usr/bin/env python3
import argparse
import os
import sys
import uuid
from datetime import datetime
import time

import boto3
import kr8s
from kr8s.objects import Job


def get_aws_credentials(profile_name=None):
    """Get AWS credentials from the specified profile"""
    if profile_name:
        session = boto3.Session(profile_name=profile_name)
        credentials = session.get_credentials()
        if credentials:
            frozen_credentials = credentials.get_frozen_credentials()
            return {
                'AWS_ACCESS_KEY_ID': frozen_credentials.access_key,
                'AWS_SECRET_ACCESS_KEY': frozen_credentials.secret_key,
                'AWS_SESSION_TOKEN': frozen_credentials.token if frozen_credentials.token else ""
            }
    return None


def create_mongodb_export_job(namespace, collection_name, s3_bucket, s3_key, 
                              aws_credentials=None, mongodb_secret="mongodb"):
    """Create a Kubernetes Job to export MongoDB data to S3"""
    # Generate a unique job name
    job_name = f"mongo-export-{collection_name.lower()}-{str(uuid.uuid4())[:8]}"
    
    # Prepare AWS environment variables
    aws_env = []
    if aws_credentials:
        for key, value in aws_credentials.items():
            aws_env.append({"name": key, "value": value})
    
    # Create the job spec
    job_spec = {
        "apiVersion": "batch/v1",
        "kind": "Job",
        "metadata": {
            "name": job_name,
            "namespace": namespace
        },
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "sling",
                        "image": "slingdata/sling",
                        "command": ["/bin/sh", "-c"],
                        "args": [
                            f"""
                            # Use the environment variables directly
                            export MONGODB="mongodb://$MONGO_USER:$MONGO_PASS@$MONGO_HOST:$MONGO_PORT/database?ssl=true&tlsInsecure=true"
                            # Run the Sling command
                            sling run --src-conn MONGODB --src-stream 'database.{collection_name}' --tgt-conn S3 --tgt-object "s3://{s3_bucket}/{s3_key}"
                            """
                        ],
                        "env": [
                            {
                                "name": "MONGO_USER",
                                "valueFrom": {
                                    "secretKeyRef": {
                                        "name": mongodb_secret,
                                        "key": "username"
                                    }
                                }
                            },
                            {
                                "name": "MONGO_PASS",
                                "valueFrom": {
                                    "secretKeyRef": {
                                        "name": mongodb_secret,
                                        "key": "password"
                                    }
                                }
                            },
                            {
                                "name": "MONGO_HOST",
                                "valueFrom": {
                                    "secretKeyRef": {
                                        "name": mongodb_secret,
                                        "key": "host"
                                    }
                                }
                            },
                            {
                                "name": "MONGO_PORT",
                                "valueFrom": {
                                    "secretKeyRef": {
                                        "name": mongodb_secret,
                                        "key": "port"
                                    }
                                }
                            },
                        ] + aws_env,
                        "volumeMounts": [
                            {
                                "name": "mongodb-cert",
                                "mountPath": "/mongodb/certs",
                                "readOnly": True
                            }
                        ]
                    }],
                    "restartPolicy": "Never",
                    "volumes": [
                        {
                            "name": "mongodb-cert",
                            "secret": {
                                "secretName": mongodb_secret,
                                "items": [
                                    {
                                        "key": "chain.pem",
                                        "path": "chain.pem"
                                    }
                                ]
                            }
                        }
                    ]
                }
            },
            "backoffLimit": 4
        }
    }
    
    # Create the job
    try:
        job = Job(job_spec)
        job.create()
        print(f"Created Kubernetes Job '{job_name}' in namespace '{namespace}'")
        return job
    except Exception as e:
        print(f"Error creating Kubernetes Job: {e}", file=sys.stderr)
        sys.exit(1)


def wait_for_job_completion(job, timeout_seconds=600):
    """Wait for the job to complete and return its status"""
    print(f"Waiting for job {job.name} to complete...")
    start_time = time.time()
    
    while True:
        job.refresh()
        
        if 'conditions' in job.status and job.status.get('conditions'):
            for condition in job.status['conditions']:
                if condition['type'] == 'Complete' and condition['status'] == 'True':
                    print(f"Job {job.name} completed successfully")
                    return True
                elif condition['type'] == 'Failed' and condition['status'] == 'True':
                    print(f"Job {job.name} failed: {condition.get('message', 'Unknown error')}")
                    return False
        
        # Check for timeout
        if time.time() - start_time > timeout_seconds:
            print(f"Timeout waiting for job {job.name} to complete")
            return False
        
        time.sleep(5)


def main():
    parser = argparse.ArgumentParser(description='Export MongoDB collection to S3 using a Kubernetes Job')
    
    parser.add_argument("--namespace", default="armonik", help="Kubernetes namespace to use (default: 'armonik')")
    parser.add_argument("--mongodb-secret", default="mongodb", 
                      help="Name of the Kubernetes secret containing MongoDB credentials (default: 'mongodb')")
    
    # Export parameters
    backup_group = parser.add_argument_group('Export Options')
    backup_group.add_argument('--collection', default="TaskData", help='Collection name to backup (default: TaskData)')
    
    # S3 upload parameters
    s3_group = parser.add_argument_group('S3 Upload Options')
    s3_group.add_argument('--s3-bucket', required=True, help='S3 bucket name to upload to')
    s3_group.add_argument('--s3-key', help='S3 object key/path (default: exports/<collection>/<timestamp>.json)')
    s3_group.add_argument('--aws-profile', help='AWS profile to use for S3 upload')
    
    # Job options
    job_group = parser.add_argument_group('Job Options')
    job_group.add_argument('--wait', action='store_true', help='Wait for the job to complete')
    job_group.add_argument('--timeout', type=int, default=600, 
                         help='Timeout in seconds when waiting for job completion (default: 600)')
    
    args = parser.parse_args()

    # Generate S3 key if not provided
    if not args.s3_key:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        args.s3_key = f"exports/{args.collection}/{timestamp}.json"
    
    # Get AWS credentials if profile is provided
    aws_credentials = None
    if args.aws_profile:
        aws_credentials = get_aws_credentials(args.aws_profile)
    if not aws_credentials:
        print(f"Warning: Could not get credentials from AWS profile '{args.aws_profile}'", file=sys.stderr)
        response = input("Continue without AWS credentials? (y/n): ")
        if response.lower() != 'y':
            sys.exit(1)
    # Create the export job
    job = create_mongodb_export_job(
        namespace=args.namespace,
        collection_name=args.collection,
        s3_bucket=args.s3_bucket,
        s3_key=args.s3_key,
        aws_credentials=aws_credentials,
        mongodb_secret=args.mongodb_secret
    )
    
    # Wait for job completion if requested
    if args.wait:
        success = wait_for_job_completion(job, args.timeout)
        sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
