## jefferyb/nextcloud

## Supported tags
-	[`latest` (*Dockerfile*)](https://github.com/jefferyb/docker-nextcloud/blob/master/Dockerfile)

## Features
- HTTPS support.
- Automatically configure with your own settings (using command line and the browser)
- Data and config persistence.

## Environment variables
- **WEB_INSTALL** : Install using the web or using the environment variables (When set to *false*, you need, at least, to set **DATABASE_ROOT_PASSWORD**, which should be the same as **MYSQL_ROOT_PASSWORD**) *(default: true)*
- **DATABASE** :  Supported database type *(default: mysql)*
- **DATABASE_NAME** : Name of the database *(default: nextcloud)*
- **DATABASE_HOST** : Hostname of the database (alias name used to link containers) *(default: mysql)*
- **DATABASE_USER** : User name to connect to the database *(default: root)*
- **DATABASE_ROOT_PASSWORD** : Password of the database user *(default: Chang3m3t0an0th3r)*
- **DATABASE_TABLE_PREFIX** : Prefix for all tables *(default: oc_)*
- **ADMIN_USER** : User name of the admin account *(default: admin)*
- **ADMIN_PASS** : Password of the admin account *(default: password)*
- **NEXTCLOUD_HOME** : Path to nextcloud directory *(default: /var/www/html)*
- **NEXTCLOUD_DATA** : Path to data directory *(default: $NEXTCLOUD_HOME/data)*
- **EXTERNAL_URL** : nextcloud hostname/url to add to your trusted domains list that users can log into *(default: "")*
- **ENABLE_SSL** : Enable SSL/HTTPS (You need to set **EXTERNAL_URL** too) *(default: false)*
- **MEMCACHE** :  false

## Port
- **80**.
- **443**.

## Volumes
- **$NEXTCLOUD_HOME/data** : Nextcloud data.
- **$NEXTCLOUD_HOME/config** : config.php location.

## Database (external container)
You have to use an **external** database container. You can use [**MySQL Server**](https://hub.docker.com/r/mysql/mysql-server/) or [**MariaDB**](https://hub.docker.com/_/mariadb/), and link it to the nextcloud container.

## Setup
In this example, it will setup owncloud with HTTPS enabled (using letsencrypt), that you can access at https://nextcloud.example.com.

```console
docker run -d \
  --name nextcloud-database \
  -v /opt/nextcloud/nextcloud-mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=Chang3m3t0an0th3r \
  mysql/mysql-server

docker run -d \
  --name nextcloud-server \
  --link nextcloud-database:mysql \
  -e DATABASE_ROOT_PASSWORD=Chang3m3t0an0th3r \
  -e EXTERNAL_URL=nextcloud.example.com \
  -e ENABLE_SSL=true \
  -v /opt/nextcloud/nextcloud-data/data:/var/www/html/data \
  -v /opt/nextcloud/nextcloud-data/config:/var/www/html/config \
  -v /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/nextcloud.example.com/cert.pem:/etc/ssl/certs/ssl-cert-snakeoil.pem:ro \
  -v /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/nextcloud.example.com/privkey.pem:/etc/ssl/private/ssl-cert-snakeoil.key:ro \
  -p 80:80 \
  -p 443:443 \
  jefferyb/nextcloud

```

The default username & password login will be *admin* and *password*, unless if you set *ADMIN_USER* and *ADMIN_PASS*

**Using docker-compose file**

    # To run it, do:
    #   $ docker-compose pull && docker-compose up -d
    #
    # To upgrade, do:
    #   $ docker-compose pull && docker-compose stop && docker-compose rm -f && docker-compose up -d
    #
    # To check the logs, do:
    #   $ docker-compose logs -f
    #

    version: '2'

    services:
      nextcloud:
        image: jefferyb/nextcloud
        restart: always
        container_name: nextcloud-server
        links:
          - nextcloud-database:mysql
        ports:
          - 80:80
          - 443:443
        volumes:
          - /etc/localtime:/etc/localtime:ro
          - /opt/nextcloud/nextcloud-data/data:/var/www/html/data
          - /opt/nextcloud/nextcloud-data/config:/var/www/html/config
          # ENABLE_SSL = true --- certs location
          - /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/nextcloud.example.com/cert.pem:/etc/ssl/certs/ssl-cert-snakeoil.pem:ro
          - /opt/letsencrypt/letsencrypt-data/etc/letsencrypt/live/nextcloud.example.com/privkey.pem:/etc/ssl/private/ssl-cert-snakeoil.key:ro
        environment:
          - "TZ=America/Chicago"
          - "DATABASE_ROOT_PASSWORD=Chang3m3t0an0th3r"
          - "EXTERNAL_URL=nextcloud.example.com"
          - "ENABLE_SSL=true"

      nextcloud-database:
        image: mysql/mysql-server
        container_name: nextcloud-database
        restart: always
        volumes:
          - /opt/nextcloud/nextcloud-mysql-data:/var/lib/mysql
        environment:
          - "MYSQL_ROOT_PASSWORD=Chang3m3t0an0th3r"
          - "TZ=America/Chicago"
