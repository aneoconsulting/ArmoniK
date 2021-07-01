FROM amazon/aws-lambda-python
COPY ./source/control_plane/python/lambda/get_results ./source/client/python/utils/ ./
RUN pip install -r requirements.txt
CMD ["get_results.lambda_handler"]