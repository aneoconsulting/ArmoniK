FROM python:3.7.7-slim-buster

COPY source/client/python/api-v0.1/ .
COPY source/client/python/utils/ .

COPY source/control_plane/python/lambda/submit_tasks/requirements.txt .
RUN pip3 install -r requirements.txt
RUN pip3 install boto3

COPY source/control_plane/python/lambda/submit_tasks/submit_tasks.py .

CMD ["submit_tasks.lambda_handler"]