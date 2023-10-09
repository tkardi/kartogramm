FROM postgis/postgis:13-3.1

COPY ./entrypoint.sh /app/entrypoint.sh
COPY ./requirements.txt /app/requirements.txt

RUN \
    apt-get update \
    && apt-get -y install \
        ca-certificates \
        curl \
        unzip \
        postgis \
        python3 \
        python3-pip \
        python3-venv \
        libpq-dev \
        nano \
    && update-ca-certificates \
    && chmod +x /app/entrypoint.sh \
    && python3 -m venv /app/venv \
    && /bin/bash -c "source /app/venv/bin/activate && python3 -m pip install -r /app/requirements.txt && deactivate"

COPY ./db/** /docker-entrypoint-initdb.d/
COPY ./data /app/main/data

ENTRYPOINT [ "/bin/bash", "-c", "/app/entrypoint.sh" ]

STOPSIGNAL SIGINT
