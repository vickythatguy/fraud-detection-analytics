
## Project Overview
End-to-end transaction monitoring pipeline simulating an AML and fraud 
detection analytics workflow for a financial institution. Built using 
SQL Server for detection logic and Power BI for dashboard reporting.

## Business Context
Financial institutions process millions of transactions daily. Manually 
reviewing every transaction for suspicious activity is impossible. This 
project builds a rule-based detection system that automatically flags 
suspicious behavior, scores customers by risk level, and surfaces 
actionable alerts for compliance investigators.

## Dataset
- Source: Credit Card Transactions Fraud Detection (Kaggle)
- 1,296,675 transactions across 983 customers
- 18 months of transaction history (Jan 2019 — Jun 2020)
- 0.58% fraud rate — consistent with real-world fraud rates

## Detection Rules Built
- Amount spike detection (z-score at customer level)
- Velocity checks (multiple transactions in short time window)
- New merchant category anomaly
- Geographic anomaly (transaction location vs home state)
- High value transaction flag

## Tech Stack
| Layer | Tool |
|---|---|
| Database | SQL Server (SQL Express) |
| Detection Logic | T-SQL — CTEs, window functions, z-score |
| BI & Visualization | Power BI Desktop |
| Version Control | GitHub |

## Project Structure
- `/sql/01_exploration` — data profiling and initial analysis
- `/sql/02_baseline` — customer behavioral baseline views
- `/sql/03_detection_rules` — fraud and AML detection flag logic
- `/sql/04_risk_scoring` — customer risk scoring and segmentation
- `/sql/05_summary_views` — Power BI ready summary tables

## Key Findings
*(To be updated as analysis completes)*

## Status
- [x] Data exploration complete
- [ ] Customer baseline view
- [ ] Detection rules
- [ ] Risk scoring
- [ ] Power BI dashboard
