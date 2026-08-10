/* 03_fee_revenue.sql
Câu hỏi nghiệp vụ
Q7. Loại giao dịch nào mang lại nhiều doanh thu từ phí nhất?
Q8. Có nhóm khách hàng nào đang chịu mức chi phí không tương xứng không?
Q9. Đâu là những nguồn friction thường xuyên nhất nhưng vẫn tạo ra doanh thu? */


-- Q7. Loại giao dịch nào mang lại nhiều doanh thu từ phí nhất?
WITH fee_data AS ( SELECT
        tt.transaction_type,
        v.fee_type,
        v.fee_amount * cur.rate_to_eur AS fee_amount_eur
    FROM marts.v_fee_detail v
    JOIN marts.dim_transaction_type tt ON v.transaction_type_key = tt.transaction_type_key
    JOIN marts.dim_date d ON v.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = v.currency AND cur.year = d.year)
SELECT
    transaction_type,
    fee_type,
    COUNT(*) AS fee_events,
    ROUND(SUM(fee_amount_eur), 2) AS fee_revenue_eur,
    ROUND(AVG(fee_amount_eur), 2) AS avg_fee_eur,
    ROUND(100.0 * SUM(fee_amount_eur) / NULLIF(SUM(SUM(fee_amount_eur)) OVER (), 0), 2) AS pct_of_total_fee_revenue
FROM fee_data
GROUP BY transaction_type, fee_type
ORDER BY fee_revenue_eur DESC;


/* Q8. Có nhóm khách hàng nào đang chịu mức chi phí không tương xứng không?
        > 1: nhóm chịu tỷ trọng phí cao hơn tỷ trọng khách hàng
        < 1: nhóm chịu tỷ trọng phí thấp hơn tỷ trọng khách hàng */
WITH customer_fees AS ( SELECT
        f.customer_key,
        c.customer_segment,
        SUM((COALESCE(f.credit_card_fees, 0)
            + COALESCE(f.insurance_fees, 0)
            + COALESCE(f.late_payment_amount, 0))
            * cur.rate_to_eur
        ) AS total_fees_eur
    FROM marts.fact_transactions f
    JOIN marts.dim_customer c ON f.customer_key = c.customer_key
    JOIN marts.dim_date d ON f.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
    GROUP BY f.customer_key, c.customer_segment)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_fees_eur), 2) AS total_fees_eur,
    ROUND(AVG(total_fees_eur), 2) AS avg_fees_per_customer_eur,
    ROUND(100.0 * SUM(total_fees_eur)/ NULLIF(SUM(SUM(total_fees_eur)) OVER (), 0)
    ,2) AS pct_of_total_fees,
    ROUND((100.0 * SUM(total_fees_eur)/ NULLIF(SUM(SUM(total_fees_eur)) OVER (), 0))
        /NULLIF(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 0)
    ,2) AS fee_burden_index
FROM customer_fees
GROUP BY customer_segment
ORDER BY fee_burden_index DESC;


/* -----------------------------------------------------------------------------
Q9. Đâu là những nguồn friction thường xuyên nhất nhưng vẫn tạo ra doanh thu?

Fee type được đánh giá theo:
- Số lần phát sinh
- Số khách hàng bị ảnh hưởng
- Tổng doanh thu phí
- Tỷ trọng số lần phát sinh

Phân tích thêm theo channel để xác định nơi friction tập trung nhiều nhất.
----------------------------------------------------------------------------- */


/* Part A - Tổng quan theo loại phí */

WITH fee_data AS (
    SELECT
        v.customer_key,
        v.fee_type,
        v.fee_amount * cur.rate_to_eur AS fee_amount_eur
    FROM marts.v_fee_detail v
    JOIN marts.dim_date d ON v.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = v.currency AND cur.year = d.year
)
SELECT
    fee_type,
    COUNT(*) AS fee_events,
    COUNT(DISTINCT customer_key) AS customers_affected,
    ROUND(SUM(fee_amount_eur), 2) AS fee_revenue_eur,
    ROUND(AVG(fee_amount_eur), 2) AS avg_fee_eur,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_fee_events
FROM fee_data
GROUP BY fee_type
ORDER BY fee_events DESC;


/* Part B - Phân bố friction theo channel */

WITH fee_data AS (
    SELECT
        v.fee_type,
        ch.channel,
        v.fee_amount * cur.rate_to_eur AS fee_amount_eur
    FROM marts.v_fee_detail v
    JOIN marts.dim_channel ch ON v.channel_key = ch.channel_key
    JOIN marts.dim_date d ON v.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = v.currency AND cur.year = d.year
)
SELECT
    fee_type,
    channel,
    COUNT(*) AS fee_events,
    ROUND(SUM(fee_amount_eur), 2) AS fee_revenue_eur,
    ROUND(
        100.0 * COUNT(*)
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY fee_type), 0),
        2
    ) AS pct_within_fee_type
FROM fee_data
GROUP BY fee_type, channel
ORDER BY fee_type, fee_events DESC;