#!/bin/bash

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "Google Cloud SDK is not installed. Please install it first."
    exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "Please authenticate with gcloud first:"
    echo "gcloud auth login"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "No project ID set. Please set your project ID:"
    echo "gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using project: $PROJECT_ID"

# Update the YAML file with the current project ID
sed -i '' "s/project: your-project-id/project: $PROJECT_ID/" dual_region_test.yaml

# Create the dual-region instance with a valid name
echo "Creating instance..."
INSTANCE_NAME="test-dual-region-$(date +%Y%m%d)"
DB_NAME="testdb-dual-region"

# Check if instance exists
if gcloud spanner instances describe $INSTANCE_NAME --project=$PROJECT_ID &>/dev/null; then
    echo "Instance $INSTANCE_NAME already exists. Using existing instance."
else
    echo "Creating new instance $INSTANCE_NAME..."
    gcloud spanner instances create $INSTANCE_NAME \
        --config=dual-region-australia1 \
        --description="Dual-region test" \
        --processing-units=100 \
        --project=$PROJECT_ID \
        --edition=ENTERPRISE_PLUS

    # Wait for instance to be ready
    echo "Waiting for instance to be ready..."
    sleep 30
fi

# Check if database exists
if gcloud spanner databases describe $DB_NAME --instance=$INSTANCE_NAME --project=$PROJECT_ID &>/dev/null; then
    echo "Database $DB_NAME already exists. Using existing database."
else
    echo "Creating database $DB_NAME..."
    gcloud spanner databases create $DB_NAME \
        --instance=$INSTANCE_NAME \
        --database-dialect=GOOGLE_STANDARD_SQL \
        --project=$PROJECT_ID

    # Apply the schema
    echo "Applying schema..."
    SCHEMA_DDL=$(grep -A 1000 'schema: |' dual_region_test.yaml | tail -n +2 | sed 's/^  //' | sed '/^workload:/q' | sed '$d')
    gcloud spanner databases ddl update $DB_NAME \
        --instance=$INSTANCE_NAME \
        --ddl="$SCHEMA_DDL" \
        --project=$PROJECT_ID
fi

# Run initial data load
echo "Loading initial data..."
./gcsb load --config dual_region_test.yaml --project=$PROJECT_ID --instance=$INSTANCE_NAME --database=$DB_NAME -t TestTable

# Run the benchmark
echo "Starting benchmark..."
RESULTS_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).txt"
./gcsb run --config dual_region_test.yaml --project=$PROJECT_ID --instance=$INSTANCE_NAME --database=$DB_NAME -t TestTable | tee $RESULTS_FILE

echo "Test completed!"
echo "Instance: $INSTANCE_NAME"
echo "Database: $DB_NAME"
echo "Results saved to: $RESULTS_FILE"
echo "You can view the results in the Cloud Console:"
echo "https://console.cloud.google.com/spanner/instances/$INSTANCE_NAME/databases/$DB_NAME/overview?project=$PROJECT_ID" 