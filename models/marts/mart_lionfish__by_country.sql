with staging as (
    select * from {{ ref('stg_lionfish__observations') }}
),

final as (
    select
        country,
        date_trunc('month', observed_on)    as observed_month,
        date_trunc('year', observed_on)     as observed_year,
        count(*)                            as observation_count,
        count(distinct taxon_id)            as species_count,
        min(observed_on)                    as first_observation_date,
        max(observed_on)                    as latest_observation_date
    from staging
    where country is not null
    group by
        country,
        date_trunc('month', observed_on),
        date_trunc('year', observed_on)
)

select * from final