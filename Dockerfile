#
# PHP-fpm container based on official PHP 7.4 image with additional extensions
# like zip, pdo_mysql, bcmath, oci8 and gd. Image is build for Laravel applications.
# PHP itself is recompiled from php-src branch PHP-7.4-CVE-2026-109618-109619
# with the security backports from ./patches applied on top.
#
# OS: Debian 11 Bullseye
# Arch: linux/amd64 only (the bundled Oracle Instant Client is x64).
#
FROM --platform=linux/amd64 php:7.4-fpm-bullseye

# Bullseye is EOL; its packages are only served from archive.debian.org.
RUN sed -i 's#http://deb.debian.org#http://archive.debian.org#g' /etc/apt/sources.list

#
#--------------------------------------------------------------------------
# PHP rebuild (CVE-2026-109618, CVE-2026-109619, CVE-2026-126714,
#              CVE-2026-129289, CVE-2026-129496)
#--------------------------------------------------------------------------
#

# https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
ARG PHP_SRC_COMMIT=712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
ARG PHP_SRC_SHA256=c85c8cae6cd97c8688eb0bb2385d2341b74606153d19c3c8688183c3bc760d47

# Backports of upstream fixes that have no PHP 7.4 branch, applied with patch -p1.
COPY ./patches /usr/src/php-patches

# Same configure flags as the upstream image, minus PEAR (already installed).
# /usr/src/php.tar.xz is replaced so docker-php-ext-install builds patched sources.
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      autoconf bison dpkg-dev file g++ gcc make patch pkg-config re2c \
      libargon2-dev libcurl4-openssl-dev libonig-dev libreadline-dev \
      libsodium-dev libsqlite3-dev libssl-dev libxml2-dev zlib1g-dev; \
    configureOptions="$(php-config --configure-options)"; \
    curl -fsSL -o /tmp/php-src.tar.gz "https://github.com/php/php-src/archive/${PHP_SRC_COMMIT}.tar.gz"; \
    echo "${PHP_SRC_SHA256} */tmp/php-src.tar.gz" | sha256sum -c -; \
    docker-php-source delete; \
    mkdir -p /usr/src/php; \
    tar -xzf /tmp/php-src.tar.gz -C /usr/src/php --strip-components=1; \
    rm /tmp/php-src.tar.gz; \
    for p in /usr/src/php-patches/*.patch; do patch -d /usr/src/php -p1 --forward < "$p"; done; \
    rm -rf /usr/src/php-patches; \
    rm -f /usr/src/php.tar.xz /usr/src/php.tar.xz.asc; \
    tar -cf - -C /usr/src php | xz -T0 > /usr/src/php.tar.xz; \
    cd /usr/src/php; \
    ./buildconf --force; \
    CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
      ./configure $configureOptions --without-pear; \
    make -j "$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; \
    cd /; \
    docker-php-source delete; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
      | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
      | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    php -r 'exit(ini_get("max_multipart_body_parts") === false ? 1 : 0);'; \
    php -v; \
    php-fpm -v

#
#--------------------------------------------------------------------------
# General Updates
#--------------------------------------------------------------------------
#

# Update OS packages and install required ones.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      curl \
      libmemcached-dev \
      libz-dev \
      libpq-dev \
      libjpeg-dev \
      libpng-dev \
      libfreetype6-dev \
      libssl-dev \
      libmcrypt-dev \
      zip \
      unzip \
      build-essential \
      libaio1 \
      libzip-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm /var/log/lastlog /var/log/faillog

#
#--------------------------------------------------------------------------
# Application Dependencies
#--------------------------------------------------------------------------
#

# Download oracle packages and install OCI8
RUN curl -o instantclient-basic-linux.x64-19.6.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip \
    && unzip instantclient-basic-linux.x64-19.6.0.0.0dbru.zip -d /usr/lib/oracle/ \
    && rm instantclient-basic-linux.x64-19.6.0.0.0dbru.zip \
    && curl -o instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip \
    && unzip instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip -d /usr/lib/oracle/ \
    && rm instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip \
    && echo /usr/lib/oracle/instantclient_19_6 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

ENV LD_LIBRARY_PATH /usr/lib/oracle/instantclient_19_6

# Install PHP extensions: Laravel needs also zip, mysqli and bcmath which
# are not included in default image. Also install our compiled oci8 extensions.
RUN docker-php-ext-install zip pdo_mysql tokenizer bcmath opcache pcntl \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/oracle/instantclient_19_6 \
    && docker-php-ext-install -j$(nproc) oci8 \
    # Install the PHP gd library
    && docker-php-ext-configure gd \
        --with-jpeg=/usr/include/ \
        --with-freetype=/usr/include/\
    && docker-php-ext-install gd

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

# Copy our configs to the image.
COPY ./config/custom.ini /usr/local/etc/php/conf.d
# FPM loads pool files alphabetically; zzz- makes this override www.conf and zz-docker.conf.
COPY ./config/pool.d/custom.conf /usr/local/etc/php-fpm.d/zzz-custom.conf

# Expose port 9000 and start php-fpm server
CMD ["php-fpm"]
EXPOSE 9000