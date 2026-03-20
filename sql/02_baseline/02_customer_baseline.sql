USE FraudAnalytics
GO

-- ============================================================
-- VIEW: customer_baseline
-- PURPOSE: Build behavioral profile for each customer
-- USED BY: Detection rules (z-score, velocity, geo anomaly)
-- ============================================================

CREATE VIEW customer_baseline AS

SELECT 
    -- CUSTOMER IDENTIFIER
    T.CC_NUM,

    -- AMOUNT BEHAVIOR
    AVG(amt)                                                    AS avg_transaction_amount,
    STDEV(amt)                                                  AS stdev_transaction_amount,
    MAX(amt)                                                    AS max_transaction_amount,

    -- TRANSACTION FREQUENCY
    COUNT(trans_num)                                            AS total_transactions,
    CAST(COUNT(trans_num) AS FLOAT) / NULLIF(DATEDIFF(day, 
        MIN(trans_date_trans_time), 
        MAX(trans_date_trans_time)), 0)                         AS avg_daily_transaction_count,

    -- SPEND PATTERN
    SUM(amt) / NULLIF(DATEDIFF(day, 
        MIN(trans_date_trans_time), 
        MAX(trans_date_trans_time)), 0)                         AS avg_daily_spend,

    -- BEHAVIORAL BREADTH
    COUNT(DISTINCT merchant)                                    AS count_distinct_merchants,
    COUNT(DISTINCT category)                                    AS count_distinct_categories,
    COUNT(DISTINCT state)                                       AS count_distinct_states,

    -- NORMAL BEHAVIOR ANCHORS
    (SELECT TOP 1 category 
     FROM transactions T2 
     WHERE T2.cc_num = T.cc_num
     GROUP BY category 
     ORDER BY COUNT(*) DESC)                                    AS most_frequent_category,

    (SELECT TOP 1 state 
     FROM transactions T2 
     WHERE T2.cc_num = T.cc_num
     GROUP BY state 
     ORDER BY COUNT(*) DESC)                                    AS most_frequent_state,

    (SELECT TOP 1 DATEPART(HOUR, trans_date_trans_time)
     FROM transactions T2 
     WHERE T2.cc_num = T.cc_num
     GROUP BY DATEPART(HOUR, trans_date_trans_time)
     ORDER BY COUNT(*) DESC)                                    AS most_frequent_hour

FROM transactions AS T

GROUP BY CC_NUM




SELECT TOP 5 * FROM customer_baseline