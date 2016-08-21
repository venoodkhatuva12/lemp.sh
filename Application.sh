#!/bin/bash
#Script made for Application installtion
#Author: Vinod.N K
#Usage: Nginx, Java, PhP, OpenSSL, Gcc, for portal installation
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether root user is running the script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Update yum repos.and install development tools
echo "Starting installation of Portal..."
sudo yum update -y
sudo yum groupinstall "Development Tools" -y
sudo yum install screen -y

# Installing needed dependencies and setting ulimit
echo "Installing  needed dependencies for Portal..."
sudo yum install  gcc openssl openssl-devel pcre-devel git unzip wget -y
sudo sed -i '61 i *	soft	nofile	99999' /etc/security/limits.conf
sudo sed -i '62 i *	hard	nofile	99999' /etc/security/limits.conf
sudo sed -i '63 i *	soft	noproc	20000' /etc/security/limits.conf
sudo sed -i '64 i *	hard	noproc	20000' /etc/security/limits.conf
sudo sysctl -w fs.file-max=6816768
sudo sysctl -p

# Remi-Repo for mysql and php
echo "Installing the Remi Repo..."
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm && rpm -Uvh epel-release-latest-6.noarch.rpm
sudo sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/remi.repo
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
# Yum update with new repo
sudo yum update -y
echo "Installing mysql with database...."


# Install MySQL v5
echo "Installing MySQL..."
sudo yum install -y mysql mysql-server
echo "Configuring MySQL data-dir..."
sudo sed -i /datadir/d /etc/my.cnf
sudo sed -i '4 i datadir=/var/lib/mysql' /etc/my.cnf
sudo /etc/init.d/mysqld restart
# password for root user of mysql
read -p "Please Enter the Password for New User root : " pass
sudo /usr/bin/mysqladmin -u root password "$pass"

sleep 2
#ask user about username
read -p "Please enter the username you wish to create : " username
#ask user about allowed hostname
read -p "Please Enter Host To Allow Access Eg: %,ip or hostname : " host
#ask user about password
read -p "Please Enter the Password for New User ($username) : " password

#mysql query that will create new user, grant privileges on database with entered password
mysql -uroot -p"$pass" -e "GRANT ALL PRIVILEGES ON dbname.* TO '$username'@'$host' IDENTIFIED BY '$password'"

echo "Installed MySQL & update new user completed..."

# Installing Java7
cd /apps/
echo "Downloading & Installing  Java7..."
wget https://s3-us-west-2.amazonaws.com/moofwd-softwares/java7.zip
sudo unzip java7.zip
sudo alternatives --install /usr/bin/java java /apps/java7/bin/java 1
sudo alternatives --config java
sudo alternatives --install /usr/bin/jar jar /apps/java7/bin/jar 1
sudo alternatives --install /usr/bin/javac javac /apps/java7/bin/javac 1
sudo alternatives --set jar /apps/java7/bin/jar
sudo alternatives --set javac /apps/java7/bin/javac
sudo /apps/java7/bin/java -version
sudo java –version
echo "export JAVA_HOME=/apps/java7/bin/java" > /etc/profile.d/java_path.sh
chmod 755 /etc/profile.d/java_path.sh

# Install Nginx v1.9
cd /apps/
echo "Installing Nginx from source..."
wget http://nginx.org/download/nginx-1.8.1.tar.gz
sudo tar -zxvf nginx-1.8.1.tar.gz
mv nginx-1.8.1 nginx
cd nginx
sudo mkdir /apps/nginx/logs/
sudo /bin/bash configure --sbin-path=/apps/nginx/sbin/nginx --conf-path=/apps/nginx/conf/nginx.conf --error-log-path=/apps/nginx/logs/error.log --http-log-path=/apps/nginx/logs/access.log --with-http_ssl_module --http-client-body-temp-path=/apps/nginx/body
sudo make
sudo make install

# configuring Nginx with help of sed
echo "Configuring Nginx Conf..."
sudo sed -i "s/mime.types/apps/nginx/conf/g" /apps/nginx/conf/nginx.conf
sudo sed -i "5 i error_log   /apps/nginx/logs/error.log;" /apps/nginx/conf/nginx.conf
sudo sed -i "26 i access_log   /apps/nginx/logs/access.log;" /apps/nginx/conf/nginx.conf

#Cleaning /apps path
sudo rm -rf /apps/nginx-1.8.1.tar.gz
sudo rm -rf /apps/java7.zip

##Now lets install Our Portal...
echo "Installing Portal & Configuration..."
sudo wget https://weblog.com/application.bin
sudo chmod 755 application.bin