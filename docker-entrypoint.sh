#!/bin/sh
set -e
if [ ! -z "$DRUPAL_WEB_ROOT" ]; then
  DRUPAL_WEB_ROOT=${DRUPAL_WEB_ROOT:=web}
  sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/html\/$DRUPAL_WEB_ROOT/g" /etc/apache2/sites-enabled/000-default.conf
fi
# if the drupal is init by composer, the code directory locate on "web".
# This options is used to change the nginx root path.
#if [ "$1" = 'httpd-foreground' -a "$(id -u)" = '0' ]; then
PHP_INI_PATH=/etc/php/${PHP_VERSION}/apache2/php.ini
# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
  sudo sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}/g" $PHP_INI_PATH
fi
# Increase the timeout
if [ ! -z "$PHP_MAX_EXECUTION_TIME" ]; then
  sudo sed -i "s/max_execution_time = 30/max_execution_time = ${TIMEOUT}/g" $PHP_INI_PATH
fi
# Increase the timeout
if [ ! -z "$PHP_UPLOAD_SIZE" ]; then
  sudo sed -i "s/post_max_size = 8M/post_max_size = ${PHP_UPLOAD_SIZE}/g" $PHP_INI_PATH
  sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = ${PHP_UPLOAD_SIZE}/g" $PHP_INI_PATH
fi
# Increase the timeout
if [ ! -z "$PHP_MAX_INPUT_VARS" ]; then
  sudo sed -i "s/;max_input_vars = 1000/max_input_vars = ${PHP_MAX_INPUT_VARS}/g" $PHP_INI_PATH
fi

# php display errors
if [ ! -z "$PHP_DISPLAY_ERRORS" ]; then
  sudo sed -i "s/display_errors = Off/display_errors = ${PHP_DISPLAY_ERRORS}/g" $PHP_INI_PATH
  sudo sed -i "s/display_startup_errors = Off/display_errors = ${PHP_DISPLAY_ERRORS}/g" $PHP_INI_PATH
fi
exec "$@"
