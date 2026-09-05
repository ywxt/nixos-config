FROM swr.cn-south-1.myhuaweicloud.com/openharmony-docker/docker_oh_standard:3.2

# The official 3.2 image predates current OpenHarmony releases. 7.0 still
# benefits from its base toolchain, but its source build also invokes autotools
# (for example while configuring libtiff) and creates Python virtualenvs.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        autoconf \
        automake \
        cmake \
        libtool \
        python3.8-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/openharmony
