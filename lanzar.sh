#!/bin/bash

if [ ! -d "./wisdm-dataset" ]; then
    echo "ERROR! El dataset WISDM no está instalado, ejecuta el script descargar_dataset.sh para descargarlo y vuelve a ejecutar este script"
    exit 1
fi

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
# Configurar conector de kafka a mosquitto
echo "Esperando a que se inicien los servicios de kafka para configurar los conectores..."
sleep 50
curl -d @kafka/connect_mosquitto_to_kafka.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
curl -d @kafka/connect_mongo_to_kafka.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
#docker compose exec -it python_server /bin/bash

echo "Iniciando envio de mensajes en el contenedor de python"
#docker exec python_server pip install paho-mqtt 
#docker exec python_server python /python_scripts/publicador.py