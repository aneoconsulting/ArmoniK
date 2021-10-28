FROM python:3.7.7-slim-buster

RUN mkdir -p /dist
RUN mkdir -p /app/agent

COPY ./dist/* /dist/
COPY ./source/compute_plane/python/agent/requirements.txt /app/agent/

WORKDIR /app/agent

RUN pip install -r requirements.txt
ADD ./source/compute_plane/python/agent/agent.py .


CMD [ "python" , "./agent.py"]


