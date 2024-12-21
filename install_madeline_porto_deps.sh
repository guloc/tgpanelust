#!/bin/bash

# Функция для автоматического ответа на запросы apt
apt_noninteractive() {
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
}

# Обновление списка пакетов
apt_noninteractive update

# Добавление репозитория PHP
add-apt-repository ppa:ondrej/php -y
apt_noninteractive update

# Удаление старых версий PHP
apt_noninteractive remove php7.4 php7.4-* php8.0 php8.0-* php8.1 php8.1-*
apt_noninteractive autoremove

# Установка PHP 8.3 и необходимых расширений
apt_noninteractive install php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-mbstring php8.3-mysql php8.3-xml php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl php8.3-readline php8.3-ldap php8.3-tidy php8.3-soap php8.3-igbinary php8.3-memcached php8.3-redis php8.3-gmp

# Установка ioncube loader для PHP 8.3
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
PHP_VERSION="8.3"
PHP_EXT_DIR=$(php -i | grep extension_dir | awk '{print $3}')
cp ioncube/ioncube_loader_lin_${PHP_VERSION}.so ${PHP_EXT_DIR}
echo "zend_extension=ioncube_loader_lin_${PHP_VERSION}.so" > /etc/php/${PHP_VERSION}/mods-available/ioncube.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/ioncube.ini /etc/php/${PHP_VERSION}/cli/conf.d/00-ioncube.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/ioncube.ini /etc/php/${PHP_VERSION}/fpm/conf.d/00-ioncube.ini

# Установка ffmpeg
apt install -y ffmpeg

# Очистка
rm -rf ioncube*

# Настройка Apache для использования PHP 8.3 по умолчанию
a2dismod php7.4 php8.0 php8.1
a2enmod php8.3

# Перезапуск Apache и PHP-FPM
systemctl restart apache2
systemctl restart php8.3-fpm

# Удаление конфигураций старых версий PHP из Fast Panel
rm -f /etc/nginx/fastpanel2/php_versions/php7.4.conf
rm -f /etc/nginx/fastpanel2/php_versions/php8.0.conf
rm -f /etc/nginx/fastpanel2/php_versions/php8.1.conf

echo "Установка завершена. PHP версии 8.3 установлен с необходимыми расширениями, ioncube loader и ffmpeg. Старые версии PHP удалены."
