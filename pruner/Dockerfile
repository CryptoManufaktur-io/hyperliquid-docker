FROM ubuntu:24.04 AS builder

ARG USERNAME
RUN apt-get update -y && \
    apt-get install -y git wget && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget -O prune.sh https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pruner/scripts/prune.sh
RUN sed -i "s|DATA_PATH=\"/home/hluser/hl/data\"|DATA_PATH=\"/home/${USERNAME}/hl/data\"|" prune.sh
# Remove files older than 2 hours
RUN sed -i 's|^HOURS=\$((60\*48))|HOURS=$((60*2))|' prune.sh

FROM ubuntu:24.04

RUN apt-get update -y && \
    apt-get install -y curl cron && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt
COPY --from=builder /tmp/prune.sh /opt/prune.sh
RUN chmod +x /opt/prune.sh

# Install cron job, run every 3 hours
RUN echo "0 */3 * * * /opt/prune.sh" | crontab -

# Run cron in foreground
CMD ["cron", "-f"]
