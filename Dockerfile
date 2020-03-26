FROM drupal:8.7-apache

RUN apt-get update && apt-get install -y \
  git \
  imagemagick \
  libmagickwand-dev \
  mariadb-client \
  rsync \
  sudo \
  libzip-dev \
  unzip \
  exif \
  vim \
  wget \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install pdo \
  && docker-php-ext-install exif \
  && docker-php-ext-install gd \
  && docker-php-ext-install dom \
  && docker-php-ext-install gettext \
  && docker-php-ext-install pdo_mysql \
  && docker-php-ext-install json \
  && docker-php-ext-install mbstring \
  && docker-php-ext-install xml \
  && docker-php-ext-install soap \
  && docker-php-ext-install zip \
  && docker-php-ext-install bcmath

RUN pecl install imagick
RUN docker-php-ext-enable imagick

# Remove the memory limit for the CLI only.
RUN echo 'memory_limit = -1' > /usr/local/etc/php/php-cli.ini

# Remove the vanilla Drupal project that comes with this image.
RUN rm -rf ..?* .[!.]* *

# Change docroot since we use Composer Drupal project.
RUN sed -ri -e 's!/var/www/html!/var/www/html/web!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www!/var/www/html/web!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install composer.
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'baf1608c33254d00611ac1705c1d9958c817a1a33bce370c0595974b342601bd80b92a3f46067da89e3b06bff421f182') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Put a turbo on composer.
RUN composer global require hirak/prestissimo

# Install Robo CI.
RUN wget https://robo.li/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# Install Dockerize.
ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Install DrupalExtension and Behat
RUN sudo mkdir /opt/drupalextension
RUN sudo chown -R 1000:1000 /opt/drupalextension
COPY drupalextension-composer.json /opt/drupalextension/composer.json
RUN cd /opt/drupalextension && composer install
RUN sudo ln -s /opt/drupalextension/bin/behat /usr/local/bin/behat
