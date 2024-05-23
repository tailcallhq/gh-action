FROM alpine:latest as builder

COPY config.graphql /config.graphql

RUN apk upgrade --no-cache && apk update --no-cache && apk add --no-cache curl jq wget
RUN export TAILCALL_DOWNLOAD_URL=$(curl -s https://api.github.com/repos/tailcallhq/tailcall/releases/latest \
    | jq --raw-output --arg arch $(arch) '.assets | map(select(.name | (contains($arch) and endswith("musl")))) | first | .browser_download_url') \
    && wget -O /usr/local/bin/tailcall $TAILCALL_DOWNLOAD_URL \
    && chmod +x /usr/local/bin/tailcall

FROM alpine:latest

COPY --from=builder /config.graphql /config.graphql
COPY --from=builder /usr/local/bin/tailcall /usr/local/bin/tailcall

CMD tailcall start /config.graphql