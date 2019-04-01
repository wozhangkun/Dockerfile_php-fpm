FROM wozhangkun/php-fpm:7.0.33

ENV PECL_SWOOLE_URL http://pecl.php.net/get/swoole-4.3.1.tgz
ENV PECL_EVENT_URL http://pecl.php.net/get/event-2.4.3.tgz
######################################################################################Copy composer
COPY composer /usr/local/bin/
RUN chmod a+x /usr/local/bin/composer
######################################################################################Configure php-ext
RUN \
      cd /tmp \
#############install mongodb.so
      && /usr/local/php/bin/pecl install mongodb >/dev/null \
      && echo -e "extension=mongodb.so" >> /usr/local/php/etc/php.ini \
      \
#############install phalcon.so
      && git clone https://github.com/phalcon/cphalcon.git >/dev/null \
      && cd cphalcon/build \
      && ./install --phpize /usr/local/php/bin/phpize --php-config /usr/local/php/bin/php-config >/dev/null \
      && echo -e "extension=phalcon.so" >> /usr/local/php/etc/php.ini \
      \
#############install swoole.so
      && wget -O swoole.tar.gz $PECL_SWOOLE_URL >/dev/null \
      && mkdir swoole \
      && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
      && cd swoole \
      && /usr/local/php/bin/phpize > /dev/null \
      && ./configure --with-php-config=/usr/local/php/bin/php-config --enable-openssl --enable-http2 --enable-thread --enable-swoole \
      && make >/dve/null \
      && make install >/dev/null \
      && echo -e "extension=swoole.so" >> /usr/local/php/etc/php.ini \
      \
#############install event.so
      && wget -O event.tar.gz $PECL_EVENT_URL >/dev/null \
      && mkdir event \
      && tar -xf event.tar.gz -C event --strip-components=1 \
      && cd event \
      && /usr/local/php/bin/phpize > /dev/null \
      && ./configure --with-php-config=/usr/local/php/bin/php-config --with-event-core --with-event-extra \
      && make >/dve/null \
      && make install >/dev/null \
      && echo -e "extension=event.so" >> /usr/local/php/etc/php.ini \
      \
      ######################################################################################move install file
      && cd \
      && rm -rf /tmp/cphalcon \
      && yum clean all

EXPOSE 9000

WORKDIR /var/www/html

CMD ["/usr/local/php/sbin/php-fpm","--nodaemonize","--fpm-config","/usr/local/php/etc/php-fpm.conf"]
