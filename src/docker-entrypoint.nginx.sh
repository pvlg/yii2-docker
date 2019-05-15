#!/usr/bin/env bash

set -e

if [[ "$1" = 'supervisor' ]]; then
    chown www-data:www-data /data
    chown -R www-data:www-data /var/www

    if [[ -z "${USER_ROOT_PASSWORD}" ]]; then
        USER_ROOT_PASSWORD='root'
    fi
    echo "root:${USER_ROOT_PASSWORD}" | chpasswd

    if [[ -z "${USER_WWW_DATA_PASSWORD}" ]]; then
        USER_WWW_DATA_PASSWORD='www-data'
    fi
    echo "www-data:${USER_WWW_DATA_PASSWORD}" | chpasswd

    if [[ "${YII_APP_TEMPLATE}" = 'advanced' ]]; then
        echo "Enabled advanced template"

        # Frontend
        if [[ ! -f /etc/nginx/conf.d/advanced.conf ]]; then
            cp /etc/nginx/conf.d/advanced.conf.tmpl /etc/nginx/conf.d/advanced.conf
        fi

        if [[ -z "${APP_FRONTEND_DOMAIN}" ]]; then
            APP_FRONTEND_DOMAIN='_'
        fi

        if [[ -z "${APP_FRONTEND_PORT}" ]]; then
            APP_FRONTEND_PORT='80'
        fi

        if [[ -z "${APP_FRONTEND_ROOT}" ]]; then
            APP_FRONTEND_ROOT='/data/frontend/web'
        fi

        sed -i "s@#APP_FRONTEND_DOMAIN#@${APP_FRONTEND_DOMAIN}@g" /etc/nginx/conf.d/advanced.conf
        sed -i "s@#APP_FRONTEND_PORT#@${APP_FRONTEND_PORT}@g" /etc/nginx/conf.d/advanced.conf
        sed -i "s@#APP_FRONTEND_ROOT#@${APP_FRONTEND_ROOT}@g" /etc/nginx/conf.d/advanced.conf

        # Backend
        if [[ -z "${APP_BACKEND_DOMAIN}" ]]; then
            APP_BACKEND_DOMAIN='_'
        fi

        if [[ -z "${APP_BACKEND_PORT}" ]]; then
            APP_BACKEND_PORT='81'
        fi

        if [[ -z "${APP_BACKEND_ROOT}" ]]; then
            APP_BACKEND_ROOT='/data/backend/web'
        fi

        sed -i "s@#APP_BACKEND_DOMAIN#@${APP_BACKEND_DOMAIN}@g" /etc/nginx/conf.d/advanced.conf
        sed -i "s@#APP_BACKEND_PORT#@${APP_BACKEND_PORT}@g" /etc/nginx/conf.d/advanced.conf
        sed -i "s@#APP_BACKEND_ROOT#@${APP_BACKEND_ROOT}@g" /etc/nginx/conf.d/advanced.conf

        if [[ "$YII_INSTALL_TEMPLATE" = true ]] && [[ ! "$(ls -A /data)" ]]; then
            gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-advanced /data
            gosu www-data php init --env=Development
        fi
    else
        echo "Enabled basic template"

        if [[ ! -f /etc/nginx/conf.d/basic.conf ]]; then
            cp /etc/nginx/conf.d/basic.conf.tmpl /etc/nginx/conf.d/basic.conf
        fi

        if [[ -z "${APP_DOMAIN}" ]]; then
            APP_DOMAIN='_'
        fi

        if [[ -z "${APP_PORT}" ]]; then
            APP_PORT='80'
        fi

        if [[ -z "${APP_ROOT}" ]]; then
            APP_ROOT='/data/web'
        fi

        sed -i "s@#APP_DOMAIN#@${APP_DOMAIN}@g" /etc/nginx/conf.d/basic.conf
        sed -i "s@#APP_PORT#@${APP_PORT}@g" /etc/nginx/conf.d/basic.conf
        sed -i "s@#APP_ROOT#@${APP_ROOT}@g" /etc/nginx/conf.d/basic.conf

        if [[ "$YII_INSTALL_TEMPLATE" = true ]] && [[ ! "$(ls -A /data)" ]]; then
            echo "Begin install basic template"
            gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-basic /data
        fi
    fi

    service nginx start
    service php${PHP_INSTALL_VERSION}-fpm start
    service ssh start

    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi

exec "$@"
