select
    lower(trim(email))   as sales_person_email,
    trim(firstname)      as first_name,
    trim(lastname)       as last_name
from {{ source('raw', 'sales_person_master') }}
qualify row_number() over (
    partition by lower(trim(email))
    order by _file_last_modified desc, _loaded_at desc, _file_row_number desc
) = 1
