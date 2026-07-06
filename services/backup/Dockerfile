FROM alpine:3.19

# Install backup and cloud sync utility dependencies
RUN apk add --no-cache \
    bash \
    postgresql-client \
    redis \
    rclone \
    curl \
    docker-cli \
    tzdata \
    tar \
    gzip

# Copy backup execution scripts into the image
COPY backup.sh /usr/local/bin/backup
COPY restore.sh /usr/local/bin/restore

RUN chmod +x /usr/local/bin/backup /usr/local/bin/restore

WORKDIR /data

# Default to run backup
CMD ["/usr/local/bin/backup"]
