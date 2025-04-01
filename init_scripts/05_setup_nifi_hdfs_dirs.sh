#!/bin/bash
# Script to setup HDFS directories for NiFi and configure initial flow

set -e  # Exit on any error

echo "===== Setting up HDFS directories for NiFi data ingestion ====="

# Create the base raw data directory
RAW_DATA_DIR="/data/raw"
# echo "Creating base raw data directory: ${RAW_DATA_DIR}"
# docker exec namenode hdfs dfs -mkdir -p ${RAW_DATA_DIR}


echo "Creating data source subdirectories..."
SOURCE_DIRS=(
  "${RAW_DATA_DIR}/nyc_trip"
  "${RAW_DATA_DIR}/web_log"
  "${RAW_DATA_DIR}/amazon_reviews"
  # "${RAW_DATA_DIR}/weather"
)

for DIR in "${SOURCE_DIRS[@]}"; do
  echo "Creating directory: ${DIR}"
  docker exec namenode hdfs dfs -mkdir -p ${DIR}
done


echo "Setting permissions for NiFi..."
docker exec namenode hdfs dfs -chmod -R 777 ${RAW_DATA_DIR}


echo "Listing created directories in HDFS..."
docker exec namenode hdfs dfs -ls -R ${RAW_DATA_DIR}

echo "===== HDFS setup for NiFi complete ====="


echo "Waiting for NiFi to start up completely..."
MAX_WAIT=10  
WAIT_INTERVAL=10 
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  if docker exec nifi curl -s https://localhost:8443/nifi-api/system-diagnostics > /dev/null; then
    echo "NiFi is up and running!"
    break
  else
    echo "Waiting for NiFi to start... (${ELAPSED}s/${MAX_WAIT}s)"
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
  fi
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo "WARNING: Timed out waiting for NiFi. You may need to manually verify NiFi is running."
  echo "Once NiFi is running, access the web UI at https://localhost:8443/nifi to configure your flows."
fi

echo "===== NiFi HDFS directory setup complete ====="
