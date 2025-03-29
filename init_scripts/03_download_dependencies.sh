#!/bin/bash
# Script to download external dependencies and files needed by the stack

set -e  # Exit on any error

echo "===== Downloading Dependencies ====="

# Create jars directory if it doesn't exist
echo "Creating jars directory..."
if [ ! -d "./jars" ]; then
  mkdir -p ./jars
fi

# Download PostgreSQL JDBC driver
echo "Downloading PostgreSQL JDBC driver..."
curl -L https://jdbc.postgresql.org/download/postgresql-42.3.1.jar -o ./jars/postgresql-42.3.1.jar
echo "PostgreSQL JDBC driver installed successfully!"

# Check if we have the driver
if [ -f "./jars/postgresql-42.3.1.jar" ]; then
  echo "JDBC driver download verified successfully."
else
  echo "ERROR: Failed to download JDBC driver!"
  exit 1
fi

echo "===== Dependencies downloaded successfully ====="
