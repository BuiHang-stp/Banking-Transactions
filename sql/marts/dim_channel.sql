/* marts.dim_channel
   Grain: 1 dòng = 1 kênh giao dịch */

DROP TABLE IF EXISTS marts.dim_channel;
CREATE TABLE marts.dim_channel AS
SELECT
    ROW_NUMBER() OVER(
        ORDER BY
        ch.channel) 
    AS channel_key,
    ch.channel
FROM (
    SELECT DISTINCT
    channel
FROM staging.stg_transactions) ch;