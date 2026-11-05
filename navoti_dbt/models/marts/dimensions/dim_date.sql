{{ config(unique_key='date_key') }}

with bounds as (
    select
        date_trunc('year', min(least(sales_created_date, sales_start_date, sales_closed_date)))  as start_date,
        last_day(max(greatest(sales_created_date, sales_start_date, sales_closed_date)), 'year') as end_date
    from {{ ref('stg_sales_task') }}
),

days as (
    select
        dateadd(day, row_number() over (order by seq4()) - 1, b.start_date) as calendar_date,
        b.end_date
    from bounds b, table(generator(rowcount => 20000))
),

src as (
    select
        to_number(to_char(calendar_date, 'YYYYMMDD'))  as date_key,
        calendar_date,
        year(calendar_date)                            as year,
        quarter(calendar_date)                         as quarter,
        'Q' || quarter(calendar_date)                  as quarter_name,
        month(calendar_date)                           as month,
        monthname(calendar_date)                       as month_name,
        to_char(calendar_date, 'YYYY-MM')              as year_month,
        weekofyear(calendar_date)                      as week_of_year,
        day(calendar_date)                             as day_of_month,
        dayofweekiso(calendar_date)                    as day_of_week,
        dayname(calendar_date)                         as day_name,
        dayofweekiso(calendar_date) in (6, 7)          as is_weekend,
        {{ row_hash(['calendar_date']) }}              as row_hash
    from days
    where calendar_date <= end_date
)

select
    src.*,
    current_timestamp() as dw_inserted_at,
    current_timestamp() as dw_updated_at
from src
{{ only_new_or_changed('date_key') }}
