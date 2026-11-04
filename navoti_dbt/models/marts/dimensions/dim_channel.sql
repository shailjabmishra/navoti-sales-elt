{{ config(unique_key='channel_sk') }}

{#- Derived from Channel + ChannelDirection. -#}
with src as (
    select distinct
        {{ surrogate_key(['channel', 'channel_direction']) }}  as channel_sk,
        channel,
        channel_direction,
        case
            when channel in ('Phone', 'Letter') then 'Remote'
            when channel = 'The system'         then 'Digital'
            when channel = 'Partner'            then 'Partner'
            else 'In-person'
        end                                                   as channel_category,
        {{ row_hash(['channel', 'channel_direction']) }}      as row_hash
    from {{ ref('stg_sales_task') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('channel_sk') }}
