import time
import os
import json
import csv
import re
import paho.mqtt.client as mqtt

# --- CONFIGURACIÓN ---
MQTT_BROKER = "practica3_mosquitto"
MQTT_PORT = 1883
MQTT_TOPIC = "aemet"

# Ruta al fichero CSV de la AEMET
AEMET_CSV_PATH = "/aemet-dataset/aemet_data.csv"

# Delimitador del CSV
CSV_DELIMITER = "," 

WAIT_TIME = 0.01
MAX_LINES = 1_000_000_000
# ---------------------

def conectar_mqtt():
    """Inicializa el cliente MQTT y se conecta al broker Mosquitto."""
    cliente = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)

    print(f"Conectando al broker MQTT en {MQTT_BROKER}:{MQTT_PORT}...")
    try:
        cliente.connect(MQTT_BROKER, MQTT_PORT, 60)
        cliente.loop_start()
        return cliente
    except Exception as e:
        print(f"Error al conectar al broker: {e}")
        return None


def limpiar_y_convertir(valor: str, es_numerico: bool):
    """
    Limpia las cadenas y convierte los datos numéricos.
    Si el dato está vacío, ausente o es inválido, devuelve None (null en JSON).
    """
    if valor is None:
        return None
    
    valor = valor.strip()
    
    if valor == "" or valor.lower() in ["null", "none", "nan", "-", "varias"]:
        return None
    
    if es_numerico:
        valor = valor.replace(",", ".")
        try:
            return float(valor) if "." in valor else int(valor)
        except ValueError:
            match = re.match(r"^[-+]?[0-9]*\.?[0-9]+", valor)
            if match:
                num_str = match.group()
                return float(num_str) if "." in num_str else int(num_str)
            return None
            
    return valor


def parsear_fila_aemet(fila: dict) -> dict:
    """
    Procesa un diccionario de fila aplicando una lista blanca estricta.
    Solo se publican los identificadores de la estación y un conjunto de metricas del archivo original.
    """
    registro_procesado = {}
    
    # 1. Definimos las ÚNICAS columnas numéricas permitidas
    columnas_numericas_permitidas = {
        "altitud", "tmed", "prec", "dir", "velmedia", "racha", "hrmedia", "sol"
    }
    
    # 2. Definimos las columnas de texto necesarias para identificar la procedencia de la lectura
    columnas_identificadores = {"indicativo", "nombre", "provincia"}
    
    for clave, valor in fila.items():
        if clave is None:
            continue
        
        clave_limpia = clave.strip()
        clave_lower = clave_limpia.lower()
        
        # Filtrado estricto:
        if clave_lower in columnas_numericas_permitidas:
            # Procesar como numérico (mantiene el nombre original de la clave del CSV, ej: hrMedia)
            registro_procesado[clave_lower] = limpiar_y_convertir(valor, es_numerico=True)
            
        elif clave_lower in columnas_identificadores:
            # Procesar como texto base
            registro_procesado[clave_lower] = limpiar_y_convertir(valor, es_numerico=False)
            
        else:
            # Se descartan fechas, horas y el resto de numéricas (tmin, tmax, presMax, presMin, hrMax, hrMin)
            continue
        
    return registro_procesado


def publicar_dataset():
    """Lee el dataset de AEMET, filtra bajo la lista blanca y publica por MQTT."""
    cliente = conectar_mqtt()
    if not cliente:
        return

    print(f"Empezando a publicar datos optimizados en el tópico: '{MQTT_TOPIC}'")
    print("Presiona Ctrl+C para detener el envío.")

    contador = 0
    try:
        if not os.path.exists(AEMET_CSV_PATH):
            print(f"Error: No se encontró el archivo en {AEMET_CSV_PATH}")
            return

        with open(AEMET_CSV_PATH, "r", encoding="utf-8", errors="replace") as f:
            lector = csv.DictReader(f, delimiter=CSV_DELIMITER)
            
            for fila in lector:
                if contador >= MAX_LINES:
                    break

                registro = parsear_fila_aemet(fila)
                
                # Omitir publicar si por algún motivo el registro quedó vacío
                if not registro:
                    continue

                payload = json.dumps(registro, ensure_ascii=False)

                info = cliente.publish(MQTT_TOPIC, payload, qos=0)
                info.wait_for_publish()

                contador += 1
                if contador % 1000 == 0:
                    print(f"-> {contador} mensajes filtrados de AEMET publicados...")

                time.sleep(WAIT_TIME)

    except KeyboardInterrupt:
        print("\nEnvío detenido por el usuario.")
    except Exception as e:
        print(f"Error inesperado en el bucle de envío: {e}")
    finally:
        print("Cerrando conexión MQTT...")
        cliente.loop_stop()
        cliente.disconnect()
        print(f"Proceso terminado. Total de mensajes enviados: {contador}")


if __name__ == "__main__":
    publicar_dataset()