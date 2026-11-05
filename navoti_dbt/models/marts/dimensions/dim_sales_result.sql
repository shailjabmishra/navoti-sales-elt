{{ config(unique_key='sales_result_sk') }}

with src as (
    select distinct
        {{ surrogate_key(['sales_result']) }}  as sales_result_sk,
        sales_result,
        {{ row_hash(['sales_result']) }}       as row_hash
    from {{ ref('stg_sales_task') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('sales_result_sk') }}
