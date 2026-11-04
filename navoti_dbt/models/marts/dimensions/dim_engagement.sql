{{ config(unique_key='engagement_sk') }}

{#- Junk dimension for the low-cardinality ReachedStatus / Appointment flags. -#}
with src as (
    select distinct
        {{ surrogate_key(['reached_status', 'appointment']) }}  as engagement_sk,
        reached_status,
        appointment,
        reached_status = 'Yes'                                   as is_customer_reached,
        appointment = 'Yes'                                      as has_appointment,
        {{ row_hash(['reached_status', 'appointment']) }}        as row_hash
    from {{ ref('stg_sales_task') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('engagement_sk') }}
