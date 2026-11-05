{{ config(unique_key='sales_status_sk') }}

with src as (
    select distinct
        {{ surrogate_key(['sales_state']) }}  as sales_status_sk,
        sales_state,
        case
            when sales_state in ('Success', 'Accepted')                     then 'Won'
            when sales_state in ('Lost', 'Rejected', 'Canceled', 'Deleted') then 'Lost / Closed'
            else 'In progress'
        end                                   as status_category,
        sales_state in ('Success', 'Accepted', 'Lost', 'Rejected', 'Canceled', 'Deleted') as is_closed,
        sales_state in ('Success', 'Accepted') as is_won,
        {{ row_hash(['sales_state']) }}       as row_hash
    from {{ ref('stg_sales_task') }}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('sales_status_sk') }}
