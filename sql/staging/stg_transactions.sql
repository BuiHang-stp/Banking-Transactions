DROP TABLE IF EXISTS staging.stg_transactions;
CREATE TABLE staging.stg_transactions AS
SELECT 
    transaction_id, 
    customer_id, 
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
    credit_card_fees::NUMERIC(18,2) AS credit_card_fees, 
    insurance_fees::NUMERIC(18,2) AS insurance_fees,
    late_payment_amount::NUMERIC(18,2) AS late_payment_amount, 
        (credit_card_fees::NUMERIC(18,2) 
       + insurance_fees::NUMERIC(18,2)
       + late_payment_amount::NUMERIC(18,2)) AS total_fee,
    customer_score::INTEGER AS customer_score, 
    monthly_income::NUMERIC(18,2) AS monthly_income, 
    customer_segment, 
    recommended_offer
FROM raw.transactions;
