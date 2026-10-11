DROP TABLE IF EXISTS errors_mv;
DROP TABLE IF EXISTS logs_mv;
DROP TABLE IF EXISTS errors_per_minute;
DROP TABLE IF EXISTS app_logs;
DROP TABLE IF EXISTS logs_raw;

CREATE TABLE logs_raw
(
    Timestamp          DateTime64(9),
    TraceId            String,
    SpanId             String,
    TraceFlags         UInt8,
    SeverityText       LowCardinality(String),
    SeverityNumber     UInt8,
    ServiceName        LowCardinality(String),
    Body               String,
    ResourceSchemaUrl  LowCardinality(String),
    ResourceAttributes Map(LowCardinality(String), String),
    ScopeSchemaUrl     LowCardinality(String),
    ScopeName          String,
    ScopeVersion       LowCardinality(String),
    ScopeAttributes    Map(LowCardinality(String), String),
    LogAttributes      Map(LowCardinality(String), String)
)
ENGINE = Null;

CREATE TABLE app_logs
(
    Timestamp   DateTime64(3) CODEC(Delta, ZSTD),
    Service     LowCardinality(String),
    Level       LowCardinality(String),
    Route       LowCardinality(String),
    Status      UInt16,
    DurationMs  UInt32,
    TraceId     String,
    Message     String
)
ENGINE = MergeTree
PARTITION BY toDate(Timestamp)
ORDER BY (Service, Level, Timestamp)
TTL toDateTime(Timestamp) + INTERVAL 7 DAY;

CREATE MATERIALIZED VIEW logs_mv TO app_logs AS
SELECT
    Timestamp,
    if(ServiceName != '', ServiceName, JSONExtractString(Body, 'service'))    AS Service,
    lower(trim(if(SeverityText != '', SeverityText, JSONExtractString(Body, 'level')))) AS Level,
    JSONExtractString(Body, 'route')                                          AS Route,
    toUInt16(JSONExtractUInt(Body, 'status'))                                 AS Status,
    toUInt32(JSONExtractUInt(Body, 'duration_ms'))                            AS DurationMs,
    if(TraceId != '', TraceId, JSONExtractString(Body, 'trace_id'))           AS TraceId,
    if(isValidJSON(Body), JSONExtractString(Body, 'msg'), Body)               AS Message
FROM logs_raw;

CREATE TABLE errors_per_minute
(
    Minute   DateTime,
    Service  LowCardinality(String),
    Errors   UInt64
)
ENGINE = SummingMergeTree
ORDER BY (Service, Minute);

CREATE MATERIALIZED VIEW errors_mv TO errors_per_minute AS
SELECT
    toStartOfMinute(Timestamp) AS Minute,
    Service,
    count()                    AS Errors
FROM app_logs
WHERE Level = 'error'
GROUP BY Minute, Service;
