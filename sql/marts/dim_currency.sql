DROP TABLE IF EXISTS marts.dim_currency;
CREATE TABLE marts.dim_currency (
    currency text NOT NULL,
    year int NOT NULL,
    rate_to_eur numeric(12,6) NOT NULL,
    rate_source text,
    PRIMARY KEY (currency, year));
INSERT INTO marts.dim_currency VALUES
    ('EUR', 2023, 1.000000, 'base'),
    ('EUR', 2024, 1.000000, 'base'),
    ('EUR', 2025, 1.000000, 'base'),
    ('USD', 2023, 0.924800, 'ECB annual average'),
    ('USD', 2024, 0.924100, 'ECB annual average'),
    ('USD', 2025, 0.886700, 'ECB annual average');