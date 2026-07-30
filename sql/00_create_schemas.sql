-- 00_create_schemas.sql
CREATE SCHEMA IF NOT EXISTS raw; -- raw: dữ liệu thô từ Excel
CREATE SCHEMA IF NOT EXISTS staging; -- staging: dữ liệu đã làm sạch và chuẩn hoá
CREATE SCHEMA IF NOT EXISTS marts; -- marts: phân tích và Power BI