FROM alpine:latest as builder

COPY scripts /scripts
COPY aws /aws
COPY fly /fly
COPY config.json /extras/config.json

RUN export FLY_APP_NAME="$(echo FLY_APP_NAME | tr '/' '_')"
RUN apk upgrade --no-cache && apk update --no-cache
RUN apk add --no-cache curl jq py-pip ripgrep
RUN pip install toml-cli --break-system-packages

ENTRYPOINT /bin/sh /scripts/entrypoint.sh