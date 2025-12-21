# PHASE I: Problem Statement

## PL/SQL Practicum Project Proposal

### Project Title: Arina Airlines Dynamic Pricing and No-Show Prediction System

### Student Name: Arinatwe Hope

### Student ID: 28313

### Course: Database Development with PL/SQL

### Area: Airline Revenue Management

---

## 1. Project Idea

The Arina Airlines Dynamic Pricing and No-Show Prediction System introduces an intelligent, automated solution using PL/SQL to revolutionize how small regional airlines manage ticket pricing and flight capacity. Instead of relying on fixed pricing or manual adjustments, the system automatically predicts passenger no-shows and adjusts ticket prices in real-time based on demand and flight occupancy.

What makes this system unique is its built-in predictive intelligence; 24 hours before each flight, smart PL/SQL functions analyze booking patterns, customer loyalty, holidays, and flight timing to forecast how many passengers won't show up. The system then automatically adjusts prices to fill empty seats, acting like a virtual revenue manager embedded directly into the airline's database.

Whether it's a busy holiday route or a regular weekday flight, the tool provides data-driven pricing decisions that maximize revenue and optimize seat occupancy. The system combines automated prediction with prescriptive pricing adjustments, helping airlines not just track bookings but actively manage revenue through intelligent automation.

---

## 2. Database Schema Overview

### Main Tables:

#### **BOOKINGS Table**

- `booking_id` (PK) - Unique identifier for each reservation
    
- `customer_id` (FK) - References CUSTOMERS table
    
- `flight_id` (FK) - References FLIGHT_SCHEDULE table
    
- `booking_date` - Date when booking was made
    
- `fare_class` - Ticket class (Economy, Business)
    
- `ticket_price` - Original ticket price
    
- `status` - Booking status (Confirmed, Cancelled)
    

#### **CUSTOMERS Table**

- `customer_id` (PK) - Unique identifier for each customer
    
- `customer_name` - Full name of customer
    
- `loyalty_level` - Loyalty tier (Bronze, Silver, Gold)
    
- `total_flights` - Number of flights taken
    
- `no_show_history` - Historical no-show percentage
    

#### **FLIGHT_SCHEDULE Table**

- `flight_id` (PK) - Unique identifier for each flight
    
- `route_code` - Flight route (e.g., NBO-DAR)
    
- `departure_time` - Scheduled departure time
    
- `aircraft_id` (FK) - References AIRCRAFT table
    
- `total_seats` - Aircraft capacity
    
- `seats_sold` - Current bookings count
    

#### **NO_SHOW_FORECAST Table**

- `forecast_id` (PK) - Unique prediction record
    
- `flight_id` (FK) - References FLIGHT_SCHEDULE
    
- `prediction_date` - Date when prediction was made
    
- `predicted_no_shows` - Estimated no-show count
    
- `confidence_score` - Prediction accuracy rating
    

#### **PRICE_RULES Table**

- `rule_id` (PK) - Unique pricing rule
    
- `route_code` - Applicable flight route
    
- `base_price` - Standard ticket price
    
- `min_price` - Minimum allowed price
    
- `max_price` - Maximum allowed price
    
- `demand_factor` - Demand multiplier
    

#### **PRICE_ADJUSTMENTS Table**

- `adjustment_id` (PK) - Unique price change record
    
- `flight_id` (FK) - References FLIGHT_SCHEDULE
    
- `old_price` - Previous ticket price
    
- `new_price` - Updated ticket price
    
- `adjustment_reason` - Reason for price change
    
- `adjustment_time` - When change was made
    

---

## 3. PL/SQL Components

### Procedures:

1. **`predict_noshows`** - Analyzes booking data and predicts no-show count for upcoming flights
    
2. **`adjust_pricing`** - Automatically adjusts ticket prices based on predictions and demand
    
3. **`generate_revenue_report`** - Creates daily revenue and occupancy reports
    

### Functions:

1. **`calculate_load_factor`** - Returns current seat occupancy percentage for flights
    
2. **`get_no_show_probability`** - Calculates individual passenger no-show likelihood
    
3. **`calculate_optimal_price`** - Determines best price point based on demand
    

### Triggers:

1. **`check_booking_completion`** - Validates booking data integrity
    
2. **`update_seat_count`** - Automatically updates available seats after booking
    
3. **`log_price_changes`** - Records all pricing adjustments for audit trail
    

### Packages:

1. **`revenue_engine_pkg`** - Main package containing all prediction and pricing logic
    
2. **`reporting_analytics_pkg`** - Business intelligence and reporting functions
    
3. **`data_validation_pkg`** - Ensures data quality and consistency
    

---

## 4. Innovation or Improvement

The Arina Airlines system transforms traditional airline revenue management by introducing predictive automation directly within the database layer. This isn't just about recording bookings it's about creating a system that anticipates passenger behavior and responds intelligently.

### Key Innovations:

#### **Real-Time No-Show Prediction**

Smart PL/SQL functions analyze multiple factors (loyalty, booking patterns, holidays, flight timing) to predict no-shows 24 hours before departure, giving airlines time to adjust strategy.

#### **Automated Dynamic Pricing**

Instead of manual price changes, the system automatically adjusts ticket prices based on predicted empty seats, maximizing revenue and seat occupancy.

#### **Self-Learning Accuracy**

Each flight's actual no-show data is fed back into the system, improving future predictions through continuous learning.

#### **Complete Database Integration**

Everything runs inside Oracle no external tools or manual processes needed. This reduces costs and increases reliability for small regional airlines.

#### **Actionable Business Intelligence**

The system doesn't just report data it triggers actions (price changes) and provides insights for strategic decisions about routes, scheduling, and capacity.

The Arina Airlines Dynamic Pricing and No-Show Prediction System creates a smart, automated revenue management assistant that helps small airlines compete effectively, optimize every flight, and make data-driven decisions that directly impact profitability.
