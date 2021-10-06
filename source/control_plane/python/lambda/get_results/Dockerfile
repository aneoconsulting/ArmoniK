FROM public.ecr.aws/lambda/python:3.7

COPY ./source/client/python/api-v0.1/ .
COPY ./source/client/python/utils/ .

COPY source/control_plane/python/lambda/get_results/requirements.txt .
RUN pip3 install -r requirements.txt

COPY ./source/control_plane/python/lambda/get_results/get_results.py .

CMD ["get_results.lambda_handler"]