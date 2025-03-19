# Big Data Processing Pipeline with HDFS, Spark, and PostgreSQL

This project sets up a complete big data processing environment using Docker containers for:
- Hadoop HDFS (for distributed storage)
- Apache Spark (for data processing)
- PostgreSQL (for data warehousing)

## Architecture Overview

The system consists of the following components:
- **HDFS Cluster**: Namenode and multiple datanodes for distributed storage
- **YARN**: Resource Manager and Node Managers for resource allocation
- **Spark Cluster**: Master and worker nodes for distributed processing
- **PostgreSQL**: Database for storing processed data
- **Monitoring**: Prometheus and Grafana for system monitoring


## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd big-data
```

### 2. Start the Services

Launch all services defined in the docker-compose.yml file:

```bash
docker-compose up -d
```

This will start the following containers:
- HDFS Namenode and Datanodes
- YARN ResourceManager and NodeManagers
- Spark Master and Workers
- PostgreSQL database
- Prometheus and Grafana for monitoring

After run `docker-compose up -d`, you must to wait for all services change from healthy:starting to healthy. You can check the status of the containers with `docker ps`.
### 3. Download Data and Initialize Components

Run the download script to:
- Download the PostgreSQL JDBC driver
- Download NYC yellow taxi trip data
- Upload the data to HDFS
- Create necessary directories in HDFS

```bash
./download.sh
```

### 4. Configure Environment Variables

The system uses two environment files:
- `hadoop.env`: Configuration for Hadoop components
- `postgres.env`: Configuration for PostgreSQL and connection details

Ensure the PostgreSQL environment variables in `postgres.env` are set correctly:
```
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=datawarehouse
```

### 5. Run the ETL Process

Execute the ETL script using spark-submit:

```bash
docker exec -it spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.postgresql:postgresql:42.2.22 \
  /scripts/etl_script.py
```

Alternatively, you can run available ETL scripts examples:
```bash
docker exec -it spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.postgresql:postgresql:42.2.22 \
  /scripts/etl_revenue.py
```

```bash
docker exec -it spark-master spark-submit \
  --master spark://spark-master:7077 \
  --packages org.postgresql:postgresql:42.2.22 \
  /scripts/etl_trip_volume.py
```

You can define another ETL script in the `scripts` directory and run it like the above examples.
## Accessing Services

- **HDFS NameNode UI**: http://localhost:9870
- **YARN ResourceManager**: http://localhost:8088
- **Spark Master UI**: http://localhost:8080
- **Spark Worker 1 UI**: http://localhost:8081
- **Spark Worker 2 UI**: http://localhost:8082
- **Grafana Dashboard**: http://localhost:3000 (default login: admin/admin)

## Data Pipeline

1. NYC yellow taxi trip data is downloaded in Parquet format
2. Data is stored in HDFS at `/user/hadoop/nyc_yellow_trip_data`
3. Spark reads the data from HDFS, processes it, and stores results in PostgreSQL
4. PostgreSQL serves as the data warehouse for analytics and visualization

## Project Structure

```
docker-hadoop/
├── conf/                      # Configuration files
│   └── spark-defaults.conf    # Spark configuration
├── scripts/                   # ETL scripts
│   ├── etl_script.py          # Main ETL script
│   ├── etl_revenue.py         # Revenue analysis ETL
│   └── etl_trip_volume.py     # Trip volume analysis ETL
├── docker-compose.yml         # Docker services definition
├── download.sh                # Data download and initialization script
├── hadoop.env                 # Hadoop environment variables
├── postgres.env               # PostgreSQL environment variables
└── prometheus.yml             # Prometheus configuration
```

## Troubleshooting

- **JDBC Connection Issues**: Ensure the PostgreSQL JDBC driver is correctly installed in all Spark nodes
- **HDFS Permission Issues**: Check the HDFS permissions using `hdfs dfs -ls /user/hadoop`
- **Spark Job Failures**: Check Spark logs in the Spark UI or in HDFS at `/spark-logs`
- **Permission Issues**: run 
  ```bash
  docker exec -it spark-master bash -c "id -u"  # get user id
  sudo chown -R <id>:<id> ivy2
  ```
  to fix permissions
## Shutting Down

To stop all services:

```bash
docker-compose down
```

To stop and remove all volumes (this will delete all data):

```bash
docker-compose down -v
