-- Task_1  Data Cleaning and Preparation
-- To identify the duplicate records
Select Order_ID, count(order_id) from orders group by order_id having count(Order_ID) > 1;


-- To check the null values in Routes table in Traffic_Delay_Min 
Select count(*) as null_count from routes where Traffic_Delay_Min is null;

-- Convert all date columns into YYYY-MM-DD format using SQL functions.

Alter table orders Modify Order_Date date, Modify Expected_Delivery_Date date, modify Actual_Delivery_Date date;

UPDATE orders
SET order_date = DATE_FORMAT(order_date,'%Y-%m-%d'),
    Expected_Delivery_Date = DATE_FORMAT(Expected_Delivery_Date,'%Y-%m-%d'),
    Actual_Delivery_Date = DATE_FORMAT(Actual_Delivery_Date,'%Y-%m-%d');

describe orders;


 -- Ensure that no Actual_Delivery_Date is before Order_Date (flag such records).

Select Order_Date, Actual_Delivery_Date from Orders where Order_Date > Actual_Delivery_Date;


-- Task_2 Delivery Delay Analysis
-- Calculate delivery delay (in days) for each order 

Select Order_Id, Actual_Delivery_Date - Expected_Delivery_Date as Delivery_Delay_Days from orders;

--  Find Top 10 delayed routes based on average delay days. 

SELECT 
    Route_ID,
    ROUND(AVG(Actual_Delivery_Date - Expected_Delivery_Date),
            2) AS Delivery_Delay_Days
FROM
    orders
GROUP BY Route_ID
ORDER BY Delivery_Delay_Days DESC
LIMIT 10;

-- Use window functions to rank all orders by delay within each warehouse. 

Select order_id, warehouse_id, datediff(Actual_Delivery_Date,Expected_Delivery_Date) as Delay_Days,
dense_rank() over ( partition by warehouse_id 
order by datediff(Actual_Delivery_Date,Expected_Delivery_Date) desc) as delay_rank from orders;


-- Task_3 Route Optimization Insights
-- For each route, calculate Average delivery time (in days).
SELECT 
    Route_ID,
    ROUND(AVG(DATEDIFF(Actual_Delivery_Date, Order_Date)),
            2) AS Avg_Delivery_Time
FROM
    orders
GROUP BY Route_Id;

-- For each route, calculate Average traffic delay.

Select Route_ID , round(avg(traffic_delay_min),2) as Avg_Traffic_Delay from routes group by Route_ID;

-- For each route, calculate Distance-to-time efficiency ratio: Distance_KM / Average_Travel_Time_Min. 

Select Route_id, Round(Distance_KM / Average_Travel_Time_Min,2) as Efficeincy_ratio from routes ;

--  Identify 3 routes with the worst efficiency ratio. 

Select Route_id, Round(Distance_KM / Average_Travel_Time_Min,2) as Efficeincy_ratio from routes order by Efficeincy_ratio limit 3 ;

 -- Find routes with >20% delayed shipments.
 
SELECT route_id FROM orders GROUP BY route_id
HAVING AVG(CASE
    WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1
    ELSE 0
END) > 0.20;

-- Recommend potential routes for optimization. 
-- Routes R006, R016, R008, R007, and R014 show the highest operational inefficiencies and delay impact and should be prioritized for logistics optimization initiatives.


-- Task_4  Warehouse Performance
--  Find the top 3 warehouses with the highest average processing time. 

SELECT warehouse_id, ROUND(AVG(Processing_Time_Min), 2) AS Avg_Processing_time
FROM warehouses GROUP BY Warehouse_ID ORDER BY Avg_Processing_time DESC LIMIT 3;
 
 -- Calculate total vs. delayed shipments for each warehouse.
 
 SELECT warehouse_id, COUNT(*) AS total_shipments, SUM(CASE
        WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1
        ELSE 0 END) AS Delayed_Shipment FROM orders GROUP BY Warehouse_ID;

-- Use CTEs to find bottleneck warehouses where processing time > global average.  

with global_average as ( select avg(processing_time_min) as avg_time from warehouses )
SELECT warehouse_id, ROUND(AVG(processing_time_min), 2) AS warehouse_avg_time
FROM warehouses, global_average GROUP BY Warehouse_ID , avg_time HAVING AVG(processing_time_min) > avg_time;

-- Rank warehouses based on on-time delivery percentage. 

Select warehouse_id, on_time_percentage, rank() over( order by on_time_percentage desc) 
 as warehouse_rank from
 ( select
    warehouse_id, 100 * avg( case when actual_delivery_date <= expected_delivery_date then 1 else 0 end) 
     as 
     on_time_percentage from orders group by Warehouse_ID) t;


-- Task_5 Delivery Agent Performance
--  Rank agents (per route) by on-time delivery percentage 
select agent_id, route_id, rank() over (partition by Route_ID order by on_time_percentage desc) as agent_rank from deliveryagents;

--  Find agents with on-time % < 80%. 
Select agent_id from deliveryagents where on_time_percentage < 80 ;

-- Compare average speed of top 5 vs bottom 5 agents using subqueries. 
Select (Select round(avg(avg_speed_km_hr),2) from ( Select Avg_Speed_KM_HR from deliveryagents order by Avg_Speed_KM_HR desc limit 5) top_5 ) as avg_speed_of_top_5 ,
       (Select round(avg(avg_speed_km_hr),2) from ( Select Avg_Speed_KM_HR from deliveryagents order by Avg_Speed_KM_HR asc limit 5) bottom_5 ) as avg_speed_of_bottom_5;
  
  
-- Task_6 Shipment Tracking Analysis
--  For each order, list the last checkpoint and time.

Select Order_ID, Checkpoint, Checkpoint_Time from(
Select order_id, checkpoint, checkpoint_time, row_number() 
over ( partition by order_id order by str_to_date(checkpoint_time,'%Y-%m-%d %H:%i:%s') desc) as rn from shipment_tracking) t
         where rn = 1;
         
--  Find the most common delay reasons (excluding None).

SELECT Delay_reason, COUNT(*) AS reason_count
FROM shipment_tracking WHERE Delay_Reason IS NOT NULL
        AND Delay_Reason <> 'None'
GROUP BY Delay_Reason
ORDER BY reason_count DESC;

--  Identify orders with >2 delayed checkpoints 
SELECT 
    order_id, COUNT(*) AS delayed_checkpoints
FROM
    shipment_tracking
WHERE
    Delay_Reason IS NOT NULL
        AND Delay_Reason <> 'None'
GROUP BY Order_ID
HAVING COUNT(*) > 2;


-- Task_7 Calculating KPI's
-- Calculate KPIs using SQL queries:  Average Delivery Delay per Region (Start_Location).
SELECT 
    start_location,
    ROUND(AVG(traffic_delay_min), 2) AS Avg_delivery_delay
FROM
    routes
GROUP BY Start_Location;


-- Calculate KPIs using SQL queries: On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100
SELECT 
    ROUND(SUM(CASE
                WHEN actual_delivery_date <= expected_delivery_date THEN 1
                ELSE 0
            END) / COUNT(order_id) * 100,
            2) AS on_time_delivery_percentage
FROM
    orders;
    
    
-- Calculate KPIs using SQL queries: Average Traffic Delay per Route.
SELECT 
    route_id,
    ROUND(AVG(traffic_delay_min), 2) AS avg_traffic_delay
FROM
    routes
GROUP BY Route_ID;



