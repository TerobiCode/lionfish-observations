with bulk as (
    select * from {{ ref('stg_lionfish__bulk') }}
),

incremental as (
    select * from {{ ref('stg_lionfish__incremental') }}
),

combined as (
    select * from bulk
    union all
    select * from incremental
),

validated as (
    select *
    from combined
    where quality_grade = 'research'
      and captive = false
      and latitude between -90 and 90
      and longitude between -180 and 180
      and observed_on is not null
      and taxon_name is not null
),

deduplicated as (
    select *
    from validated
    qualify row_number() over (
        partition by uuid
        order by ingestion_source desc
    ) = 1
)

select * from deduplicated