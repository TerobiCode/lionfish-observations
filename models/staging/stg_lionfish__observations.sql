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

deduplicated as (
    select *
    from combined
    qualify row_number() over (
        partition by uuid
        order by ingestion_source desc
    ) = 1
)

select * from deduplicated