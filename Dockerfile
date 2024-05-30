FROM alpine:latest as builder

COPY scripts /scripts
COPY aws /aws
COPY fly /fly
COPY config.json /fly/config.json

RUN apk upgrade --no-cache && apk update --no-cache
RUN apk add --no-cache curl jq

ENTRYPOINT /bin/sh /scripts/entrypoint.sh