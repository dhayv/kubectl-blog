# stage 1
FROM python:3.11.9 AS builder

WORKDIR /code

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade --prefix=/code -r requirements.txt

# stage 2
FROM python:3.11.9-slim

WORKDIR /code

COPY --from=builder /code /usr/local

COPY . /code

EXPOSE 80

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]