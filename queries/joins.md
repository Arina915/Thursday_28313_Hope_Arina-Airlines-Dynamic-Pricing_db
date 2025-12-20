-- JOIN
```
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
## left join
```
-- All customers with their booking history and flight info
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    c.loyalty_level,
    c.total_flights,
    -- Booking details
    b.booking_id,
    b.booking_date,
    b.travel_date,
    b.fare_class,
    b.ticket_price,
    b.booking_status,
    -- Flight details
    f.flight_no,
    f.departure_time,
    f.arrival_time,
    f.departure_airport,
    f.arrival_airport
FROM customers c
LEFT JOIN bookings b ON c.customer_id = b.customer_id
LEFT JOIN flight_schedule f ON b.flight_id = f.flight_id
ORDER BY c.customer_id, b.booking_date DESC;
```
## right join
```
-- Show all aircraft, even those not assigned to flights
SELECT 
    a.aircraft_id,
    a.aircraft_type,
    a.capacity,
    a.status,
    f.flight_id,
    f.flight_no,
    f.departure_time,
    f.arrival_time
FROM flight_schedule f
RIGHT JOIN aircraft a ON f.aircraft_id = a.aircraft_id
ORDER BY a.aircraft_id, f.departure_time;
```
## audit of user's Table Access Patterns
```
-- Which tables each user accesses
SELECT 
    user_name,
    table_name,
    COUNT(*) as operation_count,
    LISTAGG(DISTINCT operation_type, ', ') WITHIN GROUP (ORDER BY operation_type) as operations_performed
FROM dml_audit_log
GROUP BY user_name, table_name
ORDER BY user_name, operation_count DESC;
```
## Daily Audit Report 
```-- Daily summary report using correct column name
SELECT 
    TRUNC(OPERATION_TIMESTAMP) as AUDIT_DATE,
    COUNT(*) as TOTAL_OPERATIONS,
    COUNT(DISTINCT USER_NAME) as UNIQUE_USERS,
    SUM(CASE WHEN ATTEMPT_STATUS = 'DENIED' THEN 1 ELSE 0 END) as DENIED_OPERATIONS,
    SUM(CASE WHEN ATTEMPT_STATUS = 'ALLOWED' THEN 1 ELSE 0 END) as ALLOWED_OPERATIONS,
    LISTAGG(DISTINCT TABLE_NAME, ', ') WITHIN GROUP (ORDER BY TABLE_NAME) as TABLES_AFFECTED,
    AVG(AFFECTED_ROWS) as AVG_ROWS_AFFECTED
FROM DML_AUDIT_LOG
WHERE OPERATION_TIMESTAMP >= TRUNC(SYSDATE) - 30  -- Last 30 days
GROUP BY TRUNC(OPERATION_TIMESTAMP)
ORDER BY AUDIT_DATE DESC;
```
