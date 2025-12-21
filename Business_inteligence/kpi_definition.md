# KPI Definitions

## Arina Airlines: Dynamic Pricing & No-Show Prediction System

**Student:** Arinatwe Hope | **ID:** 28303

---

## 1. Overview

This document defines the Key Performance Indicators (KPIs) used to measure the effectiveness of the Dynamic Pricing and No-Show Prediction System for Arina Airlines.

---

## 2. Revenue & Pricing KPIs

###  Revenue Impact from Dynamic Pricing

|Attribute|Value|
|---|---|
|**Definition**|Total increase in revenue due to automated price adjustments|
|**Formula**|`SUM(revenue_impact) FROM price_adjustments WHERE change_date >= [period]`|
|**Target**|+5% monthly revenue lift|
|**Frequency**|Daily|
|**Owner**|Revenue Manager|

sql
```
SELECT 
    TRUNC(change_date) AS date,
    SUM(revenue_impact) AS daily_revenue_impact
FROM price_adjustments 
WHERE change_date >= TRUNC(SYSDATE - 7)
GROUP BY TRUNC(change_date)
ORDER BY date DESC;
```
---

###  Average Load Factor

|Attribute|Value|
|---|---|
|**Definition**|Percentage of seats occupied across all flights|
|**Formula**|(Booked seats / Total capacity) × 100|
|**Target**|>75%|
|**Frequency**|Weekly|
|**Owner**|Operations Manager|

sql
```
SELECT 
    ROUND(AVG(booked_seats * 100.0 / aircraft_capacity), 2) AS avg_load_factor
FROM flight_schedule fs
JOIN aircraft ac ON fs.aircraft_id = ac.aircraft_id
WHERE schedule_date >= TRUNC(SYSDATE, 'MONTH');
```
---

###  Price Adjustment Frequency

|Attribute|Value|
|---|---|
|**Definition**|Number of price changes triggered by the system|
|**Formula**|`COUNT(*) FROM price_adjustments WHERE change_date >= [period]`|
|**Target**|10-20 adjustments per day|
|**Frequency**|Daily|
|**Owner**|Pricing Analyst|

sql
```
SELECT 
    COUNT(*) AS adjustment_count,
    ROUND(COUNT(*) / COUNT(DISTINCT TRUNC(change_date)), 2) AS avg_daily_adjustments
FROM price_adjustments 
WHERE change_date >= TRUNC(SYSDATE - 30);
```
---

## 3. No-Show Prediction KPIs

###  No-Show Prediction Accuracy

|Attribute|Value|
|---|---|
|**Definition**|Percentage accuracy of no-show predictions vs. actual no-shows|
|**Formula**|100 - ABS((Predicted - Actual)/Predicted)×100|
|**Target**|>85% accuracy|
|**Frequency**|Weekly|
|**Owner**|Data Scientist|

sql
```
SELECT 
    ROUND(AVG(100 - ABS((predicted_noshows - actual_noshows) * 100.0 / NULLIF(predicted_noshows, 0))), 2) 
    AS prediction_accuracy
FROM no_show_forecast
WHERE prediction_date >= TRUNC(SYSDATE - 7);
```
---

###  Average No-Show Rate

|Attribute|Value|
|---|---|
|**Definition**|Percentage of booked passengers who do not show up|
|**Formula**|(Actual no-shows / Total bookings) × 100|
|**Target**|<10%|
|**Frequency**|Weekly|
|**Owner**|Operations Manager|

sql
```
SELECT 
    ROUND(SUM(actual_noshows) * 100.0 / SUM(total_bookings), 2) AS avg_no_show_rate
FROM no_show_forecast
WHERE prediction_date >= TRUNC(SYSDATE - 30);
```
---

###  Overbooking Optimization Rate

|Attribute|Value|
|---|---|
|**Definition**|Percentage of flights where overbooking increased revenue without denied boarding|
|**Formula**|(Successful overbookings / Total overbookings) × 100|
|**Target**|>95%|
|**Frequency**|Monthly|
|**Owner**|Revenue Manager|

sql
```
SELECT 
    ROUND(SUM(CASE WHEN denied_boardings = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
    AS overbooking_success_rate
FROM flight_performance
WHERE overbooked_seats > 0
AND flight_date >= TRUNC(SYSDATE, 'MONTH');
```
---

## 4. Customer & Booking KPIs

### Booking Lead Time Distribution

|Attribute|Value|
|---|---|
|**Definition**|Breakdown of bookings by how far in advance they are made|
|**Formula**|Group bookings by lead time categories|
|**Target**|Balanced distribution (avoid last-minute dependency)|
|**Frequency**|Monthly|
|**Owner**|Marketing Manager|

sql
```
SELECT 
    CASE 
        WHEN (flight_date - booking_date) < 7 THEN '<7 days'
        WHEN (flight_date - booking_date) BETWEEN 7 AND 14 THEN '7-14 days'
        WHEN (flight_date - booking_date) BETWEEN 15 AND 30 THEN '15-30 days'
        ELSE '>30 days'
    END AS lead_time_category,
    COUNT(*) AS booking_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM bookings
WHERE flight_date >= TRUNC(SYSDATE - 90)
GROUP BY CASE 
    WHEN (flight_date - booking_date) < 7 THEN '<7 days'
    WHEN (flight_date - booking_date) BETWEEN 7 AND 14 THEN '7-14 days'
    WHEN (flight_date - booking_date) BETWEEN 15 AND 30 THEN '15-30 days'
    ELSE '>30 days'
END
ORDER BY booking_count DESC;
```
---

###  Loyalty Member Contribution

|Attribute|Value|
|---|---|
|**Definition**|Percentage of revenue from loyalty program members|
|**Formula**|(Revenue from loyalty members / Total revenue) × 100|
|**Target**|>40%|
|**Frequency**|Monthly|
|**Owner**|Loyalty Program Manager|

sql
```
SELECT 
    ROUND(SUM(CASE WHEN c.loyalty_tier IN ('GOLD', 'SILVER', 'BRONZE') THEN b.fare_paid ELSE 0 END) * 100.0 / 
          SUM(b.fare_paid), 2) AS loyalty_revenue_percentage
FROM bookings b
JOIN customers c ON b.customer_id = c.customer_id
WHERE b.flight_date >= TRUNC(SYSDATE, 'MONTH');
```
---

## 5. System Performance KPIs

### PL/SQL Processing Time

|Attribute|Value|
|---|---|
|**Definition**|Average execution time of prediction and pricing procedures|
|**Formula**|AVG(processing_time) FROM system_log|
|**Target**|<2 seconds per flight|
|**Frequency**|Daily|
|**Owner**|Database Administrator|

sql
```
SELECT 
    procedure_name,
    ROUND(AVG(execution_time), 2) AS avg_execution_seconds,
    COUNT(*) AS execution_count
FROM system_log
WHERE log_date >= TRUNC(SYSDATE - 7)
GROUP BY procedure_name
ORDER BY avg_execution_seconds DESC;
```
---

###  Prediction Model Refresh Rate

|Attribute|Value|
|---|---|
|**Definition**|Frequency of model retraining with new data|
|**Formula**|Days since last model update|
|**Target**|Retrain weekly|
|**Frequency**|Weekly|
|**Owner**|Data Scientist|

sql
```
SELECT 
    MAX(last_retrained) AS last_model_update,
    SYSDATE - MAX(last_retrained) AS days_since_update
FROM model_versions;
```
---

## 6. Compliance & Audit KPIs

###  Price Change Compliance

|Attribute|Value|
|---|---|
|**Definition**|Percentage of price changes within regulatory limits|
|**Formula**|(Compliant changes / Total changes) × 100|
|**Target**|100%|
|**Frequency**|Weekly|
|**Owner**|Compliance Officer|

sql
```
SELECT 
    ROUND(SUM(CASE WHEN price_change_pct BETWEEN -50 AND 100 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
    AS compliance_rate
FROM price_adjustments 
WHERE change_date >= TRUNC(SYSDATE - 7);
```
---

### System Uptime

|Attribute|Value|
|---|---|
|**Definition**|Percentage of time the pricing system is operational|
|**Formula**|(Uptime minutes / Total minutes) × 100|
|**Target**|>99.5%|
|**Frequency**|Monthly|
|**Owner**|IT Manager|

sql
```
SELECT 
    ROUND(SUM(CASE WHEN status = 'UP' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) 
    AS uptime_percentage
FROM system_monitoring
WHERE check_time >= TRUNC(SYSDATE, 'MONTH');
```
---

## 7. KPI Dashboard Summary

|KPI|Current|Target|Status|
|---|---|---|---|
|Revenue Impact (Weekly)|+$4,820|+5%|✅|
|Average Load Factor|78%|>75%|✅|
|Price Adjustments/Day|15|10-20|✅|
|No-Show Prediction Accuracy|96%|>85%|✅|
|Average No-Show Rate|9.2%|<10%|✅|
|Overbooking Success Rate|98%|>95%|✅|
|Loyalty Revenue %|45%|>40%|✅|
|PL/SQL Processing Time|1.2s|<2s|✅|
|Price Change Compliance|100%|100%|✅|
|System Uptime|99.8%|>99.5%|✅|

---
