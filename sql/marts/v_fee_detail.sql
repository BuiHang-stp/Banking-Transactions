-- Note:
-- late_payment_amount is included in this analytical view for comparison
-- with fee-related amounts, but the source does not confirm that it is
-- strictly a fee or penalty. It is therefore labelled as
-- 'Late Payment Amount' rather than 'Late Payment Fee'.

DROP VIEW IF EXISTS marts.v_fee_detail;
CREATE VIEW marts.v_fee_detail AS
SELECT
    transaction_id,
    date_key,
    customer_key,
    product_key,
    branch_key,
    channel_key,
    transaction_type_key,
    currency,
    'Credit Card Fee' AS fee_type,
    credit_card_fees AS fee_amount
FROM marts.fact_transactions
WHERE credit_card_fees > 0
UNION ALL
SELECT
    transaction_id,
    date_key,
    customer_key,
    product_key,
    branch_key,
    channel_key,
    transaction_type_key,
    currency,
    'Insurance Fee' AS fee_type,
    insurance_fees AS fee_amount
FROM marts.fact_transactions
WHERE insurance_fees > 0
UNION ALL
SELECT
    transaction_id,
    date_key,
    customer_key,
    product_key,
    branch_key,
    channel_key,
    transaction_type_key,
    currency,
    'Late Payment Amount' AS fee_type,
    late_payment_amount AS fee_amount
FROM marts.fact_transactions
WHERE late_payment_amount > 0;