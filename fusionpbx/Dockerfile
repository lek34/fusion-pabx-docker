# -----------------------------------------------------------------------------
# 🧱 Base Image: Ubuntu 22.04
# -----------------------------------------------------------------------------
FROM ubuntu:22.04

LABEL maintainer="Pramudya Reynaldi <pramudya@example.com>"
LABEL description="FusionPBX PHP-FPM container based on Ubuntu 22.04"
LABEL version="1.0.1"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

# -----------------------------------------------------------------------------
# ⚙️ Install dependencies (tanpa nginx)
# -----------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        php8.1 php8.1-cli php8.1-fpm php8.1-pgsql php8.1-sqlite3 php8.1-gd php8.1-curl \
        php8.1-memcache php8.1-imap php8.1-mysql php8.1-xml php8.1-mbstring php8.1-ldap php8.1-intl php8.1-zip \
        git curl unzip sudo net-tools cron \
        && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 🧱 Clone FusionPBX
# -----------------------------------------------------------------------------
RUN git clone https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx

WORKDIR /var/www/fusionpbx

# -----------------------------------------------------------------------------
# 🧱 Set permissions and create required directories
# -----------------------------------------------------------------------------
RUN chown -R www-data:www-data /var/www/fusionpbx && \
    chmod -R 755 /var/www/fusionpbx && \
    mkdir -p /etc/fusionpbx /var/lib/fusionpbx /usr/share/fusionpbx/resources && \
    chown -R www-data:www-data /etc/fusionpbx /var/lib/fusionpbx /usr/share/fusionpbx && \
    chmod -R 755 /etc/fusionpbx /var/lib/fusionpbx /usr/share/fusionpbx

# -----------------------------------------------------------------------------
# ⚙️ Configure PHP-FPM
# -----------------------------------------------------------------------------
RUN mkdir -p /run/php && \
    sed -i 's/;daemonize = yes/daemonize = no/' /etc/php/8.1/fpm/php-fpm.conf && \
    sed -i 's|listen = /run/php/php8.1-fpm.sock|listen = 9000|' /etc/php/8.1/fpm/pool.d/www.conf && \
        sed -i 's/memory_limit = 128M/memory_limit = 4096M/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/8.1/fpm/php.ini && \
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.1/fpm/php.ini

EXPOSE 9000

# Jalankan PHP-FPM foreground
CMD ["php-fpm8.1", "-F"]
