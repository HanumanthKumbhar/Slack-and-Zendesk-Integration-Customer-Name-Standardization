-- models/staging/stg_slack_channels.sql
{{ config(
    materialized = 'view'
) }}

SELECT
    id AS channel_id,
    name,
    -- Extract customer name (everything after the second '-')
    CASE
        WHEN LOWER(name) LIKE 'mutual-client-%'
        OR LOWER(name) LIKE 'onebeat-client-%'
        THEN INITCAP(ARRAY_TO_STRING(ARRAY_SLICE(SPLIT(name, "-"), 2, ARRAY_LENGTH(SPLIT(name, "-"))), " "))
        ELSE 'Other'
    END AS customer,
    CASE
        WHEN LOWER(name) LIKE 'mutual-client-%' THEN 'Mutual Channel'
        WHEN LOWER(name) LIKE 'onebeat-client-%' THEN 'Internal Channel'
        ELSE 'Other Channel'
    END AS channel_type
FROM {{ source('slack_zendesk', 'slack_channel') }}
