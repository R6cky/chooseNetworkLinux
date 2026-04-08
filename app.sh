#!/bin/bash

ETHER="eth0"
#WIFI="wlan0"

#WIFI_NAME="zyxw_py Mart 2.4g"
#WIFI_PASSWORD="00000000"
INTERVAL=5
LOG_FILE="/var/log/open-browse.log"



log() {
    echo "{$(date -Iseconds)\",\"level\":\"INFO\",\"message\":\"$1\"}" >> $LOG_FILE
}

check_ping() {
    ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1
}

check_dns() {
    getent hosts google.com > /dev/null 2>&1
}

check_http() {
    CODE=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://www.google.com)
    [[ "$CODE" == "200" ]]
}

internet_ok() {
    ((check_ping && check_dns && check_http) ||  (check_dns && check_http) || (check_ping && check_dns))
}


state_adapter_ethernet(){
ETHERNET_STATUS=$(ip -br link show $ETHER | awk '{print $2}')
echo "$ETHERNET_STATUS"
}


state_adapter_wireless(){
ETHERNET_STATUS=$(ip -br link show $WIFI | awk '{print $2}')
echo "$ETHERNET_STATUS"
}



log "Script started"


while true; do
    if [[ $(state_adapter_ethernet) == "UP" && (internet_ok) ]] ; then
        log "Status da rede Ethernet: $(state_adapter_ethernet)"
        log "Ethernet OK - usando cabo"

        #nmcli device connect $ETH
        # if [[ $(nmcli radio wifi) == "enabled" ]]; then
        #    log "Desabilitando adaptador wireless [ $WIFI ]"
        #    nmcli radio wifi off
        # fi

        #nmcli device disconnect $WIFI
        sleep $INTERVAL
        continue
    else
        log "Ethernet falhou - Conectando a rede $WIFI_NAME"
        # if [[ $(nmcli -t -f ACTIVE,SSID dev wifi | awk  -F: '$1=="yes" || $1=="sim" {print $2}') == $WIFI_NAME ]]; then
        #    log "Wifi conectado a rede [ $WIFI_NAME ]"
           sleep 5
        continue
        # else
        #   log "O adaptador "$WIFI" estava desabilitado. Habilitando "$WIFI"..."
        #   nmcli radio wifi on
        #   sleep 5
        #   #log "Conectando a rede [ $WIFI_NAME ]"
        #   log $(nmcli device wifi connect "$WIFI_NAME" password $WIFI_PASSWORD)
        #   log "Status da rede Wifi:  $(state_adapter_wireless)"
        #   log "Conectado a rede [ $(nmcli -t -f ACTIVE,SSID dev wifi | awk  -F: '$1=="yes" || $1=="sim" {print $2}') ]"

        # fi
    fi

    sleep $INTERVAL

done
