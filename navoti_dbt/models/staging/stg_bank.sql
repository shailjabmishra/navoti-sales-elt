select
    trim(bank)           as bank_name,
    trim(statelocation)  as state_location
from {{ source('raw', 'bank_master') }}
