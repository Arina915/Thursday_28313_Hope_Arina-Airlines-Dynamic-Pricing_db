```
    home_airport,
    COUNT(*) as customer_count,
    AVG(loyalty_points) as avg_points
FROM customers
WHERE home_airport IS NOT NULL
GROUP BY home_airport
ORDER BY customer_count DESC;
```
