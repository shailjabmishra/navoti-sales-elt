-- Latest version of each bank across all loaded files (RAW is append-only)
select
    trim(bank)           as bank_name,
    trim(statelocation)  as state_location
from {{ source('raw', 'bank_master') }}
qualify row_number() over (
    partition by trim(bank)
    order by _file_last_modified desc, _loaded_at desc, _file_row_number desc
) = 1
