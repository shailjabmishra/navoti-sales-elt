{% macro _raw_table_ddl(create) -%}
{{ create }} NAVOTI_DB.RAW.BANK_MASTER (
  BANK VARCHAR, STATELOCATION VARCHAR,
  _FILE_NAME VARCHAR, _FILE_ROW_NUMBER NUMBER, _FILE_LAST_MODIFIED TIMESTAMP_NTZ, _LOADED_AT TIMESTAMP_LTZ);

{{ create }} NAVOTI_DB.RAW.OFFICE_MASTER (
  OFFICECODE1 NUMBER, OFFICECODE2 NUMBER, OFFICECODE3 NUMBER, OFFICENAME VARCHAR,
  _FILE_NAME VARCHAR, _FILE_ROW_NUMBER NUMBER, _FILE_LAST_MODIFIED TIMESTAMP_NTZ, _LOADED_AT TIMESTAMP_LTZ);

{{ create }} NAVOTI_DB.RAW.PRODUCT_MASTER (
  PRODUCTCODE NUMBER, PRODUCTNAME VARCHAR, PRODUCTGROUPCODE VARCHAR, PRODUCTGROUP VARCHAR,
  _FILE_NAME VARCHAR, _FILE_ROW_NUMBER NUMBER, _FILE_LAST_MODIFIED TIMESTAMP_NTZ, _LOADED_AT TIMESTAMP_LTZ);

{{ create }} NAVOTI_DB.RAW.SALES_PERSON_MASTER (
  FIRSTNAME VARCHAR, LASTNAME VARCHAR, EMAIL VARCHAR,
  _FILE_NAME VARCHAR, _FILE_ROW_NUMBER NUMBER, _FILE_LAST_MODIFIED TIMESTAMP_NTZ, _LOADED_AT TIMESTAMP_LTZ);

{{ create }} NAVOTI_DB.RAW.SALES_TASK_TRANSACTION (
  SALESTASKID NUMBER, BANK VARCHAR, CUSTOMER VARCHAR,
  OFFICECODE1 NUMBER, OFFICECODE2 NUMBER, OFFICECODE3 NUMBER,
  SALESPERSON VARCHAR, PRODUCTCODE NUMBER, CHANNEL VARCHAR, CHANNELDIRECTION VARCHAR,
  REACHEDSTATUS VARCHAR, APPOINTMENT VARCHAR, SALESRESULT VARCHAR, STATE VARCHAR,
  SALESCREATEDDATE DATE, SALESSTARTDATE DATE, SALESCLOSEDDATE DATE,
  MARGINPERCENTAGE NUMBER(10,4), SALESRESULTAMOUNT NUMBER(18,2), MARGINAMOUNT NUMBER(18,2),
  REWARDAMOUNT NUMBER(18,2), SALESTASKCOUNT NUMBER,
  _FILE_NAME VARCHAR, _FILE_ROW_NUMBER NUMBER, _FILE_LAST_MODIFIED TIMESTAMP_NTZ, _LOADED_AT TIMESTAMP_LTZ);
{%- endmacro %}

{% macro rebuild_raw_tables() %}
  {% for stmt in _raw_table_ddl('CREATE OR REPLACE TABLE').split(';') if stmt | trim %}
    {% do run_query(stmt) %}
  {% endfor %}
  {{ log('RAW tables recreated with load-metadata columns. Run: dbt run-operation load_raw', info=True) }}
{% endmacro %}

{% macro deploy_ingestion(schedule='USING CRON 0 5 * * * UTC') %}
  {% for stmt in _raw_table_ddl('CREATE TABLE IF NOT EXISTS').split(';') if stmt | trim %}
    {% do run_query(stmt) %}
  {% endfor %}

  {% set meta = "METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$FILE_LAST_MODIFIED, CURRENT_TIMESTAMP()" %}
  {% set opts = "FILE_FORMAT = (FORMAT_NAME = NAVOTI_DB.RAW.CSV_LOAD) ON_ERROR = ABORT_STATEMENT" %}

  {% set proc %}
CREATE OR REPLACE PROCEDURE NAVOTI_DB.RAW.LOAD_RAW()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  COPY INTO NAVOTI_DB.RAW.BANK_MASTER
    FROM (SELECT $1, $2, {{ meta }} FROM @NAVOTI_DB.RAW.RAW_STAGE)
    PATTERN = '.*BankMaster.*[.]csv' {{ opts }};

  COPY INTO NAVOTI_DB.RAW.OFFICE_MASTER
    FROM (SELECT $1, $2, $3, $4, {{ meta }} FROM @NAVOTI_DB.RAW.RAW_STAGE)
    PATTERN = '.*OfficeMaster.*[.]csv' {{ opts }};

  COPY INTO NAVOTI_DB.RAW.PRODUCT_MASTER
    FROM (SELECT $1, $2, $3, $4, {{ meta }} FROM @NAVOTI_DB.RAW.RAW_STAGE)
    PATTERN = '.*ProductMaster.*[.]csv' {{ opts }};

  COPY INTO NAVOTI_DB.RAW.SALES_PERSON_MASTER
    FROM (SELECT $1, $2, $3, {{ meta }} FROM @NAVOTI_DB.RAW.RAW_STAGE)
    PATTERN = '.*SalesPersonMaster.*[.]csv' {{ opts }};

  COPY INTO NAVOTI_DB.RAW.SALES_TASK_TRANSACTION
    FROM (SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
                 TO_DATE($15, 'DD/MM/YYYY'), TO_DATE($16, 'DD/MM/YYYY'), TO_DATE($17, 'DD/MM/YYYY'),
                 $18, $19, $20, $21, $22, {{ meta }}
          FROM @NAVOTI_DB.RAW.RAW_STAGE)
    PATTERN = '.*SalesTaskTransaction.*[.]csv' {{ opts }};

  RETURN 'LOAD_RAW finished at ' || CURRENT_TIMESTAMP()::VARCHAR;
END;
$$
  {% endset %}
  {% do run_query(proc) %}

  {% do run_query("CREATE OR REPLACE TASK NAVOTI_DB.RAW.LOAD_RAW_TASK WAREHOUSE = LAB_WH SCHEDULE = '" ~ schedule ~ "' COMMENT = 'Daily incremental load of new/changed files from Azure' AS CALL NAVOTI_DB.RAW.LOAD_RAW()") %}
  {% do run_query("ALTER TASK NAVOTI_DB.RAW.LOAD_RAW_TASK RESUME") %}
  {{ log('Deployed NAVOTI_DB.RAW.LOAD_RAW() and task LOAD_RAW_TASK (' ~ schedule ~ ', resumed).', info=True) }}
{% endmacro %}

{% macro load_raw() %}
  {% set res = run_query('CALL NAVOTI_DB.RAW.LOAD_RAW()') %}
  {{ log(res.rows[0][0], info=True) }}
  {% set counts = run_query("
      select 'BANK_MASTER' t, count(*) n, max(_loaded_at) last_load from NAVOTI_DB.RAW.BANK_MASTER
      union all select 'OFFICE_MASTER', count(*), max(_loaded_at) from NAVOTI_DB.RAW.OFFICE_MASTER
      union all select 'PRODUCT_MASTER', count(*), max(_loaded_at) from NAVOTI_DB.RAW.PRODUCT_MASTER
      union all select 'SALES_PERSON_MASTER', count(*), max(_loaded_at) from NAVOTI_DB.RAW.SALES_PERSON_MASTER
      union all select 'SALES_TASK_TRANSACTION', count(*), max(_loaded_at) from NAVOTI_DB.RAW.SALES_TASK_TRANSACTION") %}
  {% for r in counts.rows %}
    {{ log(r[0] ~ ': ' ~ r[1] ~ ' rows, last load ' ~ r[2], info=True) }}
  {% endfor %}
{% endmacro %}
