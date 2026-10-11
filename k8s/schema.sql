CREATE TABLE IF NOT EXISTS logs_raw ON CLUSTER main
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

CREATE TABLE IF NOT EXISTS app_logs ON CLUSTER main
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
ENGINE = ReplicatedMergeTree
PARTITION BY toDate(Timestamp)
ORDER BY (Service, Level, Timestamp)
TTL toDateTime(Timestamp) + INTERVAL 3 DAY TO VOLUME 'cold',
    toDateTime(Timestamp) + INTERVAL 30 DAY DELETE
SETTINGS storage_policy = 'hot_cold';

CREATE MATERIALIZED VIEW IF NOT EXISTS logs_mv ON CLUSTER main TO app_logs AS
SELECT
    Timestamp,
    ServiceName                                    AS Service,
    lower(SeverityText)                            AS Level,
    JSONExtractString(Body, 'route')               AS Route,
    toUInt16(JSONExtractUInt(Body, 'status'))      AS Status,
    toUInt32(JSONExtractUInt(Body, 'duration_ms')) AS DurationMs,
    JSONExtractString(Body, 'trace_id')            AS TraceId,
    JSONExtractString(Body, 'msg')                 AS Message
FROM logs_raw;

CREATE TABLE IF NOT EXISTS errors_per_minute ON CLUSTER main
(
    Minute   DateTime,
    Service  LowCardinality(String),
    Errors   UInt64
)
ENGINE = ReplicatedSummingMergeTree
ORDER BY (Service, Minute);

CREATE MATERIALIZED VIEW IF NOT EXISTS errors_mv ON CLUSTER main TO errors_per_minute AS
SELECT
    toStartOfMinute(Timestamp) AS Minute,
    Service,
    count()                    AS Errors
FROM app_logs
WHERE Level = 'error'
GROUP BY Minute, Service;
