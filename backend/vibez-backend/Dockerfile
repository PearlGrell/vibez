FROM python:3.12-slim

WORKDIR /app

# Node.js = the JS runtime yt-dlp uses to solve the n-challenge / signature
RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -U yt-dlp

COPY . .

EXPOSE 50051
CMD ["python", "server.py"]