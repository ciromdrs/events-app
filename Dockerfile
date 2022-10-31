FROM php:8.1-apache

# Enable apache2's mod_rewrite
RUN a2enmod rewrite && \
    service apache2 restart && \
    a2enmod rewrite

# Install PDO Mysql
RUN docker-php-ext-install pdo_mysql
