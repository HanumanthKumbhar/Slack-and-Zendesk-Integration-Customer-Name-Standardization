-- models/marts/mart_customer_name_mapping.sql
{{ config(
    materialized = 'table'
) }}

WITH slack_customers AS (
    -- Get distinct cleaned customer names from Slack channels
    SELECT DISTINCT
        COALESCE(cm.canonical, sc.customer) AS slack_customer_name
    FROM {{ ref('stg_slack_channels') }} sc
    LEFT JOIN {{ ref('int_slack_canonical_mapping') }} cm
        ON sc.customer = cm.variant
    WHERE COALESCE(cm.canonical, sc.customer) != 'Other'
),

zendesk_matches AS (
    -- Get the best Zendesk match for each Slack customer
    SELECT 
        slack_customer_name,
        ARRAY_AGG(zendesk_org_name ORDER BY distance ASC LIMIT 1)[OFFSET(0)] AS best_zendesk_match,
        MIN(distance) AS match_distance
    FROM {{ ref('int_slack_zendesk_name_comparison') }}
    GROUP BY slack_customer_name
)

-- Final mapping with match quality indicator
SELECT
    sc.slack_customer_name,
    zm.best_zendesk_match AS zendesk_organization_name,
    CASE
        WHEN zm.match_distance IS NULL THEN 'No Match'
        WHEN zm.match_distance = 0 THEN 'Exact Match'
        WHEN zm.match_distance = 1 THEN 'Very Close Match'
        WHEN zm.match_distance <= 3 THEN 'Possible Match'
        ELSE 'Weak Match'
    END AS match_quality,
    zm.match_distance
FROM slack_customers sc
LEFT JOIN zendesk_matches zm ON sc.slack_customer_name = zm.slack_customer_name
ORDER BY 
    CASE
        WHEN zm.match_distance IS NULL THEN 4
        ELSE zm.match_distance
    END,
    sc.slack_customer_name
