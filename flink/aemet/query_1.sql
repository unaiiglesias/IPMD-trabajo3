CREATE TABLE aemet (
    indicativo STRING,
    nombre STRING,
    provincia STRING,
    altitud INT,
    tmed DOUBLE,
    prec DOUBLE,
    dir INT,
    velmedia DOUBLE,
    racha DOUBLE,
    hrmedia INT,
    sol DOUBLE,
    proctime AS PROCTIME()
) WITH (
    'connector' = 'kafka',
    'topic' = 'aemet',
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json'
);

CREATE TABLE es_aemet (
    indicativo STRING,
    nombre STRING,
    provincia STRING,
    altitud INT,
    tmed DOUBLE,
    prec DOUBLE,
    dir INT,
    velmedia DOUBLE,
    racha DOUBLE,
    hrmedia INT,
    sol DOUBLE,
    ts STRING
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts' = 'http://elasticsearch:9200',
    'index' = 'aemet'
);

INSERT INTO es_aemet
SELECT indicativo, nombre, provincia, altitud, tmed, prec, dir, velmedia, racha, hrmedia, sol, DATE_FORMAT(CURRENT_TIMESTAMP, 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''')
FROM aemet;

QUIT;