#!/bin/bash
echo "Downloading PostgreSQL JDBC driver..."
mkdir -p ./spark-jars
curl -L https://jdbc.postgresql.org/download/postgresql-42.3.1.jar -o ./spark-jars/postgresql-42.3.1.jar

echo "Copying driver to Spark master and workers..."
docker cp ./spark-jars/postgresql-42.3.1.jar spark-master:/opt/bitnami/spark/jars/
docker cp ./spark-jars/postgresql-42.3.1.jar spark-worker1:/opt/bitnami/spark/jars/
docker cp ./spark-jars/postgresql-42.3.1.jar spark-worker2:/opt/bitnami/spark/jars/

echo "PostgreSQL JDBC driver installed successfully!"


mkdir -p nyc_trip_data
echo "Downloading NYC trip data..."
# Loop through years 2020 to 2023 and all 12 months
for year in {2020..2023}; do
    for month in {01..12}; do
        url="https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_${year}-${month}.parquet"
        echo "Downloading ${url}"
        curl -o "nyc_trip_data/yellow_tripdata_${year}-${month}.parquet" "$url" || echo "Failed to download ${url} (might not exist)"
    done
done


echo "Uploading data to HDFS..."
docker exec -it namenode bash -c "hdfs dfs -mkdir -p /user/hadoop/nyc_yellow_trip_data"
docker exec -it namenode bash -c "hdfs dfs -put /nyc_trip_data/*.parquet /user/hadoop/nyc_yellow_trip_data"

echo "Data downloaded and uploaded to HDFS successfully!"

echo "Listing files in HDFS..."
docker exec -it namenode bash -c "hdfs dfs -ls /user/hadoop/nyc_yellow_trip_data | head -n 3"

echo "Create folder spark-logs in hdfs"
docker exec -it namenode bash -c "hdfs dfs -mkdir -p /spark-logs"