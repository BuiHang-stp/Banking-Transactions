-- PK
SELECT
    'dim_date PK' AS test,
    CASE WHEN COUNT(*) = COUNT(DISTINCT date_key)
         THEN 'PASS' ELSE 'FAIL' END AS result
FROM marts.dim_date
UNION ALL

SELECT
    'dim_customer PK',
    CASE WHEN COUNT(*) = COUNT(DISTINCT customer_key)
         THEN 'PASS' ELSE 'FAIL' END
FROM marts.dim_customer
UNION ALL

SELECT
    'dim_product PK',
    CASE WHEN COUNT(*) = COUNT(DISTINCT product_key)
         THEN 'PASS' ELSE 'FAIL' END
FROM marts.dim_product
UNION ALL

SELECT
    'dim_branch PK',
    CASE WHEN COUNT(*) = COUNT(DISTINCT branch_key)
         THEN 'PASS' ELSE 'FAIL' END
FROM marts.dim_branch
UNION ALL

SELECT
    'dim_channel PK',
    CASE WHEN COUNT(*) = COUNT(DISTINCT channel_key)
         THEN 'PASS' ELSE 'FAIL' END
FROM marts.dim_channel
UNION ALL

SELECT
    'dim_transaction_type PK',
    CASE WHEN COUNT(*) = COUNT(DISTINCT transaction_type_key)
         THEN 'PASS' ELSE 'FAIL' END
FROM marts.dim_transaction_type
UNION ALL

-- FK
SELECT
    'Fact FK',
    CASE WHEN COUNT(*) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM marts.fact_transactions
WHERE date_key IS NULL
   OR customer_key IS NULL
   OR product_key IS NULL
   OR branch_key IS NULL
   OR channel_key IS NULL
   OR transaction_type_key IS NULL
UNION ALL

-- Row count
SELECT
    'Fact row count',
    CASE WHEN
        (SELECT COUNT(*) FROM staging.stg_transactions)
        =
        (SELECT COUNT(*) FROM marts.fact_transactions)
    THEN 'PASS'
    ELSE 'FAIL'
    END
UNION ALL

-- Amount
SELECT
    'Amount',
    CASE WHEN
        (SELECT SUM(amount) FROM staging.stg_transactions)
        =
        (SELECT SUM(amount) FROM marts.fact_transactions)
    THEN 'PASS'
    ELSE 'FAIL'
    END
UNION ALL

-- Fees
SELECT
    'Fees',
    CASE WHEN(
        SELECT SUM(
        credit_card_fees +
        insurance_fees +
        late_payment_amount)
        FROM staging.stg_transactions)
    =
        (SELECT SUM(
        credit_card_fees +
        insurance_fees +
        late_payment_amount)
        FROM marts.fact_transactions)
    THEN 'PASS'
    ELSE 'FAIL'
    END
UNION ALL

SELECT
    'Fee detail',
    CASE WHEN (
        SELECT SUM(fee_amount)
        FROM marts.v_fee_detail)
        =
        (SELECT SUM(
        credit_card_fees +
        insurance_fees +
        late_payment_amount)
        FROM staging.stg_transactions
        )
    THEN 'PASS'
    ELSE 'FAIL'
    END
UNION ALL

-- Duplicate transaction
SELECT
    'Duplicate transaction',
    CASE WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM (
    SELECT transaction_id
    FROM marts.fact_transactions
    GROUP BY transaction_id
    HAVING COUNT(*) > 1) t;