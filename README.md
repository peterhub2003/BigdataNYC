# Hướng dẫn sử dụng môi trường Big Data với HDFS, Spark, Hive và PostgreSQL

Dự án này thiết lập một môi trường xử lý dữ liệu lớn hoàn chỉnh sử dụng Docker containers bao gồm:
- Hadoop HDFS (lưu trữ phân tán)
- YARN (quản lý tài nguyên)
- Apache Spark (xử lý dữ liệu)
- Apache Hive (kho dữ liệu)
- PostgreSQL (cơ sở dữ liệu quan hệ)
- Jupyter Notebook (phân tích tương tác)
- Apache Superset (trực quan hóa dữ liệu)

## Bước 1: Cài đặt môi trường

### 1.1 Chuẩn bị

Đảm bảo bạn đã cài đặt:
- Docker và Docker Compose
- Git

### 1.2 Tải mã nguồn

```bash
git clone <repository-url>
cd big-data
```

## Bước 2: Khởi động các dịch vụ

### 2.1 Khởi động tất cả các container

```bash
docker compose up --build -d
```

### 2.2 Kiểm tra trạng thái các container

```bash
docker ps
```

## Bước 3: Khởi tạo môi trường

### 3.1 Chạy script khởi tạo

Download data for in range of years and also in range of months. <start_year> <end_year> <start_month> <end_month>. Ví dụ
```bash
chmod +x ./entry.sh 2024 2024 1 12
./entry.sh
```

Script này sẽ đợi 30 giây để các dịch vụ khởi động healthy và tự động thực hiện các bước sau:
1. Tạo các thư mục cần thiết trong HDFS
2. Tạo các database Hive
3. Tải các thư viện phụ thuộc (PostgreSQL JDBC driver)
4. Tải dữ liệu taxi NYC và đưa vào HDFS
5. Kiểm tra môi trường

## Bước 4: Chạy ví dụ

```bash
chmod +x ./example.sh
./example.sh
```


## Bước 5: Sử dụng Jupyter Notebook

### 5.1 Truy cập Jupyter Notebook

Mở trình duyệt và truy cập: http://localhost:8888

Jupyter Notebook đã được cấu hình sẵn để kết nối với Spark, HDFS và Hive.

### 5.2 Tạo mới notebook hoặc là chạy sẵn ví dụ notebook spark_hive_test.ipynb.

## Bước 6: Làm việc với Hive

### 6.1 Kết nối với Hive thông qua Beeline

```bash
docker exec -it hive-server beeline -u jdbc:hive2://localhost:10000
```

### 6.2 Các lệnh Hive cơ bản

```sql
-- Hiển thị danh sách databases
SHOW DATABASES;

-- Sử dụng database curated
USE curated;

-- Hiển thị danh sách tables
SHOW TABLES;

-- Truy vấn dữ liệu từ fact table
SELECT * FROM fact_sales LIMIT 10;

-- Truy vấn kết hợp với dimension tables
SELECT 
  s.date_id, 
  p.product_name, 
  st.store_name, 
  s.quantity, 
  s.total_amount
FROM 
  fact_sales s
  JOIN dim_product p ON s.product_id = p.product_id
  JOIN dim_store st ON s.store_id = st.store_id
LIMIT 10;

-- Tạo database mới
CREATE DATABASE IF NOT EXISTS my_database;

-- Xóa database (cẩn thận khi sử dụng)
DROP DATABASE IF EXISTS my_database CASCADE;
```

## Bước 7: Truy cập các giao diện web

### 7.1 Các URL quan trọng

- **HDFS NameNode**: http://localhost:9870
- **YARN ResourceManager**: http://localhost:8088
- **Hive Server Web UI**: http://localhost:10002
- **Jupyter Notebook**: http://localhost:8888
- **Superset**: http://localhost:8089 (đăng nhập: admin/admin)

### 7.2 Đăng nhập vào Superset

1. Truy cập http://localhost:8089 và đăng nhập
2. Kết nối Database Hive:
   - Vào Data -> Databases -> + DATABASE.
   - Chọn Apache Hive.
   - Đặt DISPLAY NAME (ví dụ: My Hive Cluster).
   - Nhập SQLALCHEMY URI: hive://hive-server:10000/default (Kiểm tra lại tên service và cổng).
   - Test Connection và ADD.
3. Truy vấn Dữ liệu:
   - Vào SQL Lab -> SQL Editor.
   - Chọn Database và Schema Hive.
   - Viết và chạy câu lệnh SQL (ví dụ: SELECT * FROM your_hive_table LIMIT 100;).
4. Tạo Biểu đồ (Charts) và Bảng điều khiển (Dashboards): Khám phá dữ liệu từ kết quả SQL Lab hoặc từ menu Charts/Dashboards.


### 8.4 Vấn đề về SPARK_HOME trong Jupyter

Nếu gặp lỗi về biến môi trường SPARK_HOME trong Jupyter:

```bash
docker exec -it jupyter bash -c "echo 'export SPARK_HOME=/usr/local/spark' >> ~/.bashrc && source ~/.bashrc"
```

## Bước 9: Tắt và quản lý hệ thống

### 9.1 Tắt các container nhưng giữ lại dữ liệu

```bash
docker compose down
```

### 9.2 Tắt và xóa tất cả dữ liệu

```bash
docker compose down -v
```

### 9.3 Kiểm tra dung lượng đĩa sử dụng bởi Docker

```bash
docker system df
```

### 9.4 Dọn dẹp tài nguyên không sử dụng

```bash
docker system prune
```

## Cấu trúc dự án

```
big-data/
├── conf/                      # Tệp cấu hình
│   ├── core-site.xml          # Cấu hình Hadoop core
│   ├── hdfs-site.xml          # Cấu hình HDFS
│   ├── yarn-site.xml          # Cấu hình YARN
│   ├── hive-site.xml          # Cấu hình Hive
│   └── spark-defaults.conf    # Cấu hình Spark
├── init_scripts/              # Script khởi tạo
│   ├── 01_create_hdfs_dirs.sh # Tạo thư mục HDFS
│   ├── 02_create_hive_dbs.sh  # Tạo database Hive
│   ├── 03_download_dependencies.sh # Tải thư viện
│   └── 04_download_nyc_data.sh # Tải dữ liệu NYC
├── scripts/                   # Script xử lý dữ liệu
│   ├── spark_hive_pipeline.py # Pipeline Spark-Hive
│   └── zone_data_flow.py      # Luồng dữ liệu theo vùng
├── notebooks/                 # Jupyter notebooks
├── jars/                      # Thư viện JDBC
├── superset/                  # Cấu hình Superset
├── docker-compose.yml         # Định nghĩa các dịch vụ
├── entry.sh                   # Script chính để khởi tạo
├── hadoop.env                 # Biến môi trường Hadoop
└── .env                       # Biến môi trường chung
```

## Mô hình kiến trúc dữ liệu 3 vùng

Hệ thống này triển khai mô hình kiến trúc dữ liệu 3 vùng:

1. **Vùng Raw (Thô)**
   - Lưu trữ dữ liệu nguyên bản, chưa xử lý
   - Đường dẫn HDFS: `/data/raw`
   - Database Hive: `raw`

2. **Vùng Processed (Đã xử lý)**
   - Lưu trữ dữ liệu đã được làm sạch và chuẩn hóa
   - Định dạng Parquet với phân vùng theo năm/tháng
   - Đường dẫn HDFS: `/data/processed`
   - Database Hive: `processed`

3. **Vùng Curated (Đã tổ chức)**
   - Lưu trữ dữ liệu theo mô hình star schema
   - Bao gồm fact tables và dimension tables
   - Đường dẫn HDFS: `/data/curated`
   - Database Hive: `curated`

Mô hình này cho phép quản lý dữ liệu hiệu quả từ nguồn thô đến dữ liệu sẵn sàng cho phân tích kinh doanh.
