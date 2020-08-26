#!/usr/bin/env bash

set -e

function configure-virtual-host() {
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
  # If local volume mounted then change uid and gid for www-data
  if [[ -d "/data" ]]; then
    if [[ "$(stat -c "%u" /data)" != '0' && "$(stat -c "%u" /data)" != "$(id -u www-data)" ]]; then
      usermod -u "$(stat -c "%u" /data)" www-data
      groupmod -g "$(stat -c "%g" /data)" www-data
    fi
  fi

  # If new docker volume mounted then change user and group
  if [ "$(stat -c "%u" /data)" != "$(id -u www-data)" ]; then
    chown -R www-data:www-data /data
  fi

  if [[ -z "${ROOT_PASSWORD}" ]]; then
    ROOT_PASSWORD='root'
  fi
  echo "root:${ROOT_PASSWORD}" | chpasswd

  if [[ -z "${WWW_DATA_PASSWORD}" ]]; then
    WWW_DATA_PASSWORD='www-data'
  fi
  echo "www-data:${WWW_DATA_PASSWORD}" | chpasswd

  if [[ "${YII_TEMPLATE}" == 'basic' ]]; then
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

    configure-virtual-host basic ${APP_HOST} ${APP_PORT} ${APP_ROOT}

    if [[ "$YII_INSTALL_TEMPLATE" == true ]] && [[ ! "$(ls -A /data)" ]]; then
      echo "Install basic template"
      gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-basic /data
    fi
  elif [[ "${YII_TEMPLATE}" == 'advanced' ]]; then
    echo "Enabled advanced template"

    # App frontend
    if [[ -z "${FRONTEND_HOST}" ]]; then
      FRONTEND_HOST='_'
    fi

    if [[ -z "${FRONTEND_PORT}" ]]; then
      FRONTEND_PORT='80'
    fi

    if [[ -z "${FRONTEND_ROOT}" ]]; then
      FRONTEND_ROOT='/data/frontend/web'
    fi

    # App backend
    if [[ -z "${BACKEND_HOST}" ]]; then
      BACKEND_HOST='_'
    fi

    if [[ -z "${BACKEND_PORT}" ]]; then
      if [ "${BACKEND_HOST}" == "_" ]; then
        BACKEND_PORT='81'
      else
        BACKEND_PORT='80'
      fi
    fi

    if [[ -z "${BACKEND_ROOT}" ]]; then
      BACKEND_ROOT='/data/backend/web'
    fi

    configure-virtual-host frontend ${FRONTEND_HOST} ${FRONTEND_PORT} ${FRONTEND_ROOT}
    configure-virtual-host backend ${BACKEND_HOST} ${BACKEND_PORT} ${BACKEND_ROOT}

    if [[ "$YII_INSTALL_TEMPLATE" == true ]] && [[ ! "$(ls -A /data)" ]]; then
      echo "Install advanced template"
      gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-advanced /data
      gosu www-data php init --env=Development
    fi
  fi

  if [ -n "${CUSTOM_1_HOST}" ] && [ -n "${CUSTOM_1_PORT}" ] && [ -n "${CUSTOM_1_ROOT}" ]; then
    configure-virtual-host custom_1 "${CUSTOM_1_HOST}" "${CUSTOM_1_PORT}" "${CUSTOM_1_ROOT}"
  fi
  if [ -n "${CUSTOM_2_HOST}" ] && [ -n "${CUSTOM_2_PORT}" ] && [ -n "${CUSTOM_2_ROOT}" ]; then
    configure-virtual-host custom_2 "${CUSTOM_2_HOST}" "${CUSTOM_2_PORT}" "${CUSTOM_2_ROOT}"
  fi
  if [ -n "${CUSTOM_3_HOST}" ] && [ -n "${CUSTOM_3_PORT}" ] && [ -n "${CUSTOM_3_ROOT}" ]; then
    configure-virtual-host custom_3 "${CUSTOM_3_HOST}" "${CUSTOM_3_PORT}" "${CUSTOM_3_ROOT}"
  fi

  service "${HTTP_SERVER}" start
  service php"${PHP_INSTALL_VERSION}"-fpm start
  service ssh start

  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi

exec "$@"
