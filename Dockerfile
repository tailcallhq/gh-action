FROM alpine:latest as builder

COPY entrypoint.sh /entrypoint.sh
COPY aws/tailcall.tf /aws/tailcall.tf
COPY Dockerfile_fly /fly/Dockerfile

RUN apk upgrade --no-cache && apk update --no-cache

RUN apk add --no-cache curl jq libc6-compat git openssh-client python py-pip python3 && pip install awscli

ENTRYPOINT /bin/sh /entrypoint.sh