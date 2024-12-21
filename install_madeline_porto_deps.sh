#!/bin/bash

# Функция для вывода сообщений
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Функция для автоматического ответа на запросы apt
apt_noninteractive() {
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
}

log_message "Начало выполнения скрипта для установки PHP 8.3 для Madeline Proto и Fast Panel"

# Обновление списка пакетов
log_message "Обновление списка пакетов"
apt_noninteractive update

# Проверка и добавление репозитория PHP
if ! grep -q "^deb .*/ondrej/php" /etc/apt/sources.list.d/*; then
    log_message "Добавление репозитория PHP"
    add-apt-repository ppa:ondrej/php -y
fi
apt_noninteractive update

# Установка PHP 8.3 и необходимых расширений
log_message "Установка PHP 8.3 и необходимых расширений"
apt_noninteractive install php8.3 php8.3-fpm php8.3-cli php8.3-common php8.3-curl php8.3-mbstring php8.3-mysql php8.3-xml php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl php8.3-readline php8.3-ldap php8.3-tidy php8.3-soap php8.3-igbinary php8.3-memcached php8.3-redis php8.3-gmp

# Установка ioncube loader для PHP 8.3
log_message "Установка ioncube loader для PHP 8.3"
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
PHP_EXT_DIR="/usr/lib/php/$(php-config8.3 --extension-dir)"
cp ioncube/ioncube_loader_lin_8.3.so ${PHP_EXT_DIR}
mkdir -p /etc/php/8.3/{mods-available,cli/conf.d,fpm/conf.d}
echo "zend_extension=ioncube_loader_lin_8.3.so" > /etc/php/8.3/mods-available/ioncube.ini
ln -sf /etc/php/8.3/mods-available/ioncube.ini /etc/php/8.3/cli/conf.d/00-ioncube.ini
ln -sf /etc/php/8.3/mods-available/ioncube.ini /etc/php/8.3/fpm/conf.d/00-ioncube.ini

# Установка ffmpeg
log_message "Установка ffmpeg"
apt_noninteractive install ffmpeg

# Очистка временных файлов
log_message "Очистка временных файлов"
rm -f ioncube_loaders_lin_x86-64.tar.gz
rm -rf ioncube

# Настройка PHP 8.3 как версии по умолчанию
log_message "Настройка PHP 8.3 как версии по умолчанию"
update-alternatives --set php /usr/bin/php8.3
update-alternatives --set phar /usr/bin/phar8.3
update-alternatives --set phar.phar /usr/bin/phar.phar8.3

# Обновление конфигураций Fast Panel
log_message "Обновление конфигураций Fast Panel"
if [ -f "/etc/nginx/fastpanel2/php_versions.conf" ]; then
    if ! grep -q "php8.3 = /run/php/php8.3-fpm.sock;" /etc/nginx/fastpanel2/php_versions.conf; then
        echo "php8.3 = /run/php/php8.3-fpm.sock;" >> /etc/nginx/fastpanel2/php_versions.conf
    fi
else
    log_message "Файл php_versions.conf не найден. Пропуск обновления Fast Panel."
fi

# Перезапуск PHP-FPM и Nginx
log_message "Перезапуск PHP-FPM и Nginx"
if systemctl is-active --quiet php8.3-fpm; then
    systemctl restart php8.3-fpm
else
    log_message "Сервис php8.3-fpm не найден. Пропуск перезапуска."
fi

if systemctl is-active --quiet nginx; then
    systemctl restart nginx
else
    log_message "Сервис nginx не найден. Пропуск перезапуска."
fi

# Проверка установленной версии PHP
INSTALLED_PHP_VERSION=$(php -r "echo PHP_VERSION;")
log_message "Установленная версия PHP CLI: $INSTALLED_PHP_VERSION"
FPM_VERSION=$(php-fpm8.3 -v | head -n 1 | cut -d ' ' -f 2)
log_message "Установленная версия PHP-FPM: $FPM_VERSION"

log_message "Установка завершена. PHP версии 8.3 установлен с необходимыми расширениями, ioncube loader и ffmpeg. PHP 8.3 настроен как версия по умолчанию для CLI и FPM."
