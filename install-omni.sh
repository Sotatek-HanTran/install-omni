#!/bin/bash
#Outside Requirements: Existing Obelisk Server
#Instructions are for Ubuntu 13.04 and newer

#get the current directory

set -e
echo
echo "Omni wallet Installation Script"
echo
if [ "$#" = "2" ]; then
    if [[ "$1" = "-os" ]]; then
        #Absolute path
        SERVER=$2
        PREFIG=CLE
    else
    	HELP=1
    fi
fi

if [ "$1" = "--help" ] || [ $HELP ]; then
     echo " [+] Install script help:"
     echo " --> To execute this script type:"
     echo " <sudo bash install-omni.sh>"
     echo " --> To execute this script and install with a specific obelisk server"
     echo " <bash install-omni.sh -os server-details:port>"
     echo " This script will install Omniwallet, SX and the required prerequisites"
     echo " The SX install script will install libbitcoin, libwallet, obelisk and sx tools."
     echo " The standard path for the installation is /usr/local/"
     echo " The stardard path for the conf files is /etc."
     echo
     exit
fi

if [ `id -u` = "0" ]; then
    SRC=$PWD
else
    echo
    echo "[+] ERROR: This script must be run as root." 1>&2
    echo
    echo "<sudo bash install-omni.sh>"
    echo
    exit
fi


while [ -z "$PREFIG" ]; do
	echo "Do you have an obelisk server and wish to enter its details now? [y/n]"
	echo "Need an obelisk server? Try https://wiki.unsystem.net/index.php/Libbitcoin/Servers"
	read PREFIG
done

case $PREFIG in
	y* | Y* )
		ACTIVE=1
		CONFIRM=no
	;;

	CLE)
		ACTIVE=1
		CONFIRM=P
	;;

	*)
		active=0
	;;
esac

while [ $ACTIVE -ne 0 ]; do
	case $CONFIRM in

	y* | Y* )
		echo "Writing Details to ~/.sx.cfg"
		echo "You can update/change this file as needed later"
		echo "service = \""$SERVER"\"" > ~/.sx.cfg
		ACTIVE=0
	;;

	n* | N* )
		SERVER=
		while [ -z "$SERVER" ]; do
			echo "Enter Obelisk server connection details ex: tcp://162.243.29.201:9091"
			echo "If you don't have one yet enter anything, you can update/change this later"
			read SERVER
		done
		CONFIRM=P
	;;

	P)
		echo "You entered: "$SERVER
		echo "Is this correct? [y/n]"
		read CONFIRM
	;;

	*)
		CONFIRM=no
	;;
	esac
done

if [ ! -f ~/.ssh/id_rsa.pub ]; then
	SSHGEN=
	while [ -z "$SSHGEN" ]; do
		echo "Public ssh key not found in ~/.ssh/id_rsa"
		echo "Do you wish to generate one now?[y/n]"
		read SSHGEN
	done
	case $SSHGEN in

        y* | Y* )
		echo "Generating ~/.ssh/id_rsa:"
		echo n | ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
        ;;
	*)
                echo "Slipping new ssh key generation"
        ;;
        esac
fi

echo "#############################"
echo "Adding your SSH key to Github"
echo "Before Continuing please follow Steps 3 and 4 of the Github SSH key guide"
echo "https://help.github.com/articles/generating-ssh-keys"
echo ""
echo "Your SSH key from ~/.ssh/id_rsa.pub is:"
echo "----------------------------------------------------------------------------------"
cat ~/.ssh/id_rsa.pub
echo "----------------------------------------------------------------------------------"
echo ""
echo "#############################"

VALID=1
while [ $VALID -ne 0 ]; do
        echo "When You have updated Github please enter exactly:"
	echo "		SSH Key Updated"
        read SSHREP
	if [[ $SSHREP == "SSH Key Updated" ]]; then
		VALID=0
	fi
done

exit

# Make sure we're getting the newest packages.
sudo apt-get update

# If this is a local image, you may need sshd set up.
sudo apt-get -y install openssh-server openssh-client
 
# Install some system stuff
sudo apt-get -y install daemontools

# Get your tools together
sudo apt-get -y install vim git curl libssl-dev make

# Stuff so you can compile
sudo apt-get -y install gcc g++ lib32z1-dev pkg-config ant
sudo apt-get -y install ruby rubygems
sudo gem install sass
sudo apt-get -y install python-dev python-setuptools

# Get NPM and forever, install globally
sudo apt-get -y install npm
sudo npm install -g forever

# Make it so that grunt can be used
sudo npm install -g grunt-cli

# Other node-based compilation tools
sudo npm install -g less
sudo npm install -g jshint

#Make sure we have python and build tools
sudo apt-get update
sudo apt-get -y install python-software-properties python

#Special node.js installation from chris-lea repository
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get -y install nodejs

#Get/clone Omniwallet - might be relevant
cd
git clone https://github.com/mastercoin-MSC/omniwallet.git

NAME=`logname`
# May need to clean up some strange permissions from the npm install.
sudo chown -R $NAME:$NAME ~/.npm
sudo chown -R $NAME:$NAME ~/tmp

#install packages:
sudo apt-get -y install python-simplejson python-git python-pip
sudo apt-get -y install build-essential autoconf libtool libboost-all-dev pkg-config libcurl4-openssl-dev libleveldb-dev libzmq-dev libconfig++-dev libncurses5-dev
sudo pip install -r pip.packages

cd $SRC/res
sudo bash install-sx.sh

#Get and setup nginx
sudo apt-get -y install uwsgi uwsgi-plugin-python
sudo -s
nginx=stable # use nginx=development for latest development version
add-apt-repository ppa:nginx/$nginx
apt-get update
apt-get -y install nginx
exit

sed -i "s/cmlacy/$NAME/g" ~/omniwallet/etc/nginx/sites-available/default

#Update nginx conf with omniwallet specifics
sudo cp ~/omniwallet/etc/nginx/sites-available/default /etc/nginx/sites-available

sudo npm install -g uglify-js

#Start the omniwallet dependency setup
# MAKE SURE SSH IS LINKED TO GITHUB 
cd ~/omniwallet
npm install

#Create omniwallet data directory
sudo mkdir /var/lib/omniwallet
sudo chown -R $NAME:$NAME /var/lib/omniwallet

#start the web interface
sudo service nginx start

#create the mastercoin tools data directory
#mkdir -p /var/lib/mastercoin-tools
#tar xzf $SRC/res/bootstrap.tgz -C /var/lib/mastercoin-tools

echo ""
echo ""
echo "Installation complete"
echo "Omniwallet should have been downloaded/installed in "$PWD
echo ""
echo "The webinterface is handled by nginx"
echo "'sudo service nginx [stop/start/restart/status]'"
echo ""
echo "There is a wrapper app which automates the tasks of downloading and parsing Mastercoin Data off the Blockchain"
echo ""
echo "-----Run Commands-------"
echo "start a new screen session with: screen -S omni"
echo "cd "$SRC"/omniwallet"
echo "launch the wrapper:  ./app.sh"
echo "Note: Do NOT launch it with sudo"
echo "You can disconnect from the screen session with '<ctrl-a> d'"
echo "You can reconnect to the screen session with 'screen -r omni'"
echo "----------------------------------"