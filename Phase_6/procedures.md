# PHASE VI: Database Interaction & Transactions  
---
## executive summary
This phase focuses on implementing robust, production-ready database logic using PL/SQL to enable enhanced business intelligence (BI) capabilities.
The core objective is to develop modular, efficient, and secure procedures, functions, and packages that handle complex data operations, transformations, and analytics.

### Procedures 
#### Package 1: revenue_engine 
##### purpose:
This procedure remembers the old ticket price, saves the price change in a history table, updates future bookings with the new price, and prints a summary.
It also handles cases where no previous price exists.. It automatically sets the best prices and predicts which customers might not show up (no-shows).
**procedure**
```CREATE OR REPLACE PROCEDURE update_dynamic_pricing(
    p_flight_id IN VARCHAR2,
    p_fare_class IN VARCHAR2,
    p_new_price IN NUMBER,
    p_adjustment_reason IN VARCHAR2,
    p_adjusted_by IN VARCHAR2 DEFAULT 'SYSTEM',
    p_no_show_prediction IN NUMBER DEFAULT NULL,
    p_load_factor IN NUMBER DEFAULT NULL
)
IS
    v_old_price NUMBER;
    v_adjustment_time TIMESTAMP := SYSTIMESTAMP;
BEGIN
    -- Get current average price from bookings for this flight and fare class
    SELECT AVG(ticket_price) 
    INTO v_old_price
    FROM bookings 
    WHERE flight_id = p_flight_id 
    AND fare_class = p_fare_class
    AND booking_status = 'CONFIRMED'
    AND ROWNUM = 1;
    
    -- If no current price found, use 0
    IF v_old_price IS NULL THEN
        v_old_price := 0;
    END IF;
    
    -- Insert the price adjustment record
    INSERT INTO price_adjustments (
        flight_id,
        fare_class, 
        old_price, 
        new_price, 
        adjustment_reason, 
        adjusted_by,
        adjustment_timestamp,
        no_show_prediction,
        load_factor
    )
    VALUES (
        p_flight_id,
        p_fare_class, 
        v_old_price, 
        p_new_price, 
        p_adjustment_reason, 
        p_adjusted_by,
        v_adjustment_time,
        p_no_show_prediction,
        p_load_factor
    );
    
    -- Update future bookings with the new price
    UPDATE bookings 
    SET ticket_price = p_new_price
    WHERE flight_id = p_flight_id
    AND fare_class = p_fare_class
    AND booking_status IN ('CONFIRMED', 'PENDING')
    AND travel_date > SYSDATE;
    
    COMMIT;
    
    -- Display results
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('PRICE ADJUSTMENT COMPLETED');
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('Flight: ' || p_flight_id);
    DBMS_OUTPUT.PUT_LINE('Fare Class: ' || p_fare_class);
    DBMS_OUTPUT.PUT_LINE('Old Price: ' || v_old_price);
    DBMS_OUTPUT.PUT_LINE('New Price: ' || p_new_price);
    DBMS_OUTPUT.PUT_LINE('Price Change: ' || (p_new_price - v_old_price));
    DBMS_OUTPUT.PUT_LINE('Future Bookings Updated: ' || SQL%ROWCOUNT);
    DBMS_OUTPUT.PUT_LINE('Reason: ' || p_adjustment_reason);
    DBMS_OUTPUT.PUT_LINE('Adjusted by: ' || p_adjusted_by);
    DBMS_OUTPUT.PUT_LINE('=========================================');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No existing bookings found for this flight and fare class.');
        DBMS_OUTPUT.PUT_LINE('Setting old price to 0.');
        v_old_price := 0;
        
        -- Insert with 0 as old price
        INSERT INTO price_adjustments (
            flight_id, fare_class, old_price, new_price, 
            adjustment_reason, adjusted_by, adjustment_timestamp,
            no_show_prediction, load_factor
        )
        VALUES (
            p_flight_id, p_fare_class, 0, p_new_price, 
            p_adjustment_reason, p_adjusted_by, v_adjustment_time,
            p_no_show_prediction, p_load_factor
        );
        COMMIT; 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/
```
**Testing**
```BEGIN
    update_dynamic_pricing(
        p_flight_id => 'AA101',
        p_fare_class => 'B',
        p_new_price => 400.00,
        p_adjustment_reason => 'High demand season',
        p_adjusted_by => 'ADMIN'
    );
END;
/

-- Test 2: With no-show prediction and load factor
BEGIN
    update_dynamic_pricing(
        p_flight_id => 'AA102',
        p_fare_class => 'E',
        p_new_price => 250.00,
        p_adjustment_reason => 'Low load factor adjustment',
        p_adjusted_by => 'SYSTEM',
        p_no_show_prediction => 15.5,
        p_load_factor => 65.2
    );
END;
/

-- Check the price_adjustments table
SELECT * FROM price_adjustments ORDER BY adjustment_timestamp DESC;

-- Check updated bookings
SELECT flight_id, fare_class, ticket_price, booking_status, travel_date
FROM bookings 
WHERE flight_id IN ('AA101', 'AA102')
AND fare_class IN ('B', 'E')
AND travel_date > SYSDATE
ORDER BY flight_id, fare_class;
```
![Procedure 1 update_dynamic_pricing](https://github.com/user-attachments/assets/8e3590cf-5e1e-4ebf-ba18-a81f4a65bf71)

#### Package 2: booking_manager
#### purpose:
This procedure, update_dynamic_pricing, is designed to change the ticket price for a specific flight and fare class, and record that change.
```
CREATE OR REPLACE PROCEDURE process_no_show_prediction(
    p_flight_id IN VARCHAR2,
    p_travel_date IN DATE DEFAULT SYSDATE + 7
)
IS
    v_forecast_id NUMBER;
    v_predicted_no_shows NUMBER(3);
    v_confidence NUMBER(5,2);
    v_total_bookings NUMBER;
    v_historical_rate NUMBER(5,2);
    v_season_factor NUMBER(5,2);
    v_model_version VARCHAR2(20) := 'V1.2';
BEGIN
    -- Get total confirmed bookings for this flight on travel date
    SELECT COUNT(*)
    INTO v_total_bookings
    FROM bookings
    WHERE flight_id = p_flight_id
    AND TRUNC(travel_date) = TRUNC(p_travel_date)
    AND booking_status IN ('CONFIRMED', 'CHECKEDIN', 'PENDING');
    
    -- Calculate historical no-show rate for this flight
    SELECT 
        ROUND(
            COUNT(CASE WHEN booking_status = 'NOSHOW' THEN 1 END) * 100.0 / 
            NULLIF(COUNT(*), 0), 
            2
        )
    INTO v_historical_rate
    FROM bookings
    WHERE flight_id = p_flight_id
    AND travel_date BETWEEN p_travel_date - 90 AND p_travel_date - 1;
    
    -- Adjust for seasonality
    v_season_factor := CASE 
        WHEN EXTRACT(MONTH FROM p_travel_date) IN (12, 1, 6, 7, 8) THEN 1.25  -- Peak/holiday seasons
        WHEN EXTRACT(MONTH FROM p_travel_date) IN (2, 11) THEN 0.85           -- Low seasons
        ELSE 1.0
    END;
    
    -- Default historical rate if no data
    IF v_historical_rate IS NULL THEN
        v_historical_rate := 12.5; -- Industry average
    END IF;
    
    -- Calculate predicted no-shows
    v_predicted_no_shows := ROUND(v_total_bookings * (v_historical_rate / 100) * v_season_factor);
    
    -- Calculate prediction confidence based on sample size
    SELECT 
        CASE 
            WHEN v_total_bookings >= 50 THEN 95.0
            WHEN v_total_bookings >= 20 THEN 85.0
            WHEN v_total_bookings >= 10 THEN 70.0
            WHEN v_total_bookings >= 5 THEN 60.0
            ELSE 50.0
        END
    INTO v_confidence
    FROM dual;
    
    -- Get next forecast ID
    SELECT NVL(MAX(forecast_id), 0) + 1
    INTO v_forecast_id
    FROM no_show_forecast;
    
    -- Insert the prediction
    INSERT INTO no_show_forecast (
        forecast_id,
        flight_id,
        forecast_date,
        travel_date,
        predicted_no_shows,
        prediction_confidence,
        model_version
    )
    VALUES (
        v_forecast_id,
        p_flight_id,
        SYSDATE,
        p_travel_date,
        v_predicted_no_shows,
        v_confidence,
        v_model_version
    );
    
    COMMIT;
    
    -- Output results
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('NO-SHOW PREDICTION GENERATED');
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('Flight ID: ' || p_flight_id);
    DBMS_OUTPUT.PUT_LINE('Travel Date: ' || TO_CHAR(p_travel_date, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Total Bookings: ' || v_total_bookings);
    DBMS_OUTPUT.PUT_LINE('Historical No-Show Rate: ' || v_historical_rate || '%');
    DBMS_OUTPUT.PUT_LINE('Season Factor: ' || v_season_factor);
    DBMS_OUTPUT.PUT_LINE('Predicted No-Shows: ' || v_predicted_no_shows);
    DBMS_OUTPUT.PUT_LINE('Confidence: ' || v_confidence || '%');
    DBMS_OUTPUT.PUT_LINE('Model Version: ' || v_model_version);
    DBMS_OUTPUT.PUT_LINE('Forecast ID: ' || v_forecast_id);
    DBMS_OUTPUT.PUT_LINE('==========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/
```
#### Testing
```
BEGIN
    process_no_show_prediction('AA101', SYSDATE + 7);
END;
/

-- Test 2: Generate prediction for AA102
BEGIN
    process_no_show_prediction('AA102', SYSDATE + 14);
END;
/

-- Test 3: Update with actual no-shows (for past flights)
BEGIN
    update_actual_no_shows('AA101', DATE '2024-01-20');
END;
/

-- View all forecasts
SELECT 
    forecast_id,
    flight_id,
    TO_CHAR(forecast_date, 'DD-MON-YYYY') as forecasted_on,
    TO_CHAR(travel_date, 'DD-MON-YYYY') as travel_date,
    predicted_no_shows,
    actual_no_shows,
    prediction_confidence || '%' as confidence,
    forecast_accuracy || '%' as accuracy,
    model_version
FROM no_show_forecast
ORDER BY travel_date DESC, flight_id;
```
![procedure 2](https://github.com/user-attachments/assets/0c7e1ba3-fe1e-4672-aa83-b6348677375c)

#### package 3: Flight booking availability 
#### purpose:
 It looks at how many people have booked, how many are expected not to show up, and compares this with the flight’s seat capacity.
Then it tells you if the flight is safe, almost full, or too overbooked and should stop accepting new bookings.
 ```
CREATE OR REPLACE PROCEDURE check_overbooking_status(
    p_flight_id IN VARCHAR2
)
IS
    v_capacity NUMBER := 180; -- Default capacity
    v_max_overbook_percent NUMBER := 15; -- Allow 15% overbooking
    v_confirmed_bookings NUMBER;
    v_predicted_no_shows NUMBER;
BEGIN
    -- Get confirmed bookings
    SELECT COUNT(*)
    INTO v_confirmed_bookings
    FROM bookings
    WHERE flight_id = p_flight_id
    AND booking_status IN ('CONFIRMED', 'CHECKEDIN')
    AND travel_date > SYSDATE;
    
    -- Try to get predicted no-shows
    BEGIN
        SELECT predicted_no_shows
        INTO v_predicted_no_shows
        FROM no_show_forecast
        WHERE flight_id = p_flight_id
        AND travel_date > SYSDATE
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_predicted_no_shows := ROUND(v_confirmed_bookings * 0.10); -- Assume 10%
    END;
    
    -- Display analysis
    DBMS_OUTPUT.PUT_LINE('FLIGHT: ' || p_flight_id);
    DBMS_OUTPUT.PUT_LINE('Capacity: ' || v_capacity);
    DBMS_OUTPUT.PUT_LINE('Confirmed bookings: ' || v_confirmed_bookings);
    DBMS_OUTPUT.PUT_LINE('Predicted no-shows: ' || v_predicted_no_shows);
    DBMS_OUTPUT.PUT_LINE('Effective occupancy: ' || (v_confirmed_bookings - v_predicted_no_shows));
    
    -- Decision logic
    IF v_confirmed_bookings <= v_capacity THEN
        DBMS_OUTPUT.PUT_LINE('STATUS:  UNDER CAPACITY - Accepting bookings');
    ELSIF (v_confirmed_bookings - v_predicted_no_shows) <= (v_capacity * (1 + v_max_overbook_percent/100)) THEN
        DBMS_OUTPUT.PUT_LINE('STATUS:  WITHIN OVERBOOKING LIMITS - Proceed with caution');
        DBMS_OUTPUT.PUT_LINE('Overbooked by: ' || (v_confirmed_bookings - v_capacity) || ' seats');
    ELSE
        DBMS_OUTPUT.PUT_LINE('STATUS:  EXCEEDS OVERBOOKING LIMITS - Stop bookings');
        DBMS_OUTPUT.PUT_LINE('Would exceed by: ' || 
            ((v_confirmed_bookings - v_predicted_no_shows) - (v_capacity * (1 + v_max_overbook_percent/100))) || ' seats');
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No bookings found for flight ' || p_flight_id);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/    
```
#### Testing
```
BEGIN
    check_overbooking_status('AA101');
END;
/
```
![prosedure 3](https://github.com/user-attachments/assets/49d199c1-9ced-48f4-bb55-beb14db88eea)

#### package 4:audit_trail
#### purpose:
This procedure adds loyalty points to a customer and updates their tier (Bronze, Silver, Gold, Platinum).
It increases their points, checks if they qualify for a higher tier, updates the record, and shows the new status.
```CREATE OR REPLACE PROCEDURE update_loyalty_points(
    p_customer_id IN NUMBER,
    p_points_to_add IN NUMBER DEFAULT 1000  -- Default 1000 points per flight
)
IS
    v_new_tier VARCHAR2(20);
    v_old_tier VARCHAR2(20);
    v_old_points NUMBER;
    v_new_points NUMBER;
BEGIN
    -- Get current status
    SELECT loyalty_points, NVL(loyalty_level, 'BRONZE')
    INTO v_old_points, v_old_tier
    FROM customers
    WHERE customer_id = p_customer_id;
    
    -- Calculate new points
    v_new_points := v_old_points + p_points_to_add;
    
    -- Determine new tier
    v_new_tier := CASE 
        WHEN v_new_points >= 100000 THEN 'PLATINUM'
        WHEN v_new_points >= 50000 THEN 'GOLD'
        WHEN v_new_points >= 25000 THEN 'SILVER'
        ELSE 'BRONZE'
    END;
    
    -- Update customer
    UPDATE customers
    SET 
        loyalty_points = v_new_points,
        loyalty_level = v_new_tier
    WHERE customer_id = p_customer_id;
    
    COMMIT;
    
    -- Display results
    DBMS_OUTPUT.PUT_LINE('=====================================');
    DBMS_OUTPUT.PUT_LINE('LOYALTY UPDATE - Customer: ' || p_customer_id);
    DBMS_OUTPUT.PUT_LINE('=====================================');
    DBMS_OUTPUT.PUT_LINE('Points: ' || v_old_points || ' → ' || v_new_points);
    DBMS_OUTPUT.PUT_LINE('Tier:   ' || v_old_tier || ' → ' || v_new_tier);
    DBMS_OUTPUT.PUT_LINE('Added:  ' || p_points_to_add || ' points');
    
    -- Check if tier changed
    IF v_old_tier != v_new_tier THEN
        DBMS_OUTPUT.PUT_LINE(' CONGRATULATIONS! Tier upgraded!');
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(' Customer ' || p_customer_id || ' not found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' Error: ' || SQLERRM);
END;
/
```
#### Testing:
```BEGIN
    update_loyalty_points(111, 5000); -- Add 5000 points to customer 111
END;
/

-- Test 2: Update multiple customers
BEGIN
    FOR i IN 1..5 LOOP
        update_loyalty_points(110 + i, 2500);
    END LOOP;
END;
/

-- Test 3: Check customer loyalty status
SELECT 
    customer_id,
    first_name || ' ' || last_name as customer_name,
    loyalty_level,
    loyalty_points,
    total_flights,
    CASE 
        WHEN loyalty_points >= 100000 THEN 'PLATINUM (next: maintain)'
        WHEN loyalty_points >= 50000 THEN 'GOLD (next: 100,000 for Platinum)'
        WHEN loyalty_points >= 25000 THEN 'SILVER (next: 50,000 for Gold)'
        ELSE 'BRONZE (next: 25,000 for Silver)'
    END as next_milestone,
    ROUND(loyalty_points / 25000) * 25000 as points_to_next_tier
FROM customers
WHERE customer_id IN (111, 112, 113)
ORDER BY loyalty_points DESC;
```
![procedure 4](https://github.com/user-attachments/assets/c78d84d7-0a17-4170-9e1e-0b1f490f6c6d)

#### Package 5:
#### purpose:
This procedure cancels a booking and calculates how much refund the customer should get. It checks the booking using the booking ID, finds the ticket price,
and returns the refund amount based on the refund percentage. If the booking is not found or any error happens, it returns an error message.
```
CREATE OR REPLACE PROCEDURE cancel_booking_with_refund(
    p_booking_id IN NUMBER,
    p_refund_percentage IN NUMBER DEFAULT 70,
    p_refund_amount OUT NUMBER,
    p_status OUT VARCHAR2
)
IS
    -- Local variables here (if any)
    v_ticket_price NUMBER;
    v_booking_status VARCHAR2(20);
BEGIN
    -- Your procedure logic here
    -- Example:
    SELECT ticket_price, booking_status 
    INTO v_ticket_price, v_booking_status
    FROM bookings
    WHERE booking_id = p_booking_id;
    
    -- More logic...
    
    p_refund_amount := v_ticket_price * (p_refund_percentage / 100);
    p_status := 'SUCCESS';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status := 'BOOKING_NOT_FOUND';
        p_refund_amount := 0;
    WHEN OTHERS THEN
        p_status := 'ERROR: ' || SQLERRM;
        p_refund_amount := 0;
END;
/ 
```
#### Testing
```
DECLARE
    v_refund_amount NUMBER;
    v_status VARCHAR2(100);
BEGIN
    cancel_booking_with_refund(
        p_booking_id => 123,
        p_refund_percentage => 70,
        p_refund_amount => v_refund_amount,
        p_status => v_status
    );
    
    DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    DBMS_OUTPUT.PUT_LINE('Refund Amount: ' || v_refund_amount);
END;
/
```
![procedure 5](https://github.com/user-attachments/assets/72c55769-476b-4a91-8a89-adbb41f2d83d)

#### package 6: Delete_canceled_BOOKINGS Procedure 
#### purpose:
This procedure cancels a booking and calculates how much refund the customer should get. It checks the booking using the booking ID,
finds the ticket price, and returns the refund amount based on the refund percentage. If the booking is not found or any error happens, it returns an error message.
#### procedure
```
CREATE OR REPLACE PROCEDURE DELETE_CANCELLED_BOOKINGS(
    p_months_old IN NUMBER DEFAULT 6
)
IS
    v_count NUMBER := 0;
BEGIN
    -- Delete cancelled bookings older than specified months
    DELETE FROM bookings
    WHERE booking_status = 'CANCELLED'
      AND booking_date < ADD_MONTHS(SYSDATE, -p_months_old);
    
    v_count := SQL%ROWCOUNT;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Successfully deleted ' || v_count || 
                       ' cancelled bookings (older than ' || 
                       p_months_old || ' months).');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/
```
#### Testing
```
SET SERVEROUTPUT ON;

-- Option 1: Run with default parameter (6 months)
BEGIN
    DELETE_CANCELLED_BOOKINGS;
END;
/

BEGIN
    DELETE_CANCELLED_BOOKINGS(3);
END;
/

BEGIN
    DELETE_CANCELLED_BOOKINGS(12);
END;
/

SELECT booking_id, booking_date, booking_status, customer_id, flight_id
FROM bookings
WHERE booking_status = 'CANCELLED'
  AND booking_date < ADD_MONTHS(SYSDATE, -6);  
```

![deleting](https://github.com/user-attachments/assets/4de91c05-547a-4091-9130-3c2e614b5126)




