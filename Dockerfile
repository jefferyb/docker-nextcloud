FROM php:7-apache
MAINTAINER Jeffery Bagirimvano <jeffery.rukundo@gmail.com>

# Using Installing Nextcloud From the Command Line
# https://docs.nextcloud.com/server/9/admin_manual/installation/command_line_installation.html

# nextcloud directory
ENV DATABASE mysql
ENV DATABASE_NAME nextcloud
ENV DATABASE_HOST mysql
ENV DATABASE_USER root
ENV DATABASE_ROOT_PASSWORD Chang3m3t0an0th3r
ENV DATABASE_TABLE_PREFIX oc_
ENV ADMIN_USER admin
ENV ADMIN_PASS password
ENV NEXTCLOUD_HOME /var/www/html
ENV NEXTCLOUD_DATA $NEXTCLOUD_HOME/data
ENV EXTERNAL_URL=""
ENV ENABLE_SSL false

RUN \
  apt-get update && \
  apt-get install -y \
    netcat \
    sudo \
    curl \
    w3m \
    unzip \
    libpng12-dev \
    libjpeg-dev \
    libbz2-dev \
    libmcrypt-dev \
    libicu-dev \
    && \
  # Install some more modules
  docker-php-ext-install zip gd pdo_mysql exif bz2 opcache pcntl mcrypt intl && \
  # Get nextcloud version
  NEXTCLOUD_VERSION=$(w3m https://nextcloud.com/install/#instructions-server -dump | grep -m 1 "Latest stable version" | sed 's/Latest stable version: //') && \
  # get the files
  mkdir /root/setup && \
  cd /root/setup && \
  curl -O https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip && \
  curl -O https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip.md5 && \
  # Verify the MD5
  md5sum -c nextcloud-${NEXTCLOUD_VERSION}.zip.md5 < nextcloud-${NEXTCLOUD_VERSION}.zip && \
  curl -O https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip.asc && \
  curl -O https://nextcloud.com/nextcloud.asc && \
  gpg --import nextcloud.asc && \
  gpg --verify nextcloud-${NEXTCLOUD_VERSION}.zip.asc nextcloud-${NEXTCLOUD_VERSION}.zip && \
  # Setup
  unzip nextcloud-${NEXTCLOUD_VERSION}.zip && \
  rm -fr $NEXTCLOUD_HOME && \
  cp -r nextcloud $NEXTCLOUD_HOME && \
  chown -R www-data:www-data $NEXTCLOUD_HOME && \
  a2enmod rewrite && \
  a2enmod headers && \
  cd && rm -fr /root/setup && \

# Setting Strong Directory Permissions
echo "#!/bin/bash \n\
ncpath='/var/www/html' \n\
htuser='www-data' \n\
htgroup='www-data' \n\
rootuser='root' \n\
 \n\
printf \"Creating possible missing Directories\n\" \n\
mkdir -p \$ncpath/data \n\
mkdir -p \$ncpath/assets \n\
mkdir -p \$ncpath/updater \n\
 \n\
printf \"chmod Files and Directories\n\" \n\
find \${ncpath} -type f -print0 | xargs -0 chmod 0640 \n\
find \${ncpath} -type d -print0 | xargs -0 chmod 0750 \n\
 \n\
printf \"chown Directories\n\" \n\
chown -R \${rootuser}:\${htgroup} \${ncpath} \n\
chown -R \${htuser}:\${htgroup} \${ncpath}/apps/ \n\
chown -R \${htuser}:\${htgroup} \${ncpath}/assets/ \n\
chown -R \${htuser}:\${htgroup} \${ncpath}/config/ \n\
chown -R \${htuser}:\${htgroup} \${ncpath}/data/ \n\
chown -R \${htuser}:\${htgroup} \${ncpath}/themes/ \n\
chown -R \${htuser}:\${htgroup} \${ncpath}/updater/ \n\
 \n\
chmod +x \${ncpath}/occ \n\
 \n\
printf \"chmod/chown .htaccess\n\" \n\
if [ -f \${ncpath}/.htaccess ] \n\
 then \n\
  chmod 0644 \${ncpath}/.htaccess \n\
  chown \${rootuser}:\${htgroup} \${ncpath}/.htaccess \n\
fi \n\
if [ -f \${ncpath}/data/.htaccess ] \n\
 then \n\
  chmod 0644 \${ncpath}/data/.htaccess \n\
  chown \${rootuser}:\${htgroup} \${ncpath}/data/.htaccess \n\
fi \n\
" > /usr/local/bin/nextcloud_permissions && \
chmod +x /usr/local/bin/nextcloud_permissions

EXPOSE 80 443

VOLUME ${NEXTCLOUD_DATA} $NEXTCLOUD_HOME/config

CMD \
  nextcloud_permissions && \
  service apache2 restart && \
  while ! nc -z "$DATABASE_HOST" 3306; do sleep 3; done && \
  if [ ! -f "$NEXTCLOUD_HOME/config/config.php" ] ; then cd "$NEXTCLOUD_HOME" && sudo -u www-data php occ  maintenance:install \
    --database "${DATABASE}" \
    --database-name "${DATABASE_NAME}" \
    --database-host "${DATABASE_HOST}" \
    --database-user "${DATABASE_USER}" \
    --database-pass "${DATABASE_ROOT_PASSWORD}" \
    --database-table-prefix "${DATABASE_TABLE_PREFIX}" \
    --admin-user "${ADMIN_USER}" \
    --admin-pass "${ADMIN_PASS}" \
    --data-dir "${NEXTCLOUD_DATA}"; fi && \
  if [ $EXTERNAL_URL ] ; then grep -q -F "=> '${EXTERNAL_URL}'" $NEXTCLOUD_HOME/config/config.php || sed -i "/0 => 'localhost'/a \    1 => '${EXTERNAL_URL}'" $NEXTCLOUD_HOME/config/config.php; fi && \
  if [ $ENABLE_SSL = true ] ; then \
    echo "<VirtualHost *:80> \n\
   ServerName ${EXTERNAL_URL} \n\
   Redirect permanent / https://${EXTERNAL_URL}/ \n\
</VirtualHost>" > /etc/apache2/sites-enabled/redirect-to-ssl.conf && \
    echo "<VirtualHost *:443> \n\
  ServerName ${EXTERNAL_URL} \n\
    <IfModule mod_headers.c> \n\
      Header always set Strict-Transport-Security \"max-age=15768000; includeSubDomains; preload\" \n\
    </IfModule> \n\
</VirtualHost>" > /etc/apache2/sites-enabled/enable-sts.conf && \
    a2enmod ssl && a2ensite default-ssl && service apache2 reload; fi && \
  tail -f $NEXTCLOUD_HOME/data/owncloud.log -f /var/log/apache2/access.log -f /var/log/apache2/error.log -f /var/log/apache2/other_vhosts_access.log
