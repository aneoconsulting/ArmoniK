FROM bitnami/jupyter-base-notebook:latest
USER root
RUN conda install --quiet --yes \
    'matplotlib-base' \
    'scipy' && \
    conda clean --all -f -y
RUN pip install prometheus-api-client
USER 1001

# ADD a notebook with some things preimported/ setup.. particularly the database and prom metrics client

ENTRYPOINT [ "jupyter", "notebook", "--no-browser" ]