#!/bin/bash

### ---------------------------------------------------------
###  Leitura de parâmetros (suporte ao -i URL)
### ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            TARGET_URL="$2"
            shift 2
            ;;
        *)
            TARGET_URL="$1"
            shift
            ;;
    esac
done

if [ -z "$TARGET_URL" ]; then
    echo "ERRO: Nenhuma URL foi informada."
    echo "Uso: $0 -i <URL>  ou  $0 <URL>"
    exit 1
fi

### ---------------------------------------------------------
###  Funções auxiliares
### ---------------------------------------------------------
watchdog_reset() {
    echo "V" > /dev/watchdog 2>/dev/null
}

# Detecta se o Chromium está rodando
is_chromium_running() {
    pgrep -f "chromium" >/dev/null
}

# Detecta se a janela está na tela
is_chromium_window_visible() {
    xdotool search --onlyvisible --name "Chromium" >/dev/null 2>&1
}

### ---------------------------------------------------------
###  Inicia Chromium (somente se NÃO estiver aberto)
### ---------------------------------------------------------
start_chromium() {
    if is_chromium_running; then
        return
    fi

    chromium-browser \
        --kiosk \
        "$TARGET_URL" \
        --noerrdialogs \
        --no-first-run \
        --no-default-browser-check \
        --disable-session-crashed-bubble \
        --disable-infobars \
        --disable-features=TranslateUI \
        --overscroll-history-navigation=0 \
        >/dev/null 2>&1 &
}

### ---------------------------------------------------------
###  Refresh totalmente desativado
### ---------------------------------------------------------
refresh_page() {
    return
}

### ---------------------------------------------------------
###  Detecta travamento real
### ---------------------------------------------------------
check_freeze() {
    # Se o processo SUMIU → relançar
    if ! is_chromium_running; then
        start_chromium
        sleep 8
        return
    fi

    # Se a janela sumiu → travou ou ficou oculta
    if ! is_chromium_window_visible; then
        pkill -f chromium
        sleep 2
        start_chromium
        sleep 8
        return
    fi
}

### ---------------------------------------------------------
###  Teste de rede
### ---------------------------------------------------------
check_network() {
    curl -I --max-time 5 "$TARGET_URL" 2>/dev/null \
        | head -n 1 | grep "200" >/dev/null
}

wait_network_restore() {
    echo "Rede caiu! Aguardando retorno..."
    while ! check_network; do
        sleep 2
        watchdog_reset
    done
    echo "Rede voltou!"
    sleep 3
}

### ---------------------------------------------------------
###  Início do navegador
### ---------------------------------------------------------
start_chromium
sleep 5

### ---------------------------------------------------------
###  Loop principal
### ---------------------------------------------------------
while true; do
    watchdog_reset

    # Chromium fechado?
    if ! is_chromium_running; then
        start_chromium
        sleep 8
    else
        check_freeze
    fi

    # Rede caiu?
    if ! check_network; then
        wait_network_restore
    fi

    sleep 10
done
