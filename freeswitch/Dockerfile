# -----------------------------------------------------------------------------
# 🧱 Base image: Ubuntu 22.04 LTS (Jammy)
# -----------------------------------------------------------------------------
FROM ubuntu:22.04

LABEL maintainer="Pramudya Reynaldi <pramudya@example.com>"
LABEL description="Docker image for FreeSWITCH with FusionPBX on Ubuntu 22.04"
LABEL version="1.0.1"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

# -----------------------------------------------------------------------------
# ⚙️ Install dependencies
# -----------------------------------------------------------------------------
# RUN apt-get update && \
#     apt-get install --yes --no-install-recommends \
#         build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
#         libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip \
#         libavformat-dev libswscale-dev liblua5.2-dev cmake libpq-dev unixodbc-dev autoconf automake ntpdate \
#         libxml2-dev libpq5 sngrep wget git gnupg2 lsb-release ca-certificates libtool lua5.3 && \

#     rm -rf /var/lib/apt/lists/*

# RUN apt-get update && \
#     apt-get install --yes --no-install-recommends \
#         build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
#         libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip \
#         libavformat-dev libswscale-dev liblua5.2-dev lua5.2 cmake libpq-dev unixodbc-dev autoconf automake ntpdate \
#         libxml2-dev libpq5 sngrep wget git gnupg2 lsb-release ca-certificates libtool && \
#     rm -rf /var/lib/apt/lists/*

# RUN apt-get update && \
#     apt-get install --yes --no-install-recommends \
#         build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
#         libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip \
#         libavformat-dev libswscale-dev liblua5.2-dev lua5.2 cmake libpq-dev unixodbc-dev autoconf automake libtool \
#         ntpdate libxml2-dev libpq5 sngrep wget git gnupg2 lsb-release ca-certificates && \
#     rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
        libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip \
        libavformat-dev libswscale-dev liblua5.2-dev lua5.2 cmake libpq-dev unixodbc-dev autoconf automake \
        libtool libtool-bin ntpdate libxml2-dev libpq5 sngrep wget git gnupg2 lsb-release ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 🧱 Build libks
# -----------------------------------------------------------------------------
RUN git clone https://github.com/signalwire/libks.git /usr/local/src/libks && \
    cd /usr/local/src/libks && cmake . && make && make install && ldconfig

# -----------------------------------------------------------------------------
# 🧱 Build signalwire-c
# -----------------------------------------------------------------------------
RUN git clone https://github.com/signalwire/signalwire-c.git /usr/local/src/signalwire-c && \
    cd /usr/local/src/signalwire-c && cmake . && make && make install && ldconfig

# -----------------------------------------------------------------------------
# 🧱 Build sofia-sip
# -----------------------------------------------------------------------------
RUN git clone https://github.com/freeswitch/sofia-sip.git /usr/local/src/sofia-sip && \
    cd /usr/local/src/sofia-sip && ./bootstrap.sh || autoreconf -fi && \
    ./configure && make && make install && ldconfig

# -----------------------------------------------------------------------------
# 🧱 Build spandsp (tanpa versi 0.0.6)
# -----------------------------------------------------------------------------
# RUN git clone https://github.com/freeswitch/spandsp.git /usr/local/src/spandsp && \
#     cd /usr/local/src/spandsp && ./bootstrap.sh || autoreconf -fi && \
#     ./configure && make && make install && ldconfig

# RUN cd /usr/local/src && \
#     git clone https://github.com/freeswitch/spandsp.git && \
#     cd spandsp && \
#     git checkout master && \
#     ./bootstrap.sh && \
#     ./configure && \
#     make && make install && \
#     ldconfig

RUN cd /usr/local/src && \
    git clone https://github.com/freeswitch/spandsp.git -b fs && \
    cd spandsp && \
    ./bootstrap.sh && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# -----------------------------------------------------------------------------
# 🧱 Build FreeSWITCH (fix deprecated OpenSSL warnings)
# -----------------------------------------------------------------------------
# RUN wget -c https://files.freeswitch.org/releases/freeswitch/freeswitch-1.10.10.-release.tar.gz -P /usr/local/src && \
# RUN wget -c https://files.freeswitch.org/releases/freeswitch/freeswitch-1.10.7.-release.tar.gz -P /usr/local/src && \
#     cd /usr/local/src && \
#     tar xvzf freeswitch-1.10.7.-release.tar.gz && \
#     cd freeswitch-1.10.7.-release && \
#     CFLAGS="-Wno-error=deprecated-declarations" ./configure \
#         --enable-core-odbc-support \
#         --enable-core-pgsql-support \
#         --disable-libvpx && \
#     make -j$(nproc) CFLAGS="-Wno-error=deprecated-declarations" && \
#     make install && \
#     make cd-sounds-install && \
#     make cd-moh-install && \
#     ldconfig

# -----------------------------------------------------------------------------
# 🧱 Build FreeSWITCH (stable v1.10.10)
# -----------------------------------------------------------------------------
RUN cd /usr/local/src && \
    git clone https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    git checkout v1.10.10 && \
    ./bootstrap.sh && \
    CFLAGS="-Wno-error=deprecated-declarations" ./configure \
        --enable-core-odbc-support \
        --enable-core-pgsql-support \
        --disable-libvpx && \
    make -j$(nproc) && \
    make install && \
    make cd-sounds-install && \
    make cd-moh-install && \
    ldconfig

# -----------------------------------------------------------------------------
# 🧱 Install FusionPBX (via GitHub)
# -----------------------------------------------------------------------------
RUN mkdir -p /var/www/fusionpbx && \
    git clone https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx && \
    chown -R www-data:www-data /var/www/fusionpbx

# -----------------------------------------------------------------------------
# 🔗 Symlinks
# -----------------------------------------------------------------------------
RUN ln -s /usr/local/freeswitch/conf /etc/freeswitch && \
    ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli && \
    ln -s /usr/local/freeswitch/bin/freeswitch /usr/sbin/freeswitch

# -----------------------------------------------------------------------------
# 👤 Create freeswitch user
# -----------------------------------------------------------------------------
RUN groupadd freeswitch && \
    adduser --quiet --system --home /usr/local/freeswitch \
            --gecos 'FreeSWITCH open source softswitch' \
            --ingroup freeswitch freeswitch --disabled-password && \
    chown -R freeswitch:freeswitch /usr/local/freeswitch && \
    chmod -R ug=rwX,o= /usr/local/freeswitch && \
    chmod -R u=rwx,g=rx /usr/local/freeswitch/bin/*

# -----------------------------------------------------------------------------
# ⚡ Ports
# -----------------------------------------------------------------------------
EXPOSE 5060/tcp 5060/udp 8021/tcp 7443/tcp 8081/tcp

# -----------------------------------------------------------------------------
# 🏁 Run as non-root
# -----------------------------------------------------------------------------
USER freeswitch
CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-nf"]
