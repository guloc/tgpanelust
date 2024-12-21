#!/bin/bash

# Обновление списка пакетов
apt update

# Добавление репозитория PHP
add-apt-repository ppa:ondrej/php -y
apt update

# Установка PHP 8.2 и необходимых расширений
apt install -y php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-mbstring php8.2-mysql php8.2-xml php8.2-zip php8.2-gd php8.2-bcmath php8.2-intl php8.2-readline php8.2-ldap php8.2-tidy php8.2-soap php8.2-igbinary php8.2-memcached php8.2-redis

# Установка ioncube loader
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_EXT_DIR=$(php -i | grep extension_dir | awk '{print $3}')
cp ioncube/ioncube_loader_lin_${PHP_VERSION}.so ${PHP_EXT_DIR}
echo "zend_extension=ioncube_loader_lin_${PHP_VERSION}.so" > /etc/php/${PHP_VERSION}/mods-available/ioncube.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/ioncube.ini /etc/php/${PHP_VERSION}/cli/conf.d/00-ioncube.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/ioncube.ini /etc/php/${PHP_VERSION}/fpm/conf.d/00-ioncube.ini

# Установка ffmpeg
apt install -y ffmpeg

# Очистка
rm -rf ioncube*

# Перезапуск PHP-FPM
systemctl restart php${PHP_VERSION}-fpm

echo "Установка завершена. PHP версии ${PHP_VERSION} установлен с необходимыми расширениями, ioncube loader и ffmpeg."
