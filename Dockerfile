# Stage 1: Build
FROM python:3.11-slim AS builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Copy requirements
COPY requirements.txt .

# Build wheels (PyPI + PyTorch CPU)
RUN pip wheel --no-cache-dir \
    --wheel-dir /app/wheels \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    -r requirements.txt


# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Copy wheels + requirements
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Install dependencies from wheels (no internet)
RUN pip install --no-cache-dir \
    --no-index \
    --find-links=/wheels \
    -r requirements.txt

# Copy app
COPY . .

# Env
ENV PYTHONUNBUFFERED=1
 

# Expose port
EXPOSE 8000

# Run app
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port $PORT"]