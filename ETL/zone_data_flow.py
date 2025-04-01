#!/usr/bin/env python3
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, year, month, dayofmonth

def main():
    # Initialize Spark Session with Hive support
    spark = SparkSession.builder \
        .appName("HDFS Zone Data Flow Example") \
        .config("spark.sql.warehouse.dir", "hdfs://namenode:9000/user/hive/warehouse") \
        .enableHiveSupport() \
        .getOrCreate()
    
    print("=== Three-Zone Data Architecture Example ===")
    
    # 1. RAW ZONE: Read CSV data (simulating data landing in raw zone)
    print("\n1. Reading data from Raw Zone...")
    try:
        # Check if raw data exists
        raw_data_exists = spark._jvm.org.apache.hadoop.fs.FileSystem.get(spark._jsc.hadoopConfiguration()) \
            .exists(spark._jvm.org.apache.hadoop.fs.Path("/data/raw/nyc_taxi/sales_data.csv"))
        
        if not raw_data_exists:
            print("Raw data not found. Loading sample data...")
            # Create dummy data if no raw data exists
            spark.sql("""
                CREATE TEMPORARY VIEW temp_raw_sales AS
                SELECT * FROM VALUES
                ('2023-01-01', 'Store1', 'Product1', 100.50, 5),
                ('2023-01-01', 'Store2', 'Product2', 200.75, 3),
                ('2023-01-02', 'Store1', 'Product3', 150.25, 2),
                ('2023-01-03', 'Store3', 'Product1', 100.50, 10),
                ('2023-01-04', 'Store2', 'Product2', 200.75, 4)
                AS sales(sale_date, store_id, product_id, price, quantity)
            """)
            
            # Save to raw zone
            raw_df = spark.sql("SELECT * FROM temp_raw_sales")
            raw_df.write.mode("overwrite").option("header", "true").csv("/data/raw/nyc_taxi/sales_data.csv")
            print("Sample data saved to raw zone")
        
        # Read from raw zone
        raw_df = spark.read.option("header", "true").csv("/data/raw/nyc_taxi/sales_data.csv")
        print(f"Raw data sample ({raw_df.count()} records):")
        raw_df.show(3)
        
        # Register as temp view for SQL operations
        raw_df.createOrReplaceTempView("raw_sales")
    
    except Exception as e:
        print(f"Error in Raw Zone processing: {e}")
        raw_df = spark.createDataFrame([], "sale_date STRING, store_id STRING, product_id STRING, price DOUBLE, quantity INT")
        raw_df.createOrReplaceTempView("raw_sales")
    
    # 2. PROCESSED ZONE: Clean and standardize data
    print("\n2. Processing data for Processed Zone...")
    try:
        # Apply transformations:
        # - Convert string date to date type
        # - Handle any missing values
        # - Add derived columns
        processed_df = spark.sql("""
            SELECT 
                to_date(sale_date, 'yyyy-MM-dd') as sale_date,
                store_id,
                product_id,
                CAST(price AS DOUBLE) as unit_price,
                CAST(quantity AS INT) as quantity,
                CAST(price AS DOUBLE) * CAST(quantity AS INT) as total_amount,
                year(to_date(sale_date, 'yyyy-MM-dd')) as year,
                month(to_date(sale_date, 'yyyy-MM-dd')) as month,
                dayofmonth(to_date(sale_date, 'yyyy-MM-dd')) as day
            FROM raw_sales
        """)
        
        # Save to processed zone as Parquet (columnar format)
        processed_df.write.mode("overwrite").partitionBy("year", "month").parquet("/data/processed/nyc_taxi/sales")
        print("Data saved to processed zone in Parquet format with partitioning")
        
        # Create external table in Hive pointing to processed data
        spark.sql("DROP TABLE IF EXISTS processed.sales")
        spark.sql("""
            CREATE DATABASE IF NOT EXISTS processed
        """)
        
        spark.sql("""
            CREATE EXTERNAL TABLE IF NOT EXISTS processed.sales (
                sale_date DATE,
                store_id STRING,
                product_id STRING,
                unit_price DOUBLE,
                quantity INT,
                total_amount DOUBLE,
                day INT
            )
            PARTITIONED BY (year INT, month INT)
            STORED AS PARQUET
            LOCATION '/data/processed/nyc_taxi/sales'
        """)
        
        # Recover partitions that we just wrote
        spark.sql("MSCK REPAIR TABLE processed.sales")
        
        # Show the data from the external table
        print("Processed data from Hive external table:")
        spark.sql("SELECT * FROM processed.sales").show(3)
    
    except Exception as e:
        print(f"Error in Processed Zone processing: {e}")
    
    # 3. CURATED ZONE: Create star schema (fact/dimension tables)
    print("\n3. Creating star schema in Curated Zone...")
    try:
        # Create dimension tables
        spark.sql("CREATE DATABASE IF NOT EXISTS curated")
        
        # Time dimension
        spark.sql("""
            CREATE TABLE IF NOT EXISTS curated.dim_date (
                date_id DATE,
                day INT,
                month INT,
                year INT,
                quarter INT,
                is_weekend BOOLEAN
            )
            STORED AS PARQUET
        """)
        
        # Store dimension
        spark.sql("""
            CREATE TABLE IF NOT EXISTS curated.dim_store (
                store_id STRING,
                store_name STRING,
                region STRING 
            )
            STORED AS PARQUET
        """)
        
        # Product dimension
        spark.sql("""
            CREATE TABLE IF NOT EXISTS curated.dim_product (
                product_id STRING,
                product_name STRING,
                category STRING
            )
            STORED AS PARQUET
        """)
        
        # Fact table
        spark.sql("""
            CREATE TABLE IF NOT EXISTS curated.fact_sales (
                sales_id BIGINT,
                date_id DATE,
                store_id STRING,
                product_id STRING,
                unit_price DOUBLE,
                quantity INT,
                total_amount DOUBLE
            )
            PARTITIONED BY (year INT, month INT)
            STORED AS PARQUET
        """)
        
        # For our example, we'll insert sample data into dimension tables
        # In a real scenario, these would be populated from the processed data with more logic
        
        # Insert sample store data
        spark.sql("""
            INSERT OVERWRITE TABLE curated.dim_store VALUES
            ('Store1', 'Downtown Store', 'East'),
            ('Store2', 'Mall Store', 'West'),
            ('Store3', 'Airport Store', 'North')
        """)
        
        # Insert sample product data
        spark.sql("""
            INSERT OVERWRITE TABLE curated.dim_product VALUES
            ('Product1', 'Basic Widget', 'Widgets'),
            ('Product2', 'Premium Widget', 'Widgets'),
            ('Product3', 'Super Gadget', 'Gadgets')
        """)
        
        # Insert data into fact table from processed zone
        spark.sql("""
            INSERT OVERWRITE TABLE curated.fact_sales
            SELECT 
                CAST(hash(concat(sale_date, store_id, product_id, rand())) AS BIGINT) as sales_id,
                sale_date as date_id,
                store_id,
                product_id,
                unit_price,
                quantity,
                total_amount,
                year,
                month
            FROM processed.sales
        """)
        
        # Display fact table
        print("Curated Zone - Fact table sample:")
        spark.sql("SELECT * FROM curated.fact_sales").show(3)
        
        # Example analytical query joining fact with dimensions
        print("Example analytical query from star schema:")
        spark.sql("""
            SELECT 
                d.product_name,
                s.store_name,
                SUM(f.quantity) as total_quantity,
                SUM(f.total_amount) as total_sales
            FROM 
                curated.fact_sales f
                JOIN curated.dim_product d ON f.product_id = d.product_id
                JOIN curated.dim_store s ON f.store_id = s.store_id
            GROUP BY 
                d.product_name, s.store_name
            ORDER BY 
                total_sales DESC
        """).show()
        
    except Exception as e:
        print(f"Error in Curated Zone processing: {e}")
    
    print("\n=== Three-Zone Data Flow Complete ===")
    
    # Close the session
    spark.stop()

if __name__ == "__main__":
    main()
