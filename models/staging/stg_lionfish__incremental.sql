with source as (
    select *
    from {{ source('raw', 'incremental_observations') }}
),

flattened as (
    select
        obs.value                   as observation
    from source,
    lateral flatten(input => raw_data:results) obs
    where raw_data:results is not null
),

cleaned as (
    select
        (observation:id)::integer                               as observation_id,
        (observation:uuid)::varchar                             as uuid,
        (observation:observed_on)::date                         as observed_on,
        null::varchar                                           as country,
        split_part((observation:location)::varchar, ',', 1)::float as latitude,
        split_part((observation:location)::varchar, ',', 2)::float as longitude,
        (observation:taxon.id)::integer                         as taxon_id,
        (observation:taxon.name)::varchar                       as taxon_name,
        (observation:taxon.preferred_common_name)::varchar      as taxon_common_name,
        'incremental'::varchar                                  as ingestion_source
    from flattened
    where (observation:quality_grade)::varchar = 'research'
      and (observation:captive)::boolean = false
      and (observation:id) is not null
      and (observation:uuid) is not null
      and (observation:observed_on) is not null
      and split_part((observation:location)::varchar, ',', 1)::float between -90 and 90
      and split_part((observation:location)::varchar, ',', 2)::float between -180 and 180
)

select * from cleaned