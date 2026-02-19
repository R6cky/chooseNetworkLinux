#!/bin/bash

ETH="eth0"
WIFI="wlan0"
INTERVAL=15
LOG_FILE="/var/log/network-failover.log"

log() {
    echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"INFO\",\"message\":\"$1\"}" >> $LOG_FILE
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
    check_ping && check_dns && check_http
}

while true; do

    ETH_STATE=$(nmcli -t -f DEVICE,STATE device | grep "^$ETH:" | cut -d: -f2)

    if [[ "$ETH_STATE" == "connected" ]] && internet_ok; then
        log "Ethernet OK - usando cabo"
        nmcli device connect $ETH
        nmcli device disconnect $WIFI
    else
        log "Ethernet falhou - ativando Wi-Fi"
        nmcli device connect $WIFI
    fi

    sleep $INTERVAL

done
