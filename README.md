# Navoti Sales – ELT pipeline (Azure Blob → Snowflake → dbt → Power BI)

End-to-end ELT for a bank sales-task dataset: CSV files in Azure Blob Storage are
loaded into Snowflake, transformed with dbt into an incrementally-merged star schema,
and reported in Power BI.

```
Azure Blob "raw"        Snowflake NAVOTI_DB                                       Power BI
 5 CSV files  ──COPY──▶  RAW (5 tables) ──dbt──▶ STAGING (5 views) ──dbt──▶ MARTS ──▶ reports
                         external stage            clean / rename         star schema
                                                                          (incremental MERGE)
```

## Repository layout

| Folder | What it contains |
|---|---|
| [`snowflake/`](snowflake) | Extract + Load: warehouse/database setup, external stage, RAW tables, `COPY INTO`, dbt key-pair auth |
| [`navoti_dbt/`](navoti_dbt) | Transform: dbt project (staging views, 10 dimensions, 1 fact, tests, macros) |
| [`powerbi/`](powerbi) | Reporting: Power BI report `Navoti_Sales.pbix` (Import mode over `NAVOTI_DB.MARTS`) |

## 1. Extract + Load (Snowflake)

Run in order in Snowsight: `01_setup.sql` → `02_stage.sql` → `03_load.sql`.

- External stage `raw_stage` points to `azure://navoti0hands0on.blob.core.windows.net/raw/` using a SAS token.
- File format handles the source quirks: **DD/MM/YYYY dates**, **Latin-1 encoding** (Finnish ä/ö), leading spaces.
- Loaded row counts: BankMaster 10 · OfficeMaster 605 · ProductMaster 210 · SalesPersonMaster 10 · SalesTaskTransaction 20,480.

## 2. Transform (dbt)

Star schema in `NAVOTI_DB.MARTS`:

| Type | Model | Grain / key |
|---|---|---|
| Fact | `fct_sales_task` | one row per SalesTaskId |
| Dim (master) | `dim_bank`, `dim_office`, `dim_product`, `dim_sales_person` | bank, office (OfficeCode2), product code, e-mail |
| Dim (derived) | `dim_customer`, `dim_channel`, `dim_sales_status`, `dim_sales_result`, `dim_engagement`, `dim_date` | derived from SalesTaskTransaction |

- **Incremental MERGE everywhere** – each model hashes its attributes (`row_hash`); only new or changed rows reach the `MERGE`
  (update on key match, insert otherwise). Verified: changing 1 source row updated exactly 1 of 20,480 fact rows.
- **52 data tests** – unique / not-null keys, accepted values, and fact → dimension relationships.
- Details: [`navoti_dbt/README.md`](navoti_dbt/README.md).

### Run
```bash
cp navoti_dbt/profiles.example.yml ~/.dbt/profiles.yml   # then edit for your account
export SNOWFLAKE_USER=<your login name>
cd navoti_dbt
dbt debug
dbt build
```

## 3. Report (Power BI)

`powerbi/Navoti_Sales.pbix` connects to Snowflake as a dedicated read-only user (`PBI_USER`, role `PBI_READER`,
`SELECT` on `NAVOTI_DB.MARTS` only) and imports the fact table and 10 dimensions.

- **Model:** star schema, every dimension → `FCT_SALES_TASK` as one-to-many with single-direction filtering;
  `DIM_DATE` marked as the date table (active relationship on `CREATED_DATE_KEY`); technical keys and audit columns hidden.
- **Measures** (in `_Measures`): Total Tasks, Total Sales / Margin / Reward Amount, Avg Margin %, Won / Lost / Open / Closed Tasks,
  Win Rate %, Won Sales Amount, Won Reward Amount, Appointment Rate %, Reach Rate %, Sales Amount PY, Sales YoY %.
- **Pages:**

| Page | Content |
|---|---|
| Overview | KPI cards, monthly sales trend, status split, sales by channel category and bank |
| Sales Team | Sales by sales person, pipeline matrix (Won / Lost / In progress), scorecard with win rate |
| Channels | Tasks by channel and direction, win rate by channel category, reached × appointment win-rate matrix |
| Products & Offices | Sales by product group, top 10 products, head office vs branch, top 10 offices |

Year and Bank slicers are synced across pages. Opening the file and refreshing requires your own Snowflake reporting user.

## Data quality findings

- **ProductCode is not unique** in ProductMaster (12 codes repeat across product groups; 1,800 transactions use them).
  `dim_product` keeps one deterministic row per code and flags `is_ambiguous_code`.
- **Office hierarchy:** OfficeCode1 = parent bank, OfficeCode2 = individual office (unique key), OfficeCode3 = OfficeCode1 + `9000`.
  Head office when OfficeCode1 = OfficeCode2.
- **Location values are mixed:** Finnish regions plus "Ohio" and "Chicago"; "Uusima" looks like a misspelling of Uusimaa.
- Created, start and closed dates are identical in every transaction (2007-02 → 2010-12).

## Security

No credentials are stored in this repository: the SAS token is a placeholder, `profiles.yml` and private keys are git-ignored,
and the source CSV files are not included.
