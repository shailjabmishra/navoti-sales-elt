{{ config(unique_key='office_sk') }}

with src as (
    select
        {{ surrogate_key(['office_code2']) }}  as office_sk,
        office_code2,
        office_code1,
        office_code3,
        office_name,
        office_code1 = office_code2            as is_head_office,
        iff(office_code1 = office_code2, 'Head office', 'Branch') as office_type,
        {{ row_hash(['office_code2', 'office_code1', 'office_code3', 'office_name']) }} as row_hash
    from {{ ref('stg_office') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('office_sk') }}
