select
    lower(trim(email))   as sales_person_email,
    trim(firstname)      as first_name,
    trim(lastname)       as last_name
from {{ source('raw', 'sales_person_master') }}
