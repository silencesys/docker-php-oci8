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

## License
This image on it's own does not have any license, but take a look at licences of other software that is included. 

- [PHP license](https://php.net/license/)
- [OCI license](https://www.oracle.com/technetwork/topics/linuxsoft-082809.html)

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
