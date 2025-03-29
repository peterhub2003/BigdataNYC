#!/bin/bash
# Script to create all necessary HDFS directories

set -e  # Exit on any error

echo "===== Creating HDFS Directory Structure ====="

# Wait for HDFS to be ready
echo "Waiting for HDFS to be available..."
until docker exec namenode hdfs dfs -ls / > /dev/null 2>&1; do
  echo "Waiting for HDFS namenode to be ready..."
  sleep 5
done
echo "HDFS is ready!"

# Create zone directories
echo "Creating data zone directories..."
docker exec namenode hdfs dfs -mkdir -p /data/raw /data/processed /data/curated
docker exec namenode hdfs dfs -chmod 750 /data/raw /data/processed
docker exec namenode hdfs dfs -chmod 770 /data/curated

# Create nyc_trip_data directory within raw zone
echo "Creating NYC trip data directory..."
docker exec namenode hdfs dfs -mkdir -p /data/raw/nyc_trip_data
docker exec namenode hdfs dfs -chmod 755 /data/raw/nyc_trip_data

# Create Hive warehouse directory
echo "Creating Hive warehouse directory..."
docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse
docker exec namenode hdfs dfs -chmod g+w /user/hive/warehouse

# Create Spark logs directory
echo "Creating Spark logs directory..."
docker exec namenode hdfs dfs -mkdir -p /user/hadoop/spark-logs
docker exec namenode hdfs dfs -chmod g+w /user/hadoop/spark-logs

echo "===== HDFS directories created successfully ====="
docker exec namenode hdfs dfs -ls -R /data
docker exec namenode hdfs dfs -ls /user
