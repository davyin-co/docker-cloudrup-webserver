# 介绍
站群系统使用的webserver的docker镜像，基于ubuntu 18.04,安装配置了apache/php/ssh等。

# docker-compose example
```bash
version: '3'
services:
  web:
    image: davyinsa/cloudrup-webserver:7.3
    restart: always
    environment: 
      - PHP_MEM_LIMIT=512M
      - PHP_MAX_EXECUTION_TIME=60
      - PHP_UPLOAD_SIZE=64M
      - PHP_MAX_INPUT_VARS=2000
      - PHP_DISPLAY_ERRORS=On
    volumes:
      - ./aegir:/var/aegir
    ports:
      - "80:80"
      - "22:22"
```
# 环境变量支持
#### php & php-fpm
|Name|Desciption|
|----|----------|
|PHP_MEM_LIMIT|The php memory limit in php.ini. default value is 128M.|
|PHP_MAX_EXECUTION_TIME|php max_execution_time|
|PHP_UPLOAD_SIZE|php post_max_size and upload_max_filesize|
|PHP_MAX_INPUT_VARS|php max_input_vars|
|PHP_DISPLAY_ERRORS|php display_errors and display_startup_errors|