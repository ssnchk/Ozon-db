FROM postgres:16

RUN apt update && \
    apt install -y python3-pip python3.11-venv postgresql-plpython3-16 pgxnclient postgresql-server-dev-16 build-essential && \
    python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip && \
    pip install faker

RUN pgxn install postgresql_faker