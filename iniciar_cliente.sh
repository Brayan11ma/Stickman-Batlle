#!/usr/bin/env bash
cd "$(dirname "$0")"
python3 -m pip install -r requirements.txt
read -p "IP o dirección del servidor (Enter = la última usada): " HOST
python3 client/client.py $HOST
