/* marts.dim_branch
   Grain: 1 dòng = 1 thành phố */

DROP TABLE IF EXISTS marts.dim_branch;
CREATE TABLE marts.dim_branch AS
SELECT
    ROW_NUMBER() OVER(
        ORDER BY
            b.branch_city,
            b.branch_lat,
            b.branch_long)
        AS branch_key,
    b.branch_city,
    b.branch_lat,
    b.branch_long
FROM
    (SELECT DISTINCT 
    branch_city,
    branch_lat,
    branch_long
FROM staging.stg_transactions) b;