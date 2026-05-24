import time
import os
import json
import paho.mqtt.client as mqtt

# --- CONFIGURACIÓN ---
MQTT_BROKER = "practica3_mosquitto"
MQTT_PORT = 1883
MQTT_TOPIC = "smart"

# Rutas del dataset WISDM
ROOTPATH = "/wisdm-dataset/"
PATHS = [
    "raw/phone/accel/",
    "raw/phone/gyro/",
    "raw/watch/accel/",
    "raw/watch/gyro/",
]

WAIT_TIME = 0.01     # Segundos entre mensajes (ajusta según necesidad)
MAX_LINES = 1_000_000_000
# ---------------------


def conectar_mqtt():
    """Inicializa el cliente MQTT y se conecta al broker."""
    cliente = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)

    print(f"Conectando al broker MQTT en {MQTT_BROKER}:{MQTT_PORT}...")
    try:
        cliente.connect(MQTT_BROKER, MQTT_PORT, 60)
        cliente.loop_start()
        return cliente
    except Exception as e:
        print(f"Error al conectar al broker: {e}")
        return None


def parsear_linea(line: str) -> dict | None:
    """
    Convierte una línea CSV del dataset WISDM en un diccionario.

    Formato esperado: usid,action,timestamp,x,y,z[;]
    Devuelve None si la línea no es válida.
    """
    # Eliminar terminador de sentencia ';' y espacios sobrantes
    line = line.strip()
    if line.endswith(";"):
        line = line[:-1]

    parts = line.split(",")

    # Una línea válida tiene exactamente 6 campos
    if len(parts) != 6:
        return None

    try:
        return {
            "usid":   int(parts[0]),
            "action": parts[1].strip(),
            "ts":     int(parts[2].strip()),
            "x":      float(parts[3].strip()),
            "y":      float(parts[4].strip()),
            "z":      float(parts[5].strip()),
        }
    except ValueError:
        return None


def iterar_dataset():
    """
    Generador que recorre todos los archivos del dataset y
    produce dicts listos para serializar como JSON.
    """
    for path in PATHS:
        full_path = ROOTPATH + path
        if not os.path.isdir(full_path):
            print(f"Aviso: directorio no encontrado -> {full_path}")
            continue

        data_files = sorted(os.listdir(full_path))
        for data_file in data_files:
            filepath = full_path + data_file
            print(f"Leyendo: {filepath}")
            with open(filepath, "r", errors="replace") as f:
                for raw_line in f:
                    # Saltamos líneas vacías o de un solo carácter
                    if len(raw_line.strip()) <= 1:
                        continue

                    registro = parsear_linea(raw_line)
                    if registro is not None:
                        yield registro


def publicar_dataset():
    """Lee el dataset, parsea cada línea a JSON y la publica por MQTT."""
    cliente = conectar_mqtt()
    if not cliente:
        return

    print(f"Empezando a publicar datos en el tópico: '{MQTT_TOPIC}'")
    print("Presiona Ctrl+C para detener el envío.")

    contador = 0
    try:
        for registro in iterar_dataset():
            if contador >= MAX_LINES:
                break

            payload = json.dumps(registro)

            info = cliente.publish(MQTT_TOPIC, payload, qos=0)
            info.wait_for_publish()

            contador += 1
            if contador % 1000 == 0:
                print(f"-> {contador} mensajes publicados...")

            time.sleep(WAIT_TIME)

    except KeyboardInterrupt:
        print("\nEnvío detenido por el usuario.")
    finally:
        print("Cerrando conexión MQTT...")
        cliente.loop_stop()
        cliente.disconnect()
        print(f"Proceso terminado. Total de mensajes enviados: {contador}")


if __name__ == "__main__":
    publicar_dataset()