DROP TABLE IF EXISTS marts.fact_transactions;
CREATE TABLE marts.fact_transactions AS
SELECT 
    st.transaction_id,
    dd.date_key,
    dc.customer_key,
    dp.product_key,
    db.branch_key,
    dch.channel_key,
    dtt.transaction_type_key,
    st.amount,
    st.credit_card_fees,
    st.insurance_fees,
    st.late_payment_amount 
    st.currency   
FROM staging.stg_transactions st
LEFT JOIN marts.dim_date dd
    ON st.transaction_date = dd.transaction_date
LEFT JOIN marts.dim_customer dc
    ON st.customer_id = dc.customer_id
LEFT JOIN marts.dim_product dp
    ON st.product_category = dp.product_category
    AND st.product_subcategory = dp.product_subcategory
LEFT JOIN marts.dim_branch db
    ON st.branch_city = db.branch_city
    AND st.branch_lat = db.branch_lat
    AND st.branch_long = db.branch_long
LEFT JOIN marts.dim_channel dch
    ON st.channel = dch.channel
LEFT JOIN marts.dim_transaction_type dtt
    ON st.transaction_type = dtt.transaction_type; 