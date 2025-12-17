FROM alpine:3.23

# hadolint ignore=DL3018
RUN apk --no-cache add bash gzip groff less aws-cli tar openssl ca-certificates gnupg tzdata

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
