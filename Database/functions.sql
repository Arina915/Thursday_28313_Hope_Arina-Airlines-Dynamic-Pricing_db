-- function 1: check flihgt profitability
create or replace FUNCTION calculate_flight_profitability(
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

-- function 2:calculate optimal price

create or replace FUNCTION calculate_optimal_price(
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

-- function 3:predict no show
create or replace FUNCTION predict_noshows(
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

-- function 4:validate booking eligibilty
create or replace FUNCTION validate_booking_eligibility(
    p_customer_id IN NUMBER,
    p_flight_id IN VARCHAR2,
    p_fare_class IN VARCHAR2
) RETURN VARCHAR2
IS
BEGIN
    -- Check 1: Customer exists
    DECLARE
        v_customer_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_customer_count
        FROM customers
        WHERE customer_id = p_customer_id;

        IF v_customer_count = 0 THEN
            RETURN 'CUSTOMER_NOT_FOUND';
        END IF;
    END;

    -- Check 2: Flight exists  
    DECLARE
        v_flight_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_flight_count
        FROM flight_schedule
        WHERE flight_id = p_flight_id;

        IF v_flight_count = 0 THEN
            RETURN 'FLIGHT_NOT_FOUND';
        END IF;
    END;

    -- Check 3: Valid fare class (using your fare classes)
    IF p_fare_class NOT IN ('F', 'J', 'Y', 'K', 'L', 'E') THEN
        RETURN 'INVALID_FARE_CLASS';
    END IF;

    -- If all checks pass
    RETURN 'ELIGIBLE';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END;

-- function 5: check week holiday

create or replace FUNCTION check_weekday_holiday 
RETURN VARCHAR2
IS
    v_day_of_week VARCHAR2(20);
    v_is_holiday CHAR(1);
BEGIN
    -- Get day of week (MON, TUE, WED, THU, FRI, SAT, SUN)
    v_day_of_week := TO_CHAR(SYSDATE, 'DY');

    -- Check if today is a holiday
    BEGIN
        SELECT 'Y' INTO v_is_holiday
        FROM airline_holidays
        WHERE holiday_date = TRUNC(SYSDATE)
          AND is_public_holiday = 'Y';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_is_holiday := 'N';
    END;

    -- Return result
    IF v_is_holiday = 'Y' THEN
        RETURN 'DENIED:HOLIDAY';
    ELSIF v_day_of_week IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RETURN 'DENIED:WEEKDAY';
    ELSE
        RETURN 'ALLOWED:WEEKEND';
    END IF;
END;

