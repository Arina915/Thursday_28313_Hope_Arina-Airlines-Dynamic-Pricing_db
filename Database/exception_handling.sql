--
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
