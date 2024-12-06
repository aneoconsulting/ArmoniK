

## Quick start

1- Run a docker container with Seq

```
docker run -d --rm --name seqlogpipe -e ACCEPT_EULA=Y -p 9080:80 -p 9341:5341 datalust/seq
```

2- Configure AWS

Either run the following command to generate ```~/aws/credentials```

```
aws configure
```

or export your credentials into environment variables

3- Install requirements and run the script

```
pip install -r requirements.txt
python s3_to_seq.py --help
```
