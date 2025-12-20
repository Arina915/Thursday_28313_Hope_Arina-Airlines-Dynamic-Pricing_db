```
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
