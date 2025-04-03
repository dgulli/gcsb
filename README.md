# GCSB - Google Cloud Spanner Benchmark

A tool for benchmarking Google Cloud Spanner performance.

## Features

- Configurable workload patterns
- Support for various Spanner configurations
- Real-time metrics and reporting
- Commit delay optimization support
- Easy instance creation and testing setup

## Installation

```bash
go install github.com/cloudspannerecosystem/gcsb@latest
```

## Quick Start

1. Ensure you have the Google Cloud SDK installed and are authenticated:
```bash
# Install Google Cloud SDK if not already installed
# Visit https://cloud.google.com/sdk/docs/install for installation instructions

# Authenticate with Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID
```

2. Create test instances using the provided script:
```bash
chmod +x create_test_instances.sh
./create_test_instances.sh
```

The script will:
- Show available Spanner configurations
- Let you select which configurations to create
- Create instances and databases with test schemas
- Provide example commands for running benchmarks

Available configurations include:
- Single-region (us-central1)
- Multi-region (nam3)
- Dual-region (australia-southeast1+australia-southeast2)
- Both STANDARD and ENTERPRISE versions

2. Create a configuration file (test.yaml):
```yaml
project: your-project-id
instance: your-instance-id
database: your-database-id

# Schema definition
schema: |
  CREATE TABLE TestTable (
    ID STRING(36) NOT NULL,
    Name STRING(MAX),
    Value INT64,
  ) PRIMARY KEY (ID)

# Workload configuration
workload:
  threads: 4
  operations: 1000
  commitDelay: 100ms  # Enable commit delay optimization

  # Table configuration
  tables:
    - name: TestTable
      writeRatio: 1.0
      readRatio: 0.0
      rowCount: 1000

  # Data generation
  data:
    - column: ID
      type: uuid
    - column: Name
      type: string
      length: 100
    - column: Value
      type: int
      min: 1
      max: 1000
```

3. Run the benchmark:
```bash
gcsb --config test.yaml
```

## Configuration Options

### Workload Configuration

- `threads`: Number of concurrent worker threads
- `operations`: Total number of operations to perform
- `commitDelay`: Maximum commit delay for write operations (e.g., "100ms")
- `tables`: List of tables to benchmark
  - `name`: Table name
  - `writeRatio`: Ratio of write operations (0.0 to 1.0)
  - `readRatio`: Ratio of read operations (0.0 to 1.0)
  - `rowCount`: Number of rows to operate on

### Data Generation

- `column`: Column name
- `type`: Data type (uuid, string, int)
- For strings:
  - `length`: Maximum string length
- For integers:
  - `min`: Minimum value
  - `max`: Maximum value

## Performance Optimization

The tool supports commit delay optimization for write operations. This feature:
- Buffers mutations in transactions
- Delays commits to improve throughput
- Reduces the number of round trips to Spanner

To enable commit delay, set the `commitDelay` parameter in your configuration:
```yaml
workload:
  commitDelay: 100ms  # Maximum delay for commits
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
