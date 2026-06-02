with source as (
    select * from {{ source('raw', 'incremental_observations') }}
),

flattened as (
    select
        obs.value as observation
    from source,
    lateral flatten(input => raw_data:results) obs
    where raw_data:results is not null
),

renamed as (
    select
        (observation:id)::integer                               as observation_id,
        (observation:uuid)::varchar                             as uuid,
        (observation:observed_on)::date                         as observed_on,
        null::varchar                                           as country,
        split_part((observation:location)::varchar, ',', 1)::float as latitude,
        split_part((observation:location)::varchar, ',', 2)::float as longitude,
        (observation:taxon.name)::varchar                       as taxon_name,
        (observation:taxon.preferred_common_name)::varchar      as taxon_common_name,
        (observation:quality_grade)::varchar                    as quality_grade,
        (observation:captive)::boolean                          as captive,
        'incremental'::varchar                                  as ingestion_source
    from flattened
    where observation_id is not null
)

select * from renamed