FROM alpine:latest as builder

COPY entrypoint.sh /entrypoint.sh
COPY aws/tailcall.tf /aws/tailcall.tf
COPY fly/Dockerfile /fly/Dockerfile

RUN apk upgrade --no-cache && apk update --no-cache
RUN apk add --no-cache curl jq go

RUN curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest \
      | jq --raw-output .zipball_url \
      | xargs wget -O /tmp/terraform.zip
RUN unzip /tmp/terraform.zip -d /tmp
RUN go build

FROM alpine:latest

COPY --from=builder /entrypoint.sh /entrypoint.sh
COPY --from=builder /aws/tailcall.tf /aws/tailcall.tf
COPY --from=builder /fly/Dockerfile /fly/Dockerfile
COPY --from=builder /tmp/terraform /usr/local/bin/terraform

ENTRYPOINT /bin/sh /entrypoint.sh