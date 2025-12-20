-- 1 block weekady insert
create or replace TRIGGER trg_block_weekday_insert
BEFORE INSERT ON bookings
FOR EACH ROW
DECLARE
    v_day VARCHAR2(3);
BEGIN
    v_day := TO_CHAR(SYSDATE, 'DY');

    -- Block INSERT on Monday-Friday
    IF v_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'INSERT not allowed on ' || v_day || '. Only weekend bookings allowed.');
    END IF;
END;

--2 :bookind audit
create or replace TRIGGER trg_bookings_audit
FOR UPDATE ON bookings
COMPOUND TRIGGER

    TYPE audit_t IS TABLE OF flight_audit_log%ROWTYPE;
    audit_data audit_t := audit_t();

    BEFORE EACH ROW IS
    BEGIN
        audit_data.EXTEND;
        audit_data(audit_data.LAST).flight_id := :NEW.flight_id;
        audit_data(audit_data.LAST).old_status := :OLD.booking_status;
        audit_data(audit_data.LAST).new_status := :NEW.booking_status;
        audit_data(audit_data.LAST).changed_by := USER;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FORALL i IN 1..audit_data.COUNT
            INSERT INTO flight_audit_log 
            (flight_id, old_status, new_status, changed_by)
            VALUES 
            (audit_data(i).flight_id, audit_data(i).old_status, 
             audit_data(i).new_status, audit_data(i).changed_by);
    END AFTER STATEMENT;

END trg_bookings_audit;

-- 3:bookings dml restriction
create or replace TRIGGER trg_bookings_dml_restriction
BEFORE INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW
DECLARE
    v_is_holiday CHAR(1);
    v_weekday CHAR(1);
    v_operation VARCHAR2(10);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
    ELSE
        v_operation := 'DELETE';
    END IF;

    -- Check if today is a weekday
    v_weekday := CASE 
        WHEN TO_CHAR(SYSDATE, 'DY') IN ('MON','TUE','WED','THU','FRI') THEN 'Y'
        ELSE 'N'
    END;

    -- Check if today is a holiday
    BEGIN
        SELECT 'Y' INTO v_is_holiday
        FROM holidays
        WHERE holiday_date = TRUNC(SYSDATE)
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_is_holiday := 'N';
    END;

    -- Restrict DML on weekends or holidays
    IF v_weekday = 'N' OR v_is_holiday = 'Y' THEN
        RAISE_APPLICATION_ERROR(-20001, 
            v_operation || ' operation not allowed on ' ||
            CASE 
                WHEN v_weekday = 'N' THEN 'weekends'
                ELSE 'holidays'
            END || '. Today: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY'));
    END IF;
END;

--4:flight audit 
create or replace TRIGGER trg_flight_audit_simple
FOR INSERT OR UPDATE OR DELETE ON bookings
COMPOUND TRIGGER

    TYPE audit_rec IS RECORD (
        flight_id VARCHAR2(10),
        old_status VARCHAR2(20),
        new_status VARCHAR2(20),
        changed_by VARCHAR2(30),
        change_time TIMESTAMP
    );

    TYPE audit_table IS TABLE OF audit_rec;
    audit_data audit_table := audit_table();

    -- Before each row
    BEFORE EACH ROW IS
    BEGIN
        audit_data.EXTEND;
        audit_data(audit_data.LAST) := audit_rec(
            :NEW.flight_id,
            :OLD.booking_status,
            :NEW.booking_status,
            USER,
            SYSTIMESTAMP
        );
    END BEFORE EACH ROW;

    -- After statement
    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1..audit_data.COUNT LOOP
            INSERT INTO flight_audit_log (
                flight_id, old_status, new_status, 
                changed_by, change_time
            ) VALUES (
                audit_data(i).flight_id,
                audit_data(i).old_status,
                audit_data(i).new_status,
                audit_data(i).changed_by,
                audit_data(i).change_time
            );
        END LOOP;
    END AFTER STATEMENT;

END trg_flight_audit_simple;

-- 5:no insert weekdays
create or replace TRIGGER trg_no_insert_weekdays
BEFORE INSERT ON bookings
BEGIN
    -- Just check if today is Monday-Friday
    IF TO_CHAR(SYSDATE, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        -- Simple error message
        RAISE_APPLICATION_ERROR(-20001, 
            'Cannot insert bookings on weekdays. Today is ' || 
            TO_CHAR(SYSDATE, 'Day') || '.');
    END IF;
END;
