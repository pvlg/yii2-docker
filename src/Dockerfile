FROM ubuntu:20.04 as stage

ARG PHP_VERSION
ENV PHP_VERSION=${PHP_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
ENV YII_TEMPLATE=basic
ENV LANG=C.UTF-8

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-memcache \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-xdebug \
        webp \
        wget \
        curl \
        supervisor \
        unzip \
        vim \
        openssh-server \
        iputils-ping \
        nmap \
        git \
        less \
        sudo \
        cron \
        rsync \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure supervisor
RUN sed -i '/\[supervisord\]/,/^$/s/^$/nodaemon=true\n/g' /etc/supervisor/supervisord.conf

# Install gosu
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-$(dpkg --print-architecture)" && \
    chmod +x /usr/local/bin/gosu

# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends yarn && \
    rm -rf /var/lib/apt/lists/*

# Install composer
RUN wget -O /usr/local/bin/composer "https://github.com/composer/composer/releases/download/1.10.20/composer.phar" && \
    chmod +x /usr/local/bin/composer && \
    mkdir -p /var/www && \
    chown -R www-data:www-data /var/www && \
    gosu www-data composer global require "fxp/composer-asset-plugin:~1.3"

# Configure php
RUN mkdir /run/php && \
    sed -ri "s/listen = .*$/listen = 0.0.0.0:9000/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    echo "env[PHP_IDE_CONFIG] = \$PHP_IDE_CONFIG" >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Configure xdebug
#RUN echo "xdebug.remote_enable=1" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini && \
#    echo "xdebug.remote_host=host.docker.internal" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini && \
#    echo "xdebug.remote_port=9001" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini

# Configure ssh
RUN chsh -s /bin/bash www-data && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    mkdir -p /var/www/.ssh && \
    chown -R www-data:www-data /var/www

COPY files /

VOLUME /data
WORKDIR /data

EXPOSE 80 22

CMD ["supervisor"]
ENTRYPOINT ["/docker-entrypoint.sh"]

# Build nginx
FROM stage as nginx

ENV HTTP_SERVER=nginx

RUN apt-get update && \
    apt-get -y install \
        nginx \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure nginx
RUN rm /etc/nginx/sites-enabled/default && \
    rm /etc/nginx/sites-available/default

# Build apache
FROM stage as apache

ENV HTTP_SERVER=apache2

RUN apt-get update && \
    apt-get -y install \
        apache2 \
        libapache2-mod-php${PHP_VERSION} \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure apache
RUN a2enmod rewrite && \
    rm /etc/apache2/sites-enabled/000-default.conf && \
    echo "IncludeOptional conf.d/*.conf" >> /etc/apache2/apache2.conf
