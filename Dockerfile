FROM alpine:latest as builder

COPY entrypoint.sh /tmp/entrypoint.sh
COPY tailcall.tf /tmp/tailcall.tf

RUN apk add --no-cache curl jq
RUN if [ "$TAILCALL_VERSION" = "latest" ]; then TAILCALL_VERSION=$(curl https://api.github.com/repos/tailcallhq/tailcall/releases/latest -s | jq .name -r); fi
RUN echo $TAILCALL_VERSION > /tmp/version.txt

FROM hashicorp/terraform:latest

COPY --from=builder /tmp/entrypoint.sh /entrypoint.sh
COPY --from=builder /tmp/tailcall.tf /tmp/tailcall.tf
COPY --from=builder /tmp/version.txt /version.txt

RUN export TAILCALL_VERSION=$(cat /version.txt)
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]