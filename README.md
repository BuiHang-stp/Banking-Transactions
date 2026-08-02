# Banking Transaction Analytics

Analytics pipeline over 20,000 Spanish retail-banking transactions: Python profiling → PostgreSQL (raw → staging → marts, star schema) → SQL analysis → Power BI. Answers 12 business questions on customer segmentation, transaction behaviour, fee revenue and seasonality.

<p align="left">
  <img src="https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-compose-2496ED?logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Power_BI-Desktop-F2C811?logo=powerbi&logoColor=black" />
  <img src="https://img.shields.io/badge/license-MIT-green" />
</p>


## Dashboard

Three pages — Customer & Segment · Transaction Behaviour · Revenue & Cost. Each page follows Descriptive → Diagnostic → Predictive → Prescriptive and ends with a quantified recommendation.

<!--
<table>
  <tr>
    <td width="50%" align="center">
      <a href="dashboard/screenshots/01_customer.png">
        <img src="dashboard/screenshots/01_customer.png" width="100%" alt="Customer and Segment"/>
      </a>
      <br/><sub><b>Page 1 — Customer &amp; Segment</b></sub>
    </td>
    <td width="50%" align="center">
      <a href="dashboard/screenshots/02_behaviour.png">
        <img src="dashboard/screenshots/02_behaviour.png" width="100%" alt="Transaction Behaviour"/>
      </a>
      <br/><sub><b>Page 2 — Transaction Behaviour</b></sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <a href="dashboard/screenshots/03_revenue.png">
        <img src="dashboard/screenshots/03_revenue.png" width="100%" alt="Revenue and Cost"/>
      </a>
      <br/><sub><b>Page 3 — Revenue &amp; Cost</b></sub>
    </td>
    <td width="50%"></td>
  </tr>
</table>
-->



## 1. Business Context

A retail bank holds transaction-level data across checking accounts, loans, mortgages and card payments, enriched with customer income band, credit score, branch location, channel and the marketing offer assigned to each customer.

The bank wants to use this data to:

- **Personalise** product recommendations to how customers actually behave
- **Assess** customer-level risk and profitability
- **Refine** marketing campaigns to the segments that respond
- **Optimise** branch and channel performance

### Dataset

| Attribute | Value |
|---|---|
| Records | 20,000 transactions |
| Market | Spain |
| Product lines | Checking accounts, loans, mortgages, card payments |
| Customer attributes | Monthly income, income segment, credit score, recommended offer |
| Transaction attributes | Type, amount, currency, credit-card fees, insurance fees, late-payment amount |
| Operational attributes | Branch city + coordinates, channel (ATM / Mobile / Branch) |
| Time span | ~871 distinct dates |



## 2. Business Questions

Twelve questions in four groups. Each group maps to one SQL file and one dashboard section.

### Group 1 — Customer Insight & Segmentation → `01_customer_segmentation.sql`

| # | Question |
|---|---|
| 1 | Which customer segments are the most transaction-active? |
| 2 | Which financial products are preferred within each segment? |
| 3 | Does credit score correlate with transaction frequency or total accumulated fees? |

### Group 2 — Transaction Behaviour → `02_transaction_behaviour.sql`

| # | Question |
|---|---|
| 4 | Which transaction types dominate by volume (count) and by value (amount)? |
| 5 | Which cities or branches are transaction hotspots, and which underperform? |
| 6 | How do usage habits differ across Mobile, ATM and Branch channels? |

### Group 3 — Revenue & Cost → `03_fee_revenue.sql`

| # | Question |
|---|---|
| 7 | Which transaction types generate the most fee revenue (card fees, insurance, late payment)? |
| 8 | Are any customer groups bearing a disproportionate share of fees? |
| 9 | Which friction points recur most often while still generating revenue? |

### Group 4 — Trends & Performance → `04_trends_over_time.sql`

| # | Question |
|---|---|
| 10 | Are there monthly or seasonal peaks and troughs in transaction activity? |
| 11 | Do recommended offers actually match customer needs and observed behaviour? |
| 12 | Which trends are emerging over time across segments and channels? |



## 3. Question-to-Model Mapping

Which dimension each question needs. This drove the star schema design — the model was built from the questions, not the other way round.

| # | Question | Customer | Date | Branch | Channel | Txn Type | Product |
|---|---|:--:|:--:|:--:|:--:|:--:|:--:|
| 1 | Most active segments | ✓ | | | | ✓ | |
| 2 | Product preference by segment | ✓ | | | | | ✓ |
| 3 | Credit score vs fees | ✓ | | | | | |
| 4 | Dominant transaction types | | | | | ✓ | |
| 5 | Branch / city hotspots | | | ✓ | | ✓ | |
| 6 | Channel differences by segment | ✓ | | | ✓ | ✓ | |
| 7 | Fee revenue by transaction type | | | | | ✓ | ✓ |
| 8 | Disproportionate fee burden | ✓ | | | | | ✓ |
| 9 | Friction points driving revenue | ✓ | | | ✓ | | |
| 10 | Seasonality | | ✓ | | | | |
| 11 | Offer vs behaviour fit | ✓ | | | | | ✓ |
| 12 | Emerging trends | ✓ | ✓ | | ✓ | | |



## 4. Architecture

```mermaid
flowchart LR
    A["Source file<br/>20,000 rows"] --> B["Python<br/>profiling"]
    B --> C["raw.transactions<br/>all text, unmodified"]
    C --> D["staging.stg_transactions<br/>typed · parsed · standardised"]
    D --> E["marts<br/>star schema"]
    E --> F["sql/analysis<br/>q01 – q12"]
    E --> G["Power BI<br/>3 pages"]
    E --> H["sql/tests<br/>data quality"]
```

**Three-schema separation** in PostgreSQL:

| Schema | Role | Rule |
|---|---|---|
| `raw` | Landing zone | Loaded as text, never modified. Reproducibility anchor. |
| `staging` | Cleaning | Type casting, date parsing, text standardisation, derived columns (`direction`, `total_fees`, `amount_base`). |
| `marts` | Serving | Star schema. The only layer Power BI and the analysis queries read from. |

### Star Schema

```mermaid
erDiagram
    dim_date            ||--o{ fact_transactions : ""
    dim_customer        ||--o{ fact_transactions : ""
    dim_product         ||--o{ fact_transactions : ""
    dim_branch          ||--o{ fact_transactions : ""
    dim_channel         ||--o{ fact_transactions : ""
    dim_transaction_type||--o{ fact_transactions : ""
    dim_marketing       ||--o{ fact_transactions : ""
```

**Grain:** one row per transaction.
**Measures:** `amount`, `credit_card_fees`, `insurance_fees`, `late_payment_amount`, `total_fees`.

A supporting view `marts.v_fee_detail` unpivots the three fee columns into one fee-type column, so Group 3 questions can be answered with a single grouping instead of three parallel aggregations.



## 5. Data Profiling Findings

The source is a **denormalised flat file with no physical foreign keys**. Profiling found four functional dependencies that hold on 100% of rows — these justify the dimension split:

| # | Dependency | Consequence |
|---|---|---|
| 1 | `BranchCity → BranchLat/Long` (1:1) | A clean `dim_branch` can be extracted without ambiguity |
| 2 | `MonthlyIncome → CustomerSegment` | Segment is a hard bin at €3,000 and €7,000, not an independent attribute |
| 3 | `CustomerSegment → RecommendedOffer` | Each offer belongs to exactly one segment — critical caveat for Q11 |
| 4 | Product/type ↔ fee columns | `Credit Card ⟺ CreditCardFees > 0`; `Loan ⟺ InsuranceFees > 0`; `Loan Payment ⟺ LatePaymentAmount > 0` |

**Why dependency 3 matters.** If every offer is mechanically derived from income band, Q11 ("do offers match behaviour?") cannot measure recommendation *quality* — it can only measure whether income-based targeting happens to align with observed product usage. This limitation is stated explicitly in the Q11 output rather than glossed over.

### Seven Risk Checks Run Before Loading

1. Duplicate `TransactionID`
2. Number of distinct currencies (determines whether `amount_base` conversion is needed)
3. Sign convention of `Amount` (inflow vs outflow encoding)
4. Stability of the four customer attributes per `CustomerID`
5. Number of coordinate pairs per `BranchCity`
6. Overlap between `TransactionType = 'Fee'` and the three fee columns (double-count risk)
7. Length and continuity of the time axis


## 6. Open Questions from Profiling

Documented rather than assumed away:

- **Is `LatePaymentAmount` fee revenue or outstanding overdue balance?** These are different things and cannot be summed into `total_fees` together. Resolution determines the Q7 and Q9 methodology.
- **Is `dim_customer` a real dimension?** If the number of distinct customers approaches the number of transactions, the customer dimension is degenerate and all "customer behaviour" questions collapse into "transaction attribute" questions. Profiling confirms the true customer grain before the marts layer is built.
- **What counts as a "friction point" (Q9)?** Defined as a measurable criterion — repeated fee-bearing events for the same customer within a period — before any query is written, so the answer is not retrofitted to whatever the data shows.



## 7. Key Findings



## 8. Recommendations



## 9. Limitations

- Synthetic / simulated dataset — figures illustrate methodology, not any real institution's performance.
- `RecommendedOffer` is deterministically derived from income segment, which caps what Q11 can conclude.
- No time-series depth per customer beyond the observed window, so churn and lifetime-value questions are out of scope.
- Single market (Spain); findings do not generalise across regulatory environments.

---

## Author

Bùi Thu Hằng — Data Analyst

[LinkedIn](https://www.linkedin.com/in/buithuhang/) · [Email](mailto:hangbui.bda@gmail.com)
