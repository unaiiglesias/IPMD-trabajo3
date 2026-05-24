#!/bin/bash

if command -v unzip >/dev/null 2>&1; then
    echo "EXITO! Comando unzip instalado"
else
    echo "ERROR! Este script necesita unzip (sudo apt install unzip)"
    exit 1
fi

wget -O wisdm-dataset.zip --no-check-certificate https://archive.ics.uci.edu/static/public/507/wisdm+smartphone+and+smartwatch+activity+and+biometrics+dataset.zip
unzip wisdm-dataset.zip -d wisdm-dataset-unzipped
rm wisdm-dataset.zip

unzip wisdm-dataset-unzipped/wisdm-dataset.zip -d .
rm -r wisdm-dataset-unzipped