# Slack-and-Zendesk-Integration-Customer-Name-Standardization
Project Description: This dbt project implements an automated data transformation pipeline to standardize customer names across Slack and Zendesk platforms. The solution addresses a critical business challenge where inconsistent customer naming conventions across communication tools led to fragmented data and reporting gaps.
# Slack and Zendesk Customer Name Standardization

## Project Overview

This dbt project implements a data transformation pipeline that standardizes customer names across Slack channels and Zendesk organizations. The project addresses a common business challenge where customer names appear inconsistently across different platforms due to typos, variations in formatting, and manual data entry.

Key business value:
- Creates a single source of truth for customer names
- Improves data consistency across business systems
- Enables more accurate reporting and analytics
- Simplifies customer data management

## Architecture

The project follows a classic dbt layered architecture:

```
slack_zendesk_dbt/
├── models/
│   ├── staging/         # Initial data preparation
│   ├── intermediate/    # Business logic transforms
│   └── marts/           # Final presentation models
├── tests/               # Data quality tests
└── docs/                # Project documentation
```

## Data Sources

The project uses the following source tables from BigQuery:
- `slack_zendesk_hbk.slack_channel`: Contains Slack channel data with customer identification in channel names
- `slack_zendesk_hbk.zendesk_organization`: Contains Zendesk organization data including customer names

## Implementation Highlights

### Customer Name Extraction from Slack Channels

The project extracts customer names from Slack channels using pattern matching, focusing on channels that follow specific naming conventions:

```sql
SELECT
    id AS channel_id,
    name,
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
```

### Fuzzy Matching for Similar Customer Names

A key innovation in this project is the use of edit distance algorithms to identify and standardize similar customer names with minor spelling differences:

```sql
SELECT
    a.customer AS customer_1,
    b.customer AS customer_2,
    EDIT_DISTANCE(LOWER(a.customer), LOWER(b.customer)) AS distance
FROM customer_counts a
JOIN customer_counts b
    ON a.customer < b.customer
WHERE EDIT_DISTANCE(LOWER(a.customer), LOWER(b.customer)) = 1
```

### Canonical Name Mapping

The project implements intelligent canonical name selection by choosing the more frequently occurring version of similar names:

```sql
SELECT
    CASE WHEN count_1 >= count_2 THEN customer_1 ELSE customer_2 END AS canonical,
    CASE WHEN count_1 >= count_2 THEN customer_2 ELSE customer_1 END AS variant
FROM pair_with_counts
```

### Cross-Platform Name Standardization

Finally, the project compares Slack customer names with Zendesk organization names to create a unified view across platforms:

```sql
SELECT
    sc.slack_customer_name,
    zm.best_zendesk_match AS zendesk_organization_name,
    CASE
        WHEN zm.match_distance IS NULL THEN 'No Match'
        WHEN zm.match_distance = 0 THEN 'Exact Match'
        WHEN zm.match_distance = 1 THEN 'Very Close Match'
        WHEN zm.match_distance <= 3 THEN 'Possible Match'
        ELSE 'Weak Match'
    END AS match_quality
FROM slack_customers sc
LEFT JOIN zendesk_matches zm ON sc.slack_customer_name = zm.slack_customer_name
```

## Technical Highlights

- **Edit Distance Algorithm**: Uses BigQuery's EDIT_DISTANCE() function to identify similar customer names
- **Data Lineage**: Maintains clear transformations from raw sources to final marts
- **Modular Design**: Separates extraction, transformation, and loading into distinct layers
- **Incremental Processing**: Designed for efficient processing of new data

## Results and Impact

This dbt implementation successfully identified and standardized customer names across platforms, resulting in:

- **Improved Data Quality**: Standardized naming conventions across systems
- **Enhanced Reporting**: More accurate customer-level analytics
- **Operational Efficiency**: Reduced need for manual data cleaning
- **Better Customer Service**: Easier identification of customer records across systems

## Sample Transformations

Below are examples of how customer names were standardized:

| Original Name | Standardized Name |
|---------------|-------------------|
| Bizzaro       | Bizzarro          |
| Boticaperu    | Boticasperu       |
| Deportes Marti| Deportes Martí    |
| Gco           | Gco1              |
| Helly Hansen  | Helly Hensen      |
| New Athletic  | Newathletic       |
| Super Exito   | Superexito        |
<img width="462" alt="Screenshot 2025-05-16 at 10 33 14" src="https://github.com/user-attachments/assets/0bc35719-45be-4260-bfc0-0d102a63775e" />

<img width="562" alt="Screenshot 2025-05-16 at 10 34 39" src="https://github.com/user-attachments/assets/66da3c01-d494-43c9-9668-844e5cacaf0e" />

<img width="560" alt="Screenshot 2025-05-16 at 10 35 13" src="https://github.com/user-attachments/assets/89e0347b-5c96-4825-be0d-1fc895846c83" />

<img width="771" alt="Screenshot 2025-05-16 at 10 35 50" src="https://github.com/user-attachments/assets/d5ee218f-559a-412f-ba9c-e523750c5fdb" />




## Learning and Future Improvements

- Implement more sophisticated fuzzy matching algorithms
- Add data quality tests to ensure proper transformation
- Create a historical log of name changes
- Extend the approach to other business systems

## Tools and Technologies

- **dbt**: Core transformation framework
- **BigQuery**: Data warehouse
- **SQL**: Primary programming language
- **Git**: Version control

---

*Note: This project was developed as part of data integration work for internal business systems. The code examples show the transformation logic while protecting specific business data.*
