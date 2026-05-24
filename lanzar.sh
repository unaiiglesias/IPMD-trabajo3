#!/bin/bash

wget -O wisdm-dataset.tar.gz https://www.cis.fordham.edu/wisdm/includes/datasets/latest/WISDM_ar_latest.tar.gz
tar -xf wisdm-dataset.tar.gz --transform='s|^[^/]*|wisdm-dataset|' # Extrae el contenido del archivo tar.gz y lo renombra a "dataset"
rm wisdm-dataset.tar.gz

# Esto para descargar el repo de mosquitto-docker-compose, de momento tenemos nosotros los archivos y ya
#sudo rm -rf mosquitto-docker-compose
#git clone https://github.com/vvatelot/mosquitto-docker-compose

# Lanzar mosquitto (broker mqtt)
docker network create practica3_network
#docker run -d --name practica3_mosquitto -p 1883:1883 -v ./mosquitto-docker-compose/config/:/mosquitto/config/ -v ./mosquitto-docker-compose/log/:/mosquitto/log/ -v ./mosquitto-docker-compose/data/:/mosquitto/data/ --expose 1883 --network practica3_network eclipse-mosquitto:2

# Lanzar el subscriber (usamos este que tiene GUI y es comodo, es el del labo)
docker run -d --name practica3_mqtt_explorer -p 4000:4000 -v ./mosquitto-docker-compose/config:/zmqtt-explorer/config --network practica3_network smeagolworms4/mqtt-explorer

docker compose up -d
#docker compose exec -it python_server /bin/bash
