#!/bin/bash
# -*- coding: utf-8 -*-
#
# Copyright 2019 Prophet Tech (Shanghai) Ltd.
#
# Authors: Wang Bin <wangbin@prophetech.cn>
#
# Copyright (c) 2019 This file is confidential and proprietary.
# All Rights Resrved, Prophet Tech (Shanghai) Ltd (http://www.prophetech.cn).
#
# Change HyperMotion IP address.
#
# Warning: If you change IP, you need to apply for license again to continue using HyperMotion. Please think carefully !
# Warning: The script starts to run. Do not force it to stop, or it will cause irreversible consequences !
# Warning: This operation is not recommended if an agent-mode host has been added ! 
#
# Method:
#	1. ./Change_HyperMotion_IP.sh 



# Check that the proxy mode host has been added. 
function Check_Agent()
{
cat /var/log/httpd/access_log | grep agent &>/dev/null
if [ $? = 0 ];then
echo -e "\033[31mYou have added agent mode host, do not recommend this operation!\033[0m"
exit 1
else
echo
fi
}

# Check that the "./var/lib/porter/.license" file is generated.
function Check_License()
{
if [ -e /var/lib/porter/.license ];then
echo -e "\n\033[31mWarning ! If you continue to operate, you need to apply for license again to continue to use HyperMotion ! \033[0m \n"
read -p "Would you like to continue?[Y/N]: " parameter1 
	case $parameter1 in
	y|Y|YES|yes)
	;;
	*)
	echo -e "\n\033[32mexit\033[0m\n"
	exit 1
	;;
	esac
fi
}

# Check that the Proxy and HyperMotion are deployed on one host.
function Check_Proxy()
{
docker ps  |grep proxy &>/dev/null
if [ $? = 0 ];then
echo 
else
echo -e "\033[31mProxy are deployed separately. This operation is not recommended! \033[0m"
exit 1
fi
}

# Set the IP address of the host.
function Set_Ip()
{
echo -e "\033[31mThe script starts to run. Do not force it to stop, or it will cause irreversible consequences ! \033[0m\n"
read -p "Please enter your host IP address: " parameter2
IP=$parameter2
echo $IP | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" &>/dev/null 
if [ $? = 0 ];then
ifconfig | grep -w $IP >/dev/null
	if [ $? = 0 ];then
	echo "LOCAL_IP=$parameter2" > /opt/installer/.LOCAL_IP
	agent_old_ip=`head -20 /var/www/html/softwares/getplusagent.sh  | grep ^SERVER_IP | awk -F = '{print $2}'`
        agent_new_ip=$IP
        sed -i "s/SERVER_IP=$agent_old_ip/SERVER_IP=$agent_new_ip/g" /var/www/html/softwares/getplusagent.sh
	hypergate_old_ip=`head -5 /var/www/html/softwares/gethypergate.sh | grep ^SERVER_IP | awk -F = '{print $2}'`
	hypergate_new_ip=$IP
	echo -e "\033[32mSet /opt/install/.LOCAL_IP successful! \033[0m"
	sed -i "s/SERVER_IP=$hypergate_old_ip/SERVER_IP=$hypergate_new_ip/g" /var/www/html/softwares/gethypergate.sh
	else
	echo -e "\033[31mPlease enter your host IP address \033[0m \n "
	echo -e "\033[31mThe IP address look method for your host is \033[0m 'ip a s' \033[31m and  \033[0m 'ifconfig' \033[31m ! \033[0m \n"
	exit 1
	fi
else
echo -e "\033[31mPlease enter the IP address in the correct format. \033[0m \n"
echo -e "\033[31mMethod：\033[0m \033[32m ./Change_HyperMotion_Ip.sh 192.168.11.100! \033[0m \n"
exit 1
fi
}

# Delete /opt/consul/data/* files.
function Delete_Data()
{
rm -rf /opt/consul/data/* &>/dev/null
echo -e  "\033[32mDelete /opt/consul/data successful! \033[0m"
}

# Delete all dockers and restart.
function Delete_Docker()
{
docker rm -f $(docker ps -qa) &>/dev/null
systemctl restart docker &>/dev/null
echo -e "\033[32mDelete docker successful! \033[0m"
}

# Reset Docker
function Reset_Docker()
{
hypermotion_startup &>/dev/null && echo -e "\033[32mReset hypermotion_docker successful! \033[0m"
proxy_startup &>/dev/null &&  echo -e  "\033[32mReset proxy_docker successful! \033[0m"
}

# Close the selinux, start httpd, backup license file, 
function Command()
{
setenforce 0  &>/dev/null && echo -e  "\033[32mSelinux closed successful! \033[0m"
systemctl start httpd && echo -e  "\033[32mHTTPD start successful! \033[0m"
mv /var/lib/porter/.license /var/lib/porter/.license.backup
echo -e  "\033[32mHyperMotion IP change succeeded. Please request \033[0m http://$parameter2:18088/ \033[32m!\033[0m"
}


# Check that the proxy mode host has been added.
Check_Agent

# Check that the "./var/lib/porter/.license" file is generated.
Check_License

# Check that the Proxy and HyperMotion are deployed on one host.
Check_Proxy

# Start making changes to HyperMotion's IP address.
Set_Ip  
Delete_Data 
Delete_Docker
Reset_Docker
Command




