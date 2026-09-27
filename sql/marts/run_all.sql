BEGIN;
\i sql/marts/dim_date.sql
\i sql/marts/dim_customer.sql
\i sql/marts/dim_product.sql
\i sql/marts/dim_branch.sql
\i sql/marts/dim_channel.sql
\i sql/marts/dim_currency.sql
\i sql/marts/dim_transaction_type.sql
\i sql/marts/fact_transactions.sql
\i sql/marts/v_fee_detail.sql
COMMIT;