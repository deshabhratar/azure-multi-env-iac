




#!/bin/bash

# Update and install nginx
sudo apt update -y
sudo apt install nginx -y

# Write nginx config
cat > /etc/nginx/conf.d/app.conf <<EOF
upstream app_tier {
    server ${app_lb_ip}:5000;
}
server {
    listen 80;
    location / {
        proxy_pass http://app_tier;
    }
}
EOF

# Restart nginx
sudo systemctl restart nginx
