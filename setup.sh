#!/bin/bash

TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export INSTANCE_IP=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4`
export GWLB_IP_A=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/tags/instance/GWLB_IP_A`
export GWLB_IP_C=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/tags/instance/GWLB_IP_C`
export GWLB_IP_D=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/tags/instance/GWLB_IP_D`


sudo sysctl -w net.ipv4.ip_forward=1  
sudo yum install -y iptables-services  
sudo systemctl enable iptables  
sudo systemctl start iptables

sudo iptables -P INPUT ACCEPT  
sudo iptables -P FORWARD ACCEPT  
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -F  
sudo iptables -t mangle -F  
sudo iptables -F  
sudo iptables -X

sudo iptables -t nat -A PREROUTING -p udp -s $GWLB_IP_A -d $INSTANCE_IP -i enX0 -j DNAT --to-destination $GWLB_IP_A:6081  
sudo iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $GWLB_IP_A -d $GWLB_IP_A -o enX0 -j MASQUERADE

sudo iptables -t nat -A PREROUTING -p udp -s $GWLB_IP_C -d $INSTANCE_IP -i enX0 -j DNAT --to-destination $GWLB_IP_C:6081  
sudo iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $GWLB_IP_C -d $GWLB_IP_C -o enX0 -j MASQUERADE

sudo iptables -t nat -A PREROUTING -p udp -s $GWLB_IP_D -d $INSTANCE_IP -i enX0 -j DNAT --to-destination $GWLB_IP_D:6081  
sudo iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $GWLB_IP_D -d $GWLB_IP_D -o enX0 -j MASQUERADE

sudo service iptables save

sudo dnf -y install httpd
sudo service httpd start  
sudo chkconfig httpd on  
echo "Health check page" >>/var/www/html/index.html 
