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
# Check if directories exist before creating them
for dir in /data/raw /data/processed /data/curated; do
  if ! docker exec namenode hdfs dfs -test -d $dir 2>/dev/null; then
    echo "Creating directory $dir..."
    docker exec namenode hdfs dfs -mkdir -p $dir
  else
    echo "Directory $dir already exists."
  fi
done
docker exec namenode hdfs dfs -chmod 750 /data/raw /data/processed
docker exec namenode hdfs dfs -chmod 770 /data/curated


echo "Creating Hive warehouse directory..."
docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse
docker exec namenode hdfs dfs -chmod g+w /user/hive/warehouse


echo "Creating Spark logs directory..."
docker exec namenode hdfs dfs -mkdir -p /user/hadoop/spark-logs
docker exec namenode hdfs dfs -chmod g+w /user/hadoop/spark-logs

echo "===== HDFS directories created successfully ====="
docker exec namenode hdfs dfs -ls -R /data
docker exec namenode hdfs dfs -ls /user


./init_scripts/05_setup_nifi_hdfs_dirs.sh