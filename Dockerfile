FROM python:3.12.3-alpine3.19

WORKDIR /tmp
RUN apk upgrade --update-cache -a
RUN apk add --no-cache git
COPY ./requirements.txt ./
RUN pip install -r requirements.txt

WORKDIR /docs
EXPOSE 8000

ENTRYPOINT ["mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
