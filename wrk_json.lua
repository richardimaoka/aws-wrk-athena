-- example script for creating json file report
-- https://github.com/wg/wrk/blob/master/SCRIPTING

function done(summary, latency, requests)
  file = io.open('result_intermediate.json', 'w')
  io.output(file)

  io.write(string.format("{\n"))

  io.write(string.format("\"summary.duration.microseconds\": %d,\n",      summary.duration))
  io.write(string.format("\"summary.num_requests\":          %d,\n",      summary.requests))
  io.write(string.format("\"summary.total_bytes\":           %d,\n",      summary.bytes))
  io.write(string.format("\"summary.requests_per_sec\":      %.2f,\n",    summary.requests/(summary.duration)))
  io.write(string.format("\"summary.bytes_per_sec\":         \"%.2f\"\n", summary.bytes/summary.duration))
  
  io.write(string.format("\"summary.errors.connect\": %d,\n", summary.errors.connect))
  io.write(string.format("\"summary.errors.read\":    %d,\n", summary.errors.read))
  io.write(string.format("\"summary.errors.write\":   %d,\n", summary.errors.write))
  io.write(string.format("\"summary.errors.status\":  %d,\n", summary.errors.status))
  io.write(string.format("\"summary.errors.timeout\": %d,\n", summary.errors.timeout))

  io.write(string.format("\"latency.min.microseconds\":          %.2f,\n", latency.min))
  io.write(string.format("\"latency.max.microseconds\":          %.2f,\n", latency.max))
  io.write(string.format("\"latency.mean.microseconds\":         %.2f,\n", latency.mean))
  io.write(string.format("\"latency.stdev.microseconds\":        %.2f,\n", latency.stdev))
  io.write(string.format("\"latency.10percentile.microseconds\": %.2f,\n", latency:percentile(10.0)))
  io.write(string.format("\"latency.20percentile.microseconds\": %.2f,\n", latency:percentile(20.0)))
  io.write(string.format("\"latency.30percentile.microseconds\": %.2f,\n", latency:percentile(30.0)))
  io.write(string.format("\"latency.40percentile.microseconds\": %.2f,\n", latency:percentile(40.0)))
  io.write(string.format("\"latency.50percentile.microseconds\": %.2f,\n", latency:percentile(50.0)))
  io.write(string.format("\"latency.60percentile.microseconds\": %.2f,\n", latency:percentile(60.0)))
  io.write(string.format("\"latency.70percentile.microseconds\": %.2f,\n", latency:percentile(70.0)))
  io.write(string.format("\"latency.80percentile.microseconds\": %.2f,\n", latency:percentile(80.0)))
  io.write(string.format("\"latency.90percentile.microseconds\": %.2f,\n", latency:percentile(90.0)))
  io.write(string.format("\"latency.95percentile.microseconds\": %.2f,\n", latency:percentile(95.0)))
  io.write(string.format("\"latency.99percentile.microseconds\": %.2f\n",  latency:percentile(99.0)))
  
  io.write(string.format("}\n"))
end