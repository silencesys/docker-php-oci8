# PHP with OCI8 extension docker image

This is my custom docker image based on official php-fpm image with installed oci8 and few other extensions.

## Tags
- [`latest`, `1.2`, `1.1`](https://github.com/silencesys/docker-php-oci8/blob/master/Dockerfile) 

## Extensions installed within this image
This image brings few more extensions than the default PHP-fpm one.
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

COPY . /usr/src/myapp
WORKDIR /usr/src/myapp

CMD ["php-fpm"]
EXPOSE 9000
```

<br>

### Custom configuration
To modify php configuration.
```Docker
COPY ./config/your_config.ini /usr/local/etc/php/conf.d/custom.ini
COPY ./config/pool.d/your_pool.conf /usr/local/etc/php-fpm.d/costum.conf
```

You have also ability to modify default php settings as is described [there](https://docs.docker.com/samples/library/php/).
