#!/bin/bash
#
## Color variables ##
#$YLW="\033[1;33m"
#$CSTOP="\033[0m"
#
#
set -e
## Check for root ##
if [ $UID -ne 0 ]; then
    echo -e "\033[1;33m""This program must be run as root.""\033[0m"
    sleep 2
    exit 0
    fi
## Update sources to jessie ##
echo -e "\033[1;33m""Do you need to update your repos to jessie? (y/n)""\033[0m"
    read install
    if [[ $install = Y || $install = y ]] ; then
        echo -e "\033[1;33m""Updating sources to jessie""\033[0m"
        sleep 1
        echo "deb http://ftp.us.debian.org/debian jessie main non-free contrib" > /etc/apt/sources.list
        echo "deb http://security.debian.org/ jessie/updates main non-free contrib" >> /etc/apt/sources.list
        echo -e "\033[1;33m""[+] Sources updated to jessie.""\033[0m"
        sleep 3
    else
        echo -e "\033[1;33m""[+] Ok, moving on.""\033[0m"
        sleep 1
    fi
# #Upgrade packages install some dependencies ##
echo -e "\033[1;33m""Upgrading installed packages.""\033[0m"
apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
echo -e "\033[1;33m""Installing some dependencies.""\033[0m"
apt-get install nano sudo pwgen haveged -y
echo -e "\033[1;33m""If you're on a shared/virtual server you can't set the time.\nAre you on a shared server (answer y if you don't know)? (y/n)""\033[0m"
    read share
    if [[ $share = Y || $share = y ]]; then
        echo -e "\033[1;33m""Leaving system time settings.""\033[0m"
        sleep 2
    else
        apt-get install ntp ntpdate -y
        service ntp stop
        ntpdate 0.europe.pool.ntp.org
        service ntp start
        echo -e "\033[1;33m""[+] Time set.""\033[0m"
        sleep 3
    fi
## Collecting ext.ip before tor starts for use in the bitcoin.conf ##
sudo wget -q wtfismyip.com/text -O /root/ip
IP=$(sudo cat /root/ip)
## Tor ##
echo -e "\033[1;33m""Do you have tor, tor-arm, and obfsproxy already? (y/n)""\033[0m"
    read tor
    if [[ $tor = N || $tor = n ]]; then
        echo "deb http://deb.torproject.org/torproject.org jessie main" >> /etc/apt/sources.list
        gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89; gpg --export 886DDD89 | apt-key add -
        apt-get update
        apt-get install deb.torproject.org-keyring && apt-get install tor tor-arm obfsproxy -y
        echo -e "\033[1;33m""[+] Tor installed.""\033[0m"
        sleep 3
    else
        echo -e "\033[1;33m""Look at you, ahead of the game.""\033[0m"
        sleep 3
    fi
## Relay or Bridge ##
echo -e "\033[1;33m""Do you want to run a relay or a public/private bridge? (relay/bridge)""\033[0m"
    read which
    if [[ $which = relay ]]; then
        echo -e "\033[1;33m""Setting up for a relay.""\033[0m"
        sleep 3
        service tor stop
        mv /etc/tor/torrc /etc/tor/torrc.bak
        echo -e "ORPort 22443\nDirPort 80\nDNSPort 53\nSocksPort 127.0.0.1:9050\nControlPort 127.0.0.1:9051\nExitPolicy reject *:*\nDisableDebuggerAttachment 0" > /etc/tor/torrc
        echo -e "\033[1;33m""What would you like your relay nickname to be?""\033[0m"
            read nick
        echo -e "\033[1;33m""What is your contact email?""\033[0m"
            read contact
            echo -e -n "Nickname $nick\nContactInfo $contact\n" >> /etc/tor/torrc
            echo -e "#\n#\n" >> /etc/tor/torrc
        echo -e "\033[1;33m""[+] Congratz and thank you!\n[+] You're configured for relaying traffic.\n[+] You're helping the tor network propagate traffic.\n[+]You can see stats about your relay at https://globe.torproject.org\n[+] Starting tor now.""\033[0m"
        service tor start
        sleep 5
    else
        echo -e "\033[1;33m""Public or private bridge? (pub/priv)""\033[0m"
            read pub_priv
            if [[ $pub_priv = pub ]]; then
                service tor stop
                mv /etc/tor/torrc /etc/tor/torrc.bak
                echo -e "ORPort 11443\nExtORPort 22443\nDNSPort 53\nSocksPort 127.0.0.1:9050\nControlPort 127.0.0.1:9051\nExitPolicy reject *:*\nDisableDebuggerAttachment 0\nBridgeRelay 1\nServerTransportPlugin obfs3,scramblesuit exec /usr/bin/obfsproxy managed" > /etc/tor/torrc
                echo -e "\033[1;33m""What would you like your bridge nickname to be?""\033[0m"
                    read nick
                    echo -e -n "Nickname $nick\n" >> /etc/tor/torrc
                    echo -e "#\n#\n" >> /etc/tor/torrc
                echo -e "\033[1;33m""[+] Congratz and thank you!\n[+] You're configured to be a published bridge.\n[+] Now you and others can use your bridge to mask tor traffic.\n[+] You can see stats about your bridge at https://globe.torproject.org\n[+] Starting tor now.""\033[0m"
                sleep 5
                service tor start
            else
                service tor stop
                mv /etc/tor/torrc /etc/tor/torrc.bak
                echo -e "ORPort11443\nExtORPort 22443\nDNSPort 53\nSocksPort 127.0.0.1:9050\nControlPort 127.0.0.1:9051\nExitPolicy reject *:*\nDisableDebuggerAttachment 0\nBridgeRelay 1\nServerTransportPlugin obfs3,scramblesuit exec /usr/bin/obfsproxy managed\nPublishServerDescriptor 0" > /etc/tor/torrc
                echo -e "\033[1;33m""[+] Congratz! You're configured for private bridge.\n[+] You can now use your bridges ip and dir port to mask your tor traffic.\n[+] Starting tor now.""\033[0m"
                service tor start
                sleep 5
            fi
    fi
## Download and build bitcoin from source ##
echo -e "\033[1;33m""Installing dependencies for building bitcoin.""\033[0m"
sleep 3
apt-get install pwgen git automake pkg-config build-essential libtool autotools-dev autoconf libssl-dev libboost-all-dev libdb-dev libdb++-dev -y
mkdir /root/bitcoinsrc && cd /root/bitcoinsrc
echo -e "\033[1;33m""Getting bitcoin code from github""\033[0m"
sleep 2
git clone https://github.com/bitcoin/bitcoin
cd /root/bitcoinsrc/bitcoin
git checkout master #Substitute with whatever version you prefer
echo -e "\033[1;33m""Building bitcoin master branch""\033[0m"
sleep 2
./autogen.sh
./configure --disable-wallet --without-gui --with-cli --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX
make
sudo make install
echo -e "\033[1;33m""What would you like the bitcoin user to be named?""\033[0m"
    read bituser
adduser $bituser
adduser $bituser sudo
mkdir /home/$bituser/.bitcoin
echo -e "\033[1;33m""[+] Bitcoin built and user $bituser added to your system to run bitcoin.""\033[0m"
sleep 3
## Set up tor to host a hidden service ##
echo -e "\033[1;33m""Setting up tor to host a hidden service for bitcoin.""\033[0m"
echo -e "HiddenServiceDir /var/lib/tor/bitcoin-server/\nHiddenServicePort 8333 127.0.0.1:8333\n" >> /etc/tor/torrc
service tor reload
sleep 2
EXT_IP=$(sudo cat /var/lib/tor/bitcoin-server/hostname)
echo -e "\033[1;33m""[+] Tor is set up. Your hidden service address is:""\033[0m"
echo -e "\033[32m""$EXT_IP""\033[0m"
sleep 7
## Configure bitcoin ##
echo -e "\033[1;33m""Now we will configure bitcoin""\033[0m"
sleep 3
RPC_PASS=$(pwgen -n -s 68 1)
RPC_USER=user$(pwgen -B -n -s 10 1)
echo -e "daemon=1\nrpcuser=$RPC_USER\nrpcpassword=$RPC_PASS\nmaxconnections=700\nproxy=127.0.0.1:9050\nexternalip=$EXT_IP\nlisten=1\nbind=127.0.0.1:8333" > /home/$bituser/.bitcoin/bitcoin.conf
echo -e "\033[1;33m""Do you want your node to be accessible to all or only tor users? (all/tor)""\033[0m"
     read tor_all
     if [[ $tor_all = all ]]; then
         echo -e "bind=0.0.0.0:8334\nexternalip=$IP" >> /home/$bituser/.bitcoin/bitcoin.conf
         echo -e "\033[1;33m""[+] Bitcoin is now configured to connect to all users\nas both a hidden service:""\033[0m"
         echo -e "\033[32m""$EXT_IP""\033[0m"
         echo -e "\033[1;33m""and a clearnet ip""\033[0m"
         echo -e "\033[32m""$IP""\033[0m"
         sleep 3
     else
         echo "onlynet=onion" >> /home/$bituser/.bitcoin/bitcoin.conf
         echo -e "\033[1;33m""[+] Bitcoin is now configured to connect with only tor users\nas a hidden service with the url:""\033[0m"
         echo -e "\033[32m""$EXT_IP""\033[0m"
         sleep 3
     fi
chown -R $bituser /home/$bituser/.bitcoin
echo -e "\033[1;33m""Do you want bitcoin to run on startup (y/n)?""\033[0m"
    read startup
    if [[ $startup = Y || $startup = y ]]; then
        echo "sudo -u $user -i bitcoind\nexit 0" > /etc/rc.local
        echo -e "\033[1;33m""[+] Added to /etc/rc.local""\033[0m"
        sleep 3
    else
        echo -e "\033[1;33m""[+] To run bitcoin do:""\033[0m"
        echo -e "\033[32m""sudo -u $bituser -i bitcoind""\033[0m"
        sleep 5
    fi
sudo -u $bituser -i bitcoind
sleep 2
service tor reload
echo -e "\033[1;33m""[+] Bitcoin is now running you can check the log by doing:""\033[0m"
echo -e "\033[32m""tail -f /home/$bituser/.bitcoin/debug-log""\033[0m"
echo -e "\033[1;33m""Or:""\033[0m"
echo -e "\033[32m""sudo -u $bituser -i bitcoin-cli getinfo""\033[0m"
sleep 7
## Rotate log files ##
echo -e "\033[1;33m""Setting up logfiles to prune in a reasonable\nway to save disk space.""\033[0m"
sleep 3
echo -e "/home/$bituser/.bitcoin/debug.log {\nrotate 5\ncopytruncate\ndaily\nmissingok\nnotifempty\ncompress\ndelaycompress\ncreate 0640 $bituser adm\n}" > /etc/logrotate.d/bitcoind
logrotate -f /etc/logrotate.d/bitcoind
echo -e "\033[1;33m""[+] Logfiles set to rotate automatically.""\033[0m"
sleep 3
exit 0
