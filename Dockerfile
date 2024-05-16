#
# PHP-fpm container based on official PHP 7.3 image with additional extensions
# like zip, pdo_mysql, bcmath, oci8 and gd. Image is build for Laravel applications.
#
# OS: Debian 9 Streatch-slim
#
FROM php:7.4-fpm

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
COPY ./config/pool.d/custom.conf /usr/local/etc/php/conf.d

# Expose port 9000 and start php-fpm server
CMD ["php-fpm"]
EXPOSE 9000