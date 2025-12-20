--Explicit cursors for multi-row processing
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

-- 2: Bulk operations for optimization

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
