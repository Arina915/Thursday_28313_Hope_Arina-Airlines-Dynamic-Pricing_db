# Phase Three

# Normalization Process: From Unnormalized to 3NF

### For 0NF (Unnormalized Form):

text
```
┌────────────────────────────────────────────────────────────────────────────┐
│ BOOKINGS_UNNORMALIZED (0NF)                                               │
├────────────────────────────────────────────────────────────────────────────┤
│ booking_id                                                                 │
│ flight_no                                                                  │
│ customer_id                                                                │
│ customer_name           (PROBLEM: Depends on customer_id, not booking_id)  │
│ customer_email          (PROBLEM: Depends on customer_id, not booking_id)  │
│ loyalty_tier            (PROBLEM: Depends on customer_id, not booking_id)  │
│ fare_class                                                                 │
│ price                   (PROBLEM: Derived from rules + adjustments)         │
│ booking_date                                                               │
│ status                                                                    │
└────────────────────────────────────────────────────────────────────────────┘
```
### For 1NF (First Normal Form):

text
```
┌──────────────────────────────────────────────────────────────┐
│ BOOKINGS_1NF                                                 │
├──────────────────────────────────────────────────────────────┤
│ booking_id                                                   │
│ flight_no                                                    │
│ customer_id                                                  │
│ customer_name                                                │
│ customer_email                                               │
│ loyalty_tier                                                 │
│ fare_class                                                   │
│ booking_date                                                 │
│ status                                                       │
└──────────────────────────────────────────────────────────────┘
```
    ↓ (Fixed: All columns have atomic values, no repeating groups)

### For 2NF (Second Normal Form):

text
```
┌──────────────┐      ┌──────────────┐      ┌────────────────────┐
│  CUSTOMERS   │      │FLIGHT_SCHEDULE│      │     BOOKINGS       │
├──────────────┤      ├──────────────┤      ├────────────────────┤
│ customer_id  │      │ flight_no    │      │ booking_id (PK)    │
│ first_name   │      │ departure_code│     │ flight_no (FK)    │
│ last_name    │      │ arrival_code  │     │ customer_id (FK)  │
│ loyalty_tier │      │ reg_no        │     │ fare_class        │
│ email        │      │ scheduled_time│     │ booking_date      │
│ phone        │      │ duration      │     │ status            │
└──────────────┘      └──────────────┘      └────────────────────┘
         ↓ FK                     ↓ FK
    (customer_id)            (flight_no)
 ```

**Explanation:** Removed partial dependencies. Customer details moved to CUSTOMERS table. Price column removed (transitive dependency issue).

### For 3NF (Third Normal Form):

text
```
┌─────────────────────────────────────────┐
│           AIRPORTS                      │
├─────────────────────────────────────────┤
│ airport_code (PK)  VARCHAR2(3)          │
│ city               VARCHAR2(50)         │
│ country            VARCHAR2(50)         │
│ is_hub             CHAR(1)              │
│                                          │
│ Constraints:                             │
│ - PK: airport_code                       │
│ - NOT NULL: all columns                  │
│ - CHECK: is_hub IN ('Y','N')             │
└─────────────────────────────────────────┘
            │
            │ 1
            │
            │
            │ N
            ▼
┌─────────────────────────────────────────┐
│       FLIGHT_SCHEDULE                   │
├─────────────────────────────────────────┤
│ flight_no (PK)      VARCHAR2(10)        │
│ departure_code (FK) VARCHAR2(3)         │
│ arrival_code (FK)   VARCHAR2(3)         │
│ reg_no (FK)         VARCHAR2(10)        │
│ scheduled_time      TIMESTAMP           │
│ estimated_duration  NUMBER              │
│                                          │
│ Constraints:                             │
│ - PK: flight_no                          │
│ - FK: departure_code → AIRPORTS          │
│ - FK: arrival_code → AIRPORTS            │
│ - FK: reg_no → AIRCRAFT                  │
│ - NOT NULL: all columns                  │
└─────────────────────────────────────────┘
            │
            │ 1
            │
            │
            │ N
            ▼
┌─────────────────────────────────────────┐
│         BOOKINGS                        │
├─────────────────────────────────────────┤
│ booking_id (PK)     NUMBER              │
│ flight_no (FK)      VARCHAR2(10)        │
│ customer_id (FK)    NUMBER              │
│ fare_class          VARCHAR2(2)         │
│ booking_date        DATE                │
│ status              VARCHAR2(20)        │
│                                          │
│ Constraints:                             │
│ - PK: booking_id                         │
│ - FK: flight_no → FLIGHT_SCHEDULE        │
│ - FK: customer_id → CUSTOMERS            │
│ - CHECK: fare_class IN ('K','L','M','H') │
│ - CHECK: status IN ('CONFIRMED', etc.)  │
│ - DEFAULT: booking_date = SYSDATE        │
└─────────────────────────────────────────┘
            ▲
            │ N
            │
            │
            │ 1
            │
┌─────────────────────────────────────────┐
│          CUSTOMERS                      │
├─────────────────────────────────────────┤
│ customer_id (PK)    NUMBER              │
│ first_name          VARCHAR2(50)        │
│ last_name           VARCHAR2(50)        │
│ loyalty_tier        VARCHAR2(20)        │
│ email               VARCHAR2(100)       │
│ phone               VARCHAR2(20)        │
│                                          │
│ Constraints:                             │
│ - PK: customer_id                        │
│ - NOT NULL: all columns                  │
│ - UNIQUE: email                          │
│ - CHECK: loyalty_tier IN ('STANDARD',    │
│   'SILVER','GOLD','PLATINUM')           │
└─────────────────────────────────────────┘
```
**Additional 3NF Tables:**

text
```
┌─────────────────────────────────────────┐
│         PRICE_RULES                     │
├─────────────────────────────────────────┤
│ rule_id (PK)        NUMBER              │
│ fare_class          VARCHAR2(2)         │
│ base_price          NUMBER(10,2)        │
│ min_price           NUMBER(10,2)        │
│ max_price           NUMBER(10,2)        │
│ effective_from      DATE                │
│ effective_to        DATE                │
│                                          │
│ Constraints:                             │
│ - PK: rule_id                           │
│ - CHECK: base_price > 0                 │
│ - CHECK: min_price <= max_price         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      PRICE_ADJUSTMENTS                  │
├─────────────────────────────────────────┤
│ adjustment_id (PK)  NUMBER              │
│ flight_no (FK)      VARCHAR2(10)        │
│ fare_class          VARCHAR2(2)         │
│ old_price           NUMBER(10,2)        │
│ new_price           NUMBER(10,2)        │
│ adjustment_date     TIMESTAMP           │
│ reason              VARCHAR2(200)       │
│                                          │
│ Constraints:                             │
│ - PK: adjustment_id                      │
│ - FK: flight_no → FLIGHT_SCHEDULE        │
│ - DEFAULT: adjustment_date = SYSTIMESTAMP│
│ - NOT NULL: reason                       │
└─────────────────────────────────────────┘
```
**3NF Justification:**

1. **All tables have single primary keys**
    
2. **No partial dependencies** - All non-key columns depend on entire PK
    
3. **No transitive dependencies** - Removed derived/calculated columns
    
4. **Price separated** from bookings (price depends on rules + adjustments)
    
5. **Customer details separate** from bookings
    
6. **Each table represents one entity type**
   
---

## 3. Complete Data Dictionary

### Table 1: AIRPORTS

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|airport_code|VARCHAR2(3)|PRIMARY KEY, NOT NULL|IATA airport code|
|city|VARCHAR2(50)|NOT NULL|City name|
|country|VARCHAR2(50)|NOT NULL|Country name|
|is_hub|CHAR(1)|NOT NULL, CHECK(is_hub IN ('Y','N'))|Whether airport is a hub|

### Table 2: AIRCRAFT

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|reg_no|VARCHAR2(10)|PRIMARY KEY, NOT NULL|Aircraft registration number|
|aircraft_type|VARCHAR2(20)|NOT NULL|e.g., Boeing 737, Airbus A320|
|capacity|NUMBER|NOT NULL, CHECK(capacity > 0)|Maximum passengers|

### Table 3: FLIGHT_SCHEDULE

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|flight_no|VARCHAR2(10)|PRIMARY KEY, NOT NULL|Flight number|
|departure_code|VARCHAR2(3)|FOREIGN KEY, NOT NULL|References AIRPORTS(airport_code)|
|arrival_code|VARCHAR2(3)|FOREIGN KEY, NOT NULL|References AIRPORTS(airport_code)|
|reg_no|VARCHAR2(10)|FOREIGN KEY, NOT NULL|References AIRCRAFT(reg_no)|
|scheduled_time|TIMESTAMP|NOT NULL|Planned departure time|
|estimated_duration|NUMBER|NOT NULL|Flight duration in minutes|

### Table 4: DEPARTURES

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|flight_no|VARCHAR2(10)|PRIMARY KEY, FOREIGN KEY|References FLIGHT_SCHEDULE(flight_no)|
|departure_time|TIMESTAMP|NOT NULL|Actual departure time|
|status|VARCHAR2(20)|CHECK(status IN ('SCHEDULED','BOARDING','DEPARTED','DELAYED','CANCELLED'))|Current flight status|
|actual_departure|TIMESTAMP|NULL|When flight actually departed|

### Table 5: CUSTOMERS

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|customer_id|NUMBER|PRIMARY KEY, AUTO_INCREMENT|Unique customer ID|
|first_name|VARCHAR2(50)|NOT NULL|Customer first name|
|last_name|VARCHAR2(50)|NOT NULL|Customer last name|
|loyalty_tier|VARCHAR2(20)|CHECK(tier IN ('STANDARD','SILVER','GOLD','PLATINUM'))|Loyalty program level|
|email|VARCHAR2(100)|UNIQUE, NOT NULL|Customer email|
|phone|VARCHAR2(20)|NOT NULL|Contact number|

### Table 6: BOOKINGS

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|booking_id|NUMBER|PRIMARY KEY, AUTO_INCREMENT|Unique booking ID|
|flight_no|VARCHAR2(10)|FOREIGN KEY, NOT NULL|References FLIGHT_SCHEDULE(flight_no)|
|customer_id|NUMBER|FOREIGN KEY, NOT NULL|References CUSTOMERS(customer_id)|
|fare_class|VARCHAR2(2)|NOT NULL, CHECK(fare_class IN ('K','L','M','H'))|Fare class (K=Economy, etc.)|
|booking_date|DATE|NOT NULL, DEFAULT SYSDATE|When booking was made|
|status|VARCHAR2(20)|CHECK(status IN ('CONFIRMED','CANCELLED','CHECKED_IN','NO_SHOW'))|Booking status|

### Table 7: NO_SHOW_FORECAST

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|forecast_id|NUMBER|PRIMARY KEY, AUTO_INCREMENT|Unique forecast ID|
|flight_no|VARCHAR2(10)|FOREIGN KEY, NOT NULL|References FLIGHT_SCHEDULE(flight_no)|
|forecast_date|DATE|NOT NULL, DEFAULT SYSDATE|When prediction was made|
|predicted_noshows|NUMBER|NOT NULL, CHECK(predicted_noshows >= 0)|Number of expected no-shows|
|confidence_score|NUMBER|CHECK(confidence_score >= 0 AND confidence_score <= 1)|Prediction confidence (0-1)|

### Table 8: PRICE_RULES

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|rule_id|NUMBER|PRIMARY KEY, AUTO_INCREMENT|Unique rule ID|
|fare_class|VARCHAR2(2)|NOT NULL|References fare class|
|base_price|NUMBER(10,2)|NOT NULL, CHECK(base_price > 0)|Standard price|
|min_price|NUMBER(10,2)|NOT NULL|Minimum allowed price|
|max_price|NUMBER(10,2)|NOT NULL|Maximum allowed price|
|effective_from|DATE|NOT NULL|Rule start date|
|effective_to|DATE|NULL|Rule end date (NULL = active)|

### Table 9: PRICE_ADJUSTMENTS

|Column|Data Type|Constraints|Description|
|---|---|---|---|
|adjustment_id|NUMBER|PRIMARY KEY, AUTO_INCREMENT|Unique adjustment ID|
|flight_no|VARCHAR2(10)|FOREIGN KEY, NOT NULL|References FLIGHT_SCHEDULE(flight_no)|
|fare_class|VARCHAR2(2)|NOT NULL|Which fare class adjusted|
|old_price|NUMBER(10,2)|NOT NULL|Price before adjustment|
|new_price|NUMBER(10,2)|NOT NULL|Price after adjustment|
|adjustment_date|TIMESTAMP|NOT NULL, DEFAULT SYSTIMESTAMP|When adjustment was made|
|reason|VARCHAR2(200)|NOT NULL|Reason for adjustment|

---

## 4. Relationship Cardinalities

|Relationship|Parent → Child|Cardinality|Business Rule|
|---|---|---|---|
|AIRPORTS → FLIGHT_SCHEDULE (departure)|1:N|One airport has many departing flights||
|AIRPORTS → FLIGHT_SCHEDULE (arrival)|1:N|One airport has many arriving flights||
|AIRCRAFT → FLIGHT_SCHEDULE|1:N|One aircraft used for many flights||
|FLIGHT_SCHEDULE → DEPARTURES|1:1|Each scheduled flight has one departure record||
|FLIGHT_SCHEDULE → BOOKINGS|1:N|One flight has many bookings||
|FLIGHT_SCHEDULE → NO_SHOW_FORECAST|1:N|One flight has many forecasts over time||
|FLIGHT_SCHEDULE → PRICE_ADJUSTMENTS|1:N|One flight has many price adjustments||
|CUSTOMERS → BOOKINGS|1:N|One customer can make many bookings||
|FARE_CLASS → PRICE_RULES|1:N|One fare class has many pricing rules over time||

---

## 5. Key Assumptions

### Business Rules

1. **Airport Codes**: Use IATA 3-letter codes
    
2. **Fare Classes**: K (Economy Discount), L (Economy), M (Economy Flex), H (Business)
    
3. **Loyalty Tiers**: STANDARD, SILVER, GOLD, PLATINUM
    
4. **No-show Definition**: Passenger with CONFIRMED booking who doesn't CHECK_IN
    
5. **Price Adjustments**: Can only occur within min/max bounds per PRICE_RULES
    

### Data Integrity

6. **Flight Numbers**: Unique across the system
    
7. **Booking Status Flow**: CONFIRMED → CHECKED_IN or NO_SHOW or CANCELLED
    
8. **Price Validation**: New price must be between min_price and max_price
    
9. **Aircraft Assignment**: One aircraft per flight at a time
    

### System Behavior

10. **Forecast Frequency**: Predictions run daily for next 7 days of flights
    
11. **Price Adjustment Trigger**: When flight load > 80% or predicted no-shows > 15%
    
12. **Historical Data**: Keep all price adjustments for audit
    
13. **Real-time Updates**: Prices can change up to 2 hours before departure
    

### Future Considerations

14. **Seasonal Pricing**: Could add seasonal multipliers to PRICE_RULES
    
15. **Competitor Pricing**: Future table for competitor price tracking
    
16. **Demand Forecasting**: Extend beyond no-shows to overall demand prediction
    

---

## 6. BI Considerations

### Fact vs. Dimension Tables

**Fact Tables (Measures):**

- `BOOKINGS` - Sales facts (count, revenue opportunity)
    
- `PRICE_ADJUSTMENTS` - Pricing facts (price changes, timing)
    
- `NO_SHOW_FORECAST` - Prediction facts (accuracy tracking)
    

**Dimension Tables (Context):**

- `FLIGHT_SCHEDULE` - Flight dimension (routes, times)
    
- `CUSTOMERS` - Customer dimension (demographics, loyalty)
    
- `AIRPORTS` - Location dimension
    
- `AIRCRAFT` - Equipment dimension
    
- `TIME` - Date dimension (would be created for BI)
    

### Slowly Changing Dimensions (SCD)

1. **CUSTOMERS.loyalty_tier** - Type 2 (track history)
    
    - Add effective_date, expiry_date columns
        
    - Keep history of tier changes for loyalty analysis
        
2. **PRICE_RULES** - Type 2 (versioning)
    
    - Multiple rule versions with effective dates
        
    - Track pricing strategy changes over time
        
3. **AIRCRAFT.capacity** - Type 1 (overwrite)
    
    - Current capacity is most relevant
        
    - Historical capacity changes not critical
        

### Aggregation Levels

**Revenue Analysis:**

- Daily/Weekly/Monthly revenue by route
    
- Revenue by fare class
    
- Revenue by customer tier
    
- Revenue per aircraft type
    

**Occupancy Analysis:**

- Load factor by flight, route, time of day
    
- No-show rates by customer tier, booking channel
    
- Booking lead time analysis
    

**Pricing Analysis:**

- Price elasticity by route and time
    
- Adjustment frequency and impact
    
- Competitive price positioning
    

#  Audit Trail Design 

## **What We Track Now:**

1. **`booking_date`** - When someone booked a ticket
    
2. **`adjustment_date`** - When we changed a price
    
3. **`forecast_date`** - When we predicted no-shows
    
4. **`departure_time`** - When flights actually left
    
5. **`effective_from/to`** - When price rules were active
    

## **What We Can Do With This:**

### **Good Things:**

- See **when** bookings happen (busy times, slow times)
    
- Track **all price changes** for each flight
    
- Know **when predictions** were made
    
- Compare **scheduled vs actual** departure times
    
- Check **which price rules** were used when
    

###  **Business Analysis Possible:**

- Find best booking times
    
- See how often prices change
    
- Check if predictions are getting better
    
- Measure flight punctuality
    
- Study price changes over time
