#!/bin/bash

# Update packages
sudo apt update -y 

#Install the apache2 package if it is not already installed.
if dpkg -l apache2 2>/dev/null;
then echo "Apache already installed";
else sudo apt install apache2;
fi

#Checks whether the server is running or not. If it is not running, then it starts the server
servstat=$(service apache2 status)
if [[ $servstat == *"active (running)"* ]]; then
  echo "process is running"
else
sudo service apache2 start;
fi

#Ensures that the server runs on restart/reboot
if ! pidof apache2 > /dev/null
then
    # web server down, restart the server
    echo "Server down"
else
    sudo /etc/init.d/apache2 restart > /dev/null
fi


#Archiving logs to S3
#sudo apt install awscli #Used to manually install AWS CLI
cd /var/log/apache2/
timestamp=$(date '+%d%m%Y-%H%M%S')
name=Aniruddh
sudo tar czvf $name-httpd-logs-$timestamp.tar *.log 
cd /tmp/
sudo tar czvf $name-httpd-logs-$timestamp.tar /tmp/
s3_bucket=upgrad-aniruddh
aws s3 cp /tmp/$name-httpd-logs-$timestamp.tar s3://$s3_bucket/$name-httpd-logs-$timestamp.tar



#Bookeeping
cd /var/www/html/  #Manually changing path
if [ -f "inventory.html" ]
then
echo "File found"
else
   sudo touch inventory.html
   sudo chmod 777 inventory.html
   sudo echo $'Log Type\t\tTime Created\t\tType\t\tSize' > inventory.html
fi
sudo touch diff.html
sudo chmod 777 diff.html
sudo echo $'Log Type\t\tTime Created\t\tType\t\tSize' > diff.html
aws s3 ls s3://$s3_bucket --recursive --human-readable | awk  '{printf "\n%s %s %s", $3, $4, $5} END {print ""}' | awk -F'[-. ]' '{printf "\n%s-%s\t\t%s-%s\t\t%s\t\t%s%s", $5, $6, $7, $8, $9, $1, $3} END {print ""}' >> /var/www/html/diff.html 
grep -Fxvf inventory.html diff.html >> inventory.html
sudo rm -rf diff.html


#Cron Job
cd /etc/cron.d/
if [ -f "automation" ]
then 
echo "File Found"
else
echo $'27 15 * * * root /root/Automation_Project/automation.sh' > automation
fi

