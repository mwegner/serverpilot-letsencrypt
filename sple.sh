#!/bin/bash
# Bash script to create/add Let's Encrypt SSL to ServerPilot app
# by Rudy Affandi (2016)
# Edited Feb 16, 2016

# Todo
# 1. Generate certificate
# /root/letsencrypt/letsencrypt-auto certonly --webroot -w /srv/users/serverpilot/apps/appname/public -d appdomain.tld
# 2. Generate appname.ssl.conf file
# 3. Restart nginx
# sudo service nginx-sp restart
# 4. Confirm that it's done and show how to do auto-renew via CRON

# Settings
lefolder=/root/letsencrypt
appfolder=/srv/users/serverpilot/apps
conffolder=/etc/nginx-sp/vhosts.d

# Make sure this script is run as root
if [ "$EUID" -ne 0 ]
then 
    echo ""
	echo "Please run this script as root."
	exit
fi

# Check for Let's Encrypt installation
if [ ! -d "$lefolder" ]
then
    echo "Let's Encrypt is not installed/found in your root folder. Would you like to install it?"
    read -p "Y or N " -n 1 -r
    echo ""
    if [[ "$REPLY" =~ ^[Yy]$ ]]
    then
    	cd /root && sudo git clone https://github.com/letsencrypt/letsencrypt
    else
    	exit
    fi
fi

echo ""
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""
echo "  Let's Encrypt SSL Certificate Generator"
echo "  For ServerPilot-managed server instances"
echo ""
echo "  Written by Rudy Affandi (2016)"
echo "  https://github.com/lesaff/"
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""
echo ""
echo "Please enter your app name:"
read appname
echo ""
echo "Please enter all the domain names and sub-domain names"
echo "you would like to use, separated by space"
read domains

# Assign domain names to array
APPDOMAINS=()
for domain in $domains; do
   APPDOMAINS+=("$domain")
done

# Assign domain list to array
APPDOMAINLIST=()
for domain in $domains; do
   APPDOMAINLIST+=("-d $domain")
done

# Generate certificate
echo ""
echo ""
echo "Generating SSL certificate for $appname"
echo ""
$lefolder/letsencrypt-auto certonly --webroot -w /srv/users/serverpilot/apps/$appname/public ${APPDOMAINLIST[@]}

# Generate nginx configuration file
configfile=$conffolder/$appname.ssl.conf
echo ""
echo ""
echo "Creating configuration file for $appname in the $conffolder"
sudo touch $configfile
echo "server {" | sudo tee $configfile 
echo "   listen 443 ssl http2;" | sudo tee -a $configfile 
echo "   listen [::]:443 ssl http2;" | sudo tee -a $configfile 
echo "   server_name " | sudo tee -a $configfile 
   for domain in $domains; do
      echo -n $domain" " | sudo tee -a $configfile
   done
echo ";" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   ssl on;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "   # letsencrypt certificates" | sudo tee -a $configfile 
echo "   ssl_certificate      /etc/letsencrypt/live/${APPDOMAINS[0]}/fullchain.pem;" | sudo tee -a $configfile 
echo "   ssl_certificate_key  /etc/letsencrypt/live/${APPDOMAINS[0]}/privkey.pem;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    #SSL Optimization" | sudo tee -a $configfile 
echo "    ssl_session_timeout 1d;" | sudo tee -a $configfile 
echo "    ssl_session_cache shared:SSL:20m;" | sudo tee -a $configfile 
echo "    ssl_session_tickets off;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    # modern configuration" | sudo tee -a $configfile 
echo "    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;" | sudo tee -a $configfile 
echo "    ssl_prefer_server_ciphers on;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    # OCSP stapling" | sudo tee -a $configfile 
echo "    ssl_stapling on;" | sudo tee -a $configfile 
echo "    ssl_stapling_verify on;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    # verify chain of trust of OCSP response" | sudo tee -a $configfile 
echo "    ssl_trusted_certificate /etc/letsencrypt/live/${APPDOMAINS[0]}/chain.pem;" | sudo tee -a $configfile 
echo "    #root directory and logfiles" | sudo tee -a $configfile 
echo "    root /srv/users/serverpilot/apps/$appname/public;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    access_log /srv/users/serverpilot/log/$appname/${appname}_nginx.access.log main;" | sudo tee -a $configfile 
echo "    error_log /srv/users/serverpilot/log/$appname/${appname}_nginx.error.log;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    #proxyset" | sudo tee -a $configfile 
echo "    proxy_set_header Host \$host;" | sudo tee -a $configfile 
echo "    proxy_set_header X-Real-IP \$remote_addr;" | sudo tee -a $configfile 
echo "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" | sudo tee -a $configfile 
echo "    proxy_set_header X-Forwarded-SSL on;" | sudo tee -a $configfile 
echo "    proxy_set_header X-Forwarded-Proto \$scheme;" | sudo tee -a $configfile 
echo "" | sudo tee -a $configfile 
echo "    #includes" | sudo tee -a $configfile 
echo "    include /etc/nginx-sp/vhosts.d/$appname.d/*.nonssl_conf;" | sudo tee -a $configfile 
echo "    include /etc/nginx-sp/vhosts.d/$appname.d/*.conf;" | sudo tee -a $configfile 
echo "}" | sudo tee -a $configfile 

# Wrapping it up
echo ""
echo ""
echo "We're almost done here. Restarting nginx..."
sudo service nginx-sp restart
echo ""
echo ""
echo "Adding cron job to renew your LE SSL certificate every 2 months"
echo ""

# Write crontab to temp file
crontab -l > spcron

# Append new schedule to crontab
echo "0 1 1 */2 * $lefolder/letsencrypt-auto certonly --renew-by-default --webroot -w /srv/users/serverpilot/apps/$appname/public ${APPDOMAINLIST[@]}" >> spcron
echo ""

# Save crontab
crontab spcron

# Delete temp file
rm spcron

echo ""
echo "The following has been added to your crontab for automatic renewal every two months"
echo "0 1 1 */2 * $lefolder/letsencrypt-auto certonly --renew-by-default --webroot -w /srv/users/serverpilot/apps/$appname/public ${APPDOMAINLIST[@]}"
echo ""
echo "Your Let's Encrypt SSL certificate has been installed. Please update your .htaccess to force HTTPS on your app"
echo ""
echo "Cheers!"
