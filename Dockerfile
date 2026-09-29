ARG SPARK_IMAGE=apache/spark:4.1.3-java21-python3
FROM ghcr.io/astral-sh/uv:0.8.17 AS uv

FROM ${SPARK_IMAGE} AS spark-runtime

ARG PYTHON_VERSION=3.12.10

USER root

COPY --from=uv /uv /usr/local/bin/uv
COPY --from=uv /uvx /usr/local/bin/uvx

ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_LINK_MODE=copy \
    PYSPARK_PYTHON=/usr/local/bin/python3.12 \
    PYSPARK_DRIVER_PYTHON=/usr/local/bin/python3.12 \
    PYTHONPATH=/opt/spark/python:/opt/spark/python/lib/pyspark.zip:/opt/spark/python/lib/py4j-0.10.9.9-src.zip

RUN uv python install "${PYTHON_VERSION}" \
    && python_path="$(uv python find "${PYTHON_VERSION}")" \
    && ln -s "${python_path}" /usr/local/bin/python3.12 \
    && ln -s "${python_path}" /usr/local/bin/python \
    && mkdir -p /opt/cdc-streamer \
    && chown -R spark:spark /opt/uv /opt/cdc-streamer

USER spark

FROM spark-runtime AS app

USER root
WORKDIR /opt/cdc-streamer

COPY --chown=spark:spark pyproject.toml README.md uv.lock ./
COPY --chown=spark:spark src ./src

ENV UV_PROJECT_ENVIRONMENT=/opt/venv

RUN uv sync --locked --no-dev \
    && chown -R spark:spark /opt/venv

ENV PATH=/opt/venv/bin:${PATH}

USER spark

CMD ["cdc-streamer"]

FROM spark-runtime AS notebook

USER root

WORKDIR /opt/cdc-streamer

COPY --chown=spark:spark pyproject.toml README.md uv.lock ./
COPY --chown=spark:spark src ./src
COPY jupyter-entrypoint.sh /usr/local/bin/jupyter-entrypoint

ENV UV_PROJECT_ENVIRONMENT=/opt/venv

RUN uv sync --locked --no-dev --extra notebook \
    && mkdir -p /opt/cdc-streamer/notebooks \
    && chown -R spark:spark /opt/venv /opt/cdc-streamer

ENV PATH=/opt/venv/bin:${PATH} \
    HOME=/tmp \
    JUPYTER_RUNTIME_DIR=/tmp/jupyter-runtime

RUN chmod 755 /usr/local/bin/jupyter-entrypoint

ENTRYPOINT ["/usr/local/bin/jupyter-entrypoint"]
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--ServerApp.root_dir=/opt/cdc-streamer/notebooks"]