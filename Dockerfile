# stage 1
FROM python:3.12 AS base

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# stage 2
FROM python:3.12-slim

WORKDIR /code

COPY --from=base /code /code

EXPOSE 80

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]