FROM alpine:latest as builder

COPY . /app

RUN apk upgrade --no-cache && apk update --no-cache && apk add --no-cache curl jq wget
RUN export TAILCALL_DOWNLOAD_URL=$(curl -s https://api.github.com/repos/tailcallhq/tailcall/releases/latest \
    | jq --raw-output --arg arch $(arch) '.assets | map(select(.name | (contains($arch) and endswith("musl")))) | first | .browser_download_url') \
    && wget -O /usr/local/bin/tailcall $TAILCALL_DOWNLOAD_URL \
    && chmod +x /usr/local/bin/tailcall

FROM alpine:latest

COPY --from=builder /app /app
COPY --from=builder /usr/local/bin/tailcall /usr/local/bin/tailcall

WORKDIR /app
CMD TC_TRACKER=false tailcall start config.json