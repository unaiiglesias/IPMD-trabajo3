-- NOTA: este fichero solo funcionaría para versiones más modernas de flink...

-- ####################################################################
-- Generamos las tablas correspondientes a cada topic de Kafka en Flink
-- ####################################################################

-- Tabla con la información del accelerómetro de los teléfonos 
CREATE TABLE dataset (
    sensor STRING,
    usid      INT,
    action    STRING,
    ts        BIGINT,
    x         DOUBLE,
    y         DOUBLE,
    z         DOUBLE,
    proc_time AS PROCTIME()
) WITH (
    'connector' = 'kafka',
    'topic' = 'smart',
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json'
);
 
-- #################################################################
-- Guardamos el contenido de las tablas anteriores en Elastic Search
-- #################################################################

CREATE TABLE es_dataset (
    sensor STRING,
    usid   INT,
    action STRING,
    ts     BIGINT,
    x      DOUBLE,
    y      DOUBLE,
    z      DOUBLE
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts' = 'http://elasticsearch:9200',
    'index' = 'data'
);
 

-- ######################################################################
-- Guardaremos información derivada de los datos crudos en Elastic Search
-- ######################################################################


-- (1) Contar el número de veces que se realiza cada actividad en una ventana de 1 minuto.

CREATE TABLE es_activity_count (
    sensor        STRING,
    action        STRING,
    cnt           BIGINT,
    window_start  TIMESTAMP(3)
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts'     = 'http://elasticsearch:9200',
    'index'     = 'activity_count'
);


-- (2) Tabla con distintas métricas derivadas de los datos (ventana de 1 minuto)
-- NOTA: guardamos también el tipo de sensor que ha captado la actividad,
--       para en Kibana poder distinguir el origen

CREATE TABLE es_signal_stats (
    sensor        STRING,
    action        STRING,
    -- Magnitud media del vector (accel: m/s² |  gyro: rad/s)
    avg_magnitude DOUBLE,
    -- Signal Magnitude Area: área de magnitud de la señal
    sma           DOUBLE,
    -- Desviación típica por eje
    std_x         DOUBLE,
    std_y         DOUBLE,
    std_z         DOUBLE,
    -- Rango (max - min) por eje: amplitud
    range_x       DOUBLE,
    range_y       DOUBLE,
    range_z       DOUBLE,
    -- Extra
    unique_users  BIGINT,
    sample_cnt    BIGINT,
    window_start  TIMESTAMP(3)
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts'     = 'http://elasticsearch:9200',
    'index'     = 'signal_stats'
);
 

-- Flink solo permite una instrucción INSERT, pues al ser entrada en streaming, es bloqueante.
-- Para arreglarlo, metemos todo en un statemente y listo.
BEGIN STATEMENT SET;

INSERT INTO es_dataset
SELECT sensor, usid, action, ts, x, y, z FROM dataset;

INSERT INTO es_activity_count
SELECT sensor, action, COUNT(*),
       TUMBLE_START(proc_time, INTERVAL '1' MINUTE)
FROM dataset
GROUP BY sensor, action, TUMBLE(proc_time, INTERVAL '1' MINUTE);

INSERT INTO es_signal_stats
SELECT
    sensor,
    action,
    AVG(SQRT(x*x + y*y + z*z)),
    AVG((ABS(x) + ABS(y) + ABS(z)) / 3),
    STDDEV_POP(x),
    STDDEV_POP(y),
    STDDEV_POP(z),
    MAX(x) - MIN(x),
    MAX(y) - MIN(y),
    MAX(z) - MIN(z),
    COUNT(DISTINCT usid),
    COUNT(*),
    TUMBLE_START(proc_time, INTERVAL '1' MINUTE)
FROM dataset
GROUP BY sensor, action, TUMBLE(proc_time, INTERVAL '1' MINUTE);

END;