#!/bin/bash
set -e  # Exit on any error

# --- Configuration ---
STACK_NAME=${1:-hadoop}            # Thay đổi thành tên stack Docker Swarm của bạn
NAMENODE_SERVICE_NAME="namenode" # Tên service Namenode trong docker-compose.yml

# --- Function to get the running container ID for a service ---
get_container_id() {
  local stack_name="$1"
  local service_name="$2"
  docker ps \
    --filter "name=${stack_name}_${service_name}" \
    --format "{{.ID}}" \
    | head -n 1
}

echo "===== Creating HDFS Directory Structure for Swarm Stack: ${STACK_NAME} ====="
echo "Finding Namenode container..."

NAMENODE_CONTAINER_ID=$(get_container_id "$STACK_NAME" "$NAMENODE_SERVICE_NAME")

if [ -z "$NAMENODE_CONTAINER_ID" ]; then
  echo "Lỗi: Không tìm thấy container Namenode (${NAMENODE_SERVICE_NAME}) đang chạy trong stack ${STACK_NAME}!"
  exit 1
fi
echo "Namenode container ID: ${NAMENODE_CONTAINER_ID}"

# --- Wait for HDFS to be ready using the container ID ---
echo "Waiting for HDFS to be available..."
until docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -ls / > /dev/null 2>&1; do
  echo "Waiting for HDFS namenode (${NAMENODE_CONTAINER_ID}) to be ready..."
  sleep 5
done
echo "HDFS is ready!"

# --- Create zone directories using the container ID ---
echo "Creating data zone directories..."

for dir in /data/raw /data/processed /data/curated; do

  if ! docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -test -d $dir 2>/dev/null; then
    echo "Creating directory $dir..."
    docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -mkdir -p $dir
  else
    echo "Directory $dir already exists."
  fi
done

docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -chmod 750 /data/raw /data/processed
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -chmod 770 /data/curated


echo "Creating Hive warehouse directory..."

docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -mkdir -p /user/hive/warehouse
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -chmod g+w /user/hive/warehouse

echo "Creating Spark logs directory..."# 

docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -mkdir -p /user/hadoop/spark-logs
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -chmod g+w /user/hadoop/spark-logs

echo "Creating Spark Staging directory..."

docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -mkdir -p /user/Thang/.sparkStaging
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -chown Thang:supergroup /user/Thang/.sparkStaging
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -chmod g+w /user/Thang/.sparkStaging


docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -ls -R /data
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -ls /user

echo "==================== CREATING HDFS DIRECTORIES finished ========================="




echo "==================== Creating Hive Databases ========================"

NAMENODE_SERVICE_NAME="hive-server"
NAMENODE_CONTAINER_ID=$(get_container_id "$STACK_NAME" "$NAMENODE_SERVICE_NAME")

echo "Waiting for Hive server to be available..."
until docker exec "${NAMENODE_CONTAINER_ID}" beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;" > /dev/null 2>&1; do
  echo "Waiting for Hive server to be ready..."
  sleep 5
done
echo "Hive server is ready!"


echo "Creating Hive databases for each zone..."
docker exec "${NAMENODE_CONTAINER_ID}" beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS raw;"
docker exec "${NAMENODE_CONTAINER_ID}" beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS processed;"
docker exec "${NAMENODE_CONTAINER_ID}" beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS curated;"

echo "Verifying Hive databases..."
docker exec "${NAMENODE_CONTAINER_ID}" beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"

echo "==================== Hive databases created successfully ========================"



