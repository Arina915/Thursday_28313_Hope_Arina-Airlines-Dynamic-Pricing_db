# Thursday_28313_Hope_Arina-Airlines-Dynamic-Pricing_db
----
## Arina Airlines Dynamic Pricing and No-Show Prediction System

**Student Name:** Arinatwe Hope  
**Student ID:** 28313

---

##  Project Overview

This project is a PL/SQL-based dynamic pricing and no-show prediction system designed for Arina Airlines, a regional airline operating routes between Nairobi, Dar es Salaam, and Kigali. The system automatically predicts passenger no-shows and adjusts ticket prices in real-time to maximize revenue and optimize seat occupancy.

---

##  Problem Statement

Regional airlines like Arina Airlines face significant revenue loss due to:

- **Empty seats** from passenger no-shows
    
- **Inefficient pricing** that doesn't respond to demand fluctuations
    
- **Manual overbooking decisions** that lead to denied boardings or lost revenue
    
- **Lack of predictive analytics** to anticipate booking patterns
    

This system solves these challenges by providing automated, data-driven predictions and pricing adjustments directly within the airline's Oracle database.

---

##  Key Objectives

1. **Automated No-Show Prediction** - Use historical data and booking patterns to predict passengers likely to miss flights
    
2. **Dynamic Pricing Engine** - Automatically adjust ticket prices based on demand, seat availability, and predicted no-shows
    
3. **Revenue Optimization** - Maximize flight revenue through smart overbooking and price adjustments
    
4. **Real-time Processing** - Implement PL/SQL procedures that run automatically without manual intervention
    
5. **Self-Learning System** - Improve prediction accuracy over time using actual flight outcomes
    
6. **Comprehensive Audit Trail** - Track all predictions, price changes, and revenue impacts
    

---

##  Technologies Used

- **Oracle Database** - Core database platform
    
- **PL/SQL** - Functions, Procedures, Packages, Triggers, Scheduler Jobs
    
- **SQL** - Tables, Views, Constraints, Indexes, Sequences
    
- **Oracle Scheduler** - Automated job execution
    
- **Exception Handling** - Robust error management and logging
    

---

##  Quick Start Instructions

### Prerequisites

- Oracle Database 11g or higher
    
- SQL*Plus or Oracle SQL Developer
    
- Basic understanding of SQL and PL/SQL
    

### Installation Steps

1. **Set Up the Database Schema**
    
    sql
```    

-- Connect to your Oracle database
sqlplus airline_admin/password@orcl

-- Create database tables
@scripts/create_tables.sql

-- Create PL/SQL package
@scripts/create_package_revenue_engine.sql

-- Set up scheduler jobs
@scripts/create_scheduler_jobs.sql
```
**Load Sample Data**

sql
```
-- Insert sample flights, aircraft, and bookings
@sample_data/insert_sample_data.sql
```
**Test the System**

sql
```
-- Run prediction and pricing for a specific flight
EXEC revenue_engine.predict_and_adjust('AA245');
```
---

## Project Structure

text
```
arina-airlines-pricing-system/
│
├── database/
│   ├── ddl/                    # Table creation scripts
│   │   ├── create_tables.sql
│   │   ├── create_sequences.sql
│   │   └── create_indexes.sql
│   │
│   ├── plsql/                  # PL/SQL code
│   │   ├── revenue_engine.pkg  # Main package
│   │   ├── functions/          # Individual functions
│   │   ├── procedures/         # Individual procedures
│   │   └── triggers/           # Database triggers
│   │
│   └── scheduler/              # Automated job scripts
│
├── sample_data/
│   ├── airports_data.sql
│   ├── aircraft_data.sql
│   ├── flights_data.sql
│   └── bookings_data.sql
│
├── documentation/
│   ├── database_design.md      # Schema design and ERD
│   ├── kpi_definitions.md      # Performance metrics
│   ├── dashboard_designs.md    # Visualization mockups
│   └── data_dictionary.md      # Complete table specifications
│
├── queries/
│   ├── reports.sql             # Standard reports
│   ├── dashboard_queries.sql   # KPI calculation queries
│   └── analytics.sql           # Advanced analytics
│
├── test/
│   ├── test_cases.sql          # Unit tests
│   ├── load_testing.sql        # Performance tests
│   └── validation_scripts.sql  # Data validation
│
└── README.md                   # This file
```
---

##  Documentation

### Core Documentation

- **Database Design** - Complete schema design with ER diagrams and table relationships
    
- **KPI Definitions** - Key performance indicators and calculation formulas
    
- **Dashboard Designs** - Visualization mockups for executive reporting
    
- **Data Dictionary** - Detailed table and column specifications
    

### PL/SQL Components

- **Revenue Engine Package** - Main package containing prediction and pricing logic
    
- **Functions** - `predict_noshows()`, `calculate_load_factor()`, `calculate_price_multiplier()`
    
- **Procedures** - `adjust_pricing()`, `generate_forecast_report()`, `update_prediction_model()`
    
- **Triggers** - Audit logging, data validation, and business rule enforcement
    
- **Scheduler Jobs** - Automated daily prediction and weekly model retraining
    

### Reports & Analytics

- **Daily Prediction Reports** - No-show forecasts by flight and route
    
- **Revenue Impact Analysis** - Financial impact of price adjustments
    
- **Performance Dashboards** - Real-time KPIs and trends
    
- **Audit Logs** - Complete trail of all system actions
    

---

##  Key Features

### 1. No-Show Prediction Engine

- Analyzes historical booking patterns, loyalty status, and flight timing
    
- Considers external factors like holidays and seasonality
    
- Updates predictions as booking window closes
    
- Learns from actual outcomes to improve accuracy
    

### 2. Dynamic Pricing System

- Automatically adjusts fares based on:
    
    - Current seat occupancy
        
    - Time until departure
        
    - Predicted no-show rate
        
    - Historical demand patterns
        
    - Competitor pricing (if available)
        
- Applies different rules for each fare class (K, J, F, Y)
    

### 3. Smart Overbooking Management

- Calculates optimal overbooking levels based on no-show predictions
    
- Prevents denied boardings while maximizing revenue
    
- Integrates with upgrade and standby systems
    

### 4. Real-time Processing

- PL/SQL procedures run automatically via Oracle Scheduler
    
- No manual intervention required
    
- Processes all flights daily
    
- Updates prices in real-time as conditions change
    

### 5. Comprehensive Monitoring

- Tracks all predictions vs. actual outcomes
    
- Logs every price change with before/after values
    
- Calculates revenue impact of each adjustment
    
- Provides audit trail for compliance
    

### 6. Self-Learning Capability

- Compares predictions with actual no-shows
    
- Adjusts prediction algorithms based on performance
    
- Improves accuracy over time
    
- Adapts to changing passenger behavior
    

---

## Testing

The system includes comprehensive test cases covering:

### Unit Tests

- Prediction accuracy validation
    
- Price calculation logic
    
- Trigger functionality
    
- Error handling scenarios
    

### Integration Tests

- End-to-end prediction and pricing workflow
    
- Database constraint enforcement
    
- Scheduler job execution
    
- Concurrent access scenarios
    

### Performance Tests

- Processing time for large datasets
    
- Memory usage optimization
    
- Query performance tuning
    
- Bulk operation efficiency
    

##  Database Schema Overview

**Core Tables:**

- `AIRPORTS` - Airport details (IATA codes, locations, hub status)
    
- `AIRCRAFT` - Fleet information (registration, type, capacity)
    
- `FLIGHT_SCHEDULE` - Flight routes, timings, and status
    
- `BOOKINGS` - Passenger reservations with fare classes and status
    
- `CUSTOMERS` - Customer profiles and loyalty program data
    
- `NO_SHOW_FORECAST` - Prediction records with confidence scores
    
- `PRICE_RULES` - Dynamic pricing rules and parameters
    
- `PRICE_ADJUSTMENTS` - Audit trail of all price changes
    
- `REVENUE_IMPACT` - Calculated financial impact of pricing decisions
    

**Key PL/SQL Components:**

- **Package:** `REVENUE_ENGINE` - Main business logic container
    
- **Function:** `PREDICT_NOSHOWS(flight_id)` - Returns predicted no-show count
    
- **Procedure:** `ADJUST_PRICING(flight_id)` - Updates fares based on conditions
    
- **View:** `REVENUE_DASHBOARD_VW` - Aggregated data for reporting
    

---

## Contributing

This is an academic project developed for database management coursework. For questions or academic collaboration:

- **Student:** Arinatwe Hope
    
- **Student ID:** 28313
    
- **Project:** Arina Airlines Dynamic Pricing and No-Show Prediction System
    

---

##  License

This project is created for educational purposes as part of a database management and PL/SQL programming course.

---

##  Acknowledgments

- Oracle Corporation for PL/SQL documentation and resources
    
- Course instructors and teaching assistants
    
- Academic peers for feedback and collaboration
    
- Airlines industry research papers on revenue management
