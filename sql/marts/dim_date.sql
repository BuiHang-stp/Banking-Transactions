/* marts.dim_date
   Grain: 1 dòng = 1 ngày*/
DROP TABLE IF EXISTS marts.dim_date;
CREATE TABLE marts.dim_date AS
SELECT
    TO_CHAR(d.transaction_date,'YYYYMMDD')::INT AS date_key,
    d.transaction_date,
    EXTRACT(YEAR FROM d.transaction_date) AS year,
    'Q' || EXTRACT(QUARTER from d.transaction_date) AS quarter,
    EXTRACT(MONTH FROM d.transaction_date) AS month,
    TO_CHAR(d.transaction_date, 'Mon') AS month_name,
    EXTRACT(DAY FROM d.transaction_date) AS day,
    TO_CHAR(d.transaction_date, 'Dy') AS day_of_week
FROM(
    SELECT DISTINCT 
        transaction_date
    FROM staging.stg_transactions)d;


















DROP TABLE IF EXISTS marts.dim_date CASCADE;
CREATE TABLE marts.dim_date AS
WITH bounds AS (
    SELECT date_trunc('year', MIN(transaction_date))::date AS d_min,
           (date_trunc('year', MAX(transaction_date))
            + INTERVAL '1 year - 1 day')::date             AS d_max
    FROM staging.stg_transactions
)
SELECT
    to_char(g.d, 'YYYYMMDD')::int          AS date_key,
    g.d::date                              AS full_date,

    EXTRACT(year    FROM g.d)::int         AS year_no,
    EXTRACT(quarter FROM g.d)::int         AS quarter_no,
    'Q' || EXTRACT(quarter FROM g.d)::int  AS quarter_name,
    EXTRACT(month   FROM g.d)::int         AS month_no,
    to_char(g.d, 'Mon')                    AS month_name,
    to_char(g.d, 'YYYY-MM')                AS year_month,

    EXTRACT(isodow FROM g.d)::int          AS weekday_no,
    to_char(g.d, 'Dy')                     AS weekday_name,
    (EXTRACT(isodow FROM g.d) >= 6)        AS is_weekend,

    EXTRACT(day FROM g.d)::int             AS day_of_month,
    (g.d = (date_trunc('month', g.d) + INTERVAL '1 month - 1 day')::date)
                                           AS is_month_end
FROM bounds
CROSS JOIN generate_series(bounds.d_min, bounds.d_max, INTERVAL '1 day') AS g(d);

ALTER TABLE marts.dim_date ADD PRIMARY KEY (date_key);
CREATE UNIQUE INDEX ON marts.dim_date (full_date);

