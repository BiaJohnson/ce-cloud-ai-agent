FROM python:3.12-slim

WORKDIR /srv

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV PORT=8080
ENV PYTHONUNBUFFERED=1
EXPOSE 8080

# Import path: app.main:app (matches `from app.tools import ...`)
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", "app.main:app"]
