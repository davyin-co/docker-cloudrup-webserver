# 介绍

## PHP 7.4 紧急安全更新（2026-10-22）

针对 CVE-2026-109618 / CVE-2026-109619，保留 Drupal 8 和 PHP 7.4 时，可使用现有 Ondrej PPA 的修复包。已核对的 Ubuntu 22.04 修复版本为 `1:7.4.33-31+ubuntu22.04.1+deb.sury.org+1`，`php -v` 仍显示 `7.4.33`。

已有镜像的快速重建、验证及部署步骤见 [PHP 7.4 修复说明](security/php74/README.md)。默认 `7.4/Dockerfile` 也会更新并验证软件包；无法取得修复包或验证失败时构建会停止。生产部署前仍需在测试环境验证实际网站。

站群系统使用的webserver的docker镜像，基于 cloudrup-static-server，安装配置了 apache/php/ssh 等；本次核对的 PHP 7.4 已发布镜像使用 Ubuntu 22.04。

# docker-compose example for cloudrup webserver
```bash
version: '3'
services:
  web:
    image: davyinsa/cloudrup-webserver:7.3
    restart: always
    environment: 
      - DRUPAL_WEB_ROOT=docroot
      - PHP_MEM_LIMIT=512M
      - PHP_MAX_EXECUTION_TIME=60
      - PHP_UPLOAD_SIZE=64M
      - PHP_MAX_INPUT_VARS=2000
      - PHP_DISPLAY_ERRORS=Off
    volumes:
      - ./aegir:/var/aegir
      - /data/cloudrup/aegir/logs:/var/log/aegir
    ports:
      - "80:80"
      - "22:22"
```

# docker-compose example for single webserver
```bash
version: '3'
services:
  web:
    image: davyinsa/cloudrup-webserver:7.3
    restart: always
    environment: 
      - DRUPAL_WEB_ROOT=docroot
      - PHP_MEM_LIMIT=512M
      - PHP_MAX_EXECUTION_TIME=60
      - PHP_UPLOAD_SIZE=64M
      - PHP_MAX_INPUT_VARS=2000
      - PHP_DISPLAY_ERRORS=On
    volumes:
      - ./drupal-code:/var/www/html
    ports:
      - "80:80"
```
# 环境变量支持
#### apache 
[see here](https://github.com/davyin-co/cloudrup-static-server)
#### php 
|Name|Desciption|
|----|----------|
|DRUPAL_WEB_ROOT|The drupal code web root, may be web/docroot|
|PHP_MEM_LIMIT|The php memory limit in php.ini. default value is 128M.|
|PHP_MAX_EXECUTION_TIME|php max_execution_time|
|PHP_UPLOAD_SIZE|php post_max_size and upload_max_filesize|
|PHP_MAX_INPUT_VARS|php max_input_vars|
|PHP_DISPLAY_ERRORS|php display_errors and display_startup_errors|
