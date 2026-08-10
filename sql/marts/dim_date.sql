/* marts.dim_date
   Grain: 1 dòng = 1 ngày*/
DROP TABLE IF EXISTS marts.dim_date CASCADE;
CREATE TABLE marts.dim_date AS
SELECT
    TO_CHAR(d.transaction_date, 'YYYYMMDD')::INT AS date_key,
    d.transaction_date,
    EXTRACT(YEAR FROM d.transaction_date) AS year,
    'Q' || EXTRACT(QUARTER FROM d.transaction_date) AS quarter,
    EXTRACT(MONTH FROM d.transaction_date) AS month,
    TO_CHAR(d.transaction_date, 'Mon') AS month_name,
    DATE_TRUNC('month', d.transaction_date)::date AS month_start,
    TO_CHAR(d.transaction_date, 'YYYY-MM') AS year_month,
    EXTRACT(DAY FROM d.transaction_date) AS day,
    TO_CHAR(d.transaction_date, 'Dy') AS day_of_week
FROM (
    SELECT DISTINCT transaction_date
    FROM staging.stg_transactions
) d;