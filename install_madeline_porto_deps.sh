#!/bin/bash

# Функция для вывода сообщений
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для автоматического ответа на запросы apt
apt_noninteractive() {
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
}

log_message "Начало выполнения скрипта для установки PHP 8.3 для Madeline Porto и Fast Panel"

# Обновление списка пакетов
log_message "Обновление списка пакетов"
apt_noninteractive update

# Добавление репозитория PHP
log_message "Добавление репозитория PHP"
add-apt-repository ppa:ondrej/php -y
apt_noninteractive update

# Установка PHP 8.3 и необходимых расширений
log_message "Установка PHP 8.3 и необходимых расширений"
apt_noninteractive install php8.3 php8.3-fpm php8.3-cli php8.3-common php8.3-curl php8.3-mbstring php8.3-mysql php8.3-xml php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl php8.3-readline php8.3-ldap php8.3-tidy php8.3-soap php8.3-igbinary php8.3-memcached php8.3-redis php8.3-gmp

# Установка ioncube loader для PHP 8.3
log_message "Установка ioncube loader для PHP 8.3"
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
PHP_VERSION="8.3"
PHP_EXT_DIR=$(php -i | grep extension_dir | awk '{print $3}')
cp ioncube/ioncube_loader_lin_${PHP_VERSION}.so ${PHP_EXT_DIR}
echo "zend_extension=ioncube_loader_lin_${PHP_VERSION}.so" > /etc/php/${PHP_VERSION}/mods-available/ioncube.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/ioncube.ini /etc/php/${PHP_VERSION}/cli/conf.d/00-ioncube.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/ioncube.ini /etc/php/${PHP_VERSION}/fpm/conf.d/00-ioncube.ini

# Установка ffmpeg
log_message "Установка ffmpeg"
apt_noninteractive install ffmpeg

# Очистка
log_message "Очистка временных файлов"
rm -rf ioncube*

# Настройка PHP 8.3 как версии по умолчанию
log_message "Настройка PHP 8.3 как версии по умолчанию"
update-alternatives --set php /usr/bin/php8.3
update-alternatives --set phar /usr/bin/phar8.3
update-alternatives --set phar.phar /usr/bin/phar.phar8.3

# Обновление конфигураций Fast Panel
log_message "Обновление конфигураций Fast Panel"
if [ -f "/etc/nginx/fastpanel2/php_versions.conf" ]; then
    if ! grep -q "php8.3" /etc/nginx/fastpanel2/php_versions.conf; then
        echo "php8.3 = /run/php/php8.3-fpm.sock;" >> /etc/nginx/fastpanel2/php_versions.conf
    fi
else
    log_message "Файл php_versions.conf не найден. Пропуск обновления Fast Panel."
fi

# Перезапуск PHP-FPM и Nginx
log_message "Перезапуск PHP-FPM и Nginx"
systemctl restart php8.3-fpm
systemctl restart nginx

# Проверка установленной версии PHP
INSTALLED_PHP_VERSION=$(php -r "echo PHP_VERSION;")
log_message "Установленная версия PHP CLI: $INSTALLED_PHP_VERSION"
FPM_VERSION=$(php-fpm8.3 -v | head -n 1 | cut -d ' ' -f 2)
log_message "Установленная версия PHP-FPM: $FPM_VERSION"

# Проверка статуса PHP-FPM
log_message "Проверка статуса PHP-FPM"
systemctl status php8.3-fpm

echo "Установка завершена. PHP версии 8.3 установлен с необходимыми расширениями, ioncube loader и ffmpeg. PHP 8.3 настроен как версия по умолчанию для CLI и FPM."
