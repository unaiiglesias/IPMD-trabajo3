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

CREATE TABLE es_activity_count (
    sensor        STRING,
    action        STRING,
    cnt           BIGINT,
    window_start  TIMESTAMP(3),
    PRIMARY KEY (sensor, action, window_start) NOT ENFORCED
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts'     = 'http://elasticsearch:9200',
    'index'     = 'activity_count'
);

INSERT INTO es_activity_count
SELECT sensor, action, COUNT(*), TUMBLE_START(proc_time, INTERVAL '1' MINUTE)
FROM dataset GROUP BY sensor, action, TUMBLE(proc_time, INTERVAL '1' MINUTE);

QUIT;