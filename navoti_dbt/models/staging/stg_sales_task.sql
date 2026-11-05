{#-
  RAW is append-only: a task can appear in several loaded files (or file versions).
  Keep only its latest version: newest file modification time, then newest load, then last row.
-#}
with latest as (
    select *
    from {{ source('raw', 'sales_task_transaction') }}
    qualify row_number() over (
        partition by salestaskid
        order by _file_last_modified desc, _loaded_at desc, _file_row_number desc
    ) = 1
)

select
    salestaskid                 as sales_task_id,
    trim(bank)                  as bank_name,
    trim(customer)              as customer_name,
    officecode1                 as office_code1,
    officecode2                 as office_code2,
    officecode3                 as office_code3,
    lower(trim(salesperson))    as sales_person_email,
    productcode                 as product_code,
    trim(channel)               as channel,
    trim(channeldirection)      as channel_direction,
    trim(reachedstatus)         as reached_status,
    trim(appointment)           as appointment,
    trim(salesresult)           as sales_result,
    trim(state)                 as sales_state,
    salescreateddate            as sales_created_date,
    salesstartdate              as sales_start_date,
    salescloseddate             as sales_closed_date,
    marginpercentage            as margin_percentage,
    salesresultamount           as sales_result_amount,
    marginamount                as margin_amount,
    rewardamount                as reward_amount,
    salestaskcount              as sales_task_count,
    _loaded_at                  as source_loaded_at,
    _file_name                  as source_file_name
from latest
