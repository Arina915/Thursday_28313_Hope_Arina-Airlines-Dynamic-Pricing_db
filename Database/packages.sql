-- package airline exceptions
create or replace PACKAGE airline_exceptions AS
    -- Custom exception
    price_range_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(price_range_exception, -20003);

    -- Error logging
    PROCEDURE log_error(p_proc VARCHAR2, p_code NUMBER, p_msg VARCHAR2);

    -- Recovery: undo price adjustment
    PROCEDURE rollback_price_adjustment(p_adj_id NUMBER);
END airline_exceptions;


-- package dynamic pricing

create or replace PACKAGE dynamic_pricing_pkg AS
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
