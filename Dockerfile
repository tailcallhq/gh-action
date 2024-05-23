FROM alpine:latest as builder

COPY tailcall.tf /tmp/tailcall.tf
COPY $TAILCALL_CONFIG /tmp/config.graphql

RUN apk add --no-cache curl jq
RUN if [ "$TAILCALL_VERSION" = "latest" ]; then TAILCALL_VERSION=$(curl https://api.github.com/repos/tailcallhq/tailcall/releases/latest -s | jq .name -r); fi

FROM hashicorp/terraform:latest

COPY --from=builder /tmp/tailcall.tf /tmp/tailcall.tf
COPY --from=builder /tmp/config.graphql /tmp/config.graphql

ENTRYPOINT ["./entrypoint.sh"]