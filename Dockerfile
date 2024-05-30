FROM alpine:latest as builder

COPY entrypoint.sh /entrypoint.sh
COPY aws /aws
COPY fly /fly
COPY config.json /aws/config.json
COPY config.json /fly/config.json

RUN apk upgrade --no-cache && apk update --no-cache
RUN apk add --no-cache curl jq

ENTRYPOINT /bin/sh /entrypoint.sh