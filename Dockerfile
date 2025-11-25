# Choosing Debian Slim base because it already includes glibc and 64-bit libraries needed to run Factorio. Disregarded Alpine having to compile glibc by hand - adding complexity I don't need and with neglible size benefits.
# trixie = Debian 13
FROM debian:trixie-slim 

# Arguments can only be set at build time, not runtime, and are baked into the build meta data. Do not put secrets in here.
ARG DEBIAN_FRONTEND=noninteractive

# Default Environment variables. Use Docker Secrets instead of passing user credentials as build or run time variables/arguments that can forever live in build meta data.
ENV LOAD_LATEST_SAVE=true \
    SAVE_NAME="" \
    TZ="" \
    FACTORIO_VERSION="latest" \
    SERVER_NAME="" \
    SERVER_DESCRIPTION="" \
    TAGS="" \
    MAX_PLAYERS=0 \
    IS_PUBLIC=false \
    IS_LAN=true \
    REQUIRE_USER_VERIFICATION=false \
    ALLOWCOMMANDS=admins-only \
    AUTOSAVE_INTERVAL=10 \
    AUTOSAVE_SLOTS=5 \
    AUTOSAVE_SERVER_ONLY=false \
    AFK_AUTOKICK_INTERVAL=0 \
    AUTO_PAUSE=true \
    AUTO_PAUSE_WHEN_PLAYERS_CONNECT=false \
    ONLY_ADMINS_CAN_PAUSE=true \
    IGNORE_PLAYER_LIMIT_FOR_RETURNING_PLAYERS=false \
    #Use to set container permissions equal to the UID/GID of the host; otherwise, volume mounts will break. Setting default to avoid using 1000. 
    UID=845 \
    GID=845 \
    #NETWORKING
    PORT=34197 \
    RCON_PORT=27015 
    #commentted out and used default settings from server-settings.json sample
    #MINIMUM_SEGMENT_SIZE=25 \
    #MINIMUM_SEGMENT_SIZE_PEER_COUNT=20 \
    #MAXIMUM_SEGMENT_SIZE=100 \
    #MAXIMUM_SEGMENT_SIZE_PEER_COUNT=10 \
    #MINIMUM_LATENCY_IN_TICKS=2 \
    #MAX_HEARTBEATS_PER_SECOND=60 \
    #MAX_UPLOAD_SLOTS=5 \
    #MAX_UPLOAD_IN_KILOBYTES_PER_SECOND=0 
    
# Metadata
LABEL maintainer="https://github.com/slauth82/factorio>" \
      description="Containerized dedicated server for Factorio Space Age with mod support" \
      version="1.0.0" \
      author="slauth82" 

# Install core dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    gosu \
    tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory structure
RUN mkdir -p /opt/factorio /opt/factorio/log /opt/factorio/config /opt/factorio/saves /opt/factorio/mods /opt/factorio/scenarios /opt/factorio/script-output
# Download and install Factorio headless server depending on version specified - citing web auth credentials from secrets

RUN if [ "$FACTORIO_VERSION" = "latest" ]; then \
        FACTORIO_DOWNLOAD_URL="https://www.factorio.com/get-download/latest/headless/linux64"; \
    elif [ "$FACTORIO_VERSION" = "stable" ]; then \
        FACTORIO_DOWNLOAD_URL="https://www.factorio.com/get-download/stable/headless/linux64"; \
    elif [ "$FACTORIO_VERSION" = "experimental" ]; then \
        FACTORIO_DOWNLOAD_URL="https://www.factorio.com/get-download/experimental/headless/linux64"; \
    else \
        FACTORIO_DOWNLOAD_URL="https://www.factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64"; \
    fi && \
    echo "Downloading Factorio ${FACTORIO_VERSION} from: $FACTORIO_DOWNLOAD_URL" && \
    curl -sSL "$FACTORIO_DOWNLOAD_URL" -o /tmp/factorio_headless.tar.xz && \
    tar -xJf /tmp/factorio_headless.tar.xz -C /opt && \
    rm /tmp/factorio_headless.tar.xz

# Game binaries will be in /opt/factorio/bin, saves and mods in /opt/factorio/ and config in /opt/factorio
# WORKDIR /opt/factorio

# Expose game server port (UDP) and RCON port (TCP)
EXPOSE 34197/udp 27015/tcp

# To create named volume points that reside within the container
# VOLUME ["/opt/factorio"] 

# Copy entrypoint script and run sed to fix line endings, then set executable permissions
COPY runfactorio.sh /
RUN sed -i 's/\r$//' /runfactorio.sh
RUN chmod +x /runfactorio.sh

# Create factorio user and group and set ownership permissions
RUN groupadd -o -g "${GID}" factorio \
  && useradd --create-home --no-log-init -o -u "${UID}" -g "${GID}" factorio
RUN chown -R "${UID}":"${GID}" /opt/factorio

# Set entrypoint
ENTRYPOINT ["/bin/bash"]
CMD ["/runfactorio.sh"]
