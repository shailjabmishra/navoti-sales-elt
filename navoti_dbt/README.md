# navoti_sales dbt project

Star schema over `NAVOTI_DB.RAW` (loaded from the Azure `raw` container).

```
RAW (COPY INTO)  ->  STAGING (views: clean / rename)  ->  MARTS (incremental MERGE)
```

## Models

| Layer | Model | Grain / key | Source |
|---|---|---|---|
| Staging | stg_bank, stg_office, stg_product, stg_sales_person, stg_sales_task | 1:1 with RAW | RAW tables |
| Dimension | dim_bank | bank_name | BankMaster |
| Dimension | dim_office | office_code2 (+ head office / branch) | OfficeMaster |
| Dimension | dim_product | product_code (ambiguous codes flagged) | ProductMaster |
| Dimension | dim_sales_person | e-mail | SalesPersonMaster |
| Dimension (derived) | dim_customer | customer name | SalesTaskTransaction |
| Dimension (derived) | dim_channel | channel + direction | SalesTaskTransaction |
| Dimension (derived) | dim_sales_status | state → Won / Lost / In progress | SalesTaskTransaction |
| Dimension (derived) | dim_sales_result | sales result | SalesTaskTransaction |
| Dimension (derived) | dim_engagement | reached status + appointment (junk dim) | SalesTaskTransaction |
| Dimension (derived) | dim_date | YYYYMMDD | generated from transaction dates |
| Fact | fct_sales_task | sales_task_id | SalesTaskTransaction |

## How incremental loading works

Every mart model is `materialized: incremental`, `incremental_strategy: merge`, with a `unique_key`.

1. **First run:** the table is created from all rows.
2. **Later runs:** each model computes a `row_hash` of its attributes and sends only rows that are
   **new or changed** (hash differs from the target) to a Snowflake `MERGE`:
   matching keys are **updated**, new keys are **inserted**, unchanged rows are not touched.
3. `dw_inserted_at` is kept on update (`merge_exclude_columns`); `dw_updated_at` shows the last change.

Avoid `--full-refresh` unless you deliberately want to rebuild.

## Run

```bash
# one-time: copy profiles.example.yml to ~/.dbt/profiles.yml and set credentials
set SNOWFLAKE_USER=<your user>
set SNOWFLAKE_PASSWORD=<your password>

dbt debug      # test the connection
dbt build      # run models + tests
```
