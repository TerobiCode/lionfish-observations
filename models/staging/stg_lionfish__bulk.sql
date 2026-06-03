with source as (
    select * from {{ source('raw', 'bulk_observations') }}
),

renamed as (
    select
        id::integer                 as observation_id,
        uuid::varchar               as uuid,
        observed_on::date           as observed_on,
        place_country_name::varchar as country,
        latitude::float             as latitude,
        longitude::float            as longitude,
        scientific_name::varchar    as latin_name,
        common_name::varchar        as common_name,
        quality_grade::varchar      as quality_grade,
        captive_cultivated::boolean as captive,
        'bulk'::varchar             as ingestion_source
    from source
    where id is not null
)

select * from renamed