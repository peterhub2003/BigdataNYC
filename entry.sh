#!/bin/bash
# Main entry script for initializing the big data environment
# This script orchestrates all initialization steps in the correct order

para_sleep=${1:-15}

sleep $para_sleep
set -e  # Exit on any error

# echo "===== INITIALIZING BIG DATA ENVIRONMENT ====="
# echo "Starting time: $(date)"

# # Make all init scripts executable
# chmod +x ./init_scripts/*.sh

# # Step 1: Create HDFS directories
# echo -e "\n\n===== STEP 1: Creating HDFS directories ====="
# ./init_scripts/01_create_hdfs_dirs.sh

# # Step 2: Create Hive databases
# echo -e "\n\n===== STEP 2: Creating Hive databases ====="
# ./init_scripts/02_create_hive_dbs.sh

# # Step 3: Download dependencies
# echo -e "\n\n===== STEP 3: Downloading dependencies ====="
# ./init_scripts/03_download_dependencies.sh

# Step 4: Download and ingest Kindle reviews
echo -e "\n\n===== STEP 4: Downloading and ingesting Kindle reviews ====="
./init_scripts/ingest_kindle_reviews.sh

# Step 5: Verify the environment
echo -e "\n\n===== STEP 5: Verifying environment ====="
echo "Checking HDFS directories..."
docker exec namenode hdfs dfs -ls -R /data | head -n 20

echo "Checking Hive databases..."
docker exec hive-server beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"

echo "Checking Superset database..."
docker exec superset_db psql -U superset -d superset -c "SELECT * FROM ab_user;"

echo -e "\n===== INITIALIZATION COMPLETE ====="
echo "Environment is ready for data processing"
echo "End time: $(date)"
echo -e "\nNext steps:"
echo "1. Connect to Jupyter notebook at http://localhost:8888"
echo "2. Access Spark UI at http://localhost:8080"
echo "3. Monitor YARN jobs at http://localhost:8088"
echo "4. View Hive data with beeline or through Spark SQL"



