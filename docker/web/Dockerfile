from python:latest

# Prevents Python from writing pyc files to disc
ENV PYTHONDONTWRITEBYTECODE 1
# Prevents Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED 1

WORKDIR /usr/src/app
RUN pip install --upgrade pip && \
  pip install flake8

COPY . /usr/src/app
RUN flake8 --ignore=E501,F401 . && \
  pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt


# Final
FROM python:3.8.2-slim-buster
ENV HOME=/home/app
ENV APP_HOME=/home/app/web

RUN mkdir -p /home/app && \
  addgroup app && useradd -g app app && \
  mkdir $APP_HOME
WORKDIR $APP_HOME

# Install sshpass
RUN apt update && \
  apt install -y sshpass curl && \
  rm -rf /var/lib/apt/lists/*


# copy and install from builder
COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /usr/src/app/requirements.txt .
RUN pip install --upgrade pip && \
  pip install --no-cache /wheels/*

# copy source
COPY . $APP_HOME
RUN chown -R app:app $HOME && \
  mkdir -p /var/log/box4s/ && \
  chown -R app:app /var/log/box4s/ && \
  mkdir -p /var/lib/box4s && \
  chown -R app:app /var/lib/box4s/

# change to the app user
USER app
