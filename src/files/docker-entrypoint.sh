#!/usr/bin/env bash

set -e

echo "${YII_INSTALL_TEMPLATE}"
echo "${YII_TEMPLATE}"

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
  echo "Starting"

  # If local volume mounted then change uid and gid for www-data
  if [[ -d "/data" ]]; then
    if [[ "$(stat -c "%u" /data)" != '0' && "$(stat -c "%u" /data)" != "$(id -u www-data)" ]]; then
      echo "Change uid and gid for www-data"

      usermod -u "$(stat -c "%u" /data)" www-data
      groupmod -g "$(stat -c "%g" /data)" www-data
    fi
  fi

  # If new docker volume mounted then change user and group
  if [ "$(stat -c "%u" /data)" != "$(id -u www-data)" ]; then
    echo "Change owners"

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

  echo "Select template"

  if [[ "${YII_TEMPLATE}" == 'basic' ]]; then
    echo "Enabled basic template"

    if [[ -z "${APP_HOST}" ]]; then
      APP_HOST='localhost'
    fi

    if [[ -z "${APP_PORT}" ]]; then
      APP_PORT='80'
    fi

    if [[ -z "${APP_ROOT}" ]]; then
      APP_ROOT='/data/web'
    fi

    configure-virtual-host basic ${APP_HOST} ${APP_PORT} ${APP_ROOT}

    if [[ "$YII_INSTALL_TEMPLATE" == 1 ]] && [[ ! "$(ls -A /data)" ]]; then
      echo "Install basic template"
      gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-basic /data
    fi
  elif [[ "${YII_TEMPLATE}" == 'advanced' ]]; then
    echo "Enabled advanced template"

    # App frontend
    if [[ -z "${APP_FRONTEND_HOST}" ]]; then
      APP_FRONTEND_HOST='localhost'
    fi

    if [[ -z "${APP_FRONTEND_PORT}" ]]; then
      APP_FRONTEND_PORT='80'
    fi

    if [[ -z "${APP_FRONTEND_ROOT}" ]]; then
      APP_FRONTEND_ROOT='/data/frontend/web'
    fi

    # App backend
    if [[ -z "${APP_BACKEND_HOST}" ]]; then
      APP_BACKEND_HOST='localhost'
    fi

    if [[ -z "${APP_BACKEND_PORT}" ]]; then
      if [ "${APP_BACKEND_HOST}" == "localhost" ]; then
        APP_BACKEND_PORT='81'
      else
        APP_BACKEND_PORT='80'
      fi
    fi

    if [[ -z "${APP_BACKEND_ROOT}" ]]; then
      APP_BACKEND_ROOT='/data/backend/web'
    fi

    configure-virtual-host frontend ${APP_FRONTEND_HOST} ${APP_FRONTEND_PORT} ${APP_FRONTEND_ROOT}
    configure-virtual-host backend ${APP_BACKEND_HOST} ${APP_BACKEND_PORT} ${APP_BACKEND_ROOT}

    if [[ "$YII_INSTALL_TEMPLATE" == 1 ]] && [[ ! "$(ls -A /data)" ]]; then
      echo "Install advanced template"
      gosu www-data composer create-project --prefer-dist yiisoft/yii2-app-advanced /data
      gosu www-data php init --env=Development
    fi
  fi

  if [ -n "${APP_EXT_1_HOST}" ] && [ -n "${APP_EXT_1_PORT}" ] && [ -n "${APP_EXT_1_ROOT}" ]; then
    configure-virtual-host app_ext_1 "${APP_EXT_1_HOST}" "${APP_EXT_1_PORT}" "${APP_EXT_1_ROOT}"
  fi
  if [ -n "${APP_EXT_2_HOST}" ] && [ -n "${APP_EXT_2_PORT}" ] && [ -n "${APP_EXT_2_ROOT}" ]; then
    configure-virtual-host app_ext_2 "${APP_EXT_2_HOST}" "${APP_EXT_2_PORT}" "${APP_EXT_2_ROOT}"
  fi
  if [ -n "${APP_EXT_3_HOST}" ] && [ -n "${APP_EXT_3_PORT}" ] && [ -n "${APP_EXT_3_ROOT}" ]; then
    configure-virtual-host app_ext_3 "${APP_EXT_3_HOST}" "${APP_EXT_3_PORT}" "${APP_EXT_3_ROOT}"
  fi

  service "${HTTP_SERVER}" start
  service ssh start

  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
fi

exec "$@"
