/* marts.dim_product
   Grain: 1 dòng = 1 sản phẩm riêng (category + subcategory)*/
   
DROP TABLE IF EXISTS marts.dim_product;
CREATE TABLE marts.dim_product AS
SELECT 
    ROW_NUMBER() OVER(
        ORDER BY 
        p.product_category,
        p.product_subcategory) 
    AS product_key,
    p.product_category,
    p.product_subcategory
FROM(
    SELECT DISTINCT
        product_category,
        product_subcategory
    FROM staging.stg_transactions) p;


    