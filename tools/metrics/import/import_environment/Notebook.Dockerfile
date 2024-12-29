FROM python:3.11

WORKDIR /analysis

# TODO: ADD a requirements file and install things in the startup script/command
RUN pip install jupyter 
#matplotlib-base scipy prometheus-api-client

EXPOSE 8888

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''", "--NotebookApp.allow_origin='*'"]