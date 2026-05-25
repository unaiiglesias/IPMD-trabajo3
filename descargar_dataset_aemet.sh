#!/bin/bash
# Para descargar un archivo grande de Google Drive, hay que hacer este truco con la cookie

SAVE_DIR="./aemet-dataset"
mkdir -p "$SAVE_DIR"

FILE_ID="1dwaIC4_OvMtzfo1LcGaoUG4n3Hb7NJmS"
FILENAME="aemet_data.csv"
OUTPUT="$SAVE_DIR/$FILENAME"

echo "Descargando $FILENAME..."

curl -L "https://drive.google.com/uc?export=download&id=${FILE_ID}" \
     -o "$OUTPUT"

if file "$OUTPUT" | grep -q "HTML"; then
    # Reintentar por curl para quedarse con la cookie a devolver
    CONFIRM=$(curl -sc /tmp/gdrive_cookie \
        "https://drive.google.com/uc?export=download&id=${FILE_ID}" \
        | grep -o 'confirm=[^&"]*' | head -1 | cut -d= -f2)

    # Reintentar descarga con la cookie de ocnfirmacion
    curl -L -b /tmp/gdrive_cookie \
         "https://drive.google.com/uc?export=download&confirm=${CONFIRM}&id=${FILE_ID}" \
         -o "$OUTPUT"

    rm -f /tmp/gdrive_cookie
fi

echo "Guardado en: $OUTPUT"