{{ config(unique_key='sales_task_id') }}

with src as (
    select
        sales_task_id,

        {{ surrogate_key(['bank_name']) }}                         as bank_sk,
        {{ surrogate_key(['office_code2']) }}                      as office_sk,
        {{ surrogate_key(['product_code']) }}                      as product_sk,
        {{ surrogate_key(['sales_person_email']) }}                as sales_person_sk,
        {{ surrogate_key(['customer_name']) }}                     as customer_sk,
        {{ surrogate_key(['channel', 'channel_direction']) }}      as channel_sk,
        {{ surrogate_key(['sales_state']) }}                       as sales_status_sk,
        {{ surrogate_key(['sales_result']) }}                      as sales_result_sk,
        {{ surrogate_key(['reached_status', 'appointment']) }}     as engagement_sk,
        to_number(to_char(sales_created_date, 'YYYYMMDD'))         as created_date_key,
        to_number(to_char(sales_start_date,   'YYYYMMDD'))         as start_date_key,
        to_number(to_char(sales_closed_date,  'YYYYMMDD'))         as closed_date_key,

        margin_percentage,
        sales_result_amount,
        margin_amount,
        reward_amount,
        sales_task_count,

        source_loaded_at,

        {{ row_hash([
            'bank_name', 'office_code2', 'product_code', 'sales_person_email', 'customer_name',
            'channel', 'channel_direction', 'sales_state', 'sales_result', 'reached_status', 'appointment',
            'sales_created_date', 'sales_start_date', 'sales_closed_date',
            'margin_percentage', 'sales_result_amount', 'margin_amount', 'reward_amount', 'sales_task_count'
        ]) }}                                                      as row_hash
    from {{ ref('stg_sales_task') }}

    {% if is_incremental() %}
    where source_loaded_at > (
        select coalesce(max(source_loaded_at), '1900-01-01'::timestamp_ltz) from {{ this }}
    )
    {% endif %}
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('sales_task_id') }}
