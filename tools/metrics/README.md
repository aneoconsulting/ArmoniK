

This folder contains a set of tools that can be used to analyse ArmoniK metrics. 

It's currently split into two folders, `export/` and `import/`

#### Export

This folder contains a shell script `export-prometheus-s3.sh` that can be used to export ArmoniK's metrics from Prometheus to an S3 bucket. The script has two modes. 
- When the `--local` argument is supplied, the script functions by using a `kubectl cp` command. This is ideal for local deployments. You only need to have made sure to export your kubeconfig, as well as have your aws cli configured (you don't need to supply any credentials)
- Otherwise, the script will run a Kubernetes Job. The job requires you to have ta Persistent Volume configured for Prometheus for it to work. Moreover, you need to supply AWS CLI credentials either as parameters to the script or for you to have them exported as environment variables. Ofcourse, exporting your kubeconfig is essential to be able to apply your job

Running the script with no arguments will provide a short help message containing the arguments that you can supply it. 

#### Import

This folder contains a docker-compose deployment containing Prometheus and Grafana which you can just `docker compose up -d` to deploy. Additionally, there is a script that can facilitate importing Prometheus data from S3 and extracting it. You only need to provide the complete s3 filepath and optionally the AWS profile that you want to use. 

Similarly, running the script with no arguments will provide a short help message containing the arguments that you can supply it. 