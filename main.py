from pyspark.sql import SparkSession
from pyspark.sql.functions import count

# Create a SparkSession in local mode
spark = SparkSession.builder \
    .appName("Local PySpark Test Without HDFS") \
    .master("local[*]") \
    .getOrCreate()

# -----------------------------
# Read Parquet data from the local filesystem
# -----------------------------
# Assume you have a Parquet file (or multiple files) locally. 
# For example, if your Parquet files are in the ./data directory:
local_parquet_path = "/teamspace/studios/this_studio/docker-hadoop/nyc_trip_data/yellow_tripdata_2020-01.parquet"
df = spark.read.parquet(local_parquet_path)

# Display the schema and first few rows
df.printSchema()
df.show(5)

# -----------------------------
# Data Aggregation Example
# -----------------------------
# Example: Count total records
total_records = df.count()
print(f"Total number of records: {total_records}")

# Optional: Group by a column (e.g., 'vendor_id' if present)
if "vendor_id" in df.columns:
    agg_df = df.groupBy("vendor_id").agg(count("*").alias("trip_count"))
    agg_df.show()
else:
    from pyspark.sql import Row
    agg_df = spark.createDataFrame([Row(metric="TotalRecords", value=total_records)])
    agg_df.show()

# Optionally, write output to a local folder (e.g., as Parquet or CSV)
output_path = "file:///path/to/your/output/dir"
agg_df.write.mode("overwrite").parquet(output_path)
print("Aggregated data written to local output folder.")

# Stop the SparkSession
spark.stop()
