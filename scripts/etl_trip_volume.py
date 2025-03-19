from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, dayofweek, month, quarter, year, count
from pyspark.sql.types import DateType, IntegerType
import os

# Environment variables for PostgreSQL
pg_host = os.getenv("POSTGRES_HOST", "postgres")
pg_port = os.getenv("POSTGRES_PORT", "5432")
pg_db = os.getenv("POSTGRES_DB", "datawarehouse")
pg_user = os.getenv("POSTGRES_USER", "user")
pg_password = os.getenv("POSTGRES_PASSWORD", "password")

jdbc_url = f"jdbc:postgresql://{pg_host}:{pg_port}/{pg_db}"

# Initialize Spark Session
spark = SparkSession.builder \
    .appName("Trip Volume and Temporal Trends ETL") \
    .master("spark://spark-master:7077") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.2.22") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.io.compression.codec", "snappy") \
    .config("spark.hadoop.io.compression.codecs", "org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.SnappyCodec") \
    .getOrCreate()

# Load data from HDFS
df = spark.read.parquet("hdfs://namenode:9000/user/hadoop/nyc_yellow_trip_data/*.parquet")

# ETL Process: Aggregate trip counts by date and derive temporal metrics
df_processed = df.withColumn("date", to_date(col("tpep_pickup_datetime"))) \
    .groupBy("date") \
    .agg(count("*").alias("total_trips")) \
    .withColumn("day_of_week", dayofweek(col("date")).cast(IntegerType())) \
    .withColumn("month", month(col("date")).cast(IntegerType())) \
    .withColumn("quarter", quarter(col("date")).cast(IntegerType())) \
    .withColumn("year", year(col("date")).cast(IntegerType()))

# Create dim_time (Dimension Table)
dim_time = df_processed.select("date", "day_of_week", "month", "quarter", "year").distinct()

# Save dim_time to PostgreSQL
dim_time.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "dim_time") \
    .option("user", pg_user) \
    .option("password", pg_password) \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

# Save fact_trip_volume to PostgreSQL
fact_trip_volume = df_processed.select("date", "day_of_week", "month", "quarter", "year", "total_trips")
fact_trip_volume.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "fact_trip_volume") \
    .option("user", pg_user) \
    .option("password", pg_password) \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .partitionBy("date") \
    .save()

# Stop Spark session
spark.stop()