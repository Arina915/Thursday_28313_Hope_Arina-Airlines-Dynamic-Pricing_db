# **PHASE V: TABLE IMPLEMENTATION & DATA INSERTION**
----
### **Executive Summary**

This Phase V successfully implemented the complete physical database structure for Arina Airlines. The phase involved creating 8 normalized tables, inserting **576+ rows** of realistic airline data (expandable to 2,000+), and executing comprehensive validation and testing queries. All data integrity requirements were verified, and the database is now fully prepared for PL/SQL package development in Phase VI.

### **Objectives Accomplished**

1. Created 8 normalized database tables with proper constraints
    
2. Inserted 576+ rows of realistic airline test data
    
3. Verified data integrity through comprehensive validation queries
    
4. Demonstrated all required query types (SELECT *, Joins, GROUP BY, Subqueries)
    
5. Implemented business rules and constraint enforcement
    
6. Prepared database for Phase VI PL/SQL development
    

### **Database Schema Implementation**

#### **Tables Created**

1. **AIRPORTS** - Airport details and hub status (6+ rows)
    
2. **AIRCRAFT** - Fleet information and capacity limits (4+ rows)
    
3. **FLIGHT_SCHEDULE** - Flight routes and schedules (90+ rows)
    
4. **CUSTOMERS** - Passenger profiles and loyalty data (115+ rows)
    
5. **BOOKINGS** - Passenger reservations and ticketing (121+ rows)
    
6. **NO_SHOW_FORECAST** - ML predictions for no-shows (108+ rows)
    
7. **PRICE_RULES** - Dynamic pricing rules and boundaries (5+ rows)
    
8. **PRICE_ADJUSTMENTS** - Audit trail of price changes (127+ rows)
    

#### **Key Constraints Implemented**

- Primary Keys on all tables with identity generation
    
- Foreign Keys with proper referential integrity
    
- CHECK constraints for business rules (fare classes, loyalty tiers, statuses)
    
- NOT NULL constraints for required business fields
    
- UNIQUE constraints for seat assignments and emails
    
- DEFAULT values for booking dates and statuses
    

### **Data Insertion Details**

#### **Volume Requirements Met**

|Table|Rows Inserted|Requirement|Status|
|---|---|---|---|
|BOOKINGS|121+|100+|PASS|
|CUSTOMERS|115+|100+|PASS|
|FLIGHT_SCHEDULE|90+|10+|PASS|
|NO_SHOW_FORECAST|108+|20+|PASS|
|PRICE_ADJUSTMENTS|127+|15+|PASS|
|AIRPORTS|6+|Sample|PASS|
|AIRCRAFT|4+|Sample|PASS|
|PRICE_RULES|5+|Sample|PASS|
|**TOTAL**|**576+**|**500+**|**PASS**|

#### **Data Characteristics**

- **Realistic Scenarios:** Based on actual regional airline operations (Nairobi-Dar es Salaam-Kigali routes)
  
- **Demographic Mix:** Varied customer loyalty distribution (68.7% Standard, 12.17% Gold, 9.57% Silver, 9.57% Platinum)
    
- **Edge Cases:** Includes NULL values for testing, zero-price tickets, various booking statuses
    
- **Business Rules:** Overbooking limits, price ranges, fare classes validated
    
- **Referential Integrity:** All foreign key relationships maintained

#### Query Type Demonstrations
----
### 1.SELECT queries verify data (SELECT *) ###
```SELECT COUNT(*) as "AIRCRAFT COUNT" FROM AIRCRAFT;```

![COUNT 1](https://github.com/user-attachments/assets/e3ee2546-5012-430b-8069-92c26efbd9b6)
![COUNT 2](https://github.com/user-attachments/assets/d4d3dd5e-b5d6-424d-9818-8da65e0ef579)
*This just tells you how many rows are in the table - only the number, not the actual data. It's like checking how many pages are in the book without reading any words*

![STEP 3  BUSINESS RULE VALIDATION](https://github.com/user-attachments/assets/6d604d3b-bf5b-480e-83c2-a49d78fb9851)
*The query measures and grades the success of the model that tries to guess how many people will miss a flight, helping the airline decide how many extra tickets to sell.(no_show)*
### 2.Constraints enforced properly (EDGE CASE & NULL VALIDATION) ###
```SELECT 
    loyalty_level,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) as percentage,
    AVG(loyalty_points) as avg_points,
    AVG(total_flights) as avg_flights,
    MIN(join_date) as earliest_join,
    MAX(join_date) as latest_join
FROM customers
GROUP BY loyalty_level
ORDER BY 
    CASE loyalty_level 
        WHEN 'PLATINUM' THEN 1 
        WHEN 'GOLD' THEN 2 
        WHEN 'SILVER' THEN 3 
        WHEN 'BRONZE' THEN 4
        ELSE 5 
    END;
```
![STEP 2 EDGE CASE   NULL VALIDATION](https://github.com/user-attachments/assets/86425624-b8fc-4d02-8e80-837a29cc6e8f)
*This query generates a summary report about your customers, grouping them by their loyalty status (like Platinum, Gold, etc.).*

### 3.Foreign key relationships tested(FOREIGN KEY INTEGRITY TEST) ###
```SELECT 'Orphaned Bookings (no customer)' as issue_type, COUNT(*) as count
FROM bookings b
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = b.customer_id)

UNION ALL

SELECT 'Customers with no bookings', COUNT(*)
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM bookings b WHERE b.customer_id = c.customer_id)

UNION ALL

SELECT 'Bookings with future booking dates', COUNT(*)
FROM bookings 
WHERE booking_date > SYSTIMESTAMP

UNION ALL

SELECT 'Bookings with travel_date before booking_date', COUNT(*)
FROM bookings 
WHERE travel_date < booking_date

UNION ALL

SELECT 'Bookings with zero or negative price', COUNT(*)
FROM bookings 
WHERE ticket_price <= 0;
```
![STEP 4 FOREIGN KEY INTEGRITY TEST](https://github.com/user-attachments/assets/d803f40b-b97d-4791-865b-80fea422fbc4)
*This query is a simple audit that counts bad data points, helping you clean up your records so your reports and systems work correctly.*

### 4.Data completeness checked(Data completeness checked) ###
```SELECT 
    'bookings' as table_name, 
    COUNT(*) as row_count,
    CASE 
        WHEN COUNT(*) >= 100 THEN ' PASS' 
        ELSE ' INSUFFICIENT DATA' 
    END as status
FROM bookings
UNION ALL
SELECT 'customers', COUNT(*), 
    CASE WHEN COUNT(*) >= 100 THEN ' PASS' ELSE ' INSUFFICIENT DATA' END
FROM customers
UNION ALL
SELECT 'flight_schedule', COUNT(*), 
    CASE WHEN COUNT(*) >= 10 THEN ' PASS' ELSE ' INSUFFICIENT DATA' END
FROM flight_schedule
UNION ALL
SELECT 'no_show_forecast', COUNT(*), 
    CASE WHEN COUNT(*) >= 20 THEN ' PASS' ELSE ' INSUFFICIENT DATA' END
FROM no_show_forecast
UNION ALL
SELECT 'price_adjustments', COUNT(*), 
    CASE WHEN COUNT(*) >= 15 THEN ' PASS' ELSE ' INSUFFICIENT DATA' END
FROM price_adjustments;

```
![STEP 1DATA VOLUME VERIFICATION](https://github.com/user-attachments/assets/16289089-eab3-438d-ad13-a67e94cf491c)
*This SQL code is a data check that quickly tells you if the main tables in your database have enough information (rows) to be useful for whatever you're doing,
like running a report or training a model.*

### 5.Basic retrieval (SELECT *) ###
```SELECT COUNT(*) as "AIRCRAFT COUNT" FROM AIRCRAFT;```
![COUNT 1](https://github.com/user-attachments/assets/2e705671-f864-408d-af66-5b30a7ee483a)
*This counts number of data i have in the table*
```SELECT 
    flight_id,
    fare_class,
    COUNT(*) as booking_count,
    MIN(ticket_price) as min_price,
    MAX(ticket_price) as max_price,
    AVG(ticket_price) as avg_price,
    ROUND(STDDEV(ticket_price), 2) as price_stddev,
    ROUND(((MAX(ticket_price) - MIN(ticket_price)) / MIN(ticket_price)) * 100, 2) as price_variation_percent
FROM bookings
WHERE booking_status NOT IN ('CANCELLED')
GROUP BY flight_id, fare_class
HAVING COUNT(*) > 1
ORDER BY flight_id, fare_class;
```
![STEP 5 COMPREHENSIVE TESTING QUERIES](https://github.com/user-attachments/assets/fddaeeb6-c6f1-4e3c-b6fe-278f546c4062)
*This is a tool that helps airline revenue managers look at how well their strategy of changing prices worked. 
It shows how much money was earned and how often prices were changed for specific seats on particular flights.*

### 6.Joins (multi-table queries) ###
```SELECT 
    b.booking_id,
    b.booking_date,
    b.travel_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    c.loyalty_level,
    b.flight_id,
    b.fare_class,
    b.ticket_price,
    b.booking_status,
    b.payment_status,
    -- Calculate days between booking and travel
    (b.travel_date - TRUNC(b.booking_date)) as days_advance_booking
FROM bookings b
JOIN customers c ON b.customer_id = c.customer_id
WHERE ROWNUM <= 15
ORDER BY b.booking_date DESC;
```
![JOIN QUERIES](https://github.com/user-attachments/assets/fd462d10-5f82-4886-a655-463a442ab1ff)
*This code asks for a quick summary report of your latest customer reservations.It takes details from two separate lists the list of bookings and the list of customers and merges them into a single, easy-to-read overview.*
###  7.Aggregations (GROUP BY) ###
```SELECT 
    home_airport,
    COUNT(*) as customer_count,
    AVG(loyalty_points) as avg_points
FROM customers
WHERE home_airport IS NOT NULL
GROUP BY home_airport
ORDER BY customer_count DESC;
```
![GROUP BY](https://github.com/user-attachments/assets/0da1c572-a6d5-4e2e-9e13-59f32abc2697)
*This report groups customers by their home airport. It shows how many customers come from each airport and their average loyalty points.
This helps the airline see where most customers are and how loyal they are.*

### 8.Subqueries ###
```SELECT * FROM flight_schedule 
WHERE flight_no IN (
    SELECT flight_id  -- Changed from flight_no to flight_id
    FROM bookings 
    WHERE booking_status = 'NO-SHOW'  -- Changed from status to booking_status
    GROUP BY flight_id
    HAVING COUNT(*) > (
        SELECT AVG(no_show_count) 
        FROM (
            SELECT COUNT(*) as no_show_count 
            FROM bookings 
            WHERE booking_status = 'NO-SHOW'  -- Changed here too
            GROUP BY flight_id  -- Changed here too
        )
    )
);
```
![SUBQURIES](https://github.com/user-attachments/assets/cb8f38f8-53fd-4cf1-a70f-6ece99d2bfec)
*The report helps the airline find specific flights where many more passengers than normal miss their reservations.
This information is key for deciding which future flights need to be overbooked more heavily.As for my databse i have none.*

----
## **VALIDATION RESULTS SUMMARY**

### **Data Integrity Verification**

- All SELECT queries return data: PASS
    
- All constraints properly enforced: PASS
    
- Foreign key relationships validated: PASS
    
- Data completeness verified: PASS
    
- No orphaned records found: PASS
    

### **Business Rule Enforcement Confirmed**

- No negative ticket prices
    
- Valid fare classes only (F, J, Y, K, L)
    
- Valid booking statuses only (CONFIRMED, CANCELLED, CHECKED-IN, NO-SHOW)
    
- Overbooking limited to 110% capacity
    
- Arrival times after departure times
    

---

## **KEY STATISTICS**

### **Customer Loyalty Distribution**

- **STANDARD:** 79 customers (68.7%)
    
- **GOLD:** 14 customers (12.17%)
    
- **SILVER:** 11 customers (9.57%)
    
- **PLATINUM:** 11 customers (9.57%)
    

### **Booking Status Distribution**

- **CONFIRMED:** Primary status for active bookings
    
- **NO-SHOW:** 3-7% across different flights
    
- **CANCELLED:** Included for realistic scenarios
    
- **CHECKED-IN:** Completed travel status
    

### **Prediction Performance**

- **Accuracy Range:** 85-99% across different forecasts
    
- **Confidence Levels:** 90-95% prediction confidence
    
- **Model Version:** v1.2 primary implementation
    

---**CHALLENGES AND SOLUTIONS**

**Challenge 1: Not Enough Data**

- **Problem:** The main database tables needed at least 100 rows of data.
    
- **Solution:** We wrote programs to automatically create more realistic data, adding extra customer and booking information.
    

**Challenge 2: Checking the Rules**

- **Problem:** We needed to make sure all the business rules in the database were working correctly.
    
- **Solution:** We ran detailed tests on every rule, checking the different types of restrictions we had set up.
    

**Challenge 3: Making Fake Data Look Real**

- **Problem:** The fake data had to look like real airline information.
    
- **Solution:** We built the data using real East African flight routes, pricing, and schedules to make it believable
## **CONCLUSION**

**Phase V has been successfully completed** with all requirements satisfied. The database is now:

1. **Fully Structured:** 8 normalized tables with proper relationships
    
2. **Adequately Populated:** 576+ rows of realistic airline data
    
3. **Integrity Verified:** All constraints and relationships validated
    
4. **Comprehensively Tested:** All query types demonstrated successfully
    
5. **Business Ready:** Prepared for dynamic pricing and no-show prediction algorithms
    
6. **Phase VI Ready:** Foundation established for PL/SQL package development
    

The Arina Airlines Dynamic Pricing and No-Show Prediction System database now serves as a solid foundation for the advanced PL/SQL development scheduled for Phase VI.











