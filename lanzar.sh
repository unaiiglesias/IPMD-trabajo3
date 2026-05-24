#!/bin/bash

# Esto para descargar el repo de mosquitto-docker-compose, de momento tenemos nosotros los archivos y ya
echo "Reinstalando mosquitto-docker-compose... (se necesita sudo para borrar version vieja)"
sudo rm -rf mosquitto-docker-compose
git clone https://github.com/vvatelot/mosquitto-docker-compose

# Lanzar mosquitto (broker mqtt)
docker network create practica3_network
# Ahora esto va en el compose
#docker run -d --name practica3_mosquitto -p 1883:1883 -v ./mosquitto-docker-compose/config/:/mosquitto/config/ -v ./mosquitto-docker-compose/log/:/mosquitto/log/ -v ./mosquitto-docker-compose/data/:/mosquitto/data/ --expose 1883 --network practica3_network eclipse-mosquitto:2

# Lanzar el subscriber (usamos este que tiene GUI y es comodo, es el del labo)
docker run -d --name practica3_mqtt_explorer -p 4000:4000 -v ./mosquitto-docker-compose/config:/zmqtt-explorer/config --network practica3_network smeagolworms4/mqtt-explorer

docker compose up -d
#docker compose exec -it python_server /bin/bash
