
## **Phase II: Business Process Modeling**

----

## **Business Process Overview**

### **Objective**

To model the business process for predicting passenger no-shows and adjusting ticket prices automatically using PL/SQL, ensuring better seat utilization and increased profit for Arina Airlines.

### **Scope**

The process covers:

1. Flight booking and data collection
    
2. No-show prediction using historical data and rules
    
3. Dynamic price adjustment based on demand and predicted no-shows
    
4. Reporting and auditing of changes
    

### **Identify All the Key Players (Entities)**

- **Users:** Passengers, booking agents, revenue management team
    
- **Roles:** Passengers book flights, System predicts no-shows and adjusts prices, Management reviews reports
    
- **Data Sources:** `bookings`, `customers`, `flight_schedule`, `no_show_forecast`, `price_rules`
    

**MIS Relevance:** Automates revenue management, optimizes pricing, and supports data-driven decision-making in airline operations.

**Expected Outcomes:**

- Reduced empty seats through smart overbooking
    
- Increased revenue via dynamic pricing
    
- Automated, real-time decision support

## **Process Diagram (BPMN Swimlane Model)**
<img width="1874" height="1886" alt="ER diargram" src="https://github.com/user-attachments/assets/81982c92-e4cf-49d4-8a5f-238747943eea" />


## Passenger Swimlane:

1. **Start Event** → Passenger looks for flights to book
    
2. **Book Flight** → Passenger chooses a flight and pays
    
3. **Receive Ticket with Updated Price** → Passenger gets email with final ticket price (price might be different from when they booked)
    
4. **Check-In or No-Show** → Passenger either:
    
    - Goes to airport and takes flight
        
    - Doesn't show up (no-show)
        
5. **End Event** → Trip done or marked as no-show
    

##   System Swimlane:

1. **Capture Booking Data** → System saves passenger booking information
    
2. **Trigger: Predict No-Shows** → Computer guesses how many people won't show up
    
3. **Decision Point: High No-Show Risk?** → Computer checks if many people might not come
    
    - **If Yes:** Lower prices to sell more tickets
        
    - **If No:** Keep normal prices
        
4. **Execute Price Adjustment** → Computer changes ticket prices automatically
    
5. **Log Changes** → Computer writes down what it changed
    
6. **Generate Revenue Report** → Computer makes report for manager to see
    

##  Management Swimlane:

1. **Review Reports** → Manager looks at computer's reports
    
2. **Adjust Rules if Needed** → Manager changes computer rules if something is wrong
    
3. **End Event** → Manager is done checking

## Main Components

The process includes **six core stages** across three swimlanes:

1. **Booking Initiation** – Passenger/agent interaction
    
2. **Data Capture** – System records booking details
    
3. **No-Show Prediction** – PL/SML logic evaluates risk
    
4. **Dynamic Pricing** – Prices adjusted based on load and prediction
    
5. **Audit & Reporting** – All changes logged and reported
    
6. **Management Review** – Oversight and rule tuning
    


 ## Main Components

The process includes **six core stages** across three swimlanes:

1. **Booking Initiation** – Passenger/agent interaction
    
2. **Data Capture** – System records booking details
    
3. **No-Show Prediction** – PL/SML logic evaluates risk
    
4. **Dynamic Pricing** – Prices adjusted based on load and prediction
    
5. **Audit & Reporting** – All changes logged and reported
    
6. **Management Review** – Oversight and rule tuning
    

---

## 💼 **MIS Functions**

### **1. Data Collection**

- Captures passenger details, booking history, loyalty status
    
- Logs flight schedules, aircraft capacity, and historical no-show rates
    
- Stores pricing rules and adjustment logs
    

### **2. Automated Analysis**

- **Real-Time Prediction:** PL/SQL function runs before each flight
    
- **Demand Assessment:** Evaluates seat load and booking trends
    
- **Risk Evaluation:** Identifies high no-show probability flights
    

### **3. Automated Decision-Making**

- **Price Adjustments:** Increases/decreases fares based on algorithms
    
- **Overbooking Triggers:** Suggests extra bookings when no-shows are likely
    
- **Rule-Based Execution:** Implements business logic without manual input
    

### **4. Reporting & Auditing**

- **Change Logs:** Tracks every price adjustment
    
- **Revenue Dashboards:** Shows impact of pricing changes
    
- **Forecast Accuracy Reports:** Compares predictions with actual no-shows
    

---

## **Organizational Impact**

### **Benefits for Arina Airlines:**

- **Increased Revenue** – Dynamic pricing maximizes seat revenue
    
- **Reduced Waste** – Fewer empty seats due to better predictions
    
- **Operational Efficiency** – Automated system reduces manual work
    
- **Improved Customer Satisfaction** – Fairer pricing and better seat availability
    

### **Benefits for Management:**

- **Data-Driven Decisions** – Real-time insights into booking patterns
    
- **Risk Management** – Controlled overbooking based on predictions
    
- **Transparent Auditing** – Full traceability of pricing changes
    

### **Benefits for Passengers:**

- **Fairer Pricing** – Prices reflect real-time demand
    
- **Better Availability** – Smart overbooking can free up last-minute seats
    
- **Loyalty Rewards** – System considers loyalty status in pricing
    

---

## **Analytics Opportunities**

### **1. Predictive Analytics**

- **No-Show Forecasting:** Improve accuracy using machine learning within PL/SQL
    
- **Demand Prediction:** Forecast booking surges based on season, holidays, events
    
- **Price Elasticity Modeling:** Understand how price changes affect demand
    

### **2. Performance Analytics**

- **Revenue Per Flight:** Measure impact of dynamic pricing on profitability
    
- **Prediction Accuracy Tracking:** Monitor and improve no-show forecast models
    
- **Customer Segmentation Analysis:** Identify high-value vs. high-risk passengers
    

### **3. Operational Analytics**

- **Route Performance:** Compare profitability across routes (Nairobi–Dar vs. Nairobi–Kigali)
    
- **Aircraft Utilization:** Assess seat fill rates per aircraft type
    
- **Booking Trend Analysis:** Identify peak booking times and channels
    

### **4. Customer Analytics**

- **Loyalty Impact:** Measure how loyalty status affects no-show rates
    
- **Booking Behavior:** Analyze how far in advance different customer segments book
    
- **Cancellation Patterns:** Identify common reasons for no-shows
    

---

## **Technical Implementation**

**Database Tables Used:**

- `bookings` – Stores passenger reservations
    
- `customers` – Customer profiles and loyalty data
    
- `no_show_forecast` – Holds prediction results
    
- `price_rules` – Contains dynamic pricing logic
    
- `price_adjustments` – Logs all price changes
    

**Automation Components:**

- PL/SQL Package: `revenue_engine`
    
- Function: `predict_noshows()`
    
- Procedure: `adjust_pricing()`
    
- Scheduler: Automated job to run before each flight
    

## **Conclusion**

This business process model shows how Arina Airlines can use an MIS-driven approach 
to automate no-show prediction and dynamic pricing. By leveraging PL/SQL for real-time analysis and decision-making,
the airline can increase revenue, reduce waste, and operate more efficiently—all within their existing Oracle database environment.
