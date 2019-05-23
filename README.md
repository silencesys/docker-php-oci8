# PHP+OCI8 Docker image

This is my custom docker image based on official php-fpm image with installed oci8 and few other extensions.

## Available extensions
- zip
- gdo
- opcache
- pdo_mysql
- tokenizer
- bcmath
- pcntl
- oci8

## How to use this image
You can freely use this image as a base for your own docker images. Simply put to your Dockerfile following line:
```Docker
FROM silencesys/php-oci8:latest
```

To modify php configuration.
```Docker
COPY ./config/your_config.ini /usr/local/etc/php/conf.d/custom.ini
COPY ./config/pool.d/your_pool.conf /usr/local/etc/php-fpm.d/costum.conf
```

You have also ability to modify default php settings as is described [there](https://docs.docker.com/samples/library/php/).
