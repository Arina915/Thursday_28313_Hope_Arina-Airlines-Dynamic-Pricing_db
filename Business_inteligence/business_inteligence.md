# **BUSINESS INTELLIGENCE REQUIREMENTS**

## **Arina Airlines Dynamic Pricing System**

## **PROJECT OVERVIEW**

The Arina Airlines system needs business intelligence tools to help managers make better decisions about pricing, flights, and operations.

## **MAIN GOALS**

1. Track flight performance and revenue
    
2. Watch system usage and speed
    
3. Analyze booking patterns and predict no-shows
    
4. Check compliance with business rules
    
5. Support smart decision-making
    

## **NEEDED DASHBOARDS**

1. **Airline Summary Dashboard** - Key numbers and trends
    
2. **Audit & Rules Dashboard** - Security and rule checking
    
3. **System Performance Dashboard** - Computer resources and health
    
4. **Booking & Pricing Dashboard** - Trends and predictions
    

## **DATA WE HAVE**

Based on your tables:

- **BOOKINGS table** (121+ bookings, various ticket prices)
    
- **CUSTOMERS table** (115+ customers with loyalty tiers)
    
- **FLIGHT_SCHEDULE table** (90+ flight routes)
    
- **NO_SHOW_FORECAST table** (108+ predictions)
    
- **PRICE_ADJUSTMENTS table** (127+ price changes)
    

## **TECHNICAL NEEDS**

- Real-time data updates where possible
    
- Look at past trends (last 90 days)
    
- Predict future no-shows and demand
    
- Show system rules are working
    

---

## **DECISION SUPPORT NEEDS**

### **Important Decisions About System Usage:**

1. **Database Size Planning:** How much data can we store?
    
2. **Speed Optimization:** Are queries fast enough? (< 100ms)
    
3. **Booking Volume:** How many bookings can we handle?
    
4. **Prediction Accuracy:** Are no-show predictions correct?
    
5. **Computer Resources:** Are servers working well?
    

### **Analysis Help Needed:**

- **Resource Planning:** When will we need more storage?
    
- **Speed Checks:** Compare our speed to airline standards
    
- **Growth Planning:** Predict booking growth for next 6 months
    
- **Season Patterns:** Find busy and slow travel times
    
- **Cost Saving:** Find places to save money
    
- **Alerts:** Warn when important numbers get too high
    

---

## **WHO NEEDS WHAT**

|Person/Team|Job|Main Dashboards|Key Numbers to Watch|
|---|---|---|---|
|**System Admin**|Keep computers running|System Performance|Storage, CPU, Memory, Uptime|
|**Database Admin**|Keep database fast|System Performance|Query speed, Index usage, Growth|
|**Booking Staff**|Make bookings|Airline Summary, Booking Trends|Flight capacity, Booking rates|
|**Revenue Manager**|Watch money|Airline Summary, Pricing|Ticket prices, Revenue, No-show rates|
|**IT Team**|Improve system|System Performance, Predictions|Feature usage, System load|
|**Airline Managers**|Plan strategy|Airline Summary, Predictions|Profit, Growth, Prediction accuracy|

---

## **KEY INSIGHTS FROM OUR DATA**

### **System Usage Insights:**

- **Database Size:** Currently small and efficient
    
- **Growth Rate:** Growing slowly with more bookings
    
- **Speed:** Queries are fast (< 50ms), system is healthy
    
- **Booking Volume:** 121+ bookings shows active system
    
- **Busiest Table:** BOOKINGS table uses most space
    

### **Booking Pattern Insights:****

- **No-Show Rate:** 3-7% average across flights
    
- **Prediction Accuracy:** 85-99% accuracy on no-show forecasts
    
- **Price Changes:** 127+ price adjustments show active pricing
    
- **Loyalty Spread:** 68.7% Standard, 12.17% Gold, 9.57% Silver, 9.57% Platinum customers
    
- **Route Performance:** Some routes have higher no-show rates than others
    

### **Revenue Insights:**

- **Ticket Prices:** Range from economy to business class
    
- **Dynamic Pricing:** Working with price adjustments
    
- **Customer Value:** Gold/Platinum customers book more expensive tickets
    

---

## **RECOMMENDATIONS**

### **System Management:**

1. **No urgent action needed** - System is running well
    
2. **Watch growth** - Flag if bookings grow faster than expected
    
3. **Optimize BOOKINGS table** - This is our busiest table
    
4. **Keep backups** - Regular backup of booking data
    

### **Prediction Improvement:**

1. **Improve no-show predictions** for high-risk customers
    
2. **Add seasonal adjustments:**
    
    - Holiday seasons: Higher no-shows
        
    - Business travel seasons: Lower no-shows
        
3. **Create alerts** when predictions are very wrong (>20% error)
    

### **Capacity Planning:**

1. **Next 6 months:** Watch booking growth
    
2. **Next year:** Plan for more flight routes
    
3. **Future:** Add more storage if needed
    

### **Business Decisions:**

1. **Focus on Gold/Platinum customers** - They're most valuable
    
2. **Adjust prices on busy routes** - Maximize revenue
    
3. **Watch high no-show flights** - Consider overbooking carefully
    
4. **Use predictions for staffing** - Plan for busy times
    

---

## **READY FOR BUSINESS INTELLIGENCE**

The Arina Airlines system now has:

### ** Data Foundation:**

- Clean, organized booking data
    
- Customer loyalty information
    
- Flight schedule details
    
- Price change history
    
- No-show predictions
    

### ** Analysis Tools:**

- Window functions for ranking
    
- Aggregation for summaries
    
- Prediction functions
    
- Audit tracking
    

### ** Decision Support:**

- Real-time flight performance data
    
- Customer behavior patterns
    
- Revenue tracking
    
- System health monitoring
    

**The system is ready to provide valuable business insights for smarter airline management.**
