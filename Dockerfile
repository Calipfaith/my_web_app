FROM python:3.12-alpine

WORKDIR /app
COPY web /app/build/web
COPY backend/server.py /app/backend/server.py
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

EXPOSE 80
CMD ["python3", "/app/backend/server.py"]
