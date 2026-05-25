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
CREATE TABLE es_aemet_provincia_stats (
    provincia STRING,
    window_end STRING,
    num_lecturas BIGINT,
    tmed_promedio DOUBLE,
    prec_acumulada DOUBLE,
    racha_maxima DOUBLE
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts' = 'http://elasticsearch:9200',
    'index' = 'aemet_stats_por_provincia'
);
INSERT INTO es_aemet_provincia_stats
SELECT provincia, DATE_FORMAT(TUMBLE_END(proctime, INTERVAL '1' MINUTE), 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''), COUNT(*) as num_lecturas, AVG(tmed) as tmed_promedio, SUM(COALESCE(prec, 0.0)) as prec_acumulada, MAX(racha) as racha_maxima
FROM aemet
GROUP BY provincia, TUMBLE(proctime, INTERVAL '1' MINUTE);

QUIT;