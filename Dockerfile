FROM python:3.13-slim
# update Dockerfile for test-of-existing-repo branch

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
ENV UV_SYSTEM_PYTHON=1

WORKDIR /app

# Copy project metadata
COPY pyproject.toml uv.lock* ./

COPY ecr_test ./ecr_test
RUN uv pip install --system .

# See pyproject.toml 
ENTRYPOINT ["my-app", "run"]
CMD []
