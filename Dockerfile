FROM php:7.1-fpm-buster


ENV COMPOSER_VERSION=1.10.22

# this is a sample BASE image, that php_fpm projects can start FROM
# it's got a lot in it, but it's designed to meet dev and prod needs in single image
# I've tried other things like splitting out php_fpm and nginx containers
# or multi-stage builds to keep it lean, but this is my current design for
## single image that does nginx and php_fpm
## usable with bind-mount and unique dev-only entrypoint file that builds
## some things on startup when developing locally
## stores all code in image with proper default builds for production

# install apt dependencies
# some of these are not needed in all php projects
# NOTE: you should prob use specific versions of some of these so you don't break your app
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    apt-transport-https \
    ca-certificates \
    curl \
    dos2unix \
    gnupg2 \
    dirmngr \
    g++ \
    jq \
    libedit-dev \
    libfcgi0ldbl \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpq-dev \
    supervisor \
    && rm -r /var/lib/apt/lists/*

# configure gd
RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/freetype2 \
    --with-jpeg-dir=/usr/include/

# Install extensions using the helper script provided by the base image
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    json \
    readline \
    gd \
    intl



# configure intl
RUN docker-php-ext-configure intl

RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y  --allow-unauthenticated \
						nginx \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/* \
    && rm /etc/nginx/sites-enabled/default \
    && rm /etc/nginx/sites-available/default

# forward nginx request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# install composer so we can run dump-autoload at entrypoint startup in dev
# copied from official composer Dockerfile
ENV PATH="/composer/vendor/bin:$PATH" \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_VENDOR_DIR=/var/www/vendor \
    COMPOSER_HOME=/composer

COPY ./install-composer.sh /tmp/install-composer.sh

RUN sh /tmp/install-composer.sh && rm -f /tmp/install-composer.sh \
 && composer --ansi --version --no-interaction



COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
