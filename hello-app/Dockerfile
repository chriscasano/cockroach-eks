FROM python:3.7-slim

WORKDIR /app

ADD . /app
#ADD ../certs /app

RUN apt-get update && apt-get install -y libpq-dev gcc
# need gcc to compile psycopg2
RUN pip3 install psycopg2~=2.6
RUN apt-get autoremove -y gcc
RUN pip install --trusted-host pypi.python.org -r requirements.txt

EXPOSE 80

CMD ["python", "hello.py"]
