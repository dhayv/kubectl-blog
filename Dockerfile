# stage 1
FROM python:3.11.9-slim as base

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# stage 2
FROM slim:latest

WORKDIR /code

COPY --from=base /code /code

EXPOSE 80

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]