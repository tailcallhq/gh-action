FROM alpine:latest as builder

COPY entrypoint.sh /tmp/entrypoint.sh
COPY tailcall.tf /tmp/tailcall.tf
COPY main.py /tmp/main.py

RUN apk add --no-cache curl jq
RUN curl https://api.github.com/repos/tailcallhq/tailcall/releases/latest -s | jq .name -r > /tmp/version.txt

FROM python3:latest

COPY --from=builder /tmp/entrypoint.sh /entrypoint.sh
COPY --from=builder /tmp/tailcall.tf /tmp/tailcall.tf
COPY --from=builder /tmp/version.txt /version.txt
COPY --from=builder /tmp/main.py /tmp/main.py

ENTRYPOINT /bin/sh /entrypoint.sh "$(cat /version.txt)"