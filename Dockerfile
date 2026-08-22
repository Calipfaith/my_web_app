FROM python:3.12-alpine

WORKDIR /app
COPY build/web /app/build/web
COPY backend/server.py /app/backend/server.py

EXPOSE 80
CMD ["python3", "/app/backend/server.py"]
