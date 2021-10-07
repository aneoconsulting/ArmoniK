FROM public.ecr.aws/lambda/python:3.7

COPY ./source/client/python/api-v0.1/ .
COPY ./source/client/python/utils/ .

COPY ./source/control_plane/python/lambda/cancel_tasks/requirements.txt .
RUN pip3 install -r requirements.txt

COPY ./source/control_plane/python/lambda/cancel_tasks/cancel_tasks.py .

CMD ["cancel_tasks.lambda_handler"]