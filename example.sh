echo -e "\n===== STEP 6: Executing PySpark zone data flow script... ====="
docker exec jupyter bash -c "export SPARK_HOME=/usr/local/spark && \
  /usr/local/spark/bin/spark-submit --master yarn \
  --deploy-mode client \
  --conf 'spark.yarn.appMasterEnv.PYSPARK_PYTHON=/usr/bin/python3' \
  --conf 'spark.yarn.appMasterEnv.PYSPARK_DRIVER_PYTHON=/usr/bin/python3' \
  --conf 'spark.executorEnv.PYSPARK_PYTHON=/usr/bin/python3' \
  --conf 'spark.sql.warehouse.dir=hdfs://namenode:9000/user/hive/warehouse' \
  --conf 'spark.hadoop.hive.metastore.uris=thrift://hive-metastore:9083' \
  --conf 'spark.sql.catalogImplementation=hive' \
  /mnt/scripts/zone_data_flow.py"