CREATE DATABASE IF NOT EXISTS lab;

DROP TABLE IF EXISTS lab.by_service;
DROP TABLE IF EXISTS lab.by_time;

CREATE TABLE lab.by_service AS default.app_logs
ENGINE = MergeTree
PARTITION BY toDate(Timestamp)
ORDER BY (Service, Level, Timestamp);

CREATE TABLE lab.by_time AS default.app_logs
ENGINE = MergeTree
PARTITION BY toDate(Timestamp)
ORDER BY (Timestamp);

INSERT INTO lab.by_service
WITH
    ['api', 'auth', 'payments', 'worker'] AS services,
    services[number % 4 + 1] AS service,
    rand() % 100 AS roll
SELECT
    now64(3) - toIntervalMillisecond(number * 60) AS Timestamp,
    service AS Service,
    multiIf(roll < 2, 'error', roll < 7, 'warn', roll < 95, 'info', 'debug') AS Level,
    multiIf(
        service = 'api',      ['/users', '/orders', '/search', '/health'][rand(1) % 4 + 1],
        service = 'auth',     ['/login', '/logout', '/token/refresh'][rand(1) % 3 + 1],
        service = 'payments', ['/pay', '/refund', '/webhook/stripe'][rand(1) % 3 + 1],
                              ['job:email', 'job:invoice', 'job:cleanup'][rand(1) % 3 + 1]
    ) AS Route,
    multiIf(Level = 'error', 500 + rand(2) % 5, Level = 'warn', 429, 200) AS Status,
    20 + rand(3) % 200 AS DurationMs,
    lower(hex(randomString(16))) AS TraceId,
    multiIf(Level = 'error', 'unexpected error', Level = 'warn', 'client error', 'request ok') AS Message
FROM numbers(10000000);

INSERT INTO lab.by_time SELECT * FROM lab.by_service;

OPTIMIZE TABLE lab.by_service FINAL;
OPTIMIZE TABLE lab.by_time FINAL;
