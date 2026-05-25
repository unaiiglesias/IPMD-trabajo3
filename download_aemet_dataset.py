import gdown
import os

to_download = [
    {"url": "https://drive.google.com/uc?id=1dwaIC4_OvMtzfo1LcGaoUG4n3Hb7NJmS", "filename": "aemet_data.csv"}
]
save_dir = "./aemet-dataset"
os.makedirs("./aemet-dataset", exist_ok=True)
for x in to_download:
    gdown.download(x['url'], os.path.join(save_dir, x["filename"]), quiet=False)