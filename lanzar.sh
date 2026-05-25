#!/bin/bash

set -e

if [ ! -d "./wisdm-dataset" ]; then
    echo "ERROR! El dataset WISDM no está instalado, ejecuta el script descargar_dataset_WISDM.sh para descargarlo y vuelve a ejecutar este script"
    exit 1
fi

if [ ! -d "./aemet-dataset" ]; then
    echo "ERROR! El dataset aemet no está instalado, ejecuta el script descargar_dataset_aemet.sh para descargarlo y vuelve a ejecutar este script"
    exit 1
fi

docker rm -f practica3_mqtt_explorer 2>/dev/null

# Esto para descargar el repo de mosquitto-docker-compose, de momento tenemos nosotros los archivos y ya
echo "Reinstalando mosquitto-docker-compose... (se necesita sudo para borrar version vieja)"
sudo rm -rf mosquitto-docker-compose
git clone https://github.com/vvatelot/mosquitto-docker-compose

# Lanzar mosquitto (broker mqtt)
docker network inspect practica3_network >/dev/null 2>&1 || \
docker network create practica3_network

# Lanzar el subscriber (usamos este que tiene GUI y es comodo, es el del labo)
docker run -d --name practica3_mqtt_explorer -p 4000:4000 -v ./mosquitto-docker-compose/config:/zmqtt-explorer/config --network practica3_network smeagolworms4/mqtt-explorer

docker compose up -d
# Configurar conector de kafka a mosquitto
echo "Esperando a que se inicien los servicios de kafka para configurar los conectores..."
until curl -s http://localhost:8083/connectors >/dev/null; do
    sleep 5
done

# Compartimos la configuración de los conectores con Kafka-connect
curl -d @kafka/connect_mosquitto_to_kafka.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
curl -d @kafka/connect_mongo_to_kafka.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
curl -d @kafka/connect_mosquito_kafka_aemet.json -H "Content-Type: application/json" -X POST http://localhost:8083/connectors
#docker compose exec -it python_server /bin/bash

# Esperamos a que el contenedor python_server esté operativo: wisdm
echo "Esperando python_server..."
until docker exec python_server true 2>/dev/null; do
    sleep 2
done

echo "Iniciando envio de mensajes en el contenedor de python"
docker exec python_server pip install paho-mqtt 
docker exec -d python_server python /python_scripts/publicador.py

# Esperamos a que el contenedor python_server esté operativo: eamet
echo "Esperando python_server..."
until docker exec python_server_2 true 2>/dev/null; do
    sleep 2
done

echo "Iniciando envio de mensajes en el contenedor de python"
docker exec python_server_2 pip install paho-mqtt 
docker exec -d python_server_2 python /python_scripts/publicador_aemet.py

sleep 10

# Ejecución de sentencias SQL propuestas en Flink
# WISDM
docker exec -i flink_sql_client ./sql-client.sh < ./flink/wisdm/raw_data.sql
sleep 3
docker exec -i flink_sql_client ./sql-client.sh < ./flink/wisdm/stats.sql
sleep 3
docker exec -i flink_sql_client ./sql-client.sh < ./flink/wisdm/activity.sql
sleep 3
# AEMET
docker exec -i flink_sql_client ./sql-client.sh < ./flink/aemet/query_1.sql
sleep 3
docker exec -i flink_sql_client ./sql-client.sh < ./flink/aemet/query_2.sql
sleep 3

# Importamos las visualizaciones realizadas (en un dashboard) a Kibana
# Así no será necesario andar creándolas cada vez que se lanza el Kibana
echo "Esperando a que Kibana esté listo"
until curl -s -I http://localhost:5601/api/status | grep -q "HTTP/1.1 200"; do
    sleep 5
done

echo "Importando gráficos y dashboards (.ndjson) en Kibana..."
curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form file=@kibana/kibana_objects.ndjson

