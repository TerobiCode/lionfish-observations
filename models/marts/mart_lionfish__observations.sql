with intermediate as (
    select * from {{ ref('int_lionfish__observations') }}
),

final as (
    select
        observation_id,
        uuid,
        observed_on,
        date_trunc('year', observed_on) as observed_year,
        country,
        latitude,
        longitude,
        latin_name,
        common_name,
        ingestion_source
    from intermediate
)

select * from final