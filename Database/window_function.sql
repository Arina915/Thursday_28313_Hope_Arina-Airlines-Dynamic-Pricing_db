-- This SQL query retrieves booking information for customers and calculates various rankings and price comparisons for each booking
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
