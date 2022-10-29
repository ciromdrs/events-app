FROM php:7.2-apache

# Enable apache2's mod_rewrite
RUN a2enmod rewrite && \
    service apache2 restart && \
    a2enmod rewrite
