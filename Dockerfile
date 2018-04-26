FROM alpine:edge

RUN apk update \
    && apk add nginx git

ENV PHP_FPM_USER="nginx"
ENV PHP_FPM_GROUP="nginx"
ENV PHP_FPM_LISTEN_MODE="0660"
ENV PHP_MEMORY_LIMIT="512M"
ENV PHP_MAX_UPLOAD="50M"
ENV PHP_MAX_FILE_UPLOAD="200"
ENV PHP_MAX_POST="100M"
ENV PHP_DISPLAY_ERRORS="On"
ENV PHP_DISPLAY_STARTUP_ERRORS="On"
ENV PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
ENV PHP_CGI_FIX_PATHINFO=0
ENV TIMEZONE="Asia/Shanghai"
# mysql
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    TERM="xterm"

RUN apk add curl \
    ssmtp \
    tzdata \
    php7 \
    php7-apcu \
    php7-bcmath \
    php7-bz2 \
    php7-curl \
    php7-ctype \
    php7-dom \
    php7-fpm \
    php7-gd \
    php7-gettext \
    php7-gmp \
    php7-iconv \
    php7-json \
    php7-mcrypt \
    php7-mysqli \
    php7-mysqlnd \
    php7-mbstring \
    php7-odbc \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-pdo_sqlite \
    php7-pdo_dblib \
    php7-pdo_odbc \
    php7-session \
    php7-simplexml \
    php7-soap \
    php7-sqlite3 \
    php7-tokenizer \
    php7-xmlwriter \
    php7-xmlreader \
    php7-xmlrpc \
    php7-xml \
    php7-zip \
    supervisor \
    composer

RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.conf \
    && sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.conf \
    && sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.conf \
    && sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.conf \
    && sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.conf \
    && sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.conf \
    && sed -i 's/include\ \=\ \/etc\/php7\/fpm.d\/\*.conf/\;include\ \=\ \/etc\/php7\/fpm.d\/\*.conf/g' /etc/php7/php-fpm.conf

RUN sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini \
    && sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini \
    && sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini \
    && sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini \
    && sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini \
    && sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini \
    && sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini \
    && sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini \
    && sed -i 's/smtp_port\ =\ 25/smtp_port\ =\ 81/g' /etc/php7/php.ini \
    && sed -i 's/SMTP\ =\ localhost/SMTP\ =\ mail.solutions.com/g' /etc/php7/php.ini \
    && sed -i 's/;sendmail_path\ =/sendmail_path\ =\ \/usr\/sbin\/sendmail\ -t/g' /etc/php7/php.ini

RUN rm -rf /etc/localtime \
    && ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini \
    && echo 'sendmail_path = "/usr/sbin/ssmtp -t "' > /etc/php7/conf.d/mail.ini \
    && sed -i 's/mailhub=mail/mailhub=mail.domain.com\:81/g' /etc/ssmtp/ssmtp.conf

ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD index.php /www/index.php
ADD bin /opt/bin

RUN chmod +x -R /opt/bin

# Drupal
RUN rm -rf /www
RUN git clone -b 8.6.x git://git.drupal.org/project/drupal.git /www
WORKDIR /www
ENV COMPOSER_PROCESS_TIMEOUT 1200
RUN composer install
RUN composer update

RUN composer require \
    drupal/address

# Install drush
RUN composer require drush/drush

EXPOSE 80 443
CMD ["/opt/bin/wrapper.sh"]