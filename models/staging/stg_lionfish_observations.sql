WITH bulk AS (
    SELECT
        ID::INTEGER                                         AS observation_id,
        UUID::VARCHAR                                       AS uuid,
        OBSERVED_ON::DATE                                   AS observed_on,
        CREATED_AT::TIMESTAMP_TZ                           AS created_at,
        UPDATED_AT::TIMESTAMP_TZ                           AS updated_at,
        QUALITY_GRADE::VARCHAR                              AS quality_grade,
        PLACE_GUESS::VARCHAR                               AS place_guess,
        PLACE_COUNTRY_NAME::VARCHAR                        AS country,
        LATITUDE::FLOAT                                     AS latitude,
        LONGITUDE::FLOAT                                    AS longitude,
        POSITIONAL_ACCURACY::INTEGER                        AS positional_accuracy,
        COORDINATES_OBSCURED::BOOLEAN                       AS coordinates_obscured,
        CAPTIVE_CULTIVATED::BOOLEAN                         AS captive,
        DESCRIPTION::VARCHAR                               AS description,
        URL::VARCHAR                                       AS uri,
        IMAGE_URL::VARCHAR                                 AS taxon_photo_url,
        SCIENTIFIC_NAME::VARCHAR                           AS taxon_name,
        COMMON_NAME::VARCHAR                               AS taxon_common_name,
        TAXON_ID::INTEGER                                   AS taxon_id,
        USER_ID::INTEGER                                    AS user_id,
        USER_LOGIN::VARCHAR                                AS user_login,
        'bulk'::VARCHAR                                    AS ingestion_source
    FROM {{ source('raw', 'bulk_observations') }}
    WHERE QUALITY_GRADE = 'research'
      AND CAPTIVE_CULTIVATED = FALSE
),

incremental AS (
    SELECT
        (RAW_DATA:id)::INTEGER                             AS observation_id,
        (RAW_DATA:uuid)::VARCHAR                           AS uuid,
        (RAW_DATA:observed_on)::DATE                       AS observed_on,
        NULL::TIMESTAMP_TZ                                 AS created_at,
        NULL::TIMESTAMP_TZ                                 AS updated_at,
        (RAW_DATA:quality_grade)::VARCHAR                  AS quality_grade,
        (RAW_DATA:place_guess)::VARCHAR                    AS place_guess,
        NULL::VARCHAR                                      AS country,
        SPLIT_PART((RAW_DATA:location)::VARCHAR, ',', 1)::FLOAT AS latitude,
        SPLIT_PART((RAW_DATA:location)::VARCHAR, ',', 2)::FLOAT AS longitude,
        (RAW_DATA:positional_accuracy)::INTEGER            AS positional_accuracy,
        (RAW_DATA:obscured)::BOOLEAN                       AS coordinates_obscured,
        (RAW_DATA:captive)::BOOLEAN                        AS captive,
        (RAW_DATA:description)::VARCHAR                    AS description,
        (RAW_DATA:uri)::VARCHAR                            AS uri,
        (RAW_DATA:taxon.default_photo.url)::VARCHAR        AS taxon_photo_url,
        (RAW_DATA:taxon.name)::VARCHAR                     AS taxon_name,
        (RAW_DATA:taxon.preferred_common_name)::VARCHAR    AS taxon_common_name,
        (RAW_DATA:taxon.id)::INTEGER                       AS taxon_id,
        (RAW_DATA:user.id)::INTEGER                        AS user_id,
        (RAW_DATA:user.login)::VARCHAR                     AS user_login,
        'incremental'::VARCHAR                             AS ingestion_source
    FROM {{ source('raw', 'incremental_observations') }},
    LATERAL FLATTEN(input => RAW_DATA:results) obs
    WHERE (RAW_DATA:results) IS NOT NULL
      AND (obs.value:quality_grade)::VARCHAR = 'research'
      AND (obs.value:captive)::BOOLEAN = FALSE
),

combined AS (
    SELECT * FROM bulk
    UNION ALL
    SELECT * FROM incremental
),

deduplicated AS (
    SELECT *
    FROM combined
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY uuid
        ORDER BY ingestion_source DESC
    ) = 1
)

SELECT * FROM deduplicated