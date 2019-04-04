FROM wozhangkun/php-fpm:7.2.16

ENV PECL_SWOOLE_URL http://pecl.php.net/get/swoole-4.3.1.tgz
ENV PECL_EVENT_URL http://pecl.php.net/get/event-2.4.3.tgz
######################################################################################Copy composer
COPY composer /usr/local/bin/
RUN chmod a+x /usr/local/bin/composer && /usr/local/bin/composer self-update
######################################################################################Configure php-ext
RUN \
      cd /tmp \
#############install mongodb.so
      && /usr/local/php/bin/pecl install mongodb  \
      && echo -e "extension=mongodb.so" >> /usr/local/php/etc/php.ini \
      \
 #############install phalcon.so depend on psr.so
      && /usr/local/php/bin/pecl install psr \
      && echo -e "extension=psr.so" >> /usr/local/php/etc/php.ini \
      \
#############install phalcon.so
      && git clone https://github.com/phalcon/cphalcon.git  \
      && cd cphalcon/build \
      && ./install --phpize /usr/local/php/bin/phpize --php-config /usr/local/php/bin/php-config  \
      && echo -e "extension=phalcon.so" >> /usr/local/php/etc/php.ini \
      \
#############install swoole.so
      && wget -O swoole.tar.gz $PECL_SWOOLE_URL  \
      && mkdir swoole \
      && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
      && cd swoole \
      && /usr/local/php/bin/phpize \
      && ./configure --with-php-config=/usr/local/php/bin/php-config --enable-openssl --enable-http2 --enable-swoole \
      && make \
      && make install  \
      && echo -e "extension=swoole.so" >> /usr/local/php/etc/php.ini \
      \
#############install event.so (RCC Requirements >=PHP 7.2)
      && wget -O event.tar.gz $PECL_EVENT_URL  \
      && mkdir event \
      && tar -xf event.tar.gz -C event --strip-components=1 \
      && cd event \
      && /usr/local/php/bin/phpize > /dev/null \
      && ./configure --with-php-config=/usr/local/php/bin/php-config --with-event-core --with-event-extra \
      && make \
      && make install \
      && echo -e "extension=event.so" >> /usr/local/php/etc/php.ini \
      \
      ######################################################################################move install file
      && cd \
      && rm -rf /tmp/cphalcon \
      && yum clean all
