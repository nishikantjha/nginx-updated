#!/bin/bash
set -e
echo "*****    Installing Nginx    *****"
apt update
apt install -y nginx
ufw allow '${ufw_allow_nginx}'
systemctl enable nginx
systemctl restart nginx
sudo snap install core; sudo snap refresh core
sudo apt-get remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot run -n --nginx --agree-tos -d devopstesting.tk -m nishikantjha0011@gmail.com --redirect
sudo systemctl reload nginx

{ echo "nishikantjha0011 soft nofile 10000"
  echo "nishikantjha0011 hard nofile 10000"
} | sudo tee -a /etc/security/limits.conf > /dev/null

sysctl -p
sudo sh -c "echo 'worker_rlimit_nofile 10000;' >> /etc/nginx/nginx.conf"
sudo sed -i 's/worker_connections 768;/worker_connections 20000;/g' /etc/nginx/nginx.conf 
sudo systemctl restart nginx

