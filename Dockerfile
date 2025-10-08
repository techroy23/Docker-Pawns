FROM --platform=linux/amd64 iproyal/pawns-cli AS source_amd64

FROM --platform=linux/arm64 iproyal/pawns-cli AS source_arm64

FROM alpine:latest AS final

WORKDIR /app

RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache ca-certificates ca-certificates-bundle unzip curl bash dos2unix tzdata iptables redsocks \
    && update-ca-certificates

COPY --from=source_amd64 /pawns-cli /app/pawns-cli-amd64

COPY --from=source_arm64 /pawns-cli /app/pawns-cli-arm64

COPY entrypoint.sh /app/entrypoint.sh

RUN dos2unix /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh \
             /app/pawns-cli-amd64 \
             /app/pawns-cli-arm64

ENTRYPOINT ["/app/entrypoint.sh"]