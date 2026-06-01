with staging as (
    select * from {{ ref('stg_lionfish__observations') }}
),

final as (
    select
        observed_on,
        date_trunc('month', observed_on)    as observed_month,
        date_trunc('year', observed_on)     as observed_year,
        taxon_id,
        taxon_name,
        taxon_common_name,
        count(*)                            as observation_count,
        count(distinct country)             as countries_observed_in
    from staging
    group by
        observed_on,
        date_trunc('month', observed_on),
        date_trunc('year', observed_on),
        taxon_id,
        taxon_name,
        taxon_common_name
)

select * from final