FROM python:3.11-slim-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    libssl3 \
    libssl-dev \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PRISMA_BINARY_PLATFORM=debian-openssl-3.0.x
ENV PYTHON_PRISMA_BINARY_PLATFORM=debian-openssl-3.0.x

RUN python -m prisma generate --schema ./prisma/schema.prisma

EXPOSE 8000

# Honor the PORT environment variable provided by Render, defaulting to 8000.
# This ensures health checks reach the app on the correct port.
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
