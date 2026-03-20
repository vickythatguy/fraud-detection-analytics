-- ============================================================
-- FRAUD ANALYTICS PROJECT
-- Dataset: Credit Card Transactions Fraud Detection (Kaggle)
-- Author: Vignesh
-- Date: March 2026
-- ============================================================

USE FraudAnalytics

-- ============================================================
-- SECTION 0: DATASET OVERVIEW
-- ============================================================

-- Total row count
SELECT COUNT(*) AS total_rows FROM transactions
-- RESULT: 1,296,675

-- High level summary
SELECT 
    COUNT(DISTINCT cc_num)                                    AS unique_customers,
    COUNT(*)                                                  AS total_transactions,
    SUM(CAST(is_fraud AS INT))                               AS total_fraud_cases,
    ROUND(SUM(CAST(is_fraud AS INT)) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
/*
RESULT:
unique_customers    : 983
total_transactions  : 1,296,675
total_fraud_cases   : 7,506
fraud_rate_pct      : 0.58%

INSIGHT: Fraud rate of 0.58% is consistent with real-world credit card fraud rates 
(industry average: 0.1% - 1%). This gives us a realistic ground truth to validate 
our detection rules against.
*/

-- Quick data preview
SELECT TOP 10 * FROM transactions

-- ============================================================
-- SECTION 1: DATA EXPLORATION
-- ============================================================

-- Q1: What is the transaction date range?
SELECT 
    MIN(trans_date_trans_time) AS earliest_transaction,
    MAX(trans_date_trans_time) AS latest_transaction
FROM transactions
/*
RESULT:
earliest_transaction : 2019-01-01 00:00:18
latest_transaction   : 2020-06-21 12:13:37

INSIGHT: Dataset covers approximately 18 months of transaction history 
across 2019 and first half of 2020. Sufficient history to build 
meaningful customer behavioral baselines.
*/

-- Q2: What transaction categories exist?
SELECT DISTINCT category FROM transactions
/*
RESULT: 14 categories
shopping_pos, misc_pos, entertainment, personal_care, food_dining,
gas_transport, health_fitness, grocery_pos, grocery_net, misc_net,
kids_pets, travel, home, shopping_net

INSIGHT: Categories split between in-person (pos) and online (net) 
channels — important for detection rules as online transactions 
carry higher fraud risk.
*/

-- Q3: What is the fraud rate by category?
SELECT 
    category,
    COUNT(*)                                                  AS total_transactions,
    SUM(CAST(is_fraud AS INT))                               AS fraud_cases,
    ROUND(SUM(CAST(is_fraud AS INT)) * 100.0 / 
          (SELECT COUNT(*) FROM transactions), 2)            AS fraud_rate_pct
FROM transactions
GROUP BY category
ORDER BY fraud_rate_pct DESC
/*
RESULT:
grocery_pos     : 0.13%
shopping_net    : 0.13%
shopping_pos    : 0.07%
misc_net        : 0.07%
gas_transport   : 0.05%
kids_pets       : 0.02%
misc_pos        : 0.02%
entertainment   : 0.02%
personal_care   : 0.02%
home            : 0.02%
food_dining     : 0.01%
health_fitness  : 0.01%
grocery_net     : 0.01%
travel          : 0.01%

INSIGHT: grocery_pos and shopping_net have the highest fraud rates.
Online shopping (net) categories show elevated fraud risk vs in-person (pos)
equivalents — consistent with card-not-present fraud patterns seen in real banking.
*/

-- Q4: What is the fraud rate by state?
SELECT 
    state,
    COUNT(*)                                                  AS total_transactions,
    SUM(CAST(is_fraud AS INT))                               AS fraud_cases,
    ROUND(SUM(CAST(is_fraud AS INT)) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
GROUP BY state
ORDER BY fraud_rate_pct DESC


-- Q5: Average transaction amount — fraud vs non-fraud
SELECT 
    is_fraud,
    COUNT(*)                     AS transaction_count,
    ROUND(AVG(amt), 2)          AS avg_amount,
    ROUND(MIN(amt), 2)          AS min_amount,
    ROUND(MAX(amt), 2)          AS max_amount,
    ROUND(SUM(amt), 2)          AS total_amount
FROM transactions
GROUP BY is_fraud
/*
RESULT:
is_fraud  total_amount
0         87,234,340.29  (legitimate)
1          3,988,088.61  (fraud)
*/