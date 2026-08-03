/* marts.dim_customer
   Grain: 1 dòng = 1 khách hàng */

DROP TABLE IF EXISTS marts.dim_customer;
CREATE TABLE marts.dim_customer AS
SELECT 
    ROW_NUMBER() OVER(
        ORDER BY customer_id) AS customer_key,
    customer_id,
    customer_score,
    monthly_income,
    customer_segment,
    recommended_offer
FROM(
    SELECT 
    customer_id,
    customer_score,
    monthly_income,
    recommended_offer,
    customer_segment,
    transaction_date,
    ROW_NUMBER() OVER(
        PARTITION BY customer_id
        ORDER BY transaction_date DESC)
        AS rn
    FROM staging.stg_transactions) c
WHERE c.rn = 1;
