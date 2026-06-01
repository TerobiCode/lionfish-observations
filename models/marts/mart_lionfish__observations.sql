with staging as (
    select * from {{ ref('stg_lionfish__observations') }}
),

final as (
    select
        observation_id,
        uuid,
        observed_on,
        date_trunc('month', observed_on)    as observed_month,
        date_trunc('year', observed_on)     as observed_year,
        country,
        latitude,
        longitude,
        taxon_id,
        taxon_name,
        taxon_common_name,
        ingestion_source
    from staging
)

select * from final