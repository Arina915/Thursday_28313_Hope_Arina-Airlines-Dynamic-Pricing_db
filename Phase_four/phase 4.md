# PHASE IV: Database Creation

# Project Overview

## Executive Summary

This project creates a ready-to-use Oracle database for the **Arina Airlines Dynamic Pricing and No-Show Prediction System**. The database is set up to work well, grow when needed, and stay secure. It follows Oracle’s best practices for organizing data, managing space, and keeping everything running smoothly.

## Project Goals

- Create a separate database just for Arina Airlines
    
- Set up different storage areas for data, indexes, and temporary work
    
- Make the database grow automatically when it needs more space
    
- Create a secure admin user with the right permissions
    
- Write down all steps so others can set it up too
    

## Key takeaways

- How Oracle databases work (PDB and containers)
    
- How to create and manage storage areas (tablespaces)
    
- How to make databases grow automatically
    
- How to set up user security
    
---

## How the Database is Organized

text
```
Main Oracle System
    └── Our New Database: mon_28313_Hope_Arina-Airlines-Dynamic-Pricing_db
            ├── System Area (for Oracle itself)
            └── Our Custom Storage Areas
                    ├── AIR_DATA     → For flight and booking tables
                    ├── AIR_INDEX    → For database indexes (makes searches faster)
                    └── AIR_TEMP     → For temporary work during calculations
```
### Why Multiple Storage Areas?

- **Better Speed:** Data and indexes are separate so they don’t slow each other down
    
- **Easy Growth:** Each area can grow at its own pace
    
- **Easy Maintenance:** We can backup or fix one area without affecting others
    
- **Better Control:** We decide how much space each part gets
    

---

## Storage Area Details

### 1. AIR_DATA Storage Area

- **Purpose:** Stores all airline data (flights, bookings, customers, prices)
    
- **Starting Size:** 200 MB
    
- **Grows By:** 20 MB each time it needs more space
    
- **Max Size:** 2 GB
    

**Why These Settings:**

- Big enough to start with real airline data
    
- Grows in small steps to use disk space wisely
    
- Has a limit so it doesn’t take over the whole server
    

### 2. AIR_INDEX Storage Area

- **Purpose:** Stores only indexes (like a book index - helps find data fast)
    
- **Starting Size:** 100 MB
    
- **Grows By:** 10 MB each time
    
- **Max Size:** 1 GB

**Why These Settings:**

- Indexes help the pricing system work quickly
    
- Separate from data for better performance
    
- Smaller growth since indexes grow slower than data
    

### 3. AIR_TEMP Storage Area

- **Purpose:** Temporary space for calculations and sorting
    
- **Starting Size:** 100 MB
    
- **Grows By:** 10 MB each time
    
- **Max Size:** 500 MB
    
- **Type:** Temporary (data disappears after work is done)
    

**Why These Settings:**

- Enough space for pricing calculations
    
- Temporary data doesn’t need to be saved
    
- Has a limit to stop problems if a query runs wild
    
---

## Auto-Grow Settings

### What is Auto-Grow?

Auto-grow means the database automatically adds more space when it’s running out.

### How We Set It Up:

For all our storage areas:

text
```
AUTOEXTEND ON      -- Turn on auto-grow   
NEXT 10M-20M       -- Add this much space each time
MAXSIZE 500M-2GB    -- Stop growing at this limit
```
### Why This is Good:

- **No Downtime:** The system won’t stop with "out of space" errors
    
- **Smart Growth:** Uses disk space only when really needed
    
- **Safety Limit:** Won’t fill up the entire disk
    
- **Less Work:** No one has to manually add space
    
---

## Backup Logs (Archive Logging)

### What Are Backup Logs?

Backup logs save a copy of every change made to the database. If something goes wrong, we can recover everything.

### How to Set It Up:

**Step 1: Turn On Archive Mode**

sql
```
SHUTDOWN IMMEDIATE;            -- Stop the database        
STARTUP MOUNT;                 -- Start in setup mode
ALTER DATABASE ARCHIVELOG;     -- Turn on backup logs
ALTER DATABASE OPEN;           -- Start normally
```
**Step 2: Tell Oracle Where to Save Logs**

sql
```
ALTER SYSTEM SET log_archive_dest_1='LOCATION=/u01/app/oracle/archive' SCOPE=BOTH;
```
**Step 3: Check It Worked**

sql
```
ARCHIVE LOG LIST;

-- Should Show:
-- Database log mode:         
-- Automatic archival:        
-- Archive destination:       
```
---

## Admin User Setup

- **Username:** arina_admin
    
- **Password:** arinatwe
    
- **Permissions:** Full access to everything in the database
    
---

## Memory Settings

### Database Memory Configuration:

- **SGA_TARGET:** 1 GB (for shared memory)
    
- **PGA_AGGREGATE_TARGET:** 500 MB (for private memory per user)
    
- **MEMORY_TARGET:** 2 GB (total memory available)
These settings give enough memory for the pricing system to run fast, even with many users.

### Conclusion:
This setup for the Arina Airlines system is strong, flexible, and safe.
It helps the system figure out ticket prices and predict no-shows,
keeping everything running smoothly and quickly according to Oracle's guidelines.
