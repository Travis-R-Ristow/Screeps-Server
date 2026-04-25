# Custom Screeps server
# Uses pre-built screeps-launcher with modern Python for node-gyp

FROM node:22-slim

# Install dependencies including modern Python 3.10+
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    make \
    g++ \
    curl \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Download screeps-launcher binary v1.16.2
RUN curl -L https://github.com/screepers/screeps-launcher/releases/download/v1.16.2/screeps-launcher_linux_amd64 \
    -o /usr/local/bin/screeps-launcher \
    && chmod +x /usr/local/bin/screeps-launcher

WORKDIR /screeps

# Create screeps user (some screeps components expect this)
RUN useradd -m screeps && chown -R screeps:screeps /screeps
USER screeps

CMD ["screeps-launcher"]
