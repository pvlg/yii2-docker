#!/usr/bin/env bash

set -e

function configure-vurtual-host() {
  local NAME=$1
  local HOST=$2
  local PORT=$3
  local ROOT=$4

  if [[ ! -f /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf ]]; then
    cp /etc/"${HTTP_SERVER}"/conf.d/virtual-host.conf.dist /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf

    if [ "${HOST}" == "_" ] && [ "${HTTP_SERVER}" == "apache2" ]; then
      sed -i "/#HOST#/d" /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf
    else
      sed -i "s@#HOST#@${HOST}@g" /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf
    fi

    if [ "${PORT}" == "80" ] && [ "${HTTP_SERVER}" == "apache2" ]; then
      sed -i "/Listen #PORT#/d" /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf
    fi
    sed -i "s@#PORT#@${PORT}@g" /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf

    sed -i "s@#ROOT#@${ROOT}@g" /etc/"${HTTP_SERVER}"/conf.d/"${NAME}".conf
  fi
}

if [[ "$1" == 'supervisor' ]]; then
  chown www-data:www-data /data
  chown -R www-data:www-data /var/www

  if [[ -z "${ROOT_PASSWORD}" ]]; then
    ROOT_PASSWORD='root'
  fi
  echo "root:${ROOT_PASSWORD}" | chpasswd

  if [[ -z "${WWW_DATA_PASSWORD}" ]]; then
    WWW_DATA_PASSWORD='www-data'
  fi
  echo "www-data:${WWW_DATA_PASSWORD}" | chpasswd

  if [[ "${YII_APP_TEMPLATE}" == 'basic' ]]; then
    echo "Enabled basic template"

    if [[ -z "${APP_HOST}" ]]; then
      APP_HOST='_'
    fi

    if [[ -z "${APP_PORT}" ]]; then
      APP_PORT='80'
    fi

    if [[ -z "${APP_ROOT}" ]]; then
      APP_ROOT='/data/web'
    fi

    configure-vurtual-host basic ${APP_HOST} ${APP_PORT} ${APP_ROOT}

    if [[ "$YII_INSTALL_TEMPLATE" == true ]] && [[ ! "$(ls -A /data)" ]]; then
      echo "Install basic template"
      gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-basic /data
    fi
  elif [[ "${YII_APP_TEMPLATE}" == 'advanced' ]]; then
    echo "Enabled advanced template"

    # App frontend
    if [[ -z "${APP_FRONTEND_HOST}" ]]; then
      APP_FRONTEND_HOST='_'
    fi

    if [[ -z "${APP_FRONTEND_PORT}" ]]; then
      APP_FRONTEND_PORT='80'
    fi

    if [[ -z "${APP_FRONTEND_ROOT}" ]]; then
      APP_FRONTEND_ROOT='/data/frontend/web'
    fi

    # App backend
    if [[ -z "${APP_BACKEND_HOST}" ]]; then
      APP_BACKEND_HOST='_'
    fi

    if [[ -z "${APP_BACKEND_PORT}" ]]; then
      if [ "${APP_BACKEND_HOST}" == "_" ]; then
        APP_BACKEND_PORT='81'
      else
        APP_BACKEND_PORT='80'
      fi
    fi

    if [[ -z "${APP_BACKEND_ROOT}" ]]; then
      APP_BACKEND_ROOT='/data/backend/web'
    fi

    configure-vurtual-host frontend ${APP_FRONTEND_HOST} ${APP_FRONTEND_PORT} ${APP_FRONTEND_ROOT}
    configure-vurtual-host backend ${APP_BACKEND_HOST} ${APP_BACKEND_PORT} ${APP_BACKEND_ROOT}

    if [[ "$YII_INSTALL_TEMPLATE" == true ]] && [[ ! "$(ls -A /data)" ]]; then
      echo "Install advanced template"
      gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-advanced /data
      gosu www-data php init --env=Development
    fi
  fi

  if [ -n "${APP_CUSTOM_1_HOST}" ] && [ -n "${APP_CUSTOM_1_PORT}" ] && [ -n "${APP_CUSTOM_1_ROOT}" ]; then
    configure-vurtual-host custom_1 "${APP_CUSTOM_1_HOST}" "${APP_CUSTOM_1_PORT}" "${APP_CUSTOM_1_ROOT}"
  fi
  if [ -n "${APP_CUSTOM_2_HOST}" ] && [ -n "${APP_CUSTOM_2_PORT}" ] && [ -n "${APP_CUSTOM_2_ROOT}" ]; then
    configure-vurtual-host custom_2 "${APP_CUSTOM_2_HOST}" "${APP_CUSTOM_2_PORT}" "${APP_CUSTOM_2_ROOT}"
  fi
  if [ -n "${APP_CUSTOM_3_HOST}" ] && [ -n "${APP_CUSTOM_3_PORT}" ] && [ -n "${APP_CUSTOM_3_ROOT}" ]; then
    configure-vurtual-host custom_3 "${APP_CUSTOM_3_HOST}" "${APP_CUSTOM_3_PORT}" "${APP_CUSTOM_3_ROOT}"
  fi

  service "${HTTP_SERVER}" start
  service php"${PHP_INSTALL_VERSION}"-fpm start
  service ssh start

  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi

exec "$@"
