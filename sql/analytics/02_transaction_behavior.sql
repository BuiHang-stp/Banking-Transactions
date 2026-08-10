/* 02_transaction_behavior.sql
Câu hỏi nghiệp vụ
Q4. Loại giao dịch nào chiếm ưu thế về số lượng và giá trị?
Q5. Thành phố/chi nhánh nào là điểm nóng giao dịch và nơi nào hoạt động kém hiệu quả?
Q6. Thói quen sử dụng khác nhau như thế nào giữa các kênh giao dịch? */


-- Q4. Loại giao dịch nào chiếm ưu thế về số lượng và giá trị?
SELECT
    tt.transaction_type,
    tt.direction,
    COUNT(*) AS txn_volume,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_volume,
    ROUND(SUM(f.amount * cur.rate_to_eur), 2) AS total_value_eur,
    ROUND(100.0 * SUM(f.amount * cur.rate_to_eur) / NULLIF(SUM(SUM(f.amount * cur.rate_to_eur)) OVER (), 0), 2) AS pct_of_value,
    ROUND(AVG(f.amount * cur.rate_to_eur), 2) AS avg_ticket_eur,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_by_volume,
    RANK() OVER (ORDER BY SUM(f.amount * cur.rate_to_eur) DESC) AS rank_by_value
FROM marts.fact_transactions f
JOIN marts.dim_transaction_type tt ON f.transaction_type_key = tt.transaction_type_key
JOIN marts.dim_date d ON f.date_key = d.date_key
JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
GROUP BY tt.transaction_type, tt.direction
ORDER BY txn_volume DESC;

-- Q5. Thành phố/chi nhánh nào là điểm nóng giao dịch và nơi nào hoạt động kém hiệu quả?
SELECT
    br.branch_city,
    COUNT(*) AS txn_volume,
    COUNT(DISTINCT f.customer_key) AS distinct_customers,
    ROUND(SUM(f.amount * cur.rate_to_eur), 2) AS total_value_eur,
    ROUND(AVG(f.amount * cur.rate_to_eur), 2) AS avg_ticket_eur,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_volume,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_by_volume,
    RANK() OVER (ORDER BY SUM(f.amount * cur.rate_to_eur) DESC) AS rank_by_value
FROM marts.fact_transactions f
JOIN marts.dim_branch br ON f.branch_key = br.branch_key
JOIN marts.dim_date d ON f.date_key = d.date_key
JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
GROUP BY br.branch_city
ORDER BY txn_volume DESC;


/* Q6. Thói quen sử dụng khác nhau như thế nào giữa các kênh giao dịch?
A: So sánh tổng quan giữa các channel:
   - Transaction volume và tỷ trọng
   - Số khách hàng sử dụng
   - Số giao dịch trên mỗi khách hàng
   - Average ticket và total value
B: So sánh mức độ sử dụng các kênh giao dịch giữa các phân khúc khách hàng */

-- A. Tổng quan về các kênh giao dịch
SELECT
    ch.channel,
    COUNT(*) AS txn_volume,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_volume,
    COUNT(DISTINCT f.customer_key) AS distinct_customers,
    ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT f.customer_key), 0), 2) AS txn_per_customer,
    ROUND(AVG(f.amount * cur.rate_to_eur), 2) AS avg_ticket_eur,
    ROUND(SUM(f.amount * cur.rate_to_eur), 2) AS total_value_eur
FROM marts.fact_transactions f
JOIN marts.dim_channel ch ON f.channel_key = ch.channel_key
JOIN marts.dim_date d ON f.date_key = d.date_key
JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
GROUP BY ch.channel
ORDER BY txn_volume DESC;

-- B. mức độ sử dụng các kênh giao dịch giữa các phân khúc khách hàng
SELECT
    c.customer_segment,
    ch.channel,
    COUNT(*) AS txn_volume,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY c.customer_segment), 0), 2) AS pct_within_segment
FROM marts.fact_transactions f
JOIN marts.dim_customer c ON f.customer_key = c.customer_key
JOIN marts.dim_channel ch ON f.channel_key = ch.channel_key
GROUP BY c.customer_segment, ch.channel
ORDER BY c.customer_segment, txn_volume DESC;