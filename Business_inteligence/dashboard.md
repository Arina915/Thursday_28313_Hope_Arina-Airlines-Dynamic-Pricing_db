# Arina Airlines: Dynamic Pricing & No-Show Dashboard

**Student:** Arinatwe Hope | **ID:** 28303

---

## 1. Executive Overview Dashboard

### Purpose

Provide airline management with a real-time overview of flight performance, no-show predictions, pricing adjustments, and revenue impact.

### Layout Mockup

text
```
┌─────────────────────────────────────────────────────────────────────────────┐
│               ARINA AIRLINES: REVENUE & PREDICTION DASHBOARD                │
│                         Last Updated: 2025-12-07 10:15                       │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────┤
│                 │                 │                 │                         │
│   ✈️ TOTAL      │  ⏳ TODAY’S     │  ⚠️ PREDICTED  │   💰 REVENUE IMPACT    │
│   FLIGHTS       │  FLIGHTS        │  NO-SHOWS       │   FROM PRICING          │
│      47         │      12         │      58         │   +$4,820                │
│   This Month    │  Scheduled      │  Today          │   This Week             │
├─────────────────┴─────────────────┴─────────────────┴─────────────────────────┤
│                                                                               │
│   📊 NO-SHOW PREDICTION TREND (Last 7 Days)                                  │
│   ┌───────────────────────────────────────────────────────────────┐          │
│   │     ▲                                                         │          │
│   │  80─┤        ████                                             │          │
│   │     │   ████ ████ ████                                        │          │
│   │  60─┤   ████ ████ ████ ████                                   │          │
│   │     │   ████ ████ ████ ████ ████                              │          │
│   │  40─┤   ████ ████ ████ ████ ████ ████                         │          │
│   │     │   ████ ████ ████ ████ ████ ████                         │          │
│   │  20─┼───Mon──Tue──Wed──Thu──Fri──Sat──Sun──────────────▶      │          │
│   └───────────────────────────────────────────────────────────────┘          │
│                                                                               │
├───────────────────────────────────────┬───────────────────────────────────────┤
│                                       │                                       │
│   🎫 PRICE ADJUSTMENTS BY CLASS       │   🏙️ TOP ROUTES (NO-SHOW RATE)       │
│   ┌─────────────────────────┐         │   ┌─────────────────────────┐        │
│   │ K-Class    ▼ 18%        │         │   │ NBO→DAR   ████  22%     │        │
│   │ J-Class    ▲ 12%        │         │   │ KGL→NBO   ███   18%     │        │
│   │ F-Class    ▲ 5%         │         │   │ DAR→KGL   ██    15%     │        │
│   │ Y-Class    ▼ 8%         │         │   │ NBO→KGL   █     10%     │        │
│   └─────────────────────────┘         │   │                         │        │
│                                       │   └─────────────────────────┘        │
└───────────────────────────────────────┴───────────────────────────────────────┘
```
### KPI Cards

|KPI|Value|Trend|
|---|---|---|
|Total Flights This Month|47|📈|
|Today’s Scheduled Flights|12|⏳|
|Predicted No-Shows Today|58|⚠️|
|Revenue Impact (Week)|+$4,820|💰|

### SQL Query for Executive Dashboard

sql

-- Executive Dashboard KPIs
SELECT 
    (SELECT COUNT(*) FROM flight_schedule 
     WHERE TRUNC(schedule_date, 'MM') = TRUNC(SYSDATE, 'MM')) AS total_flights,
    (SELECT COUNT(*) FROM flight_schedule 
     WHERE TRUNC(schedule_date) = TRUNC(SYSDATE)) AS todays_flights,
    (SELECT SUM(predicted_noshows) FROM no_show_forecast 
     WHERE TRUNC(prediction_date) = TRUNC(SYSDATE)) AS predicted_noshows_today,
    (SELECT SUM(revenue_impact) FROM price_adjustments 
     WHERE TRUNC(change_date) >= TRUNC(SYSDATE - 7)) AS revenue_impact_week
FROM dual;

---

## 2. Pricing & Revenue Dashboard

### Purpose

Monitor dynamic pricing adjustments, load factors, and revenue performance across flights and fare classes.

### Layout Mockup

text
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   PRICING & REVENUE MONITORING DASHBOARD                                          │
│                         Last Updated: 2025-12-07 10:15                                                                  │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────┤
│                               │                 │                 │                         │
│  💺 AVG LOAD    │  🎫 AVG PRICE   │  📉 MAX PRICE   │   📈 REVENUE            │
│  FACTOR         │  ADJUSTMENT     │  DROP           │   LIFT                  │
│     78%         │     -5.2%       │      -22%       │   +8.3%                 │
│  This Month     │  This Week      │  Today (K-Class)│  vs. Last Month         │
├─────────────────┴─────────────────┴─────────────────┴─────────────────────────┤
│                                                                               │
│   📊 REVENUE IMPACT BY FARE CLASS                                            │
│   ┌───────────────────────────────────────────────────────────────┐          │
│   │                                                               │          │
│   │ K-Class  ████████████████████████████  +$2,140               │          │
│   │ J-Class  ████████████████████          +$1,230               │          │
│   │ F-Class  ██████████████                +$980                 │          │
│   │ Y-Class  ███████████                   +$470                 │          │
│   │                                                               │          │
│   └───────────────────────────────────────────────────────────────┘          │
│                                                                               │
├───────────────────────────────────────┬───────────────────────────────────────┤
│                                       │                                       │
│   🛫 TOP FLIGHTS (REV IMPACT)         │   📅 PRICE CHANGE LOG                 │
│   ┌─────────────────────────┐         │   ┌─────────────────────────┐        │
│   │ NBO→DAR 245   +$420     │         │   │ 10:00 K-Class ▼ 18%     │        │
│   │ KGL→NBO 112   +$310     │         │   │ 09:45 J-Class ▲ 12%     │        │
│   │ DAR→KGL 198   +$290     │         │   │ 09:30 F-Class ▲ 5%      │        │
│   │ NBO→KGL 76    +$180     │         │   │ 08:15 Y-Class ▼ 8%      │        │
│   └─────────────────────────┘         │   └─────────────────────────┘        │
│                                       │                                       │
└───────────────────────────────────────┴───────────────────────────────────────┘
```
### SQL Query for Pricing Dashboard

sql

-- Pricing & Revenue Summary
SELECT 
    ROUND(AVG(load_factor), 2) AS avg_load_factor,
    ROUND(AVG(price_change_pct), 2) AS avg_price_adjustment,
    MIN(price_change_pct) AS max_price_drop,
    ROUND((SUM(current_revenue) / SUM(base_revenue) - 1) * 100, 2) AS revenue_lift_pct
FROM price_adjustments 
WHERE change_date >= TRUNC(SYSDATE, 'MM');

---

## 3. No-Show Prediction Dashboard

### Purpose

Track no-show predictions, accuracy over time, and factors influencing predictions.

### Layout Mockup

text
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     NO-SHOW PREDICTION ANALYTICS                                  
│                         Last Updated: 2025-12-07 10:15                            │
├─────────────────┬─────────────────┬─────────────────┬─────────────────────────
│                   │                                           │                   │
│  🔮 PREDICTED     │  ✅ ACTUAL         │  📊 ACCURACY        │   🧠 MODEL       │  
│  NO-SHOWS         │  NO-SHOWS           │  RATE               │   VERSION         │
│     1,240         │       1,190         │     96%             │   v2.3            │
│  This Month       │  This Month         │  (Last 30 Days)     │  (Updated Dec 1)  │
├─────────────────┴─────────────────┴─────────────────┴─────────────────────────┤
│                                                                                                                                                │
│   📊 PREDICTION FACTORS WEIGHTING                                                        │
│   ┌───────────────────────────────────────────────────────────────┐                       │
│   │ Booking Lead Time      ████████████████████  35%               │                       │
│   │ Loyalty Level          ████████████████      28%               │     
│   │ Day of Week            ████████████          22%               │                      │
│   │ Holiday Proximity      ███████               15%               │
│   └───────────────────────────────────────────────────────────────┘                       │
│                                                                                                                                                │
├───────────────────────────────────────┬───────────────────────────────────────┤
│                                       │                                       │
│   🎯 ACCURACY BY ROUTE                │   ⏳ LEAD TIME vs NO-SHOW RATE        │
│   ┌─────────────────────────┐         │   ┌─────────────────────────┐         │
│   │ NBO→DAR    ████  94%    │         │   │ <7d   ████████████ 42%  │         │
│   │ KGL→NBO    ████  96%    │         │   │ 7-14d ████████     28%  │         │
│   │ DAR→KGL    ███   92%    │         │   │ 15-30d████         18%  │         │          
│   │ NBO→KGL    ████  97%    │         │   │ >30d  ███          12%  │         │                    
│   └─────────────────────────┘         │   └─────────────────────────┘         │
│                                                                       │                                                   
└───────────────────────────────────────┴───────────────────────────────────────┘
```
### SQL Query for No-Show Dashboard

sql

-- No-Show Prediction Summary
SELECT 
    SUM(predicted_noshows) AS predicted_noshows,
    SUM(actual_noshows) AS actual_noshows,
    ROUND((1 - AVG(ABS(predicted_noshows - actual_noshows) / NULLIF(predicted_noshows, 0))) * 100, 2) AS accuracy_rate
FROM no_show_forecast
WHERE prediction_date >= TRUNC(SYSDATE, 'MM');

---

## 4. Implementation Notes

### Technology Options

- **Option 1:** Oracle APEX (native integration with PL/SQL)
    
- **Option 2:** Power BI + Oracle Connector
    
- **Option 3:** Custom React + Express.js dashboard with Oracle DB connection
    
- **Option 4:** Tableau for advanced analytics visualization
    

### Refresh Rates

- Executive Dashboard: Every 5 minutes
    
- Pricing Dashboard: Every 15 minutes
    
- No-Show Dashboard: Daily (overnight batch)
    
- Real-time alerts: Trigger-based (e.g., price change >10%)
    

### Access Control

| Dashboard          | Access Level                       |
| ------------------ | ---------------------------------- |
| Executive Overview | Airline Management, Revenue Team   |
| Pricing & Revenue  | Pricing Analysts, Revenue Managers |
| No-Show Prediction | Operations, Data Science Team      |
| Audit Log          | IT, Compliance                     |
