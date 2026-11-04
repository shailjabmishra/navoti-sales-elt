{{ config(unique_key='sales_person_sk') }}

with src as (
    select
        {{ surrogate_key(['sales_person_email']) }}  as sales_person_sk,
        sales_person_email,
        first_name,
        last_name,
        first_name || ' ' || last_name               as full_name,
        {{ row_hash(['sales_person_email', 'first_name', 'last_name']) }} as row_hash
    from {{ ref('stg_sales_person') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('sales_person_sk') }}
