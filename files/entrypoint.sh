#!/bin/bash

if [ ! -f /var/www/spotweb/ownsettings.php ]; then
  touch /var/www/spotweb/ownsettings.php 
fi

if [ ! -f /var/www/spotweb/dbsettings.inc.php ]; then
  touch /var/www/spotweb/dbsettings.inc.php 
fi

#touch /config/ownsettings.php && chown www-data:www-data /config/ownsettings.php
#rm -f /var/www/spotweb/ownsettings.php
#ln -s /config/ownsettings.php /var/www/spotweb/ownsettings.php

chown -R www-data:www-data /var/www/spotweb

if [[ -n "$SPOTWEB_DB_TYPE" && -n "$SPOTWEB_DB_HOST" && -n "$SPOTWEB_DB_NAME" && -n "$SPOTWEB_DB_USER" && -n "$SPOTWEB_DB_PASS" ]]; then
    echo "Creating database configuration"
    echo "<?php" > /var/www/spotweb/dbsettings.inc.php
    echo "\$dbsettings['engine'] = '$SPOTWEB_DB_TYPE';" >> /var/www/spotweb/dbsettings.inc.php
    echo "\$dbsettings['host'] = '$SPOTWEB_DB_HOST';" >> /var/www/spotweb/dbsettings.inc.php
    echo "\$dbsettings['dbname'] = '$SPOTWEB_DB_NAME';"  >> /var/www/spotweb/dbsettings.inc.php
    echo "\$dbsettings['user'] = '$SPOTWEB_DB_USER';" >> /var/www/spotweb/dbsettings.inc.php
    echo "\$dbsettings['pass'] = '$SPOTWEB_DB_PASS';"  >> /var/www/spotweb/dbsettings.inc.php
fi

#if [ -f /config/dbsettings.inc.php ]; then
#	chown www-data:www-data /config/dbsettings.inc.php
#	rm /var/www/spotweb/dbsettings.inc.php
#	ln -s /config/dbsettings.inc.php /var/www/spotweb/dbsettings.inc.php
#else
#	echo -e "\nWARNING: You have no database configuration file, either create /config/dbsettings.inc.php or restart this container with the correct environment variables to auto generate the config.\n"
#fi

TZ=${TZ:-"Europe/Amsterdam"}
echo -e "Setting (PHP) time zone to ${TZ}\n"
sed -i "s#^;date.timezone =.*#date.timezone = ${TZ}#g"  /etc/php/7.*/*/php.ini

# Run database update
/usr/bin/php /var/www/spotweb/bin/upgrade-db.php

# Clean up apache pid (if there is one)
rm -rf /run/apache2/apache2.pid

# Enabling PHP mod rewrite
#/usr/sbin/a2enmod rewrite && /etc/init.d/apache2 restart

dockerize /bin/bash -c "cron && (crontab -l ; echo '* * * * * /usr/bin/php /var/www/spotweb/retrieve.php > /var/log/spotweb-retrieve.log') | crontab - && source /etc/apache2/envvars && rm -f /var/run/apache2/apache2.pid && apachectl -k restart -DFOREGROUND | true"

#tail -F /var/log/spotweb-retrieve.log
