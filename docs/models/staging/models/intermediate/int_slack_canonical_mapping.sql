-- models/intermediate/int_slack_canonical_mapping.sql
{{ config(
    materialized = 'table'
) }}

WITH customer_data AS (
    SELECT 
        customer
    FROM {{ ref('stg_slack_channels') }}
),

-- Count each distinct customer
customer_counts AS (
    SELECT
        customer,
        COUNT(*) AS customer_count
    FROM customer_data
    GROUP BY customer
),

-- Find similar name pairs using edit distance = 1
similar_customers AS (
    SELECT
        a.customer AS customer_1,
        b.customer AS customer_2,
        EDIT_DISTANCE(LOWER(a.customer), LOWER(b.customer)) AS distance
    FROM customer_counts a
    JOIN customer_counts b
        ON a.customer < b.customer
    WHERE EDIT_DISTANCE(LOWER(a.customer), LOWER(b.customer)) = 1
),

-- Join counts for both names in the pair
pair_with_counts AS (
    SELECT
        s.customer_1,
        s.customer_2,
        c1.customer_count AS count_1,
        c2.customer_count AS count_2
    FROM similar_customers s
    JOIN customer_counts c1 ON s.customer_1 = c1.customer
    JOIN customer_counts c2 ON s.customer_2 = c2.customer
),

-- Decide canonical name based on higher count
canonical_mapping AS (
    SELECT
        CASE WHEN count_1 >= count_2 THEN customer_1 ELSE customer_2 END AS canonical,
        CASE WHEN count_1 >= count_2 THEN customer_2 ELSE customer_1 END AS variant
    FROM pair_with_counts
)

-- Final output: canonical → variant mapping
SELECT 
    canonical,
    variant
FROM canonical_mapping
ORDER BY canonical
