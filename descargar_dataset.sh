#!/bin/bash
wget -O wisdm-dataset.tar.gz https://www.cis.fordham.edu/wisdm/includes/datasets/latest/WISDM_ar_latest.tar.gz
tar -xf wisdm-dataset.tar.gz --transform='s|^[^/]*|wisdm-dataset|' # Extrae el contenido del archivo tar.gz y lo renombra a "dataset"
rm wisdm-dataset.tar.gz