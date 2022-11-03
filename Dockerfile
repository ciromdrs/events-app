FROM php:8.1-apache AS base

COPY php/ /var/www/

# Enable apache2's mod_rewrite
RUN a2enmod rewrite && \
    service apache2 restart && \
    a2enmod rewrite # Check whether the mode is enabled

# Install PDO Mysql
RUN docker-php-ext-install pdo_mysql



# dev
FROM base AS dev

# Install Git
RUN apt-get -y update && \
    apt-get -y install git && \
    apt-get -y install zip

# Install PHP composer
WORKDIR ..
RUN pwd && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir /usr/bin --filename composer && \
    php -r "unlink('composer-setup.php');"
RUN composer install



# test
FROM dev AS test
