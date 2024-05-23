FROM alpine:latest as builder

COPY entrypoint.sh /entrypoint.sh
COPY aws/tailcall.tf /aws/tailcall.tf
COPY fly/Dockerfile /fly/Dockerfile

RUN apk upgrade --no-cache && apk update --no-cache
RUN apk add --no-cache curl jq go

ENTRYPOINT /bin/sh /entrypoint.sh