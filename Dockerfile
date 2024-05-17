FROM php:8.1-apache
WORKDIR /var/www/html

# Mod Rewrite
RUN a2enmod rewrite 

# Linux Library
RUN apt-get update -y && apt-get install -y \
    libicu-dev \
    libmariadb-dev \
    unzip zip \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    curl gnupg

# PHP Extension
RUN docker-php-ext-install gettext intl pdo_mysql gd

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy file aplikasi
COPY ./tamiyochi-laravel /var/www/html

# Copy .env.example to .env
RUN cp .env.example .env

# Create necessary directories
RUN mkdir -pv storage/framework/views storage/app storage/framework/sessions storage/framework/cache bootstrap/cache

# Permission
RUN chmod 777 -R storage && \
    chown -R www-data:www-data storage && \
    chmod -R 755 storage && \
    chmod -R 755 bootstrap/cache

# Install Yarn
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn

# Run additional commands
RUN composer install 

RUN chmod o+w ./storage/ -R

RUN chown www-data:www-data -R ./storage

RUN php artisan key:generate

RUN php artisan config:clear

RUN php artisan config:cache

RUN yarn

RUN php artisan storage:link

RUN yarn build
