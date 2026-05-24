CREATE TABLE dataset (
    sensor    STRING,
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

INSERT INTO es_dataset SELECT sensor, usid, action, ts, x, y, z FROM dataset;

QUIT;