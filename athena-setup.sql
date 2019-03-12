CREATE DATABASE aws_wrk_athena;

CREATE EXTERNAL TABLE IF NOT EXISTS aws_wrk_athena.results (
         `parameters.test_id` string,
         `parameters.test_case` string,
         `parameters.web_framework` string,
         `parameters.execution_time` string,
         `parameters.connections` int,
         `parameters.duration_seconds` int,
         `parameters.num_threads` int,
         `metadata.web_server.ami_id` string,
         `metadata.web_server.instance_id` string,
         `metadata.web_server.instance_type` string,
         `metadata.web_server.hostname` string,
         `metadata.web_server.local_hostname` string,
         `metadata.web_server.local_ipv4` string,
         `metadata.web_server.public_hostname` string,
         `metadata.web_server.public_ipv4` string,
         `metadata.wrk.ami_id` string,
         `metadata.wrk.instance_id` string,
         `metadata.wrk.instance_type` string,
         `metadata.wrk.hostname` string,
         `metadata.wrk.local_hostname` string,
         `metadata.wrk.local_ipv4` string,
         `metadata.wrk.public_hostname` string,
         `metadata.wrk.public_ipv4` string,
         `summary.duration.microseconds` int,
         `summary.num_requests` int,
         `summary.total_bytes` int,
         `summary.requests_per_sec` double,
         `summary.bytes_per_sec` double,
         `summary.errors.connect` int,
         `summary.errors.read` int,
         `summary.errors.write` int,
         `summary.errors.status` int,
         `summary.errors.timeout` int,
         `latency.min.microseconds` double,
         `latency.max.microseconds` double,
         `latency.mean.microseconds` double,
         `latency.stdev.microseconds` double,
         `latency.10percentile.microseconds` double,
         `latency.20percentile.microseconds` double,
         `latency.30percentile.microseconds` double,
         `latency.40percentile.microseconds` double,
         `latency.50percentile.microseconds` double,
         `latency.60percentile.microseconds` double,
         `latency.70percentile.microseconds` double,
         `latency.80percentile.microseconds` double,
         `latency.90percentile.microseconds` double,
         `latency.95percentile.microseconds` double,
         `latency.99percentile.microseconds` double 
) 
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
         'serialization.format' = '1' 
) LOCATION 's3://samplebucket-richardimaoka-sample-sample/aggregated/' TBLPROPERTIES ('has_encrypted_data'='false');