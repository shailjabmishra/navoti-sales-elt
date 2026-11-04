select
    productcode              as product_code,
    trim(productname)        as product_name,
    trim(productgroupcode)   as product_group_code,
    trim(productgroup)       as product_group
from {{ source('raw', 'product_master') }}
