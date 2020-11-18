FROM ubuntu:18.04
ENV TERM="xterm" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"\
    DEBIAN_FRONTEND="noninteractive"
ENV PHPREDIS_VERSION 5.3.2
ENV DRUSH_VERSION 8.4.5
ENV PHP_VERSION 7.4

RUN apt-get update -qq; \
    apt-get install -y software-properties-common ;\
    add-apt-repository -y ppa:ondrej/php; \
    add-apt-repository -y ppa:ondrej/apache2; \
    apt-get update -qq && apt-get install -y -qq \
    apache2 \
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
    sudo \
    rsync \
    git-core \
    unzip \
    wget \
    mysql-client \
    vim \
    openssh-server; \
    rm -rf /var/lib/apt/lists/*

# Install redis extension
RUN cd /tmp && \
    git clone --branch $PHPREDIS_VERSION https://github.com/phpredis/phpredis && \
    cd phpredis && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    rm -rf /tmp/phpredis && \
    echo "extension=redis.so" > /etc/php/$PHP_VERSION/mods-available/redis.ini && \
    ln -s /etc/php/$PHP_VERSION/mods-available/redis.ini /etc/php/$PHP_VERSION/apache2/conf.d/30-redis.ini && \
    ln -s /etc/php/$PHP_VERSION/mods-available/redis.ini /etc/php/$PHP_VERSION/cli/conf.d/30-redis.ini

# Use --build-arg option when running docker build to set these variables.
# If wish to "mount" a volume to your host, set AEGIR_UID and AEGIR_GIT to your local user's UID.
# There are both ARG and ENV lines to make sure the value persists.
# See https://docs.docker.com/engine/reference/builder/#/arg
ARG AEGIR_UID=1000
ENV AEGIR_UID ${AEGIR_UID:-1000}

COPY sudoers-aegir /etc/sudoers.d/aegir
COPY httpd-foreground /usr/local/bin/httpd-foreground
COPY config/other-vhosts-access-log.conf /etc/apache2/conf-available/other-vhosts-access-log.conf
COPY config/security.conf /etc/apache2/conf-available/security.conf

RUN echo "Creating user aegir with UID $AEGIR_UID and GID $AEGIR_GID" && \
    addgroup --gid $AEGIR_UID aegir && \
    adduser --uid $AEGIR_UID --gid $AEGIR_UID --system --home /var/aegir aegir && \
    adduser aegir www-data && \
    usermod aegir -s /bin/bash && \
    chown root:root /etc/sudoers.d/aegir && \
    chmod 0440 /etc/sudoers.d/aegir

## setup apache config
RUN a2enmod rewrite && \
    a2enmod speling && \
    a2enmod ssl && \
    a2enmod headers && \
    # Save a symlink to the /var/aegir/config/docker.conf file.
    mkdir -p /var/aegir/config && \
    echo "" > /var/aegir/config/apache.conf && \
    chown aegir:aegir /var/aegir/config -R && \
    mkdir /var/aegir/.ssh && \
    chown aegir:aegir /var/aegir/.ssh -R && \
    chmod 750 /var/aegir/.ssh && \
    ln -sf /var/aegir/config/apache.conf /etc/apache2/conf-available/aegir.conf && \
    ln -sf /etc/apache2/conf-available/aegir.conf /etc/apache2/conf-enabled/aegir.conf && \
    # Prepare Aegir Logs folder.
    mkdir /var/log/aegir && \
    chown aegir:aegir /var/log/aegir && \
    echo 'Hello, Cloudrup.' > /var/log/aegir/system.log && \
    chmod +x /usr/local/bin/httpd-foreground && \
    systemctl enable ssh

## install composer & drush
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    wget https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar -O - -q > /usr/local/bin/drush && \
    chmod +x /usr/local/bin/composer && \
    chmod +x /usr/local/bin/drush

USER aegir
WORKDIR /var/aegir
VOLUME /var/aegir

# docker-entrypoint.sh waits for mysql and runs hostmaster install
ENTRYPOINT []
CMD ["httpd-foreground"]
