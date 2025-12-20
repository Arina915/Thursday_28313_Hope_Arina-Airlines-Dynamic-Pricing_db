-- procedure 1: update loyalty points
create or replace PROCEDURE update_loyalty_points(
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

--Procedure 2 process no show prediction

create or replace PROCEDURE process_no_show_prediction(
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

--procedure 3: delete cancelled bookings

create or replace PROCEDURE DELETE_CANCELLED_BOOKINGS(
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

--- procedure 4: cancel bookings with refund
create or replace PROCEDURE cancel_booking_with_refund(
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

--procedure 5: check overbooking status
create or replace PROCEDURE check_overbooking_status(
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
