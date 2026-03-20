USE FraudAnalytics
GO

-- ============================================================
-- VIEW: flagged_transactions
-- PURPOSE: Apply detection rules to every transaction
-- USED BY: Risk scoring, validation, Power BI dashboard
-- ============================================================

CREATE VIEW flagged_transactions AS

SELECT
    -- --------------------------------------------------------
    -- TRANSACTION IDENTIFIERS
    -- --------------------------------------------------------
    T.trans_num,
    T.cc_num,
    T.trans_date_trans_time,
    T.amt,
    T.category,
    T.state,
    T.merchant,
    T.is_fraud,

    -- --------------------------------------------------------
    -- BASELINE REFERENCE VALUES
    -- --------------------------------------------------------
    B.avg_transaction_amount,
    B.stdev_transaction_amount,
    B.max_transaction_amount,
    B.most_frequent_category,
    B.most_frequent_state,

    -- --------------------------------------------------------
    -- DETECTION FLAGS
    -- --------------------------------------------------------

    -- Rule 1: Amount spike (z-score > 3 standard deviations)
    CASE 
        WHEN (T.amt - B.avg_transaction_amount) / 
             NULLIF(B.stdev_transaction_amount, 0) > 3 
        THEN 1 ELSE 0 
    END AS amount_spike_flag,

    -- Rule 2: Max amount exceeded (above personal ceiling)
    CASE 
        WHEN T.amt > B.max_transaction_amount 
        THEN 1 ELSE 0 
    END AS max_amount_flag,

    -- Rule 3: New high-risk category deviation (>$50 threshold)
    -- Note: Production improvement would use top-3 category 
    -- subset per customer for better personalization
    CASE 
        WHEN T.category != B.most_frequent_category 
        AND  T.category IN ('shopping_net', 'grocery_net', 'misc_net') 
        AND  T.amt > 50
        THEN 1 ELSE 0 
    END AS category_flag,

    -- Rule 4: Geographic anomaly (transaction outside home state)
    CASE 
        WHEN T.state != B.most_frequent_state 
        THEN 1 ELSE 0 
    END AS state_flag,

    -- Rule 5: Velocity (more than 3 transactions in same hour)
    CASE 
        WHEN COUNT(*) OVER (
            PARTITION BY 
                T.cc_num,
                DATEPART(YEAR,  T.trans_date_trans_time),
                DATEPART(MONTH, T.trans_date_trans_time),
                DATEPART(DAY,   T.trans_date_trans_time),
                DATEPART(HOUR,  T.trans_date_trans_time)
        ) > 3 
        THEN 1 ELSE 0 
    END AS velocity_flag

FROM transactions T
JOIN customer_baseline B ON T.cc_num = B.cc_num

GO

-- ============================================================
-- VALIDATION QUERY 1: Preview fraud transactions with flags
-- ============================================================

SELECT TOP 10 
    trans_num,
    cc_num,
    amt,
    category,
    state,
    is_fraud,
    amount_spike_flag,
    max_amount_flag,
    category_flag,
    state_flag,
    velocity_flag
FROM flagged_transactions
ORDER BY is_fraud DESC

GO

-- ============================================================
-- VALIDATION QUERY 2: Rule performance summary
-- ============================================================

SELECT 
    -- ALERT VOLUMES PER RULE
    SUM(amount_spike_flag)                                        AS total_amount_flags,
    SUM(max_amount_flag)                                          AS total_max_flags,
    SUM(category_flag)                                            AS total_category_flags,
    SUM(state_flag)                                               AS total_state_flags,
    SUM(velocity_flag)                                            AS total_velocity_flags,

    -- HIT RATES PER RULE
    -- (% of alerts that were actually fraud)
    ROUND(SUM(CASE WHEN amount_spike_flag = 1 
        AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(amount_spike_flag), 0), 2)                     AS amount_spike_hit_rate,

    ROUND(SUM(CASE WHEN category_flag = 1 
        AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(category_flag), 0), 2)                         AS category_hit_rate,

    ROUND(SUM(CASE WHEN state_flag = 1 
        AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(state_flag), 0), 2)                            AS state_hit_rate,

    ROUND(SUM(CASE WHEN velocity_flag = 1 
        AND is_fraud = 1 THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(velocity_flag), 0), 2)                         AS velocity_hit_rate

FROM flagged_transactions