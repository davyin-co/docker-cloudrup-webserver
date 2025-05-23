FROM davyinsa/cloudrup-static-server
ENV TERM="xterm" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    DEBIAN_FRONTEND="noninteractive" \
    COMPOSER1_VERSION=1.10.26 \
    PHPREDIS_VERSION=5.3.7 \
    DRUSH_VERSION=8.4.11 \
    OPENSSL_VERSION=1.1.1q \
    PHP_VERSION=7.1

RUN apt-get update -qq && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:ondrej/php && \
    apt-get update -qq && apt-get install -y -qq \
    php$PHP_VERSION \
    php$PHP_VERSION-dev \
    libapache2-mod-php$PHP_VERSION \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-opcache \
    php$PHP_VERSION-json \
    php$PHP_VERSION-xmlrpc \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-ldap \
    php$PHP_VERSION-bz2 \
    php$PHP_VERSION-cgi \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-common \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-bcmath \
    php-redis \
    sudo \
    rsync \
    git-core \
    unzip \
    wget \
    mariadb-client \
    vim \
    build-essential \
    checkinstall \
    zlib1g-dev \
    curl && \
    # Install redis extension
    update-alternatives --set php /usr/bin/php$PHP_VERSION && \
    cd /tmp && \
    git clone --branch $PHPREDIS_VERSION https://github.com/phpredis/phpredis && \
    cd phpredis && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    rm -rf /tmp/phpredis && \
    echo "extension=redis.so" > /etc/php/$PHP_VERSION/mods-available/redis.ini && \
    ln -s /etc/php/$PHP_VERSION/mods-available/redis.ini /etc/php/$PHP_VERSION/apache2/conf.d/30-redis.ini && \
    ln -s /etc/php/$PHP_VERSION/mods-available/redis.ini /etc/php/$PHP_VERSION/cli/conf.d/30-redis.ini && \
    rm -rf /var/lib/apt/lists/* && \
    ## set /var/www dir AllowOverride => All
    sed -i "170,174s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
    ## install composer 
    wget https://getcomposer.org/installer -O - -q > /tmp/composer-setup.php && \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('/tmp/composer-setup.php');" && \
    chmod +x /usr/local/bin/composer && \
    ## install drush
    wget https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar -O - -q > /usr/local/bin/drush && \
    chmod +x /usr/local/bin/drush && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV \
    PATH=/usr/local/ssl/bin:$PATH \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs
COPY rootfs /
#USER aegir
WORKDIR /var/aegir
VOLUME /var/aegir
EXPOSE 22 80 443
