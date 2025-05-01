FROM debian:12.6-slim

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# create custom user, install dependencies, create data directory
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install curl cron procps findutils -y \
    # Added findutils for xargs/print0 used in prune.sh
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && mkdir -p /home/$USERNAME/scripts && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

# Add our scripts
COPY scripts/ /home/$USERNAME/scripts/
# Cron file is now generated dynamically, so COPY cron/ is removed

# Give execution rights on the scripts
RUN chmod +x /home/$USERNAME/scripts/* && chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts

# Create cron job from environment variable and start cron service
CMD ["bash", "-c", "echo \"${PRUNE_SCHEDULE:-0 3 * * *} /bin/bash -c '/home/hluser/scripts/prune.sh >> /proc/1/fd/1 2>&1'\" > /etc/cron.d/prune && chmod 0644 /etc/cron.d/prune && crontab /etc/cron.d/prune && cron -f -L 15"]