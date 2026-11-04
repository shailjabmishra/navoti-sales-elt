{{ config(unique_key='customer_sk') }}

{#- Derived from SALES_TASK_TRANSACTION.Customer (no customer master was provided). -#}
with src as (
    select distinct
        {{ surrogate_key(['customer_name']) }}  as customer_sk,
        customer_name,
        {{ row_hash(['customer_name']) }}       as row_hash
    from {{ ref('stg_sales_task') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('customer_sk') }}
