from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, count
import os

pg_host = os.getenv("POSTGRES_HOST", "postgres")
pg_port = os.getenv("POSTGRES_PORT", "5432")
pg_db = os.getenv("POSTGRES_DB", "datawarehouse")
pg_user = os.getenv("POSTGRES_USER", "user")
pg_password = os.getenv("POSTGRES_PASSWORD", "password")

jdbc_url = f"jdbc:postgresql://{pg_host}:{pg_port}/{pg_db}"

# Initialize Spark Session
spark= SparkSession.builder \
    .appName("NYC Yellow Trip Data ETL") \
    .master("spark://spark-master:7077") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.2.22") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.io.compression.codec", "snappy") \
    .config("spark.hadoop.io.compression.codecs", 
            "org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.SnappyCodec") \
    .getOrCreate()


df   = spark.read.parquet("hdfs://namenode:9000/user/hadoop/nyc_yellow_trip_data/*.parquet")

df_processed = df.withColumn("date", to_date(col("tpep_pickup_datetime"))) \
                 .groupBy("date") \
                 .agg(count("*").alias("num_trips"))

df_processed.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", pg_db) \
    .option("user", pg_user) \
    .option("password", pg_password) \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()

spark.stop()