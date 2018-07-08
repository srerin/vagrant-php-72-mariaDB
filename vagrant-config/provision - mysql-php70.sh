DBPASSWD=localhost
DBUSER=localhost
DBNAME=drupal

# Set MySQL and phpmyadmin root password
echo "--- Setting mysql and phpmyadmin root password ---"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-user string $DBUSER" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" |debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections

# Install extensions
apt-get update >/dev/null
echo "--- Installing apache2 ---"
apt-get -y install apache2 >/dev/null 2>&1

# echo "php version upgrade to 7.2"
# add-apt-repository ppa:ondrej/php  >/dev/null 2>&1
# apt-get update >/dev/null 2>&1

echo "--- Installing packages ---"
apt-get -y install libapache2-mod-php  >/dev/null 2>&1
apt-get -y install php-mbstring php-cli php-mysql mysql-client mysql-server >/dev/null 2>&1
echo "--- Installing PhpMyAdmin ---"
apt-get -y install phpmyadmin 
apt-get -y install php-curl php-mcrypt git php-gd php-intl php-xsl php-zip >/dev/null 2>&1
phpenmod mcrypt >/dev/null 2>&1

echo "--- Installing und setup mysql and phpmyadmin ---"
cp /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
# ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
a2enconf phpmyadmin >/dev/null 2>&1
service apache2 restart >/dev/null 2>&1

echo "--- Updating packages ---"
phpenmod mcrypt
apt-get update >/dev/null 2>&1
apt-get upgrade >/dev/null 2>&1

echo "Configurate of 000-default.conf"
a2enmod rewrite
service apache2 restart >/dev/null 2>&1
cp /1214-drupal/vagrant-config/000-default.conf /etc/apache2/sites-available/000-default.conf

echo "--- Restarting apache2 ---"
service apache2 restart >/dev/null 2>&1



if [ -f /1214-drupal/vagrant-config/PROVISIONED ];
 then
    echo "----- The database exists already! -----"
 else
   echo "----- Creating of new user and database -----"
   mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
   mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"
  # mysql -uroot -p$DBPASSWD $DBNAME < /1214-drupal/vagrant-config/$DBNAME.sql

 fi
echo -e "\n--- We definitly need to see the PHP errors, turning them on ---\n"
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/apache2/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/apache2/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/apache2/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 6M/" /etc/php/7.0/apache2/php.ini

echo "--- Restarting apache2 ---"
service apache2 restart  >/dev/null 2>&1

echo "Link to drupal"	
rm -rf /var/www/html
ln -s /1214-drupal/drupal /var/www/html

if [ ! -f /1214-drupal/vagrant-config/PROVISIONED ];
then
    touch /1214-drupal/vagrant-config/PROVISIONED
fi
echo Install done
