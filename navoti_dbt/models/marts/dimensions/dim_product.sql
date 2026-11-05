{{ config(unique_key='product_sk') }}

with ranked as (
    select
        *,
        count(*) over (partition by product_code) as source_row_count,
        row_number() over (partition by product_code
                           order by product_group_code, product_name) as rn
    from {{ ref('stg_product') }}
),

src as (
    select
        {{ surrogate_key(['product_code']) }}  as product_sk,
        product_code,
        product_name,
        product_group_code,
        product_group,
        source_row_count > 1                   as is_ambiguous_code,
        source_row_count,
        {{ row_hash(['product_code', 'product_name', 'product_group_code', 'product_group', 'source_row_count']) }} as row_hash
    from ranked
    where rn = 1
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('product_sk') }}
