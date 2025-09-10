FROM python:3.13-slim AS build
# just some text to imitate a change
WORKDIR /app
COPY . .

RUN pip install --no-cache-dir --upgrade pip pipenv

RUN apt-get update && apt-get upgrade -y && apt-get install -y git

COPY Pipfile* /
RUN pipenv install

ENTRYPOINT ["pipenv", "run", "ecr_test"]
