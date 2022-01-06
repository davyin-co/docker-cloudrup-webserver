## https://hub.docker.com/r/adrianharabula/php7-with-oci8/dockerfile
FROM davyinsa/cloudrup-webserver:8.1
USER root
RUN apt -qq update && apt install -y curl unzip libaio1 && \
    cd /tmp &&  \
    curl -L https://raw.github.com/adrianharabula/php7-with-oci8/master/instantclient/19.3.0.0.0/instantclient-basiclite-linux.x64-19.3.0.0.0dbru.zip -O && \
    curl -L https://raw.github.com/adrianharabula/php7-with-oci8/master/instantclient/19.3.0.0.0/instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip -O && \
    curl -L https://raw.github.com/adrianharabula/php7-with-oci8/master/instantclient/19.3.0.0.0/instantclient-sqlplus-linux.x64-19.3.0.0.0dbru.zip -O && \
    unzip /tmp/instantclient-basiclite-linux.x64-19.3.0.0.0dbru.zip -d /usr/local/ && \
    unzip /tmp/instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip -d /usr/local/ && \
    unzip /tmp/instantclient-sqlplus-linux.x64-19.3.0.0.0dbru.zip -d /usr/local/ && \
    rm /tmp/*.zip && \
    ln -s /usr/local/instantclient_19_3 /usr/local/instantclient && \
    # fixes error "libnnz19.so: cannot open shared object file: No such file or directory"
    ln -s /usr/local/instantclient/lib* /usr/lib && \
    ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus && \
    export LD_LIBRARY_PATH="/usr/local/instantclient" && \
    echo 'instantclient,/usr/local/instantclient' | pecl install oci8-2.2.0 && \
    echo "extension=oci8.so" > /etc/php/8.1/apache2/conf.d/php-oci.ini && \
    echo "extension=oci8.so" > /etc/php/8.1/cli/conf.d/php-oci.ini && \
    # install pdo_oci  /  https://github.com/rosemberg-al/docker-php7-pdo_oci-oci8/blob/master/Dockerfile
    git clone -b PHP-8.1 https://github.com/php/php-src.git /tmp/php-src && \
    cd /tmp/php-src/ext/pdo_oci/  && \
    phpize  && \
    ./configure --with-pdo-oci=instantclient,/usr/local/instantclient && \
    make install  && \
    echo "extension=pdo_oci.so" > /etc/php/8.1/apache2/conf.d/pdo_oci.ini && \
    echo "extension=pdo_oci.so" > /etc/php/8.1/cli/conf.d/pdo_oci.ini && \
    rm -rf /tmp/php-src
