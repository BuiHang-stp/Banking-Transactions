/* 04_trends_over_time.sql
Câu hỏi nghiệp vụ
Q10. Có tháng hoặc mùa nào phản ánh đỉnh điểm hoặc sự sụt giảm giao dịch không?
Q11. Các đề xuất sản phẩm có phù hợp với nhu cầu và hành vi thực tế không?
Q12. Những xu hướng nào mới nổi lên theo thời gian giữa các phân khúc hoặc các kênh giao dịch? */


-- Q10. Có tháng hoặc mùa nào phản ánh đỉnh điểm hoặc sự sụt giảm giao dịch không?
-- A. Khối lượng và giá trị theo tháng, Month-over-Month change so với tháng liền trước 
WITH monthly AS ( SELECT
        d.year_month,
        COUNT(*) AS txn_volume,
        SUM(f.amount * cur.rate_to_eur) AS total_value_eur
    FROM marts.fact_transactions f
    JOIN marts.dim_date d ON f.date_key = d.date_key
    JOIN marts.dim_currency cur ON cur.currency = f.currency AND cur.year = d.year
    GROUP BY d.year_month)
SELECT
    year_month,
    txn_volume,
    ROUND(total_value_eur, 2) AS total_value_eur,
    txn_volume - LAG(txn_volume) OVER (ORDER BY year_month) AS mom_volume_change,
    ROUND(100.0 * (txn_volume - LAG(txn_volume) OVER (ORDER BY year_month))
        / NULLIF(LAG(txn_volume) OVER (ORDER BY year_month), 0)
    , 2) AS mom_volume_pct
FROM monthly
ORDER BY year_month;

-- B. So sánh hoạt động giữa các tháng trong năm 
SELECT
    d.month,
    d.month_name,
    COUNT(*) AS txn_volume,
    ROUND(AVG(COUNT(*)) OVER (PARTITION BY d.month), 1) AS avg_txn_volume
FROM marts.fact_transactions f
JOIN marts.dim_date d ON f.date_key = d.date_key
GROUP BY d.month, d.month_name
ORDER BY d.month;

-- Q11. Các đề xuất sản phẩm có phù hợp với nhu cầu và hành vi thực tế không?
WITH customer_product AS ( SELECT
        f.customer_key,
        c.recommended_offer,
        p.product_category,
        COUNT(*) AS txn_volume
    FROM marts.fact_transactions f
    JOIN marts.dim_customer c ON f.customer_key = c.customer_key
    JOIN marts.dim_product p ON f.product_key = p.product_key
    GROUP BY f.customer_key, c.recommended_offer, p.product_category),
ranked AS ( SELECT
        customer_key,
        recommended_offer,
        product_category,
        txn_volume,
        ROW_NUMBER() OVER (PARTITION BY customer_key ORDER BY txn_volume DESC, product_category) AS rn
    FROM customer_product)
SELECT
    recommended_offer,
    product_category AS top_product_category,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY recommended_offer), 0), 2) AS pct_within_offer
FROM ranked
WHERE rn = 1
GROUP BY recommended_offer, product_category
ORDER BY recommended_offer, customers DESC;

-- Q12. Những xu hướng nào mới nổi lên theo thời gian giữa các phân khúc và các kênh giao dịch?
-- A. Xu hướng theo customer segment
WITH segment_month AS ( SELECT
        d.year_month,
        c.customer_segment,
        COUNT(*) AS txn_volume
    FROM marts.fact_transactions f
    JOIN marts.dim_customer c ON f.customer_key = c.customer_key
    JOIN marts.dim_date d ON f.date_key = d.date_key
    GROUP BY d.year_month, c.customer_segment)
SELECT
    year_month,
    customer_segment,
    txn_volume,
    ROUND(100.0 * txn_volume / NULLIF(SUM(txn_volume) OVER (PARTITION BY year_month), 0), 2) AS pct_of_month,
    txn_volume - LAG(txn_volume) OVER (PARTITION BY customer_segment ORDER BY year_month) AS mom_volume_change,
    ROUND(100.0 * (txn_volume - LAG(txn_volume) OVER (PARTITION BY customer_segment ORDER BY year_month))
        / NULLIF(LAG(txn_volume) OVER (PARTITION BY customer_segment ORDER BY year_month), 0)
    , 2) AS mom_volume_pct
FROM segment_month
ORDER BY customer_segment, year_month;

-- B. Xu hướng theo channel 
WITH channel_month AS ( SELECT
        d.year_month,
        ch.channel,
        COUNT(*) AS txn_volume
    FROM marts.fact_transactions f
    JOIN marts.dim_channel ch ON f.channel_key = ch.channel_key
    JOIN marts.dim_date d ON f.date_key = d.date_key
    GROUP BY d.year_month, ch.channel)
SELECT
    year_month,
    channel,
    txn_volume,
    ROUND(100.0 * txn_volume / NULLIF(SUM(txn_volume) OVER (PARTITION BY year_month), 0), 2) AS pct_of_month,
    txn_volume - LAG(txn_volume) OVER (PARTITION BY channel ORDER BY year_month) AS mom_volume_change,
    ROUND(100.0 * (txn_volume - LAG(txn_volume) OVER (PARTITION BY channel ORDER BY year_month))
        / NULLIF(LAG(txn_volume) OVER (PARTITION BY channel ORDER BY year_month), 0)
    , 2) AS mom_volume_pct
FROM channel_month
ORDER BY channel, year_month;