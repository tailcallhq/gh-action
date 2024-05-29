FROM alpine:latest as builder

COPY entrypoint.sh /entrypoint.sh
COPY aws/tailcall.tf /aws/tailcall.tf
COPY aws/replace.py /aws/replace.py
COPY fly/Dockerfile /fly/Dockerfile

RUN apk upgrade --no-cache && apk update --no-cache
RUN apk add --no-cache curl jq python3

ENTRYPOINT /bin/sh /entrypoint.sh