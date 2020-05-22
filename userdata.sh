#!/bin/bash
#Install apache mysql and php
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd

#Install wordpress
wget https://wordpress.org/latest.tar.gz
sleep 5
tar -xzf latest.tar.gz
sudo systemctl start mariadb
sudo cp wordpress/wp-config-sample.php wordpress/wp-config.php
sudo sed -i 's/database_name_here/wp2/' wordpress/wp-config.php
sudo sed -i 's/username_here/admin/' wordpress/wp-config.php
sudo sed -i 's/password_here/adminadmin/' wordpress/wp-config.php
sudo sed -i 's/localhost/terraform-20200520112823394200000001.cu2vapzameti.us-east-1.rds.amazonaws.com/' wordpress/wp-config.php
sudo mkdir /var/www/html/blog
sudo cp -r wordpress/* /var/www/html/blog/

sudo chown -R apache /var/www
sudo chgrp -R apache /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;

sudo systemctl restart httpd