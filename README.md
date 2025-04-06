# Nền tảng Phân tích Dữ liệu Lớn với Docker Swarm

Dự án này triển khai một nền tảng phân tích dữ liệu lớn hoàn chỉnh sử dụng hệ sinh thái Hadoop (HDFS, YARN, Hive, Spark) cùng với Jupyter Notebook cho xử lý dữ liệu và Apache Superset để trực quan hóa. Toàn bộ nền tảng được đóng gói bằng Docker và triển khai trên Docker Swarm.

Dữ liệu ví dụ được sử dụng là đánh giá sản phẩm Amazon Kindle Store.

## Kiến trúc

Nền tảng bao gồm các thành phần chính sau, được quản lý bởi Docker Compose và chạy trên Docker Swarm:

*   **Lưu trữ:**
    *   **HDFS:** Hệ thống file phân tán Hadoop để lưu trữ dữ liệu lớn.
        *   `namenode`: Quản lý metadata của HDFS.
        *   `datanode` (x3): Lưu trữ các block dữ liệu thực tế.
*   **Tính toán:**
    *   **YARN:** Quản lý tài nguyên và lập lịch cho cluster.
        *   `resourcemanager`: Trung tâm điều phối của YARN.
        *   `nodemanager` (x3): Thực thi các container tác vụ trên các node worker.
*   **Xử lý & Truy vấn:**
    *   **Hive:** Data warehouse trên nền Hadoop, cho phép truy vấn dữ liệu trên HDFS bằng HiveQL (tương tự SQL).
        *   `postgres` (Metastore DB): Cơ sở dữ liệu PostgreSQL lưu trữ metadata (schema, vị trí bảng) cho Hive.
        *   `hive-metastore`: Dịch vụ quản lý metadata của Hive.
        *   `hive-server`: Dịch vụ HiveServer2 cho phép client kết nối (JDBC/ODBC) và thực thi truy vấn.
    *   **Spark:** Framework tính toán phân tán mạnh mẽ. Được tích hợp với YARN để chạy job.
    *   **JupyterLab (`jupyter`):** Môi trường notebook tương tác với PySpark, cho phép viết và thực thi code Spark để phân tích dữ liệu trên cluster. Được cấu hình sẵn để kết nối với HDFS, YARN và Hive Metastore.
*   **Trực quan hóa:**
    *   **Apache Superset:** Nền tảng BI (Business Intelligence) hiện đại, mã nguồn mở.
        *   `superset_db`: Cơ sở dữ liệu PostgreSQL riêng biệt lưu trữ metadata của Superset (dashboards, charts, user,...).
        *   `superset`: Web application của Superset, kết nối tới `superset_db` và các nguồn dữ liệu khác (như Hive) để tạo báo cáo và dashboard.
*   **Giám sát & Lịch sử:**
    *   **History Server (`historyserver`):** Dịch vụ lưu trữ và hiển thị thông tin lịch sử về các ứng dụng YARN/MapReduce/Spark đã chạy.

Tất cả các dịch vụ giao tiếp với nhau qua mạng overlay `hadoop-net` của Docker Swarm. Dữ liệu persistent được lưu trữ trong Docker volumes. Cấu hình được quản lý linh hoạt thông qua biến môi trường và Docker Swarm configs.

## Yêu cầu hệ thống

*   **Docker:** Phiên bản mới nhất được khuyến nghị.
*   **Docker Swarm:** Cần được khởi tạo trên máy của bạn (hoặc cluster). Chạy `docker swarm init` nếu bạn chưa có Swarm.
*   **Git:** Để clone repository.
*   **wget:** Cần thiết để chạy script `download_data.sh`.
*   **Bash:** Để chạy các script tiện ích (`.sh`).
*   **Tài nguyên:** Cluster cần đủ RAM và CPU để chạy các dịch vụ. Đặc biệt, Namenode, ResourceManager, Jupyter và Superset có thể cần nhiều RAM hơn (Xem cấu hình `memory` trong `docker-compose.yml`).

## Cài đặt và Cấu hình

1.  **Clone Repository:**
    ```bash
    git clone <your-repository-url>
    cd <repository-directory>
    ```

2.  **Cấu hình Biến Môi trường:**
    Xem xét và chỉnh sửa các file sau nếu cần:
    *   **`.env`**:
        *   `CLUSTER_NAME`: Tên cluster Hadoop (ít khi cần đổi).
        *   `POSTGRES_PASSWORD`: Mật khẩu cho user `ThangData` kết nối tới Hive Metastore DB.
        *   `HIVE_SITE_CONF_javax_jdo_option_ConnectionPassword`: Phải khớp với `POSTGRES_PASSWORD`.
        *   `SUPERSET_SECRET_KEY`: Đặt một chuỗi bí mật ngẫu nhiên, dài cho Superset.
        *   `ADMIN_USERNAME`, `ADMIN_PASSWORD`, etc.: Thông tin đăng nhập admin cho Superset (nếu muốn thay đổi).
        *   Các biến `*_PRECONDITION`: Thường không cần thay đổi, dùng để kiểm soát thứ tự khởi động.
    *   **`hadoop.env`**:
        *   `HDFS_CONF_dfs_replication`: Số bản sao HDFS (mặc định là 2). Có thể giảm xuống 1 nếu chỉ có 1 Datanode hoặc để tiết kiệm dung lượng trong môi trường dev.
        *   `YARN_CONF_yarn_nodemanager_resource_memory___mb`: Tổng bộ nhớ (MB) cấp cho mỗi NodeManager quản lý.
        *   `YARN_CONF_yarn_nodemanager_resource_cpu___vcores`: Tổng số vCPU cấp cho mỗi NodeManager quản lý.
        *   *Lưu ý:* `HDFS_CONF_dfs_permissions_enabled=false` được đặt để đơn giản hóa quyền trong môi trường dev/test. **Không khuyến nghị** cho môi trường production.
        *   Các cấu hình tài nguyên khác (`MAPRED_CONF_*`, `YARN_CONF_yarn_scheduler_*`) có thể được tinh chỉnh dựa trên tài nguyên máy chủ và nhu cầu workload.

3.  **Cấu hình Hadoop/Hive/Spark (Thư mục `conf/`):**
    *   Các file trong thư mục `conf/` (`core-site.xml`, `hdfs-site.xml`, `hive-site.xml`, `mapred-site.xml`, `spark-defaults.conf`, `yarn-site.xml`) chứa cấu hình chi tiết.
    *   Các file này được nạp dưới dạng Docker Swarm configs thông qua script `setup_config.sh`.
    *   **Chỉ chỉnh sửa** các file này nếu bạn hiểu rõ về cấu hình Hadoop/Hive/Spark và cần thay đổi các giá trị không thể cấu hình qua `hadoop.env` hoặc `.env`. Ví dụ: thay đổi scheduler, thêm các thuộc tính tùy chỉnh.

4.  **Chuẩn bị file JARs:**
    *   Script `setup_config.sh` sẽ tự động lấy file JAR driver PostgreSQL từ `jars/postgres_jars/postgresql-42.3.1.jar` và tạo config `postgres_jars`. File JAR này **bắt buộc** phải có để Spark và Hive có thể kết nối tới database Metastore.
    *   Nếu bạn cần thêm các file JAR khác cho Spark (ví dụ: kết nối tới các nguồn dữ liệu khác), hãy đặt chúng vào thư mục `jars/spark_jars/` (hoặc một thư mục con khác) và cập nhật:
        *   `setup_config.sh`: Thêm lệnh `docker config create <tên_config_jar> <đường_dẫn_jar>`
        *   `docker-compose.yml`: Mount config JAR mới vào thư mục `/usr/local/spark/jars` (hoặc đường dẫn phù hợp) của service `jupyter` (và các service Spark khác nếu có).

5.  **Tạo Docker Swarm Configs:**
    **Quan trọng:** Chạy script này trên **Swarm manager node** *trước khi* deploy stack.
    *   Script này sẽ đọc các file cấu hình từ `conf/`, `jars/`, `requirements.txt`, `superset/` và tạo các đối tượng Docker Swarm config tương ứng.
    *   **Cảnh báo:** Lệnh đầu tiên trong script (`docker config ls -q | xargs -r docker config rm`) sẽ **XÓA TẤT CẢ** các config đang tồn tại trên Swarm của bạn. Hãy cẩn thận nếu bạn đang chạy các stack khác trên cùng Swarm.
    ```bash
    chmod +x setup_config.sh
    ./setup_config.sh
    ```
    Kiểm tra lại danh sách config đã được tạo bằng `docker config ls`.

## Triển khai Stack

Sử dụng lệnh `docker stack deploy` để triển khai các service được định nghĩa trong `docker-compose.yml`.

```bash
# Thay <your_stack_name> bằng tên bạn muốn đặt cho stack (ví dụ: bigdata)
# Tên này sẽ được dùng làm tiền tố cho tên các service, container, network
export STACK_NAME="hadoop" # Hoặc tên stack bạn chọn
docker stack deploy -c docker-compose.yml ${STACK_NAME}
```

Sử dụng các lệnh sau để kiểm tra trạng thái triển khai:
```bash
docker stack ps ${STACK_NAME}
docker service ls
# Xem log của một service cụ thể (ví dụ: namenode)
docker service logs ${STACK_NAME}_namenode -f
```
Đợi cho đến khi tất cả các service có REPLICAS là 1/1 (hoặc số replicas bạn cấu hình). Quá trình này có thể mất vài phút vì các container cần tải image và khởi động.

## Khởi tạo Môi trường (Sau khi Deploy)
Sau khi các service đã chạy ổn định (đặc biệt là namenode và hive-server), bạn cần chạy script init.sh để tạo cấu trúc thư mục cần thiết trên HDFS và các database trong Hive.
```bash
chmod +x init.sh
# Chạy script với tên stack đã deploy
./init.sh ${STACK_NAME}
```
Script này sẽ:
*   Chờ HDFS và HiveServer2 sẵn sàng.
*   Tạo các thư mục `/data/raw`, `/data/processed`, `/data/curated`, `/user/hive/warehouse`, `/user/hadoop/spark-logs`, `/user/Thang/.sparkStaging` trên HDFS với các quyền truy cập phù hợp.
*   Tạo các database `raw`, `processed`, `curated` trong Hive. 

## Tải Dữ liệu (Sau khi Khởi tạo)
Nếu đây là lần đầu tiên bạn thiết lập hoặc muốn tải lại dữ liệu gốc, chạy script download_data.sh
```bash
chmod +x download_data.sh
# Chạy script với tên stack đã deploy
./download_data.sh ${STACK_NAME}
```
Script này sẽ:
*   Tải file dữ liệu đánh giá (Kindle_Store.jsonl.gz) và metadata (meta_Kindle_Store.jsonl.gz) từ nguồn.
*   Giải nén chúng.
*   Upload các file .jsonl đã giải nén vào thư mục `/data/raw/amazon_reviews`  trên HDFS.

## Truy cập Giao diện Người dùng (UI)
*   HDFS Namenode UI: http://<swarm-manager-ip>:9870
*   YARN ResourceManager UI: http://<swarm-manager-ip>:8088
*   Spark History Server UI: http://<swarm-manager-ip>:8188
*   JupyterLab: http://<swarm-manager-ip>:8888
*   Apache Superset: http://<swarm-manager-ip>:8089 (Lưu ý port là 8089, không phải 8088)
    * Giao diện để trực quan hóa dữ liệu.
    * Đăng nhập bằng tài khoản admin bạn cấu hình trong .env (mặc định: user admin, pass admin).
    * Bạn cần cấu hình kết nối tới Hive trong Superset (Data -> Databases -> + Database):
      * Database: Hive
      * SQLAlchemy URI: `hive://hive-server:10000/default` (hoặc database Hive cụ thể bạn muốn kết nối, ví dụ: `hive://hive-server:10000/curated`)
      * Điền các thông tin khác nếu cần và Test Connection.
      
(Thay <swarm-manager-ip> bằng địa chỉ IP của máy đang chạy Docker Swarm manager)
