#! /bin/bash

# Required Params
DIRECTORY=d-XXXXXXXXXX
DOMAINNAME=example.com

# Optional Params
USERGROUPDN='CN=test,OU=Users,OU=beachfamily,DC=beachfamily,DC=us'
ADMINGROUP='AWS\ Delegated\ Administrators@beachfamily.us'
COMPUTEROU='ou=beachfamily,dc=beachfamily,dc=us'

# Gererate a random password used to join the domain
PASSWORD=$(date | md5sum | cut -c 1-16)

# Generate a new hostname <= 15 chars
IP_ADDR=$(hostname -I)
IP_HEX=$(printf '%02X' ${IP_ADDR//./ })
COMPUTERNAME=ip-$IP_HEX
sudo hostname $COMPUTERNAME
sudo sed -i "s/HOSTNAME=localhost.localdomain/HOSTNAME=$COMPUTERNAME.$DOMAINNAME/g" /etc/sysconfig/network

# Create computer account and join the domain
sudo yum -y install sssd realmd krb5-workstation
aws ds create-computer --region us-east-1 --directory-id $DIRECTORY --computer-name $COMPUTERNAME --password $PASSWORD --organizational-unit-distinguished-name $COMPUTEROU
sudo realm join --one-time-password=$PASSWORD $DOMAINNAME --verbose
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config


# Set up access permissions and reboot
if [ -n "$ADMINGROUP" ]; then echo "%$ADMINGROUP ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo; fi
if [ -n "$USERGROUPDN" ]; then echo "ad_access_filter = (memberOf=$USERGROUPDN)" | sudo tee -a /etc/sssd/sssd.conf; fi
sudo service sssd start
sudo reboot now
