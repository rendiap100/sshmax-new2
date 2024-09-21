#!/bin/bash
dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=$(date +"%Y-%m-%d" -d "$dateFromServer")
#########################
clear
tls="$(cat ~/log-install.txt | grep -w "Vmess Ws Tls" | cut -d: -f2 | sed 's/ //g')"
none="$(cat ~/log-install.txt | grep -w "Vmess Ws None Tls" | cut -d: -f2 | sed 's/ //g')"
NUMBER_OF_CLIENTS=$(grep -c -E "^#vmg " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    clear
    echo ""
    echo "You have no existing clients!"
    exit 1
fi

clear
echo ""
echo "SHOW USER XRAY VMESS WS"
echo "Select the existing client you want to check"
echo " Press CTRL+C to return"
echo -e "==============================="
grep -E "^#vmg " "/etc/xray/config.json" | cut -d ' ' -f 2-3 | nl -s ') '
read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER

domain=$(cat /etc/xray/domain)
user=$(grep -E "^#vmg " "/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^#vmg " "/etc/xray/config.json" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
uuid=$(grep -E "^#vm " "/etc/xray/config.json" | cut -d ' ' -f 5 | sed -n "${CLIENT_NUMBER}"p)
created_date=$(grep -E "^#vmg " "/etc/xray/config.json" | cut -d ' ' -f 4 | sed -n "${CLIENT_NUMBER}"p)
active_days=$(grep -E "^#vmg " "/etc/xray/config.json" | cut -d ' ' -f 6 | sed -n "${CLIENT_NUMBER}"p)

# Display the account details
echo -e "\e[33m◈━━━━━◈◈━━━━━◈\033[0m"
echo -e "» Domain  : ${domain}"
echo -e "» Pengguna  : ${user}"
echo -e "\e[33m◈━━━━━◈◈━━━━━◈\033[0m"
echo -e "» Port TLS : 443"
echo -e "» Port NTLS  : 80, 8080, 8880, 2082"
echo -e "» Key  : ${uuid}"
echo -e "» Path  : /vmess"
echo -e "» ServiceName  : vmess-grpc"
echo -e "\e[33m◈━━━━━◈◈━━━━━◈\033[0m"
echo -e "» Expired On : $exp"
echo -e "» Created On : $created_date"
echo -e "» Active For : $active_days Days"
echo -e "\e[33m◈━━━━━━━━◈◈━━━━━━━━◈\033[0m"
read -n 1 -s -r -p "Press any key to go back to menu"
menu
