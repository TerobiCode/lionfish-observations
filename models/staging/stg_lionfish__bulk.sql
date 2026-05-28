with source as (
    select *
    from {{ source('raw', 'bulk_observations') }}
),

cleaned as (
    select
        id::integer                 as observation_id,
        uuid::varchar               as uuid,
        observed_on::date           as observed_on,
        place_country_name::varchar as country,
        latitude::float             as latitude,
        longitude::float            as longitude,
        taxon_id::integer           as taxon_id,
        scientific_name::varchar    as taxon_name,
        common_name::varchar        as taxon_common_name,
        'bulk'::varchar             as ingestion_source
    from source
    where quality_grade = 'research'
      and captive_cultivated = false
      and id is not null
      and uuid is not null
      and observed_on is not null
      and latitude between -90 and 90
      and longitude between -180 and 180
)

select * from cleaned