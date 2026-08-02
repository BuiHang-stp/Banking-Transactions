/* marts.dim_transaction_type
   Grain: 1 dòng = 1 loại giao dịch */
   
DROP TABLE IF EXISTS marts.dim_transaction_type;
CREATE TABLE marts.dim_transaction_type AS
SELECT
    ROW_NUMBER() OVER(
        ORDER BY tt.transaction_type) 
        AS transaction_type_key,
    tt.transaction_type,
    tt.direction
FROM(
    SELECT DISTINCT 
    transaction_type,
    direction
FROM staging.stg_transactions) tt;