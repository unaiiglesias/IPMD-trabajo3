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

CREATE TABLE es_signal_stats (
    sensor        STRING,
    action        STRING,
    avg_magnitude DOUBLE,
    sma           DOUBLE,
    std_x         DOUBLE,
    std_y         DOUBLE,
    std_z         DOUBLE,
    range_x       DOUBLE,
    range_y       DOUBLE,
    range_z       DOUBLE,
    unique_users  BIGINT,
    sample_cnt    BIGINT,
    window_start  TIMESTAMP(3),
    PRIMARY KEY (sensor, action, window_start) NOT ENFORCED
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts'     = 'http://elasticsearch:9200',
    'index'     = 'signal_stats'
);



INSERT INTO es_signal_stats
SELECT sensor, action, AVG(SQRT(x*x + y*y + z*z)), AVG((ABS(x) + ABS(y) + ABS(z)) / 3), STDDEV_POP(x), STDDEV_POP(y), STDDEV_POP(z), MAX(x) - MIN(x), MAX(y) - MIN(y), MAX(z) - MIN(z), COUNT(DISTINCT usid), COUNT(*), TUMBLE_START(proc_time, INTERVAL '1' MINUTE)
FROM dataset GROUP BY sensor, action, TUMBLE(proc_time, INTERVAL '1' MINUTE);

QUIT;