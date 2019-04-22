FROM ubuntu:18.04 as stage

ARG PHP_INSTALL_VERSION
ENV PHP_INSTALL_VERSION ${PHP_INSTALL_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install software-properties-common && \
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
    apt-get update && \
    apt-get -y install \
        php${PHP_INSTALL_VERSION}-cli \
        php${PHP_INSTALL_VERSION}-fpm \
        php${PHP_INSTALL_VERSION}-mbstring \
        php${PHP_INSTALL_VERSION}-intl \
        php${PHP_INSTALL_VERSION}-mysql \
        php${PHP_INSTALL_VERSION}-sqlite3 \
        php${PHP_INSTALL_VERSION}-curl \
        php${PHP_INSTALL_VERSION}-gd \
        php${PHP_INSTALL_VERSION}-dom \
        php${PHP_INSTALL_VERSION}-zip \
        php-imagick \
        php-apcu \
        php-memcache \
        php-memcached \
        wget \
        curl \
        supervisor \
        unzip \
        vim \
        openssh-server \
        git \
        less \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure supervisor
RUN sed -i '/\[supervisord\]/,/^$/s/^$/nodaemon=true\n/g' /etc/supervisor/supervisord.conf

# Install gosu
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-$(dpkg --print-architecture)" && \
    chmod +x /usr/local/bin/gosu

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    mkdir -p /var/www && \
    chown -R www-data:www-data /var/www && \
    gosu www-data composer global require "fxp/composer-asset-plugin:~1.3"

# Configure php
RUN sed -ri "s/listen = .*$/listen = 0.0.0.0:9000/" /etc/php/${PHP_INSTALL_VERSION}/fpm/pool.d/www.conf

# Configure ssh
RUN chsh -s /bin/bash www-data && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    mkdir -p /var/www/.ssh && \
    chown -R www-data:www-data /var/www

COPY files /

WORKDIR /data

EXPOSE 80 443 22

CMD ["supervisor"]
ENTRYPOINT ["/docker-entrypoint.sh"]

FROM stage as nginx

RUN apt-get update && \
    apt-get -y install \
        nginx \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure nginx
RUN rm /etc/nginx/sites-enabled/default && \
    rm /etc/nginx/sites-available/default

COPY ./docker-entrypoint.nginx.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

FROM stage as apache

RUN apt-get update && \
    apt-get -y install \
        apache2 \
        libapache2-mod-php${PHP_INSTALL_VERSION} \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure apache
RUN a2enmod rewrite && \
    rm /etc/apache2/sites-enabled/000-default.conf

COPY ./docker-entrypoint.apache.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
