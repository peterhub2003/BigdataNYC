#!/bin/bash
# Script to download NYC trip data and upload it to HDFS

set -e  # Exit on any error

# Parse command line arguments
# Default values
START_YEAR=${1:-2024}
END_YEAR=${2:-2024}
START_MONTH=${3:-1}
END_MONTH=${4:-12}

echo "===== Downloading NYC Trip Data ====="
echo "Parameters: Years ${START_YEAR}-${END_YEAR}, Months ${START_MONTH}-${END_MONTH}"

# Create temporary directory for downloads
mkdir -p ./tmp_data

# Set the target directory in HDFS
HDFS_TARGET_DIR="/data/raw/nyc_trip"

# Ensure the HDFS directory exists (should be created by 01_create_hdfs_dirs.sh)
echo "Verifying HDFS target directory exists..."
docker exec namenode hdfs dfs -ls $HDFS_TARGET_DIR || docker exec namenode hdfs dfs -mkdir -p $HDFS_TARGET_DIR

# Function to download and upload one month of data
download_and_upload() {
  YEAR=$1
  MONTH=$2
  
  # Format month with leading zero
  MONTH_PADDED=$(printf "%02d" $MONTH)
  
  # File names and URLs
  FILENAME="yellow_tripdata_${YEAR}-${MONTH_PADDED}.parquet"
  URL="https://d37ci6vzurychx.cloudfront.net/trip-data/${FILENAME}"
  LOCAL_PATH="./tmp_data/${FILENAME}"
  
  echo "Downloading: ${URL}"
  
  # Download the file
  if curl -L --fail ${URL} -o ${LOCAL_PATH}; then
    echo "Download successful: ${FILENAME}"
    
    # Upload to HDFS
    echo "Uploading to HDFS: ${HDFS_TARGET_DIR}/${FILENAME}"
    docker exec -i namenode bash -c "hdfs dfs -put -f - ${HDFS_TARGET_DIR}/${FILENAME}" < ${LOCAL_PATH}
    
    # Verify upload
    if docker exec namenode hdfs dfs -test -e "${HDFS_TARGET_DIR}/${FILENAME}"; then
      echo "Upload successful: ${HDFS_TARGET_DIR}/${FILENAME}"
      # Clean up local file
      rm ${LOCAL_PATH}
    else
      echo "Upload failed: ${HDFS_TARGET_DIR}/${FILENAME}"
    fi
  else
    echo "Download failed or file doesn't exist: ${URL}"
  fi
}

# Download selected data to limit time and storage
# For a real environment with sufficient storage, you could download all years
echo "Downloading sample NYC trip data..."

# Download data for the specified year and month ranges
for YEAR in $(seq $START_YEAR $END_YEAR); do
  for MONTH in $(seq $START_MONTH $END_MONTH); do
    download_and_upload $YEAR $MONTH
  done
done


# Clean up
echo "Cleaning up temporary files..."
rm -rf ./tmp_data

# List uploaded files
echo "Listing files in HDFS..."
docker exec namenode hdfs dfs -ls $HDFS_TARGET_DIR

echo "===== NYC Trip Data download and upload complete ====="
