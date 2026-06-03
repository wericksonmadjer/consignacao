#!/bin/bash

# Carrega as variáveis de ambiente do .env
if [ -f .env ]; then
    # Lê o arquivo .env, ignora comentários e exporta as variáveis
    export $(grep -v '^#' .env | xargs)
else
    echo "Erro: Arquivo .env não encontrado!"
    exit 1
fi

FILE="index.html"

if [ ! -f "$FILE" ]; then
    echo "Erro: Arquivo $FILE não encontrado no diretório atual!"
    exit 1
fi

echo "Iniciando upload de $FILE para o servidor HostGator..."

# Tenta enviar para /public_html/index.html
# -s: silencioso (sem barra de progresso)
# -w "%{http_code}": imprime o código de status HTTP resultante
# -o /dev/null: descarta o corpo da resposta
# -u "$USERNAME:$PASSWORD": autenticação
# -T "$FILE": faz upload do arquivo index.html
# --insecure / -k: adicionado caso haja problemas com certificado SSL do servidor HostGator
URL_DEST="https://$SERVER_ADDRESS:$PORT/public_html/$FILE"
echo "Tentando enviar para: $URL_DEST"

RESPONSE=$(curl -k -s -w "%{http_code}" -o /dev/null -u "$USERNAME:$PASSWORD" -T "$FILE" "$URL_DEST")

if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 201 ] || [ "$RESPONSE" -eq 204 ]; then
    echo "Sucesso! O arquivo $FILE foi enviado com sucesso para public_html (Código HTTP: $RESPONSE)."
else
    echo "Falha ao enviar para public_html (Código HTTP: $RESPONSE)."
    echo "Tentando caminho alternativo na raiz do Web Disk (caso o Web Disk já aponte diretamente para public_html)..."
    
    URL_DEST_ALT="https://$SERVER_ADDRESS:$PORT/$FILE"
    echo "Tentando enviar para: $URL_DEST_ALT"
    
    RESPONSE_ALT=$(curl -k -s -w "%{http_code}" -o /dev/null -u "$USERNAME:$PASSWORD" -T "$FILE" "$URL_DEST_ALT")
    
    if [ "$RESPONSE_ALT" -eq 200 ] || [ "$RESPONSE_ALT" -eq 201 ] || [ "$RESPONSE_ALT" -eq 204 ]; then
        echo "Sucesso! O arquivo $FILE foi enviado com sucesso para a raiz (Código HTTP: $RESPONSE_ALT)."
    else
        echo "Erro crítico: Falha em ambas as tentativas."
        echo "Retorno da tentativa na raiz: Código HTTP $RESPONSE_ALT"
        echo "Por favor, verifique se as credenciais estão corretas ou se o servidor está acessível."
        exit 1
    fi
fi
