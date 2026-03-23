USE FraudAnalytics
GO

-- ============================================================
-- VIEW: customer_risk_scores
-- PURPOSE: Score each customer by total flags triggered
-- USED BY: Power BI dashboard, high risk customer list
-- ============================================================

CREATE VIEW customer_risk_scores AS

WITH base AS (
    SELECT
        cc_num,

        -- Rule fired AND caught real fraud at least once per customer
        MAX(CASE WHEN amount_spike_flag = 1 
            AND is_fraud = 1 THEN 1 ELSE 0 END)    AS had_real_amount_spike,
        MAX(CASE WHEN category_flag = 1 
            AND is_fraud = 1 THEN 1 ELSE 0 END)    AS had_real_category,
        MAX(CASE WHEN velocity_flag = 1 
            AND is_fraud = 1 THEN 1 ELSE 0 END)    AS had_real_velocity,

        MAX(is_fraud)                               AS confirmed_fraud

    FROM flagged_transactions
    GROUP BY cc_num
)

SELECT
    cc_num,

    -- Total distinct rules that caught real fraud
    had_real_amount_spike + 
    had_real_category + 
    had_real_velocity                               AS total_rules_triggered,

    -- Risk label based on how many rules fired
    CASE 
        WHEN had_real_amount_spike + 
             had_real_category + 
             had_real_velocity >= 2 THEN 'High Risk'
        WHEN had_real_amount_spike + 
             had_real_category + 
             had_real_velocity  = 1 THEN 'Medium Risk'
        ELSE                              'Low Risk'
    END                                             AS risk_label,

    confirmed_fraud

FROM base

GO

-- ============================================================
-- VALIDATION QUERY 1: Flag volume summary across all customers
-- ============================================================

SELECT 
    SUM(amount_spike_flag)      AS total_amount_spike_flags,
    SUM(max_amount_flag)        AS total_max_amount_flags,
    SUM(category_flag)          AS total_category_flags,
    SUM(state_flag)             AS total_state_flags,
    SUM(velocity_flag)          AS total_velocity_flags,
    COUNT(DISTINCT cc_num)      AS total_customers_analyzed
FROM flagged_transactions

GO

-- ============================================================
-- VALIDATION QUERY 2: Risk distribution across customers
-- ============================================================

SELECT 
    risk_label,
    COUNT(*)                    AS customer_count,
    SUM(confirmed_fraud)        AS confirmed_fraud_customers,
    ROUND(SUM(confirmed_fraud) * 100.0 / COUNT(*), 2) AS fraud_confirmation_rate
FROM customer_risk_scores
GROUP BY risk_label
ORDER BY customer_count DESC