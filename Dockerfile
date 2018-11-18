FROM php:5.6-apache

ARG BOOKED_VERSION="2.7.2"

RUN apt-get update && \
    apt-get install -y vim \
    curl \
    unzip \
    mysql-client \
    libpng-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    libicu-dev \
    g++


RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl

RUN docker-php-ext-install -j$(nproc) mysql mysqli pdo pdo_mysql \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd
    
# LDAP
RUN apt-get install -y git zip libldb-dev libldap2-dev subversion \
        && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
        && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
        && docker-php-ext-configure ldap --with-ldap=/usr \
    && docker-php-ext-install -j$(nproc) zip ldap
    

RUN cd /var/www && curl -L -Os https://sourceforge.net/projects/phpscheduleit/files/Booked/2.7/booked-${BOOKED_VERSION}.zip && \
    unzip booked-${BOOKED_VERSION}.zip

COPY ActiveDirectory.config.php /var/www/booked/plugins/Authentication/ActiveDirectory/

RUN chown www-data: /var/www/booked -R && \
    chmod 0755 /var/www/booked -R
    
RUN cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/booked.conf && \
    sed -i 's,/var/www/html,/var/www/booked,g' /etc/apache2/sites-available/booked.conf && \
    sed -i 's,${APACHE_LOG_DIR},/var/log/apache2,g' /etc/apache2/sites-available/booked.conf && \
    a2ensite booked.conf && a2dissite 000-default.conf && a2enmod rewrite

COPY php.ini /usr/local/etc/php/

WORKDIR /var/www/booked

EXPOSE 80 443

CMD ["apache2-foreground"]