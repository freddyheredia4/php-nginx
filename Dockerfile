FROM php:7.4-fpm-buster


ENV COMPOSER_VERSION=2.1.6


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
    libpng-dev \
    libmcrypt-dev \
    libpq-dev \
    libreadline-dev \
    supervisor \
    && rm -r /var/lib/apt/lists/*


# Install extensions using the helper script provided by the base image
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    json \
    gd \
    intl

# configure gd
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

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
