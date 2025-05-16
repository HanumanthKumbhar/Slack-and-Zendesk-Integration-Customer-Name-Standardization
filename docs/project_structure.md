# Project Structure

This document outlines the structure of the dbt models in this project.

## Staging Models

These models perform initial data preparation and cleaning:

- `stg_slack_channels.sql`: Extracts customer names from Slack channel naming patterns
- `stg_zendesk_organizations.sql`: Prepares Zendesk organization data for comparison

## Intermediate Models

These models implement the core business logic:

- `int_slack_customer_similarities.sql`: Identifies similar customer names using edit distance
- `int_slack_canonical_mapping.sql`: Creates canonical mapping to standardize variant spellings
- `int_slack_zendesk_name_comparison.sql`: Compares Slack customer names with Zendesk organizations

## Mart Models

These models represent the final, presentation-ready data:

- `mart_slack_channels_cleaned.sql`: Provides cleaned Slack channel data with standardized customer names
- `mart_customer_name_mapping.sql`: Delivers a unified view of customer names across platforms

## Data Flow Diagram

```
Source Tables:
[slack_channel] --> [stg_slack_channels]
[zendesk_organization] --> [stg_zendesk_organizations]

Intermediate Processing:
[stg_slack_channels] --> [int_slack_customer_similarities]
[int_slack_customer_similarities] --> [int_slack_canonical_mapping]
[stg_slack_channels] + [stg_zendesk_organizations] --> [int_slack_zendesk_name_comparison]

Final Output:
[stg_slack_channels] + [int_slack_canonical_mapping] --> [mart_slack_channels_cleaned]
[mart_slack_channels_cleaned] + [int_slack_zendesk_name_comparison] --> [mart_customer_name_mapping]
```
