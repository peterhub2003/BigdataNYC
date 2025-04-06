

echo "DELETE AVAILABLE CONFIGS"
docker config ls -q | xargs -r docker config rm


docker config create core-site-v1 ./conf/core-site.xml
docker config create hdfs-site-v1 ./conf/hdfs-site.xml
docker config create yarn-site-v1 ./conf/yarn-site.xml
docker config create mapred-site-v1 ./conf/mapred-site.xml
docker config create spark-defaults-v1 ./conf/spark-defaults.conf
docker config create hive-site-v1 ./conf/hive-site.xml

docker config create postgres_jars ./jars/postgres_jars/postgresql-42.3.1.jar

docker config create requirements ./requirements.txt

docker config create superset_entrypoint ./superset/entrypoint.sh
docker config create superset_config ./superset/superset_config.py

echo "CREATED SUCCESSFULLY"
docker config ls




