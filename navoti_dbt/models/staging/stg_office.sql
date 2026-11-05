-- Latest version of each office (OfficeCode2 is the unique office key; RAW is append-only)
select
    officecode1                                        as office_code1,
    officecode2                                        as office_code2,
    officecode3                                        as office_code3,
    trim(officename)                                   as office_name_raw,
    -- name without the trailing 10-digit code, e.g. "Akaan Seudun Osuuspankki Pääkonttori"
    trim(regexp_replace(officename, '[[:space:]]*[0-9]{10}[[:space:]]*$', '')) as office_name
from {{ source('raw', 'office_master') }}
qualify row_number() over (
    partition by officecode2
    order by _file_last_modified desc, _loaded_at desc, _file_row_number desc
) = 1
