#!/bin/bash

DATA_URL="https://mcauleylab.ucsd.edu/public_datasets/data/amazon_2023/raw/review_categories/Kindle_Store.jsonl.gz"

LOCAL_TMP_DIR="./tmp_data"

HDFS_RAW_DIR="/data/raw/amazon_reviews"
DOWNLOAD_FILENAME_GZ=$(basename "$DATA_URL")
DOWNLOAD_FILENAME=$(basename "$DATA_URL" .gz) 
HDFS_TARGET_FILE="$HDFS_RAW_DIR/$DOWNLOAD_FILENAME" # Target is the unzipped .jsonl file

STACK_NAME=${1:-hadoop}             # Thay đổi thành tên stack Docker Swarm của bạn
NAMENODE_SERVICE_NAME="namenode" # Tên service Namenode trong docker-compose.yml


get_container_id() {
  local stack_name="$1"
  local service_name="$2"
  docker ps \
    --filter "name=${stack_name}_${service_name}" \
    --format "{{.ID}}" \
    | head -n 1 #
}
NAMENODE_CONTAINER_ID=$(get_container_id "$STACK_NAME" "$NAMENODE_SERVICE_NAME")


echo "Starting ingestion process for Kindle_Store reviews (unzipped)..."
mkdir -p "$LOCAL_TMP_DIR"
echo "Downloading data to $LOCAL_TMP_DIR/$DOWNLOAD_FILENAME_GZ..."
wget -O "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME_GZ" "$DATA_URL"
if [ $? -ne 0 ]; then echo "Error downloading."; rmdir "$LOCAL_TMP_DIR"; exit 1; fi
echo "Download complete."

echo "Unzipping the downloaded file..."
gzip -d "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME_GZ"
if [ $? -ne 0 ]; then echo "Error unzipping."; rm "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME"; rmdir "$LOCAL_TMP_DIR"; exit 1; fi
echo "Unzipping complete. Unzipped file: $LOCAL_TMP_DIR/$DOWNLOAD_FILENAME"

echo "Ensuring HDFS directory exists: $HDFS_RAW_DIR"
docker exec "${NAMENODE_CONTAINER_ID}" hdfs dfs -mkdir -p "$HDFS_RAW_DIR"
if [ $? -ne 0 ]; then echo "Error creating HDFS dir."; rm "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME"; rmdir "$LOCAL_TMP_DIR"; exit 1; fi

echo "Uploading unzipped file $LOCAL_TMP_DIR/$DOWNLOAD_FILENAME to $HDFS_TARGET_FILE..."
cat "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME" | docker exec -i "${NAMENODE_CONTAINER_ID}" hdfs dfs -put -f - "$HDFS_TARGET_FILE" # Pipe file content into HDFS put
if [ $? -ne 0 ]; then
    echo "Error uploading to HDFS."
    rm "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME"; rmdir "$LOCAL_TMP_DIR"; exit 1;
else
    echo "File successfully uploaded to HDFS (unzipped)."
fi



# --- Script for Kindle Store Meta Data (added section) ---
META_DATA_URL="https://mcauleylab.ucsd.edu/public_datasets/data/amazon_2023/raw/meta_categories/meta_Kindle_Store.jsonl.gz"
META_DOWNLOAD_FILENAME_GZ=$(basename "$META_DATA_URL")
META_DOWNLOAD_FILENAME=$(basename "$META_DATA_URL" .gz) # Remove .gz extension
META_HDFS_TARGET_FILE="$HDFS_RAW_DIR/$META_DOWNLOAD_FILENAME" # Target is the unzipped .jsonl file

echo "" # Add an empty line for better separation
echo "Starting ingestion process for meta_Kindle_Store (unzipped)..."
echo "Downloading meta data to $LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME_GZ..."
wget -O "$LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME_GZ" "$META_DATA_URL"
if [ $? -ne 0 ]; then echo "Error downloading meta data."; exit 1; fi
echo "Meta data download complete."

echo "Unzipping the downloaded meta data file..."
gzip -d "$LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME_GZ"
if [ $? -ne 0 ]; then echo "Error unzipping meta data."; rm "$LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME"; exit 1; fi
echo "Meta data unzipping complete. Unzipped file: $LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME"

echo "Uploading unzipped meta data file $LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME to $META_HDFS_TARGET_FILE..."
cat "$LOCAL_TMP_DIR/$META_DOWNLOAD_FILENAME" | docker exec -i "${NAMENODE_CONTAINER_ID}" hdfs dfs -put -f - "$META_HDFS_TARGET_FILE" # Pipe file content into HDFS put
if [ $? -ne 0 ]; then
    echo "Error uploading meta data to HDFS."
    exit 1;
else
    echo "Meta data file successfully uploaded to HDFS (unzipped)."
fi

# Clean up (moved to the end to clean up files from both sections)
echo "Cleaning up temporary files..."
rm -rf "$LOCAL_TMP_DIR"
echo "Local cleanup complete."
echo "Ingestion process finished successfully!"
exit 0