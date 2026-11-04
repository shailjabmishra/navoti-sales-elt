{{ config(unique_key='bank_sk') }}

with src as (
    select
        {{ surrogate_key(['bank_name']) }}                 as bank_sk,
        bank_name,
        state_location,
        {{ row_hash(['bank_name', 'state_location']) }}    as row_hash
    from {{ ref('stg_bank') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('bank_sk') }}
