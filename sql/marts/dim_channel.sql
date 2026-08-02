/* marts.dim_channel
   Grain: 1 dòng = 1 kênh giao dịch */

DROP TABLE IF EXISTS marts.dim_channel;
CREATE TABLE marts.dim_channel AS
SELECT
    ROW_NUMBER() OVER(
        ORDER BY
        ch.channel,
        ch.currency) 
    AS channel_key,
    ch.channel,
    ch.currency
FROM (
    SELECT DISTINCT
    channel,
    currency
FROM staging.stg_transactions) ch;