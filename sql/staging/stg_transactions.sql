DROP TABLE IF EXISTS staging.stg_transactions;
CREATE TABLE staging.stg_transactions AS
SELECT 
    TRIM(transaction_id) AS transaction_id, 
    TRIM(customer_id) AS customer_id, 
    transaction_date::DATE AS transaction_date, 
    TRIM(transaction_type) AS transaction_type, 
        CASE 
        WHEN TRIM(transaction_type) = 'Deposit' THEN 'Inflow'
        ELSE 'Outflow'
        END AS direction,
    amount::NUMERIC(18,2) AS amount, 
    TRIM(product_category) AS product_category, 
    TRIM(product_subcategory) AS product_subcategory,
    TRIM(branch_city) AS branch_city, 
    branch_lat, 
    branch_long, 
    TRIM(channel) AS channel, 
    UPPER(currency) AS currency, 
    COALESCE(credit_card_fees::NUMERIC(18,2),0) AS credit_card_fees, 
    COALESCE(insurance_fees::NUMERIC(18,2),0) AS insurance_fees,
    COALESCE(late_payment_amount::NUMERIC(18,2),0) AS late_payment_amount, 
        COALESCE(credit_card_fees::NUMERIC(18,2),0) 
       + COALESCE(insurance_fees::NUMERIC(18,2),0)
       + COALESCE(late_payment_amount::NUMERIC(18,2),0) AS total_fee,
    customer_score::INTEGER AS customer_score, 
    monthly_income::NUMERIC(18,2) AS monthly_income, 
    TRIM(customer_segment) AS customer_segment, 
    TRIM(recommended_offer) AS recommended_offer
FROM raw.transactions;
CREATE UNIQUE INDEX ON staging.stg_transactions(transaction_id);
