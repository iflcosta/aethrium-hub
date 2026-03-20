FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    libssl-dev \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

# Generate Prisma client for Linux platform
# Uses the schema.prisma co-located in backend/
ENV PRISMA_BINARY_PLATFORM=debian-openssl-3.0.x
RUN python -m prisma generate

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
