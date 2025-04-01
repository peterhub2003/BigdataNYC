#!/bin/bash

DATA_URL="https://mcauleylab.ucsd.edu/public_datasets/data/amazon_2023/raw/review_categories/Kindle_Store.jsonl.gz"

LOCAL_TMP_DIR="./tmp_data"

HDFS_RAW_DIR="/data/raw/amazon_reviews"
DOWNLOAD_FILENAME_GZ=$(basename "$DATA_URL")
DOWNLOAD_FILENAME=$(basename "$DATA_URL" .gz) # Remove .gz extension
HDFS_TARGET_FILE="$HDFS_RAW_DIR/$DOWNLOAD_FILENAME" # Target is the unzipped .jsonl file

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
docker exec namenode hdfs dfs -mkdir -p "$HDFS_RAW_DIR"
if [ $? -ne 0 ]; then echo "Error creating HDFS dir."; rm "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME"; rmdir "$LOCAL_TMP_DIR"; exit 1; fi

echo "Uploading unzipped file $LOCAL_TMP_DIR/$DOWNLOAD_FILENAME to $HDFS_TARGET_FILE..."
cat "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME" | docker exec -i namenode hdfs dfs -put -f - "$HDFS_TARGET_FILE" # Pipe file content into HDFS put
if [ $? -ne 0 ]; then
  echo "Error uploading to HDFS."
  rm "$LOCAL_TMP_DIR/$DOWNLOAD_FILENAME"; rmdir "$LOCAL_TMP_DIR"; exit 1;
else
   echo "File successfully uploaded to HDFS (unzipped)."
fi

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$LOCAL_TMP_DIR"
echo "Local cleanup complete."
echo "Ingestion process finished successfully!"
exit 0