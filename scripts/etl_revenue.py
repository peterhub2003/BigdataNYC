from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, avg, sum, count
from pyspark.sql.types import IntegerType, DecimalType
import os

# PostgreSQL connection settings
pg_host = os.getenv("POSTGRES_HOST", "postgres")
pg_port = os.getenv("POSTGRES_PORT", "5432")
pg_db = os.getenv("POSTGRES_DB", "datawarehouse")
pg_user = os.getenv("POSTGRES_USER", "user")
pg_password = os.getenv("POSTGRES_PASSWORD", "password")
jdbc_url = f"jdbc:postgresql://{pg_host}:{pg_port}/{pg_db}"

# Initialize Spark session
spark = SparkSession.builder \
    .appName("Revenue ETL") \
    .master("spark://spark-master:7077") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.2.22") \
    .getOrCreate()

# Load data from HDFS
df = spark.read.parquet("hdfs://namenode:9000/user/hadoop/nyc_yellow_trip_data/*.parquet")

# Transform: Aggregate revenue metrics
fact_revenue = df.withColumn("date", to_date(col("tpep_pickup_datetime"))) \
    .withColumn("payment_type_id", col("Payment_type").cast(IntegerType())) \
    .groupBy("date", "payment_type_id") \
    .agg(
        sum(col("Fare_amount").cast(DecimalType(10, 2))).alias("total_fare"),
        sum(col("Tip_amount").cast(DecimalType(10, 2))).alias("total_tips"),
        avg(col("Fare_amount").cast(DecimalType(10, 2))).alias("avg_fare_per_trip"),
        count("*").alias("transaction_count")
    )

# Dimension table: Payment types (from NYC TLC data dictionary)
dim_payment_type_data = [
    (1, "Credit Card"),
    (2, "Cash"),
    (3, "No Charge"),
    (4, "Dispute"),
    (5, "Unknown"),
    (6, "Voided Trip")
]
dim_payment_type = spark.createDataFrame(dim_payment_type_data, ["payment_type_id", "payment_desc"])

# Save dimension table to PostgreSQL
dim_payment_type.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "dim_payment_type") \
    .option("user", pg_user) \
    .option("password", pg_password) \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

# Save fact table to PostgreSQL
fact_revenue.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "fact_revenue") \
    .option("user", pg_user) \
    .option("password", pg_password) \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .partitionBy("date") \
    .save()

# Stop Spark session
spark.stop()