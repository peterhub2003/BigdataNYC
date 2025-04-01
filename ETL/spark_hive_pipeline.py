#!/usr/bin/env python3
"""
Spark script to demonstrate Hadoop/Spark/Hive integration
This script:
1. Reads sales data from HDFS
2. Performs basic transformations
3. Creates Hive tables
4. Runs Hive queries
"""
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as spark_sum, avg, count, month, year, desc

def create_spark_session():
    """Create a Spark session with Hive support"""
    return (SparkSession.builder
            .appName("Hadoop-Spark-Hive Pipeline")
            .config("spark.sql.warehouse.dir", "hdfs://namenode:9000/user/hive/warehouse")
            .enableHiveSupport()
            .getOrCreate())

def load_data_from_hdfs(spark, hdfs_path):
    """Load data from HDFS"""
    print(f"Loading data from {hdfs_path}")
    return spark.read.csv(hdfs_path, header=True, inferSchema=True)

def analyze_sales_data(df):
    """Perform basic analysis on sales data"""
    print("Data Schema:")
    df.printSchema()
    
    print("\nSample Data:")
    df.show(5, truncate=False)
    
    print("\nTotal Records:", df.count())
    
    # Sales by category
    print("\nSales by Category:")
    df.groupBy("category") \
      .agg(spark_sum("total").alias("total_sales"),
           count("*").alias("num_transactions"),
           avg("total").alias("avg_sale")) \
      .orderBy(desc("total_sales")) \
      .show()
    
    # Sales by store
    print("\nSales by Store:")
    df.groupBy("store_name", "city", "state") \
      .agg(spark_sum("total").alias("total_sales")) \
      .orderBy(desc("total_sales")) \
      .show()
    
    # Monthly sales trend
    print("\nMonthly Sales Trend:")
    df.withColumn("month", month("sale_date")) \
      .withColumn("year", year("sale_date")) \
      .groupBy("year", "month") \
      .agg(spark_sum("total").alias("monthly_sales")) \
      .orderBy("year", "month") \
      .show()

def create_hive_tables(spark, df):
    """Create Hive tables from DataFrame"""
    # Create a temporary view
    df.createOrReplaceTempView("sales_temp")
    
    # Create a Hive table
    print("\nCreating Hive table 'sales'...")
    spark.sql("""
    CREATE TABLE IF NOT EXISTS sales (
        sale_id INT,
        sale_date DATE,
        product_id INT,
        product_name STRING,
        category STRING,
        price DOUBLE,
        quantity INT,
        total DOUBLE,
        store_id INT,
        store_name STRING,
        city STRING,
        state STRING,
        payment_method STRING
    )
    STORED AS PARQUET
    """)
    
    # Insert data into Hive table
    print("Inserting data into Hive table...")
    spark.sql("""
    INSERT OVERWRITE TABLE sales
    SELECT * FROM sales_temp
    """)
    
    # Create aggregated tables
    print("\nCreating aggregated tables...")
    
    # Sales by category
    spark.sql("""
    CREATE TABLE IF NOT EXISTS sales_by_category AS
    SELECT 
        category,
        SUM(total) as total_sales,
        COUNT(*) as num_transactions,
        AVG(total) as avg_sale
    FROM sales
    GROUP BY category
    ORDER BY total_sales DESC
    """)
    
    # Sales by store
    spark.sql("""
    CREATE TABLE IF NOT EXISTS sales_by_store AS
    SELECT 
        store_name,
        city,
        state,
        SUM(total) as total_sales
    FROM sales
    GROUP BY store_name, city, state
    ORDER BY total_sales DESC
    """)

def run_hive_queries(spark):
    """Run sample Hive queries"""
    print("\nRunning Hive queries...")
    
    print("\nTop 5 selling products:")
    spark.sql("""
    SELECT 
        product_name,
        SUM(total) as total_sales,
        SUM(quantity) as units_sold
    FROM sales
    GROUP BY product_name
    ORDER BY total_sales DESC
    LIMIT 5
    """).show()
    
    print("\nSales by payment method:")
    spark.sql("""
    SELECT 
        payment_method,
        COUNT(*) as num_transactions,
        SUM(total) as total_sales,
        AVG(total) as avg_sale
    FROM sales
    GROUP BY payment_method
    ORDER BY total_sales DESC
    """).show()
    
    print("\nTop selling category by store:")
    spark.sql("""
    WITH ranked_categories AS (
        SELECT 
            store_name,
            category,
            SUM(total) as category_sales,
            RANK() OVER (PARTITION BY store_name ORDER BY SUM(total) DESC) as rank
        FROM sales
        GROUP BY store_name, category
    )
    SELECT 
        store_name,
        category,
        category_sales
    FROM ranked_categories
    WHERE rank = 1
    ORDER BY category_sales DESC
    """).show()

def main():
    """Main function"""
    spark = create_spark_session()
    
    # Path to the sales data in HDFS
    hdfs_path = "hdfs://namenode:9000/user/hadoop/sales_data/sales_data.csv"
    
    # Load data
    sales_df = load_data_from_hdfs(spark, hdfs_path)
    
    # Analyze data
    analyze_sales_data(sales_df)
    
    # Create Hive tables
    create_hive_tables(spark, sales_df)
    
    # Run Hive queries
    run_hive_queries(spark)
    
    spark.stop()

if __name__ == "__main__":
    main()
