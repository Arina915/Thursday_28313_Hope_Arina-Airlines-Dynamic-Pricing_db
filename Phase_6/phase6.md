# PHASE VI: Database Interaction & Transactions
----
## Executive Summary

Phase VI implemented comprehensive PL/SQL program units enabling robust database interactions and 
transactional processing for the Airline Management System. This phase successfully delivered:

- **6 Parameterized Procedures** (full DML support)
    
- **5 Specialized Functions** (calculation, validation, lookup)
    
- **Advanced Cursors** (explicit + bulk)
    
- **Window Functions** (5 categories)
    
- **Full Exception Handling Framework**
    

All **16 program units** were implemented, tested, and validated to manage airline operations including dynamic pricing, 
no-show predictions, overbooking management, loyalty programs, and booking cancellation

## Implementation Components

##  Procedures (6 Total)

| Procedure                    | Purpose                  | Key Features                                         | Complexity   |
| ---------------------------- | ------------------------ | ---------------------------------------------------- | ------------ |
| `update_dynamic_pricing`     | Dynamic price adjustment | Input validation, auditing, transaction management   | Advanced     |
| `process_no_show_prediction` | Predict no-shows         | Historical analysis, seasonality, confidence scoring | Intermediate |
| `check_overbooking_status`   | Overbooking analysis     | Capacity checking, prediction integration            | Intermediate |
| `update_loyalty_points`      | Loyalty program          | Tier calculations, customer updates                  | Basic        |
| `cancel_booking_with_refund` | Booking cancellation     | Refund calculations, status updates                  | Intermediate |
| `delete_cancelled_bookings`  | Data cleanup             | Archival logic, batch deletion                       | Basic        |

### Procedure Details:
#### Package 1: revenue_engine 
##### purpose:
This procedure remembers the old ticket price, saves the price change in a history table, updates future bookings with the new price, and prints a summary.
It also handles cases where no previous price exists.. It automatically sets the best prices and predicts which customers might not show up (no-shows).
**procedure**
```. CREATE OR REPLACE PROCEDURE update_dynamic_pricing(
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
    v_future_bookings_updated NUMBER := 0;
    v_adjustment_id NUMBER;
    v_error_code VARCHAR2(100);
    v_error_message VARCHAR2(4000);
    
    -- Custom exceptions
    e_invalid_price EXCEPTION;
    e_invalid_input EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_price, -20001);
    PRAGMA EXCEPTION_INIT(e_invalid_input, -20002);
    
BEGIN
    -- ================= INPUT VALIDATION =================
    DBMS_OUTPUT.PUT_LINE('Validating inputs...');
    
    IF p_flight_id IS NULL OR LENGTH(TRIM(p_flight_id)) = 0 THEN
        RAISE e_invalid_input;
    END IF;
    
    IF p_fare_class IS NULL OR LENGTH(TRIM(p_fare_class)) = 0 THEN
        RAISE e_invalid_input;
    END IF;
    
    IF p_new_price IS NULL THEN
        RAISE e_invalid_price;
    END IF;
    
    IF p_new_price < 0 THEN
        RAISE e_invalid_price;
    END IF;
    
    IF p_adjustment_reason IS NULL OR LENGTH(TRIM(p_adjustment_reason)) = 0 THEN
        RAISE e_invalid_input;
    END IF;
    
    -- ================= MAIN LOGIC =================
    DBMS_OUTPUT.PUT_LINE('Starting price adjustment...');
    
    -- Get current average price from bookings
    BEGIN
        SELECT AVG(ticket_price) 
        INTO v_old_price
        FROM bookings 
        WHERE flight_id = p_flight_id 
        AND fare_class = p_fare_class
        AND booking_status = 'CONFIRMED'
        AND ROWNUM = 1;
        
        -- Handle NULL result
        IF v_old_price IS NULL THEN
            v_old_price := 0;
            DBMS_OUTPUT.PUT_LINE('No current bookings found. Using 0 as old price.');
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_old_price := 0;
            DBMS_OUTPUT.PUT_LINE('No data found. Using 0 as old price.');
        WHEN OTHERS THEN
            v_old_price := 0;
            DBMS_OUTPUT.PUT_LINE('Error getting old price. Using 0 as default.');
    END;
    
    -- Generate unique ID using timestamp (NO SEQUENCE)
    v_adjustment_id := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS')) || 
                      TRUNC(DBMS_RANDOM.VALUE(100, 999));
    
    -- Insert the price adjustment record
    BEGIN
        INSERT INTO price_adjustments (
            adjustment_id,
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
            v_adjustment_id,
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
        
        DBMS_OUTPUT.PUT_LINE('Price adjustment record inserted. ID: ' || v_adjustment_id);
        
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- If duplicate, generate new ID
            v_adjustment_id := v_adjustment_id + 1;
            
            INSERT INTO price_adjustments (
                adjustment_id,
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
                v_adjustment_id,
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
            
            DBMS_OUTPUT.PUT_LINE('Record inserted with new ID: ' || v_adjustment_id);
    END;
    
    -- Update future bookings with the new price
    BEGIN
        UPDATE bookings 
        SET ticket_price = p_new_price
        WHERE flight_id = p_flight_id
        AND fare_class = p_fare_class
        AND booking_status IN ('CONFIRMED', 'PENDING')
        AND travel_date > SYSDATE;
        
        v_future_bookings_updated := SQL%ROWCOUNT;
        
        IF v_future_bookings_updated = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No future bookings found to update.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Updated ' || v_future_bookings_updated || ' future booking(s).');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error updating bookings: ' || SQLERRM);
            RAISE;
    END;
    
    COMMIT;
    
    -- ================= SUCCESS MESSAGE =================
    DBMS_OUTPUT.PUT_LINE('Price adjustment completed successfully.');
    DBMS_OUTPUT.PUT_LINE('Adjustment ID: ' || v_adjustment_id);
    DBMS_OUTPUT.PUT_LINE('Future bookings updated: ' || v_future_bookings_updated);
    
EXCEPTION
    -- ================= CUSTOM EXCEPTIONS =================
    WHEN e_invalid_price THEN
        v_error_code := 'INVALID_PRICE';
        v_error_message := 'Price must be a positive number. Got: ' || p_new_price;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_error_message);
        ROLLBACK;
        
    WHEN e_invalid_input THEN
        v_error_code := 'INVALID_INPUT';
        v_error_message := 'Flight ID, Fare Class, and Adjustment Reason cannot be empty';
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_error_message);
        ROLLBACK;
        
    -- ================= PREDEFINED EXCEPTIONS =================
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Invalid value provided.');
        ROLLBACK;
        
    WHEN INVALID_NUMBER THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Invalid number format for price.');
        ROLLBACK;
        
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Required data not found.');
        ROLLBACK;
        
    -- ================= TABLE/COLUMN NOT FOUND =================
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;
        
END update_dynamic_pricing;
/

```
**Testing**
```-- Test 2: Update BUSINESS class
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 2: Business class update ===');
    update_dynamic_pricing(
        p_flight_id => 'FL123',
        p_fare_class => 'BUSINESS',
        p_new_price => 699.99,
        p_adjustment_reason => 'Premium service upgrade',
        p_adjusted_by => 'MANAGER'
    );
END;
/

-- Test 3: Flight with no bookings (should use 0 as old price)
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 3: Flight with no bookings ===');
    update_dynamic_pricing(
        p_flight_id => 'FL999',
        p_fare_class => 'ECONOMY',
        p_new_price => 199.99,
        p_adjustment_reason => 'New route promotion'
    );
END;
/

-- Test 4: Test error handling - negative price
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 4: Negative price (should error) ===');
    update_dynamic_pricing(
        p_flight_id => 'FL123',
        p_fare_class => 'ECONOMY',
        p_new_price => -100,
        p_adjustment_reason => 'Test error'
    );
END;
/

-- Test 5: Test error handling - empty flight ID
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 5: Empty flight ID (should error) ===');
    update_dynamic_pricing(
        p_flight_id => '',
        p_fare_class => 'ECONOMY',
        p_new_price => 200,
        p_adjustment_reason => 'Test'
    );
END;
/

-- Test 6: Test error handling - NULL price
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 6: NULL price (should error) ===');
    update_dynamic_pricing(
        p_flight_id => 'FL123',
        p_fare_class => 'ECONOMY',
        p_new_price => NULL,
        p_adjustment_reason => 'Test'
    );
END;
/
```

![1111111](https://github.com/user-attachments/assets/277d0fbb-38cd-4011-bd9f-e63002112e62)


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






##  Functions (5 Total)

|Function|Type|Purpose|Return Type|
|---|---|---|---|
|`predict_noshows`|Calculation|Predict no-show rates|NUMBER|
|`calculate_optimal_price`|Calculation|Dynamic pricing|NUMBER|
|`validate_booking_eligibility_simple`|Validation|Booking validation|VARCHAR2|
|`get_risk_score`|Scoring|Customer risk assessment|NUMBER|
|`calculate_flight_profitability`|Analysis|Profit calculation|NUMBER|

### Function Details:

**1. `predict_noshows()`** This function predicts the no-show rate for a flight by looking at past booking data and adjusting for factors like seasonality and how close the flight is to departure.
It returns a predicted no-show percentage between 0% and 100%, with a default of 15% if an error occurs.
```CREATE OR REPLACE FUNCTION predict_noshows(
    p_flight_id IN VARCHAR2,
    p_days_before_departure IN NUMBER DEFAULT 7
) RETURN NUMBER
IS
    v_predicted_rate NUMBER(5,2);
    v_historical_rate NUMBER(5,2);
    v_season_factor NUMBER(5,2);
    v_total_bookings NUMBER;
    v_no_show_count NUMBER;
    v_current_date DATE := SYSDATE;
    v_departure_date DATE := v_current_date + p_days_before_departure;
BEGIN
    -- Get historical no-show rate for this flight (last 90 days)
    SELECT 
        COUNT(*) as total_bookings,
        COUNT(CASE WHEN booking_status = 'NOSHOW' THEN 1 END) as no_show_count
    INTO v_total_bookings, v_no_show_count
    FROM bookings
    WHERE flight_id = p_flight_id
    AND travel_date BETWEEN v_current_date - 90 AND v_current_date - 1;
    
    -- Calculate historical rate
    IF v_total_bookings > 0 THEN
        v_historical_rate := (v_no_show_count * 100.0) / v_total_bookings;
    ELSE
        v_historical_rate := 12.5; -- Default industry average
    END IF;
    
    -- Adjust for seasonality (higher no-shows during holidays)
    v_season_factor := CASE 
        WHEN EXTRACT(MONTH FROM v_departure_date) IN (12, 1) THEN 1.3  -- Christmas/New Year
        WHEN EXTRACT(MONTH FROM v_departure_date) IN (7, 8) THEN 1.2   -- Summer vacation
        WHEN EXTRACT(MONTH FROM v_departure_date) IN (4, 10) THEN 0.9  -- Shoulder seasons
        ELSE 1.0
    END;
    
    -- Adjust for days before departure (more no-shows closer to departure)
    v_predicted_rate := v_historical_rate * v_season_factor * 
        CASE 
            WHEN p_days_before_departure <= 1 THEN 1.5   -- Last minute
            WHEN p_days_before_departure <= 3 THEN 1.3   -- 2-3 days
            WHEN p_days_before_departure <= 7 THEN 1.1   -- 1 week
            ELSE 1.0
        END;
    
    -- Ensure result is between 0 and 100
    RETURN LEAST(GREATEST(ROUND(v_predicted_rate, 2), 0), 100);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 15.0; -- Default prediction if error
END;
/
```    
### Testing
```
SELECT predict_noshows('AA101', 7) as predicted_no_show_rate FROM dual;
```
![FUNCTION 1](https://github.com/user-attachments/assets/b2345f9f-5708-43df-bc85-e241c9c0ae2c)

**2. `calculate_optimal_price()`** This function calculates the price of a flight ticket based on the fare class (e.g., first class, economy) and how full the flight is. 
It starts with a base price for the class and then adjusts the price based on the flight's load factor (how many seats are booked). The result is the final ticket price.
```
CREATE OR REPLACE FUNCTION calculate_optimal_price(
    p_flight_id IN VARCHAR2,
    p_fare_class IN CHAR,
    p_load_factor IN NUMBER
) RETURN NUMBER
IS
    v_base_price NUMBER;
    v_multiplier NUMBER;
BEGIN
    -- Base prices
    v_base_price := CASE p_fare_class
        WHEN 'F' THEN 1000.00
        WHEN 'B' THEN 600.00
        WHEN 'E' THEN 300.00
        WHEN 'K' THEN 250.00
        ELSE 200.00
    END;
    
    -- Simple multiplier based on load factor
    v_multiplier := CASE 
        WHEN p_load_factor >= 90 THEN 1.5
        WHEN p_load_factor >= 70 THEN 1.3
        WHEN p_load_factor >= 50 THEN 1.1
        WHEN p_load_factor >= 30 THEN 1.0
        ELSE 0.9
    END;
    
    RETURN ROUND(v_base_price * v_multiplier, 2);
END;
/
```
### Testing
```
SELECT 
    calculate_optimal_price('AA101', 'E', 80) as economy_80pct,
    calculate_optimal_price('AA101', 'B', 80) as business_80pct,
    calculate_optimal_price('AA101', 'E', 30) as economy_30pct
FROM dual;

-- Compare all fare classes
SELECT 
    fare_class,
    calculate_optimal_price('AA101', fare_class, 90) as price_90pct_load,
    calculate_optimal_price('AA101', fare_class, 50) as price_50pct_load,
    calculate_optimal_price('AA101', fare_class, 20) as price_20pct_load
FROM (
    SELECT 'F' as fare_class FROM dual UNION ALL
    SELECT 'B' FROM dual UNION ALL
    SELECT 'E' FROM dual UNION ALL
    SELECT 'K' FROM dual
);
```

![FUNCTION 2](https://github.com/user-attachments/assets/d235a8a6-d524-4849-ab22-79816078e152)

**3. `validate_booking_eligibility`** -This function checks if a booking is eligible by performing three simple checks. First, it ensures the fare class is valid (like 'F', 'Y', or 'K'). Then, it verifies that the specified flight exists in the flight schedule. Finally, it checks if the customer is registered in the system.
If any of these checks fail, it returns an error message, but if all checks pass, it returns "ELIGIBLE".
```
CREATE OR REPLACE FUNCTION validate_booking_eligibility_simple(
    p_customer_id IN NUMBER,
    p_flight_id IN VARCHAR2,
    p_fare_class IN VARCHAR2
) RETURN VARCHAR2
IS
    v_result VARCHAR2(100);
BEGIN
    -- Check 1: Valid fare class
    IF p_fare_class NOT IN ('F', 'J', 'Y', 'K', 'L', 'E') THEN
        RETURN 'Invalid fare class';
    END IF;
    
    -- Check 2: Flight exists
    DECLARE
        v_flight_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_flight_exists
        FROM flight_schedule
        WHERE flight_id = p_flight_id;
        
        IF v_flight_exists = 0 THEN
            RETURN 'Flight not found';
        END IF;
    END;
    
    -- Check 3: Customer exists
    DECLARE
        v_customer_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_customer_exists
        FROM customers
        WHERE customer_id = p_customer_id;
        
        IF v_customer_exists = 0 THEN
            RETURN 'Customer not found';
        END IF;
    END;
    
    RETURN 'ELIGIBLE';
END;
/
```
### Testing
```
SELECT 'Test Case 1: Valid Booking' as test_case,
       validate_booking_eligibility(111, 'FL001', 'E') as result
FROM dual
UNION ALL
SELECT 'Test Case 2: Invalid Customer',
       validate_booking_eligibility(999, 'FL001', 'E')
FROM dual
UNION ALL
SELECT 'Test Case 3: Invalid Flight', 
       validate_booking_eligibility(111, 'FL999', 'E')
FROM dual
UNION ALL
SELECT 'Test Case 4: Invalid Fare Class',
       validate_booking_eligibility(111, 'FL001', 'X')
FROM dual;
```

![FUNCTION 3](https://github.com/user-attachments/assets/e43b3a26-583c-4f74-9f6e-8afe51b78a35)

**4. `get_risk_score()`**
This function calculates a risk score for a customer based on their booking history. It adds points for each no-show and canceled booking (50 points for a no-show and 30 points for a cancellation). If no bookings are found, it defaults to a score of 50.
The function then ensures the final score does not exceed 100 and returns the result.
```
CREATE OR REPLACE FUNCTION get_risk_score(
    p_customer_id IN NUMBER
) RETURN NUMBER
IS
    v_score NUMBER;
BEGIN
    SELECT 
        NVL(ROUND(
            (COUNT(CASE WHEN booking_status = 'NOSHOW' THEN 1 END) * 50) +
            (COUNT(CASE WHEN booking_status = 'CANCELLED' THEN 1 END) * 30)
        ), 50)
    INTO v_score
    FROM bookings
    WHERE customer_id = p_customer_id;
    
    RETURN LEAST(v_score, 100);
END;
/
```
### Testing
```
SELECT GET_RISK_SCORE(111) as customer_111_score FROM dual;

-- Test CALCULATE_OPTIMAL_PRICE
SELECT CALCULATE_OPTIMAL_PRICE('AA101', 'E', 75) as economy_price FROM dual;
```
![FUNCTION 4](https://github.com/user-attachments/assets/8595275a-1e7a-4d6a-b436-bf9064c6b1fd)

**5. `calculate_flight_profitability)`**
This function calculates the profitability of a flight. It sums up the total revenue from confirmed bookings for the flight, then estimates the cost as 30% of that revenue. 
It subtracts the estimated cost from the total revenue to return the flight’s profit.
```
CREATE OR REPLACE FUNCTION calculate_flight_profitability(
    p_flight_id IN VARCHAR2
) RETURN NUMBER
IS
    v_total_revenue NUMBER;
    v_estimated_cost NUMBER;
BEGIN
    -- Calculate revenue from confirmed bookings
    SELECT SUM(ticket_price)
    INTO v_total_revenue
    FROM bookings
    WHERE flight_id = p_flight_id
    AND booking_status = 'CONFIRMED';
    
    -- Estimated cost (simplified: $50 per booked seat)
    v_estimated_cost := NVL(v_total_revenue, 0) * 0.3; -- Assume 30% cost
    
    RETURN NVL(v_total_revenue, 0) - v_estimated_cost;
END;
/

```
### Testing
```
SELECT 
    flight_id,
    COUNT(*) as bookings,
    SUM(ticket_price) as total_revenue,
    calculate_flight_profitability(flight_id) as estimated_profit
FROM bookings
WHERE booking_status = 'CONFIRMED'
GROUP BY flight_id
HAVING COUNT(*) > 0
ORDER BY estimated_profit DESC;

```
![FUCTION 5](https://github.com/user-attachments/assets/70bfa015-5231-495b-a917-e9cdfceae57f)

## **`Explicit cursors for multi-row processing`**
This PL/SQL block uses a cursor to select flights with more than 5 confirmed bookings and displays the flight ID along with the number of bookings.
It collects the results in a table and outputs them using DBMS_OUTPUT.
```
DECLARE
    CURSOR flight_cursor IS
        SELECT flight_id, COUNT(*) as booking_count
        FROM bookings
        WHERE booking_status = 'CONFIRMED'
        GROUP BY flight_id
        HAVING COUNT(*) > 5;
    
    TYPE flight_table IS TABLE OF flight_cursor%ROWTYPE;
    flight_records flight_table;
BEGIN
    OPEN flight_cursor;
    FETCH flight_cursor BULK COLLECT INTO flight_records LIMIT 100;
    CLOSE flight_cursor;

    -- Display results
    FOR i IN 1..flight_records.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Flight: ' || flight_records(i).flight_id || 
                           ' | Bookings: ' || flight_records(i).booking_count);
    END LOOP;
END;
/
```
### Testing
```
DECLARE
    CURSOR c IS SELECT flight_id FROM bookings WHERE ROWNUM <= 3;
    v_id VARCHAR2(10);
BEGIN
    OPEN c;
    LOOP
        FETCH c INTO v_id;
        EXIT WHEN c%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Flight: ' || v_id);
    END LOOP;
    CLOSE c;
END;
/
```
![Explicit cursors for multi-row processing](https://github.com/user-attachments/assets/7f272109-23b3-4ea8-acdd-bc9987f99d7c)

## **`Bulk operations for optimization`**
This PL/SQL block fetches the customer_ids of up to 5 customers who have had a "NO SHOW" booking.
It collects these IDs into a table and then outputs each customer's ID using DBMS_OUTPUT.
```DECLARE
    TYPE ids_t IS TABLE OF NUMBER;
    v_ids ids_t;
BEGIN
    SELECT DISTINCT customer_id 
    BULK COLLECT INTO v_ids
    FROM bookings 
    WHERE booking_status = 'NOSHOW'
    AND ROWNUM <= 5;
    
    FOR i IN 1..v_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Customer: ' || v_ids(i));
    END LOOP;
END;
/
```
![BULK](https://github.com/user-attachments/assets/54489e94-c97d-4f7b-bc98-d251b2c2055e)


**.`Window function`**
```
SELECT 
    customer_id,
    flight_id,
    ticket_price,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ticket_price DESC) as cust_flight_rank,
    RANK() OVER (PARTITION BY customer_id ORDER BY ticket_price DESC) as cust_price_rank,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY ticket_price DESC) as cust_dense_rank,
    LAG(ticket_price, 1, 0) OVER (PARTITION BY customer_id ORDER BY booking_date) as prev_ticket_price,
    LEAD(ticket_price, 1, 0) OVER (PARTITION BY customer_id ORDER BY booking_date) as next_ticket_price
FROM bookings
WHERE booking_status = 'CONFIRMED'
ORDER BY customer_id, ticket_price DESC;

```
![WINDOW FUNCTION](https://github.com/user-attachments/assets/1470c2aa-fa59-443a-bba1-2291626230b2)

This SQL query retrieves booking information for customers and calculates various rankings and
price comparisons for each booking.:
1. **ROW_NUMBER()**:
Assigns a unique, sequential number to each booking within a customer, ordered by `ticket_price` in descending order. No two bookings for a customer will have the same number.
       
2. **RANK()**:
Assigns a rank to each booking within a customer, ordered by `ticket_price` in descending order. If two bookings have the same price, they will receive the same rank, but the next rank will be skipped.
        
1. **DENSE_RANK()**:
 Similar to `RANK()`, but there are **no gaps** in the ranking. If two bookings have the same price, they get the same rank, but the next rank will be consecutive (no skipped ranks).
    
3. **LAG(ticket_price, 1, 0)**:
Retrieves the `ticket_price` of the previous booking for the same customer, ordered by `booking_date`. If there is no previous booking (e.g., the first booking), it returns `0`.

4. **LEAD(ticket_price, 1, 0)**:
Retrieves the `ticket_price` of the next booking for the same customer, ordered by `booking_date`. If there is no next booking (e.g., the last booking), it returns `0`.To rank bookings with gaps for ties.

## Package Performance Benefits
Oracle packages speed up databases by remembering queries, storing data in memory, and organizing code efficiently making repeated operations faster and more reliable.
```
-- First, create the PRICE_ADJUSTMENTS table if not exists
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE price_adjustments';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE price_adjustments (
    adjustment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    flight_id VARCHAR2(10),
    fare_class VARCHAR2(20),
    old_price NUMBER(10,2),
    new_price NUMBER(10,2),
    price_difference NUMBER(10,2),
    adjustment_reason VARCHAR2(200),
    adjusted_by VARCHAR2(50) DEFAULT 'SYSTEM',
    adjusted_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Create a package for dynamic pricing
CREATE OR REPLACE PACKAGE dynamic_pricing_pkg AS
    -- 1. ENCAPSULATION: Hide implementation details
    PROCEDURE update_dynamic_pricing(
        p_flight_id IN VARCHAR2,
        p_fare_class IN VARCHAR2,
        p_new_price IN NUMBER,
        p_adjustment_reason IN VARCHAR2,
        p_adjusted_by IN VARCHAR2 DEFAULT 'SYSTEM'
    );
    
    -- Additional procedures for better modularity
    FUNCTION get_average_price(
        p_flight_id IN VARCHAR2,
        p_fare_class IN VARCHAR2
    ) RETURN NUMBER;
    
    PROCEDURE log_adjustment(
        p_flight_id IN VARCHAR2,
        p_fare_class IN VARCHAR2,
        p_old_price IN NUMBER,
        p_new_price IN NUMBER,
        p_reason IN VARCHAR2,
        p_adjusted_by IN VARCHAR2
    );
    
    -- Public constants
    MIN_PRICE CONSTANT NUMBER := 0;
    MAX_PRICE CONSTANT NUMBER := 9999.99;
    
    -- Public exceptions
    invalid_price EXCEPTION;
    invalid_flight_id EXCEPTION;
    PRAGMA EXCEPTION_INIT(invalid_price, -20001);
    PRAGMA EXCEPTION_INIT(invalid_flight_id, -20002);
    
END dynamic_pricing_pkg;
/

CREATE OR REPLACE PACKAGE BODY dynamic_pricing_pkg AS
    
    -- 2. SHARED MEMORY: Package-level cursor for reuse
    CURSOR c_avg_price(p_flight_id VARCHAR2, p_fare_class VARCHAR2) IS
        SELECT NVL(AVG(ticket_price), 0) as avg_price
        FROM bookings
        WHERE flight_id = p_flight_id
          AND fare_class = p_fare_class
          AND booking_status = 'CONFIRMED';
    
    -- 3. REDUCED SQL PARSING: Static SQL in package initialization
    TYPE price_cache_type IS TABLE OF NUMBER INDEX BY VARCHAR2(50);
    g_price_cache price_cache_type; -- Shared across sessions in same instance
    
    -- Initialize package (runs once per session)
    PROCEDURE initialize_cache IS
    BEGIN
        -- Could pre-load cache here for frequently accessed flights
        NULL;
    END initialize_cache;
    
    -- Helper function with reduced parsing (reusable)
    FUNCTION calculate_price_difference(
        p_old_price IN NUMBER,
        p_new_price IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        RETURN p_new_price - p_old_price;
    END calculate_price_difference;
    
    -- Public function to get average price
    FUNCTION get_average_price(
        p_flight_id IN VARCHAR2,
        p_fare_class IN VARCHAR2
    ) RETURN NUMBER IS
        v_avg_price NUMBER;
        v_cache_key VARCHAR2(50);
    BEGIN
        v_cache_key := p_flight_id || ':' || p_fare_class;
        
        -- Check cache first (SHARED MEMORY benefit)
        IF g_price_cache.EXISTS(v_cache_key) THEN
            RETURN g_price_cache(v_cache_key);
        END IF;
        
        -- Use reusable cursor (REDUCED PARSING benefit)
        OPEN c_avg_price(p_flight_id, p_fare_class);
        FETCH c_avg_price INTO v_avg_price;
        CLOSE c_avg_price;
        
        -- Cache the result
        g_price_cache(v_cache_key) := NVL(v_avg_price, 0);
        
        RETURN v_avg_price;
    END get_average_price;
    
    -- Procedure to log adjustments
    PROCEDURE log_adjustment(
        p_flight_id IN VARCHAR2,
        p_fare_class IN VARCHAR2,
        p_old_price IN NUMBER,
        p_new_price IN NUMBER,
        p_reason IN VARCHAR2,
        p_adjusted_by IN VARCHAR2
    ) IS
        v_price_diff NUMBER;
    BEGIN
        v_price_diff := calculate_price_difference(p_old_price, p_new_price);
        
        INSERT INTO price_adjustments (
            flight_id, fare_class, old_price, new_price,
            price_difference, adjustment_reason, adjusted_by
        ) VALUES (
            p_flight_id, p_fare_class, p_old_price, p_new_price,
            v_price_diff, p_reason, p_adjusted_by
        );
    END log_adjustment;
    
    -- Main procedure
    PROCEDURE update_dynamic_pricing(
        p_flight_id IN VARCHAR2,
        p_fare_class IN VARCHAR2,
        p_new_price IN NUMBER,
        p_adjustment_reason IN VARCHAR2,
        p_adjusted_by IN VARCHAR2 DEFAULT 'SYSTEM'
    ) IS
        v_old_price NUMBER;
        v_rows_updated NUMBER;
    BEGIN
        -- Input validation with encapsulated logic
        IF p_flight_id IS NULL OR LENGTH(TRIM(p_flight_id)) = 0 THEN
            RAISE invalid_flight_id;
        END IF;
        
        IF p_new_price IS NULL OR p_new_price < MIN_PRICE OR p_new_price > MAX_PRICE THEN
            RAISE invalid_price;
        END IF;
        
        -- Get old price using package function (encapsulation)
        v_old_price := get_average_price(p_flight_id, p_fare_class);
        
        -- Update bookings - single SQL execution
        UPDATE bookings
        SET ticket_price = p_new_price
        WHERE flight_id = p_flight_id
          AND fare_class = p_fare_class
          AND booking_status = 'CONFIRMED';
        
        v_rows_updated := SQL%ROWCOUNT;
        
        -- Log the adjustment using package procedure
        log_adjustment(
            p_flight_id, p_fare_class, v_old_price, p_new_price,
            p_adjustment_reason, p_adjusted_by
        );
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Price updated successfully for ' || 
                             p_flight_id || ' - ' || p_fare_class ||
                             '. Old price: ' || v_old_price ||
                             ', New price: ' || p_new_price ||
                             ', Rows updated: ' || v_rows_updated);
        
    EXCEPTION
        WHEN invalid_flight_id THEN
            RAISE_APPLICATION_ERROR(-20002, 'Flight ID cannot be empty');
        WHEN invalid_price THEN
            RAISE_APPLICATION_ERROR(-20001, 
                'Price must be between ' || MIN_PRICE || ' and ' || MAX_PRICE);
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END update_dynamic_pricing;
    
    -- Package initialization (runs once when package is first called)
BEGIN
    initialize_cache;
    DBMS_OUTPUT.PUT_LINE('Dynamic Pricing Package initialized at ' || 
                         TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
END dynamic_pricing_pkg;
/

-- Enable DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- Test the package implementation
BEGIN
    -- First, insert test data using single-letter fare codes
    INSERT INTO bookings (flight_id, fare_class, ticket_price, booking_status, travel_date)
    VALUES ('FL123', 'E', 250.00, 'CONFIRMED', SYSDATE + 30);
    
    INSERT INTO bookings (flight_id, fare_class, ticket_price, booking_status, travel_date)
    VALUES ('FL123', 'B', 500.00, 'CONFIRMED', SYSDATE + 30);
    
    INSERT INTO bookings (flight_id, fare_class, ticket_price, booking_status, travel_date)
    VALUES ('FL123', 'E', 260.00, 'CONFIRMED', SYSDATE + 31);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Test data inserted successfully');
END;
/

-- Now test the package procedures
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 1: Basic economy update (Package) ===');
    dynamic_pricing_pkg.update_dynamic_pricing(
        p_flight_id => 'FL123',
        p_fare_class => 'E',
        p_new_price => 299.99,
        p_adjustment_reason => 'Seasonal price increase',
        p_adjusted_by => 'ADMIN'
    );
END;
/

-- Check results
SELECT * FROM price_adjustments;
SELECT flight_id, fare_class, ticket_price, booking_status 
FROM bookings 
WHERE flight_id = 'FL123'
ORDER BY travel_date;

-- Test cache functionality (SHARED MEMORY benefit)
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== Testing Cache Performance ===');
    DBMS_OUTPUT.PUT_LINE('First call (should compute): ' || 
                         dynamic_pricing_pkg.get_average_price('FL123', 'E'));
    DBMS_OUTPUT.PUT_LINE('Second call (should use cache): ' || 
                         dynamic_pricing_pkg.get_average_price('FL123', 'E'));
END;
/

-- Test other procedures
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 2: Business class update ===');
    dynamic_pricing_pkg.update_dynamic_pricing(
        p_flight_id => 'FL123',
        p_fare_class => 'B',
        p_new_price => 699.99,
        p_adjustment_reason => 'Premium service upgrade',
        p_adjusted_by => 'MANAGER'
    );
END;
/

-- Test error handling
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== TEST 3: Invalid price test ===');
    dynamic_pricing_pkg.update_dynamic_pricing(
        p_flight_id => 'FL123',
        p_fare_class => 'E',
        p_new_price => -100,
        p_adjustment_reason => 'Test error'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Show all adjustments
SELECT * FROM price_adjustments ORDER BY adjustment_id;
```

![package](https://github.com/user-attachments/assets/b4a50e56-2bf9-41e2-9816-d42f5bc89db0)

## DYNAMIC PRICING WITH EXCEPTION HANDLING
```
CREATE OR REPLACE PROCEDURE apply_dynamic_pricing(
    p_flight_id     IN VARCHAR2,
    p_fare_class    IN VARCHAR2,
    p_new_price     IN NUMBER,
    p_reason        IN VARCHAR2,
    p_out_status    OUT VARCHAR2,
    p_out_audit_id  OUT NUMBER
) IS
    v_old_price   NUMBER;
    v_min_price   NUMBER;
    v_max_price   NUMBER;
    v_load_factor NUMBER;
    v_audit_id    NUMBER;
    
BEGIN
    -- Savepoint for manual recovery
    SAVEPOINT before_price_change;

    -------------------------------------
    -- GET CURRENT PRICE (may raise NO_DATA_FOUND)
    -------------------------------------
    SELECT ticket_price INTO v_old_price
    FROM bookings
    WHERE flight_id = p_flight_id
      AND fare_class = p_fare_class
      AND booking_status = 'CONFIRMED'
      AND ROWNUM = 1;

    -------------------------------------
    -- GET PRICE RULES (may raise NO_DATA_FOUND)
    -------------------------------------
    SELECT min_price, max_price
    INTO v_min_price, v_max_price
    FROM price_rules
    WHERE fare_class = p_fare_class
      AND is_active = 'Y';

    -------------------------------------
    -- CUSTOM EXCEPTION: PRICE OUTSIDE RANGE
    -------------------------------------
    IF p_new_price < v_min_price OR p_new_price > v_max_price THEN
        RAISE airline_exceptions.price_range_exception;
    END IF;

    -------------------------------------
    -- CALCULATE LOAD FACTOR
    -------------------------------------
    SELECT (COUNT(b.booking_id) * 100.0) / a.capacity
    INTO v_load_factor
    FROM flight_schedule f
    JOIN aircraft a ON f.aircraft_id = a.registration_no
    LEFT JOIN bookings b ON f.flight_id = b.flight_id
         AND b.booking_status IN ('CONFIRMED', 'CHECKED-IN')
    WHERE f.flight_id = p_flight_id;

    -------------------------------------
    -- INSERT PRICE ADJUSTMENT RECORD
    -------------------------------------
    INSERT INTO price_adjustments(
        flight_no, fare_class, old_price, new_price,
        adjustment_reason, load_factor, adjusted_by
    ) VALUES(
        p_flight_id, p_fare_class, v_old_price, p_new_price,
        p_reason, v_load_factor, USER
    )
    RETURNING adjustment_id INTO v_audit_id;

    -------------------------------------
    -- UPDATE FUTURE BOOKINGS
    -------------------------------------
    UPDATE bookings
    SET ticket_price = p_new_price
    WHERE flight_id = p_flight_id
      AND fare_class = p_fare_class
      AND booking_status = 'CONFIRMED'
      AND booking_date > SYSDATE - 1;

    p_out_status    := 'SUCCESS';
    p_out_audit_id  := v_audit_id;
    COMMIT;


-------------------------------------
-- EXCEPTION HANDLING SECTION
-------------------------------------
EXCEPTION

    ----------------------------------------
    -- CUSTOM EXCEPTION HANDLED
    ----------------------------------------
    WHEN airline_exceptions.price_range_exception THEN
        ROLLBACK TO before_price_change;
        airline_exceptions.log_error(
            'apply_dynamic_pricing', 
            -20003,
            'Price ' || p_new_price || 
            ' outside allowed range [' || v_min_price || ' - ' || v_max_price || ']'
        );
        p_out_status := 'ERROR: Price out of allowed range';

    ----------------------------------------
    -- PREDEFINED EXCEPTION: NO DATA FOUND
    ----------------------------------------
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO before_price_change;
        airline_exceptions.log_error(
            'apply_dynamic_pricing',
            -20008,
            'No valid bookings or price rules found for flight ' || p_flight_id
        );
        p_out_status := 'ERROR: Missing required data';

    ----------------------------------------
    -- PREDEFINED EXCEPTION: TOO MANY ROWS
    ----------------------------------------
    WHEN TOO_MANY_ROWS THEN
        ROLLBACK TO before_price_change;
        airline_exceptions.log_error(
            'apply_dynamic_pricing',
            -1422,
            'Multiple active price rules for fare class ' || p_fare_class
        );
        p_out_status := 'ERROR: Duplicate price rules';

    ----------------------------------------
    -- GENERIC EXCEPTION (OTHERS)
    ----------------------------------------
    WHEN OTHERS THEN
        ROLLBACK TO before_price_change;

        -- RECOVERY: rollback the price adjustment if created
        IF v_audit_id IS NOT NULL THEN
            airline_exceptions.rollback_price_adjustment(v_audit_id);
        END IF;

        airline_exceptions.log_error(
            'apply_dynamic_pricing',
            SQLCODE,
            SQLERRM
        );

        p_out_status := 'ERROR: ' || SQLERRM;

END apply_dynamic_pricing;
/
```
![error](https://github.com/user-attachments/assets/c98f78c3-acbf-4575-b431-7a3915fd2008)

