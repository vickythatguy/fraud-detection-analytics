USE FraudAnalytics
GO

-- ============================================================
-- VIEW 1: daily_alert_summary
-- PURPOSE: Alert volume and fraud count per day
-- USED BY: Power BI Page 1 - trend line chart
-- ============================================================

-- You need per day:
-- The date (just the date part, not time)
-- Total transactions that day
-- Total flags that day (any flag = 1)
-- Total confirmed fraud that day
-- Hint: CAST(trans_date_trans_time AS DATE) gives you just the date
-- Hint: a transaction is flagged if ANY of the 5 flags = 1

CREATE VIEW daily_alert_summary AS
SELECT CAST(trans_date_trans_time AS DATE) AS TRANSACTION_DATE, COUNT(TRANS_NUM) TOTAL_TRANS,
SUM(CASE WHEN (amount_spike_flag + max_amount_flag + category_flag + 
               state_flag + velocity_flag) > 0 
         THEN 1 ELSE 0 END)     AS total_flagged_transactions,
     SUM(IS_FRAUD) AS CONF_FRUAD
FROM FLAGGED_TRANSACTIONS
GROUP BY CAST(trans_date_trans_time AS DATE)

GO

-- ============================================================
-- VIEW 2: rule_performance
-- PURPOSE: Hit rate and alert volume per rule
-- USED BY: Power BI Page 2 - rule performance bar chart
-- ============================================================

-- You need one row per rule showing:
-- Rule name (hardcode as a string e.g. 'Amount Spike')
-- Total alerts that rule generated
-- Total confirmed fraud that rule caught
-- Hit rate percentage
-- Hint: Use UNION ALL to stack each rule as a separate row
CREATE VIEW  rule_performance AS
SELECT 'Amount Spike'  AS rule_name,
       SUM(amount_spike_flag)                                       AS total_alerts,
       SUM(CASE WHEN amount_spike_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END)                     AS confirmed_fraud,
       ROUND(SUM(CASE WHEN amount_spike_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
           NULLIF(SUM(amount_spike_flag), 0), 2)                    AS hit_rate_pct
FROM flagged_transactions
UNION ALL
SELECT 'Max Amount'  AS rule_name,
       SUM(max_amount_flag)                                       AS total_alerts,
       SUM(CASE WHEN max_amount_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END)                     AS confirmed_fraud,
       ROUND(SUM(CASE WHEN max_amount_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
           NULLIF(SUM(max_amount_flag), 0), 2)                    AS hit_rate_pct
FROM flagged_transactions
UNION ALL
SELECT 'Category'  AS rule_name,
       SUM(category_flag)                                       AS total_alerts,
       SUM(CASE WHEN category_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END)                     AS confirmed_fraud,
       ROUND(SUM(CASE WHEN category_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
           NULLIF(SUM(category_flag), 0), 2)                    AS hit_rate_pct
FROM flagged_transactions
UNION ALL
SELECT 'Geographic anomaly'  AS rule_name,
       SUM(state_flag)                                       AS total_alerts,
       SUM(CASE WHEN state_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END)                     AS confirmed_fraud,
       ROUND(SUM(CASE WHEN state_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
           NULLIF(SUM(state_flag), 0), 2)                    AS hit_rate_pct
FROM flagged_transactions
UNION ALL
SELECT 'Velocity'  AS rule_name,
       SUM(velocity_flag)                                       AS total_alerts,
       SUM(CASE WHEN velocity_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END)                     AS confirmed_fraud,
       ROUND(SUM(CASE WHEN velocity_flag = 1 
           AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
           NULLIF(SUM(velocity_flag), 0), 2)                    AS hit_rate_pct
FROM flagged_transactions





-- ============================================================
-- VIEW 3: high_risk_customers
-- PURPOSE: Top customers by risk for investigation queue
-- USED BY: Power BI Page 3 - customer drill down
-- ============================================================

-- You need per customer:
-- cc_num
-- risk_label
-- total_rules_triggered
-- confirmed_fraud
-- total transactions
-- total amount spent
-- avg transaction amount
-- Hint: JOIN customer_risk_scores with flagged_transactions
-- Only include High Risk and Medium Risk customers
-- Order by total_rules_triggered DESC
GO
CREATE VIEW  high_risk_customers AS
SELECT crs.cc_num,
risk_label,total_rules_triggered,confirmed_fraud,
COUNT(ft.trans_num)     AS total_transactions,
SUM(ft.amt)             AS total_amount_spent,
AVG(ft.amt)             AS avg_transaction_amount
from customer_risk_scores as crs join flagged_transactions  ft on crs.cc_num = ft.cc_num
WHERE risk_label IN ('High Risk', 'Medium Risk')
GROUP BY crs.cc_num, risk_label, total_rules_triggered, confirmed_fraud



SELECT TOP 5 * FROM daily_alert_summary
SELECT * FROM rule_performance
SELECT TOP 5 * FROM high_risk_customers