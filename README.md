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
| `powerbi/` | Reporting (to be added) |

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
