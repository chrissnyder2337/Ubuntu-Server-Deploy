#!/bin/bash

echo
echo
echo "Install Solr v3.6.2 Ubuntu Server Deployment Script"
echo


# Check that this distribution is Ubuntu
if uname -v | grep -qvi ubuntu
then
	echo "This script is meant for Ubuntu distributions only."
	exit 1
fi


# Check if root
if [[ $UID != 0 ]]
then
	echo "You are not root. This script must be run with root permissions."
	exit 1
fi


# Check Internet Access
if ! ping -c 2 8.8.8.8 > /dev/null
then
	echo "You do not have internet access. This script requires the internet to install packages."
	exit 1
fi


# Filepath
root=$(dirname $(readlink -f $0))


# Confirmation
echo
echo -n "Would you like to install Solr v3.6.2? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "Solr v3.6.2 installation cancelled."
	exit 1
fi


echo
echo "Installing Solr v3.6.2 ..."


# Install Java
sudo apt-get -y install openjdk-7-jdk


# Download latest version or the one you want:
wget -q -O ~/apache-solr-3.6.2.tgz http://archive.apache.org/dist/lucene/solr/3.6.2/apache-solr-3.6.2.tgz
tar -zxf ~/apache-solr-3.6.2.tgz


# Copy the solr executable and sample conf to the solr home dir
sudo cp -r ~/apache-solr-3.6.2/example /usr/local/share/solr


# For Multi-Core
sudo mv /usr/local/share/solr/solr/ /usr/local/share/solr/singlecore
sudo cp -r /usr/local/share/solr/multicore/ /usr/local/share/solr/solr
sudo cp -r /usr/local/share/solr/singlecore/conf /usr/local/share/solr/solr/core0
sudo cp -r /usr/local/share/solr/singlecore/conf /usr/local/share/solr/solr/core1


# Setup example and template cores
sudo mv /usr/local/share/solr/solr/core0 /usr/local/share/solr/solr/tpl-base
sudo mv /usr/local/share/solr/solr/core1 /usr/local/share/solr/solr/example-com
sudo sed -i '/core0/d' /usr/local/share/solr/solr/solr.xml
sudo sed -i 's/core1/example-com/g' /usr/local/share/solr/solr/solr.xml


# Create Drupal 7 Search API Solr template core
SEARCH_API_SOLR_CURRENT=$(wget -O - http://updates.drupal.org/release-history/search_api_solr/7.x 2> /dev/null | sed -e '/<download_link>.*<\/download_link>/!d' -e 's/.*<download_link>\(.*\)<\/download_link>/\1/g' | head -n 1)
wget -q -O ~/${SEARCH_API_SOLR_CURRENT##*/} "$SEARCH_API_SOLR_CURRENT"
tar -zxf ~/${SEARCH_API_SOLR_CURRENT##*/}
sudo cp -a /usr/local/share/solr/solr/tpl-base /usr/local/share/solr/solr/tpl-drupal-search-api-7
sudo cp -a ~/search_api_solr/solr-conf/3.x/* /usr/local/share/solr/solr/tpl-drupal-search-api-7/conf/


# Copy deploy-core script
sudo cp $root/solr/deploy-core.sh /usr/local/share/solr/solr/


# Create the solr user
sudo useradd --system --home-dir /usr/local/share/solr --shell /bin/false solr
sudo chown -R solr:solr /usr/local/share/solr


# Create init.d script:
sudo cp $root/solr/init.d/solr /etc/init.d/solr
sudo chmod +x /etc/init.d/solr


# Debian: update rc
sudo update-rc.d solr defaults


# Start Solr
sudo service solr start


# Add UFW rules
if [[ -x $(which ufw) ]]
then
	echo
	echo -n "Would you like to allow access to Solr remotely? [y/N] "
	read confirm
	echo
	
	if [[ "$confirm" =~ ^[yY]([eE][sS])?$ ]]
	then
		echo
		echo "Allowing solr (8983) in UFW ..."
		sudo ufw allow 8983
	fi
fi


echo
echo "Solr v3.6.2 installation complete."
echo
