FROM centos

ENV PHP_v php-7.1.27
ENV PHP_USER www-data
ENV PHP_DIR /usr/local/${PHP_v}

ENV PHP_URL https://www.php.net/distributions/${PHP_v}.tar.gz
ENV PECL_REDIS_URL http://pecl.php.net/get/redis-4.3.0.tgz

###########################################################################################Install $PHP_v
RUN \
     useradd -s /sbin/nologin $PHP_USER \
    && yum -y install epel-release \
    && yum -y install git wget gcc gcc-c++ m4 autoconf libtool bison bison-devel zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel freetype-devel libpng-devel libcurl-devel libxslt-devel libmcrypt libmcrypt-devel mcrypt sqlite-devel libevent-devel mhash-devel pcre-devel bzip2-devel curl-devel openssl-devel bison-devel php-devel pcre-devel make re2c php-mysql \
    && cd /tmp \
    && wget -O php.tar.gz $PHP_URL \
    && mkdir php \
    && tar -xf php.tar.gz -C php --strip-components=1 \
    && cd php \
    && ./configure --prefix=${PHP_DIR} \
            --with-config-file-path=${PHP_DIR}/etc \
            --enable-fpm \
            --with-fpm-user=${PHP_USER} \
            --with-fpm-group=${PHP_USER} \
            --enable-opcache \
            --enable-mysqlnd \
            --with-libdir=lib64 \
            --with-mysqli=mysqlnd \
            --with-pdo-mysql=mysqlnd \
            --with-freetype-dir \
            --with-jpeg-dir \
            --with-png-dir \
            --with-iconv-dir \
            --with-mcrypt \
            --with-zlib \
            --with-libxml-dir \
            --enable-xml \
            --with-xmlrpc \
            --disable-rpath \
            --enable-bcmath \
            --enable-shmop \
            --enable-sysvsem \
            --enable-inline-optimization \
            --with-curl \
            --enable-mbregex \
            --enable-mbstring \
            --with-gd \
            --with-openssl \
            --with-openssl \
            --with-mhash \
            --enable-pcntl \
            --enable-sockets \
            --enable-bcmath \
            --enable-wddx \
            --with-xmlrpc \
            --enable-soap \
            --enable-zip \
            --enable-short-tags \
            --enable-static \
            --with-xsl \
            --disable-debug \
            --disable-ipv6 \
            --enable-ftp \
            --disable-maintainer-zts \
            --enable-fileinfo \
      && make \
      && make install \ 
      \
      && ln -s ${PHP_DIR} /usr/local/php \ 
      && ln -s ${PHP_DIR}/bin/* /usr/local/bin/ \
      && ln -s ${PHP_DIR}/sbin/* /usr/local/sbin/ \
######################################################################################Configure php.ini
      \
      && cp -rf php.ini-production ${PHP_DIR}/etc/php.ini \
      && extension_dir=`${PHP_DIR}/bin/php -i | grep '^extension_dir' | awk '{print $NF}'` \
      && sed -i 's,expose_php = On,expose_php = Off,g' ${PHP_DIR}/etc/php.ini \
      && sed -i "s#; extension_dir = \"\.\/\"#extension_dir = ${extension_dir}#g"  ${PHP_DIR}/etc/php.ini \
      && sed -i 's/post_max_size = 8M/post_max_size = 64M/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;date.timezone =/date.timezone = PRC/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/max_execution_time = 30/max_execution_time = 300/g' ${PHP_DIR}/etc/php.ini \
      \
######################################################################################Configure php Cache
      && sed -i 's/;opcache.enable=0/opcache.enable=1/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;opcache.interned_strings_buffer=4/opcache.interned_strings_buffer=8/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;opcache.fast_shutdown=0/opcache.fast_shutdown=1/g' ${PHP_DIR}/etc/php.ini \
      && sed -i 's/;opcache.enable_cli=0/opcache.enable_cli=1/g' ${PHP_DIR}/etc/php.ini \
      && echo -e "zend_extension=opcache.so" >> ${PHP_DIR}/etc/php.ini \
      \
######################################################################################Configure php-fpm
      && cp -rf ${PHP_DIR}/etc/php-fpm.conf.default ${PHP_DIR}/etc/php-fpm.conf \
      && mv ${PHP_DIR}/etc/php-fpm.d/www.conf.default ${PHP_DIR}/etc/php-fpm.d/www.conf \
      && sed -i 's,;pm.max_requests = 500,pm.max_requests = 3000,g' ${PHP_DIR}/etc/php-fpm.d/www.conf \
      && sed -i 's,^pm.min_spare_servers = 1,pm.min_spare_servers = 5,g'   ${PHP_DIR}/etc/php-fpm.d/www.conf \
      && sed -i 's,^pm.max_spare_servers = 3,pm.max_spare_servers = 35,g'  ${PHP_DIR}/etc/php-fpm.d/www.conf \
      && sed -i 's,^pm.max_children = 5,pm.max_children = 100,g'  ${PHP_DIR}/etc/php-fpm.d/www.conf \
      && sed -i 's,^pm.start_servers = 2,pm.start_servers = 20,g'   ${PHP_DIR}/etc/php-fpm.d/www.conf \
      && sed -i 's,;pid = run/php-fpm.pid,pid = run/php-fpm.pid,g'   ${PHP_DIR}/etc/php-fpm.conf \
      && sed -i "s,;error_log = php_errors.log,error_log = ${PHP_DIR}/var/log/php-fpm.log,g" ${PHP_DIR}/etc/php-fpm.conf \
#Php-fpm and nginx continue to listen for all ips when they are not in the same container
      && sed -i 's,^listen = 127.0.0.1:9000,listen = 9000,g' ${PHP_DIR}/etc/php-fpm.d/www.conf \
      \
######################################################################################Configure php-ext
      && wget -O redis.tar.gz $PECL_REDIS_URL \
      && mkdir redis \
      && tar -xf redis.tar.gz -C redis --strip-components=1 \
      && cd redis \
      && ${PHP_DIR}/bin/phpize \
      && ./configure --with-php-config=${PHP_DIR}/bin/php-config \
      && make \
      && make install \
      && echo -e "extension=redis.so" >> ${PHP_DIR}/etc/php.ini \
      \
######################################################################################move install file
      && cd \
      && rm -rf /tmp/php* \
      && yum clean all

VOLUME ["/var/www/html"]

EXPOSE 9000

WORKDIR /var/www/html

CMD ["/usr/local/php/sbin/php-fpm","--nodaemonize","--fpm-config","/usr/local/php/etc/php-fpm.conf"]
