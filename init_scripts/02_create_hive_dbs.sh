#!/bin/bash
# Script to create Hive databases for the 3-zone architecture

set -e  # Exit on any error

echo "===== Creating Hive Databases ====="
# ./init_scripts/init-databases.sh


echo "Waiting for Hive server to be available..."
until docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;" > /dev/null 2>&1; do
  echo "Waiting for Hive server to be ready..."
  sleep 5
done
echo "Hive server is ready!"


echo "Creating Hive databases for each zone..."
docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS raw;"
docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS processed;"
docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS curated;"

echo "Verifying Hive databases..."
docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"

echo "===== Hive databases created successfully ====="


