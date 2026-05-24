import time
import os
import paho.mqtt.client as mqtt

# --- CONFIGURACIÓN ---
# Si usas un broker local (ej. Mosquitto en Docker), usa "localhost"
# Para pruebas rápidas puedes usar el broker público de HiveMQ: "broker.hivemq.com"
MQTT_BROKER = "practica3_mosquitto"
MQTT_PORT = 1883
MQTT_TOPIC = "/raw"  # Esta es tu "carpeta" en MQTT

# Ruta al archivo raw del dataset WISDM
PATH_DATASET = "/wisdm-dataset/WISDM_ar_v1.1_raw.txt" 
# ---------------------

def conectar_mqtt():
    """Inicializa el cliente MQTT y se conecta al broker."""
    # En la versión actual de paho-mqtt (v2.x), se define el protocolo explícitamente
    cliente = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    
    print(f"Conectando al broker MQTT en {MQTT_BROKER}:{MQTT_PORT}...")
    try:
        cliente.connect(MQTT_BROKER, MQTT_PORT, 60)
        # Arrancamos el bucle en segundo plano para gestionar la conexión
        cliente.loop_start()
        return cliente
    except Exception as e:
        print(f"Error al conectar al broker: {e}")
        return None

def publicar_dataset():
    # 1. Verificar si el archivo existe
    if not os.path.exists(PATH_DATASET):
        print(f"Error: No se encontró el archivo en {PATH_DATASET}")
        print("Asegúrate de haber descomprimido el dataset correctamente.")
        return

    # 2. Conectar a MQTT
    cliente = conectar_mqtt()
    if not cliente:
        return

    print(f"Empezando a publicar datos en el tópico: '{MQTT_TOPIC}'")
    print("Presiona Ctrl+C para detener el envío.")

    try:
        # 3. Leer el archivo línea por línea (ideal para archivos grandes de texto raw)
        with open(PATH_DATASET, 'r') as archivo:
            contador = 0
            for linea in archivo:
                # Limpiamos espacios en blanco o saltos de línea al inicio/final
                datos_raw = linea.strip()
                
                # Ignorar líneas vacías si las hay
                if not datos_raw:
                    continue
                
                # 4. Publicar la línea raw en MQTT
                # info_publicacion guarda el estado del envío si necesitas verificarlo
                info_publicacion = cliente.publish(MQTT_TOPIC, datos_raw, qos=0)
                info_publicacion.wait_for_publish() # Garantiza que se envió antes de seguir
                
                contador += 1
                if contador % 1000 == 0:
                    print(f"-> {contador} mensajes publicados...")

                # Simular un pequeño retraso para no saturar (ej. 0.01 segundos por lectura)
                # Si quieres enviar todo a máxima velocidad, puedes comentar la línea de abajo
                time.sleep(0.01) 

    except KeyboardInterrupt:
        print("\nEnvío detenido por el usuario.")
    finally:
        # 5. Desconexión limpia
        print("Cerrando conexión MQTT...")
        cliente.loop_stop()
        cliente.disconnect()
        print(f"Proceso terminado. Total de mensajes enviados: {contador}")

if __name__ == "__main__":
    publicar_dataset()