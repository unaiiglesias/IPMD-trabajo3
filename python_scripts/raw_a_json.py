import os, time

rootpath = "/wisdm-dataset"
paths = ["raw/phone/accel/", "raw/phone/gyro/", "raw/watch/accel/", "raw/watch/gyro/"]

WAIT_TIME = 0.5
MAX_LINES = 1000000000

i = 0
for path in paths:
    data_files = sorted(os.listdir(rootpath + path))
    for data_file in data_files:
        with open(rootpath + path + data_file, "r") as f:
            maxl = 0
            while True:
                try:
                    line = f.readline()
                except UnicodeDecodeError:
                    continue
                if not line or len(line) == 1:
                    break
                line = f.readline().split(",")
                try:
                    if line[-1][-1] == ";":
                        line[-1] = line[-1][:-1]
                    elif line[-1][-1] == "\n":
                        line[-1] = line[-1][:-2]
                except:
                    continue
                line = (
                    '{"usid":'
                    + line[0]
                    + ',"action": "'
                    + line[1]
                    + '","ts": '
                    + line[2]
                    + ',"x":'
                    + line[3]
                    + ',"y":'
                    + line[4]
                    + ',"z":'
                    + line[5]
                    + "}"
                )
                print(line)
                time.sleep(WAIT_TIME)
                maxl += 1
                if maxl > MAX_LINES:
                    break
                i += 1
