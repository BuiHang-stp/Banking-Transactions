/* 01_customer_segmentation.sql
Câu hỏi nghiệp vụ
Q1. Phân khúc khách hàng nào hoạt động giao dịch năng nổ nhất?
Q2. Sản phẩm tài chính nào phổ biến nhất trong từng phân khúc?
Q3. Điểm tín dụng có liên quan đến tần suất giao dịch hoặc tổng phí tích lũy không? */


-- Q1. Phân khúc khách hàng nào hoạt động giao dịch năng nổ nhất? 
SELECT
    c.customer_segment,
    COUNT(*) AS txn_volume,
    COUNT(DISTINCT f.customer_key) AS active_customers,
    ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT f.customer_key), 0), 2) AS txn_per_customer,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_all_txns,
    ROUND(SUM(f.amount * cur.rate_to_eur), 2) AS total_value_eur,
    ROUND(AVG(f.amount * cur.rate_to_eur), 2) AS avg_ticket_eur
FROM marts.fact_transactions f
JOIN marts.dim_customer c ON f.customer_key = c.customer_key
JOIN marts.dim_date d ON f.date_key = d.date_key
JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
GROUP BY c.customer_segment
ORDER BY txn_volume DESC;

-- Q2. Sản phẩm tài chính nào phổ biến nhất trong từng phân khúc?
WITH txn AS ( SELECT
        c.customer_segment,
        p.product_category,
        p.product_subcategory,
        f.amount * cur.rate_to_eur AS amount_eur
    FROM marts.fact_transactions f
    JOIN marts.dim_customer c ON f.customer_key = c.customer_key
    JOIN marts.dim_product p ON f.product_key = p.product_key
    JOIN marts.dim_date d ON f.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year),
segment_product AS ( SELECT
        customer_segment,
        product_category,
        product_subcategory,
        COUNT(*) AS txn_volume,
        ROUND(SUM(amount_eur), 2) AS total_value_eur
    FROM txn
    GROUP BY customer_segment, product_category, product_subcategory),
ranked AS ( SELECT
        sp.*,
        RANK() OVER (PARTITION BY customer_segment ORDER BY txn_volume DESC) AS rnk,
        ROUND(100.0 * txn_volume / NULLIF(SUM(txn_volume) OVER (PARTITION BY customer_segment), 0), 2) AS pct_within_segment
    FROM segment_product sp)
SELECT
    customer_segment,
    rnk,
    product_category,
    product_subcategory,
    txn_volume,
    pct_within_segment,
    total_value_eur
FROM ranked
WHERE rnk <= 3
ORDER BY customer_segment, rnk, txn_volume DESC;

/* Q3. Điểm tín dụng có liên quan đến tần suất giao dịch hoặc tổng phí tích lũy?
(a) So sánh theo 5 nhóm credit-score 
(b) Pearson correlation giữa credit score và các chỉ số giao dịch */

-- (a) Tần suất giao dịch và tổng phí theo credit-score 
WITH per_customer AS ( SELECT
        f.customer_key,
        c.customer_score,
        COUNT(*) AS txn_frequency,
        ROUND(SUM(
            (COALESCE(f.credit_card_fees, 0)
            + COALESCE(f.insurance_fees, 0)
            + COALESCE(f.late_payment_amount, 0))
            * cur.rate_to_eur
        ), 2) AS cumulative_fees_eur
    FROM marts.fact_transactions f
    JOIN marts.dim_customer c ON f.customer_key = c.customer_key
    JOIN marts.dim_date d ON f.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
    GROUP BY f.customer_key, c.customer_score),
banded AS ( SELECT
        pc.*,
        NTILE(5) OVER (ORDER BY customer_score) AS score_quintile
    FROM per_customer pc)
SELECT
    score_quintile,
    COUNT(*) AS customers,
    MIN(customer_score) AS score_min,
    MAX(customer_score) AS score_max,
    ROUND(AVG(txn_frequency), 2) AS avg_txn_frequency,
    ROUND(AVG(cumulative_fees_eur), 2) AS avg_cumulative_fees_eur
FROM banded
GROUP BY score_quintile
ORDER BY score_quintile;

-- (b) Pearson correlation 
WITH per_customer AS ( SELECT
        f.customer_key,
        c.customer_score,
        COUNT(*) AS txn_frequency,
        SUM(
            (COALESCE(f.credit_card_fees, 0)
            + COALESCE(f.insurance_fees, 0)
            + COALESCE(f.late_payment_amount, 0))
            * cur.rate_to_eur
        ) AS cumulative_fees_eur
    FROM marts.fact_transactions f
    JOIN marts.dim_customer c ON f.customer_key = c.customer_key
    JOIN marts.dim_date d ON f.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
    GROUP BY f.customer_key, c.customer_score)
SELECT
    COUNT(*) AS customers,
    ROUND(corr(customer_score, txn_frequency)::numeric, 4) AS corr_score_vs_frequency,
    ROUND(corr(customer_score, cumulative_fees_eur)::numeric, 4) AS corr_score_vs_fees
FROM per_customer;