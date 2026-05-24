#!/bin/bash
docker stop practica3_mosquitto
docker rm practica3_mosquitto
docker stop practica3_mqtt_explorer
docker rm practica3_mqtt_explorer
docker compose down