FROM public.ecr.aws/lambda/python:3.7

COPY ./source/client/python/api-v0.1/ .
COPY ./source/client/python/utils/ .

COPY ./source/control_plane/python/lambda/ttl_checker/requirements.txt .
RUN pip3 install -r requirements.txt
RUN pip3 install boto3

COPY ./source/control_plane/python/lambda/ttl_checker/ttl_checker.py .

CMD ["ttl_checker.lambda_handler"]