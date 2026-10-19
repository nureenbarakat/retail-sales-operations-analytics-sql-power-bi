-- 1. Create Database
CREATE DATABASE Retail_GP;
USE Retail_GP;

-- 2. Create Dimension Tables
CREATE TABLE Calendar (
    date DATE PRIMARY KEY
);

CREATE TABLE Region (
    region_id INT PRIMARY KEY,
    sales_district VARCHAR(50),
    sales_region VARCHAR(50)
);

CREATE TABLE Stores (
    store_id INT PRIMARY KEY,
    region_id INT FOREIGN KEY REFERENCES Region(region_id),
    store_type VARCHAR(50),
    store_name VARCHAR(50),
    store_street_address VARCHAR(255),
    store_city VARCHAR(50),
    store_state VARCHAR(50),
    store_country VARCHAR(50),
    store_phone VARCHAR(20),
    first_opened_date DATE,
    last_remodel_date DATE,
    total_sqft INT,
    grocery_sqft INT
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_brand VARCHAR(100),
    product_name VARCHAR(255),
    product_sku BIGINT, 
    product_retail_price DECIMAL(10,2), 
    product_cost DECIMAL(10,2),
    product_weight DECIMAL(10,2),
    recyclable INT,
    low_fat INT
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_acct_num BIGINT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    customer_address VARCHAR(255),
    customer_city VARCHAR(50),
    customer_state_province VARCHAR(50),
    customer_postal_code VARCHAR(20),
    customer_country VARCHAR(50),
    birthdate DATE,
    marital_status CHAR(1),
    yearly_income VARCHAR(50),
    gender CHAR(1),
    total_children INT,
    num_children_at_home INT,
    education VARCHAR(50),
    acct_open_date DATE,
    member_card VARCHAR(50),
    occupation VARCHAR(50),
    homeowner CHAR(1)
);

-- 3. Create Facts Tables
CREATE TABLE Sales_2017 (
    transaction_date DATE FOREIGN KEY REFERENCES Calendar(date),
    stock_date DATE,
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    customer_id INT FOREIGN KEY REFERENCES Customers(customer_id),
    store_id INT FOREIGN KEY REFERENCES Stores(store_id),
    quantity INT
);

CREATE TABLE Sales_2018 (
    transaction_date DATE FOREIGN KEY REFERENCES Calendar(date),
    stock_date DATE,
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    customer_id INT FOREIGN KEY REFERENCES Customers(customer_id),
    store_id INT FOREIGN KEY REFERENCES Stores(store_id),
    quantity INT
);

CREATE TABLE Returns (
    return_date DATE FOREIGN KEY REFERENCES Calendar(date),
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    store_id INT FOREIGN KEY REFERENCES Stores(store_id),
    quantity INT
);

-- 4. Load data from CSV files
BULK INSERT Calendar
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Calendar.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Products
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Products.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Region
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Region.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Returns
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Returns.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Stores
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Stores.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
); 

BULK INSERT Sales_2017
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Sales 2017.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Sales_2018
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Sales 2018.csv' 
WITH (
    FIRSTROW = 2,          
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
);

BULK INSERT Customers 
FROM 'D:\Data Analysis Course\Data Source-20260504T142005Z-3-001\Data Source\Customers.csv' 
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- 5. Row count validation for all tables in the database
SELECT 'Products' AS TableName, COUNT(*) AS TotalRows FROM Products
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'Sales_2017', COUNT(*) FROM Sales_2017
UNION ALL
SELECT 'Sales_2018', COUNT(*) FROM Sales_2018
UNION ALL
SELECT 'Calendar', COUNT(*) FROM Calendar
UNION ALL
SELECT 'Stores', COUNT(*) FROM Stores
UNION ALL 
SELECT 'Region', COUNT(*) FROM Region
UNION ALL
SELECT 'Returns', COUNT(*) FROM Returns;

-- 6. Create Non-Clustered Indexes on Large Fact Tables (Sales)
/* 
to Speed up UNION ALL operations and heavy JOINs with Dimension tables 
by creating a lookup map for Foreign Keys (Product, Customer, and Store IDs)
*/
CREATE NONCLUSTERED INDEX IX_Sales2017_Product_Customer_Store 
ON Sales_2017 (product_id, customer_id, store_id);

CREATE NONCLUSTERED INDEX IX_Sales2018_Product_Customer_Store 
ON Sales_2018 (product_id, customer_id, store_id);


-- 7. Answer Business Questions
/* 1) Sales & Profit 
Q1: Annual Performance & Growth -- Evaluate yearly trends and cumulative revenue
*/
WITH YearlyStats AS (
    SELECT 
        YEAR(CAST(c.date AS DATE)) AS Sales_Year,
        SUM(s.quantity * p.product_retail_price) AS Revenue,
        SUM(s.quantity * p.product_cost) AS TotalCost, 
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Profit
    FROM (SELECT transaction_date, product_id, quantity FROM Sales_2017 
          UNION ALL 
          SELECT transaction_date, product_id, quantity FROM Sales_2018) s
    JOIN Products p ON s.product_id = p.product_id
    JOIN Calendar c ON s.transaction_date = c.date
    GROUP BY YEAR(CAST(c.date AS DATE)))
SELECT 
    Sales_Year,
    FORMAT(Revenue, 'C', 'en-US') AS Total_Revenue,
    FORMAT(TotalCost, 'C', 'en-US') AS Total_Cost, 
    FORMAT(Profit, 'C', 'en-US') AS Total_Profit,
    FORMAT(Profit / Revenue, 'P') AS Profit_Margin,
    FORMAT(SUM(Revenue) OVER(ORDER BY Sales_Year), 'C', 'en-US') AS Running_Total_Revenue,
    FORMAT(LAG(Revenue) OVER(ORDER BY Sales_Year), 'C', 'en-US') AS Last_Year_Revenue
FROM YearlyStats;

/* 
Q2: Top 5 Profitable Brands -- identify which brands contribute most 
*/
SELECT * FROM (
    SELECT 
        p.product_brand,
        FORMAT(SUM(s.quantity * p.product_retail_price), 'C', 'en-US') AS Brand_Revenue,
        FORMAT(SUM(s.quantity * p.product_cost), 'C', 'en-US') AS Brand_Cost,
        FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Brand_Profit,
        -- Window Function: Ranking brands by profit
        DENSE_RANK() OVER(ORDER BY SUM(s.quantity * (p.product_retail_price - p.product_cost)) DESC) AS Profit_Rank
    FROM (SELECT product_id, quantity FROM Sales_2017 
          UNION ALL 
          SELECT product_id, quantity FROM Sales_2018) s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY p.product_brand
) AS RankedBrands
WHERE Profit_Rank <= 5;

/* 
Q3: Annual Profit Cycle: Identifying High-Impact Months
*/
WITH MonthlySales AS (
    SELECT 
        MONTH(CAST(s.transaction_date AS DATE)) AS SaleMonth,
        SUM(s.quantity) AS Total_Qty,
        SUM(s.quantity * p.product_retail_price) AS Total_Revenue, 
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Raw_Profit
    FROM (
        SELECT transaction_date, product_id, quantity FROM Sales_2017
        UNION ALL
        SELECT transaction_date, product_id, quantity FROM Sales_2018
    ) s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY MONTH(CAST(s.transaction_date AS DATE))
)
SELECT 
    SaleMonth,
    DATENAME(MONTH, DATEADD(MONTH, SaleMonth - 1, '2000-01-01')) AS Month_Name,
    Total_Qty,
    FORMAT(Total_Revenue, 'C', 'en-US') AS Total_Revenue, 
    FORMAT(Raw_Profit, 'C', 'en-US') AS Total_Profit,
    FORMAT(Raw_Profit / SUM(Raw_Profit) OVER(), 'P') AS Profit_Contribution
FROM MonthlySales
ORDER BY Raw_Profit DESC; 

/* 
Q4: Store Performance & Efficiency Analysis -- evaluate each store's profitability and space utilization efficiency 
*/
SELECT 
    st.store_name,
    st.store_city,
    st.total_sqft,
    st.grocery_sqft,
    SUM(AllSales.quantity) AS Total_Items_Sold,
    FORMAT(SUM(AllSales.quantity * p.product_retail_price), 'C', 'en-US') AS Total_Revenue,
    FORMAT(SUM(AllSales.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Total_Profit,
    
    FORMAT(SUM(AllSales.quantity * 1.0) / st.grocery_sqft, 'N2') AS Sales_Per_Grocery_SqFt,
    FORMAT((st.grocery_sqft * 1.0 / st.total_sqft) * 100, 'N0') + '%' AS Display_Area_Ratio
FROM (
    SELECT store_id, product_id, quantity FROM Sales_2017
    UNION ALL
    SELECT store_id, product_id, quantity FROM Sales_2018
) AS AllSales
JOIN Stores st ON AllSales.store_id = st.store_id
JOIN Products p ON AllSales.product_id = p.product_id 
GROUP BY 
    st.store_name, 
    st.store_city, 
    st.total_sqft, 
    st.grocery_sqft
HAVING SUM(AllSales.quantity) > 20000 
ORDER BY SUM(AllSales.quantity * (p.product_retail_price - p.product_cost)) DESC;

/* 2) Customer Demographics
Q5: Gender-Based Profitability & Sales Distribution -- Analyze financial performance by customer gender to optimize targeted marketing campaigns 
*/
SELECT 
    c.gender,
    SUM(s.quantity) AS Total_Items_Sold,
    FORMAT(SUM(s.quantity * p.product_retail_price), 'C', 'en-US') AS Total_Revenue,
    FORMAT(SUM(s.quantity * p.product_cost), 'C', 'en-US') AS Total_Cost,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Total_Profit,
    FORMAT(
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) / 
        SUM(SUM(s.quantity * (p.product_retail_price - p.product_cost))) OVER()
    , 'P') AS Profit_Percentage

FROM (
    SELECT customer_id, product_id, quantity FROM Sales_2017 
    UNION ALL 
    SELECT customer_id, product_id, quantity FROM Sales_2018
) s
JOIN Customers c ON s.customer_id = c.customer_id
JOIN Products p ON s.product_id = p.product_id
GROUP BY c.gender;

/* 
Q6: Impact of Yearly Income on Purchase Volume -- Comprehensive distribution across all income brackets 
*/

WITH AllSales AS (
    SELECT customer_id, product_id, quantity FROM Sales_2017
    UNION ALL
    SELECT customer_id, product_id, quantity FROM Sales_2018)
SELECT 
    c.yearly_income,
    SUM(s.quantity) AS Total_Items_Sold,
    FORMAT(SUM(s.quantity * p.product_retail_price), 'C', 'en-US') AS Total_Revenue,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Total_Profit,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)) / SUM(s.quantity * p.product_retail_price), 'P') AS Profit_Margin
FROM AllSales s
JOIN Customers c ON s.customer_id = c.customer_id
JOIN Products p ON s.product_id = p.product_id 
GROUP BY c.yearly_income
ORDER BY 
    CASE c.yearly_income
        WHEN '$10K - $30K'   THEN 1
        WHEN '$30K - $50K'   THEN 2
        WHEN '$50K - $70K'   THEN 3
        WHEN '$70K - $90K'   THEN 4
        WHEN '$90K - $110K'  THEN 5
        WHEN '$110K - $130K' THEN 6
        WHEN '$130K - $150K' THEN 7
        WHEN '$150K +'       THEN 8
    END;

/* 
Q7: Who Buys What? Brand Rankings Across Income Levels 
Analyzes customer preferences by ranking brands based on profit within each income bracket
*/
WITH BrandIncomeStats AS (
    SELECT 
        p.product_brand,
        c.yearly_income,
        SUM(s.quantity) AS Items_Sold,
        SUM(s.quantity * p.product_retail_price) AS Total_Revenue, 
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Total_Profit
    FROM (
        SELECT customer_id, product_id, quantity FROM Sales_2017
        UNION ALL
        SELECT customer_id, product_id, quantity FROM Sales_2018
    ) s
    JOIN Customers c ON s.customer_id = c.customer_id
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY p.product_brand, c.yearly_income
),
RankedBrandIncome AS (
    SELECT 
        product_brand,
        yearly_income,
        Items_Sold,
        FORMAT(Total_Revenue, 'C', 'en-US') AS Revenue_Value,
        FORMAT(Total_Profit, 'C', 'en-US') AS Profit_Value,
        DENSE_RANK() OVER(PARTITION BY yearly_income ORDER BY Total_Profit DESC) AS Brand_Rank_In_Income
    FROM BrandIncomeStats
)
SELECT * FROM RankedBrandIncome
WHERE Brand_Rank_In_Income <= 5 
ORDER BY 
   CASE yearly_income
        WHEN '$10K - $30K'   THEN 1
        WHEN '$30K - $50K'   THEN 2
        WHEN '$50K - $70K'   THEN 3
        WHEN '$70K - $90K'   THEN 4
        WHEN '$90K - $110K'  THEN 5
        WHEN '$110K - $130K' THEN 6
        WHEN '$130K - $150K' THEN 7
        WHEN '$150K +'       THEN 8
    END
   ,Brand_Rank_In_Income;

/* 
Q8: Country Performance & Return Impact -- evaluate regional profitability, margins, and customer return behavior 
to support geographical expansion decisions 
*/
WITH AllSales AS (
    SELECT customer_id, product_id, store_id, quantity FROM Sales_2017
    UNION ALL
    SELECT customer_id, product_id, store_id, quantity FROM Sales_2018
),
ReturnStats AS (
    SELECT 
        st.store_country,
        SUM(r.quantity) AS Total_Returned_Items
    FROM Returns r
    JOIN Stores st ON r.store_id = st.store_id
    GROUP BY st.store_country
),
CountryStats AS (
    SELECT 
        c.customer_country,
        COUNT(DISTINCT c.customer_id) AS Unique_Customers,
        SUM(s.quantity) AS Total_Items_Sold,
        SUM(s.quantity * p.product_retail_price) AS Total_Revenue, 
        SUM(s.quantity * p.product_cost) AS Total_Cost,           
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Total_Profit
    FROM AllSales s
    JOIN Customers c ON s.customer_id = c.customer_id
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY c.customer_country
)
SELECT 
    cs.customer_country,
    cs.unique_customers,
    cs.total_items_sold,
    FORMAT(cs.total_revenue, 'C', 'en-US') AS Total_Revenue, 
    FORMAT(cs.total_cost, 'C', 'en-US') AS Total_Cost,      
    FORMAT(cs.total_profit, 'C', 'en-US') AS Total_Profit,
    FORMAT(cs.total_profit / NULLIF(cs.total_revenue, 0), 'P') AS Country_Profit_Margin,
    FORMAT(cs.total_items_sold * 1.0 / cs.unique_customers, 'N2') AS Sales_Items_Per_Customer,
    FORMAT(ISNULL(rs.total_returned_items, 0) * 1.0 / cs.unique_customers, 'N2') AS Return_Items_Per_Customer,
    FORMAT(CAST(ISNULL(rs.total_returned_items, 0) AS FLOAT) / NULLIF(cs.total_items_sold, 0), 'P') AS Return_Rate
FROM CountryStats cs
LEFT JOIN ReturnStats rs ON cs.customer_country = rs.store_country
ORDER BY cs.total_profit DESC;

/* Q9: Customer Segmentation using RFM Analysis
Segment customers based on Recency (R), Frequency (F), and Monetary (M)
to optimize targeted marketing campaigns
*/
WITH AllSales AS (
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2017
    UNION ALL
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2018
),
RFM_Base AS (
    SELECT 
        s.customer_id,
        -- Recency: How recently did the customer buy?
        DATEDIFF(DAY, MAX(CAST(s.transaction_date AS DATE)), (SELECT MAX(CAST(transaction_date AS DATE)) FROM AllSales)) AS Recency,
        -- Frequency: How often does the customer buy?
        COUNT(DISTINCT CAST(s.transaction_date AS DATE)) AS Frequency,
        -- Monetary: How much money did the customer spend?
        SUM(s.quantity * p.product_retail_price) AS Monetary
    FROM AllSales s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY s.customer_id
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score, 
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score, 
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score  
    FROM RFM_Base
)
SELECT 
    customer_id,
    Recency,
    Frequency,
    FORMAT(Monetary, 'C', 'en-US') AS Total_Spent,
    R_Score,
    F_Score,
    M_Score,
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
    CASE 
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'VIP / Champions'
        WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
        WHEN R_Score >= 4 AND F_Score < 3 THEN 'New / Promising'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk / Cant Lose Them'
        ELSE 'Lost / Hibernating'
    END AS Customer_Segment
FROM RFM_Scores
ORDER BY Customer_Segment DESC, Monetary DESC;

/* 3) Product Performance & Returns 
Q10: Top 10 Returned Products -- Identify quality issues and evaluate supplier performance 
*/
WITH ProductSales AS (
    SELECT 
        product_id, 
        SUM(quantity) AS Total_Sold_Quantity
    FROM Sales_2018
    GROUP BY product_id
),
RankedReturns AS (
    SELECT 
        p.product_id, 
        p.product_name,
        p.product_brand, 
        ISNULL(ps.Total_Sold_Quantity, 0) AS Total_Sold_Quantity,
        SUM(r.quantity) AS Total_Returned_Quantity,
        FORMAT(SUM(r.quantity * p.product_cost), 'C', 'en-US') AS Total_Return_Cost, 
        FORMAT(SUM(r.quantity) * 1.0 / NULLIF(ISNULL(ps.Total_Sold_Quantity, 0), 0), 'P') AS Product_Return_Rate, 
        ROW_NUMBER() OVER (ORDER BY SUM(r.quantity) DESC, SUM(r.quantity * p.product_cost) DESC) AS Return_Rank
    FROM Returns r
    JOIN Products p ON r.product_id = p.product_id
    LEFT JOIN ProductSales ps ON r.product_id = ps.product_id 
    WHERE r.return_date >= '1998-01-01' AND r.return_date <= '1998-12-31'
    GROUP BY p.product_id, p.product_name, p.product_brand, ps.Total_Sold_Quantity
)
SELECT * FROM RankedReturns
WHERE Return_Rank <= 10;

/* 
Q11: Global Product Type Performance 
evaluate total volume and profitability of Low Fat vs Regular products 
to understand health trends 
*/
WITH AllSales AS (
    SELECT product_id, quantity FROM Sales_2017
    UNION ALL
    SELECT product_id, quantity FROM Sales_2018
)
SELECT 
    CASE WHEN p.low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS Product_Type,
    SUM(s.quantity) AS Total_Items_Sold,
    FORMAT(SUM(s.quantity * p.product_retail_price), 'C', 'en-US') AS Total_Revenue, 
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Total_Profit,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)) / NULLIF(SUM(s.quantity), 0), 'C', 'en-US') AS Profit_Per_Item,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)) / NULLIF(SUM(s.quantity * p.product_retail_price), 0), 'P') AS Profit_Margin 
FROM AllSales s
JOIN Products p ON s.product_id = p.product_id
GROUP BY p.low_fat;

/* 
Q12: Regional Product Type Breakdown
Analyze volume and profit margins of health categories across countries for localized marketing strategies 
*/
WITH AllSales AS (
    SELECT customer_id, product_id, quantity FROM Sales_2017
    UNION ALL
    SELECT customer_id, product_id, quantity FROM Sales_2018
)
SELECT 
    c.customer_country,
    CASE WHEN p.low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS Product_Type,
    SUM(s.quantity) AS Total_Items_Sold,
    FORMAT(SUM(s.quantity * p.product_retail_price), 'C', 'en-US') AS Total_Revenue, 
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)), 'C', 'en-US') AS Total_Profit,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)) / NULLIF(SUM(s.quantity), 0), 'C', 'en-US') AS Profit_Per_Item,
    FORMAT(SUM(s.quantity * (p.product_retail_price - p.product_cost)) / NULLIF(SUM(s.quantity * p.product_retail_price), 0), 'P') AS Profit_Margin 
FROM AllSales s
JOIN Customers c ON s.customer_id = c.customer_id
JOIN Products p ON s.product_id = p.product_id
GROUP BY c.customer_country, p.low_fat
ORDER BY SUM(s.quantity * (p.product_retail_price - p.product_cost)) DESC, c.customer_country; 


/* 
Q13: Hermanos Brand Deep-Dive -- Evaluate global volume, revenue, and profit margins for the top-performing brand
*/
WITH HermanosSales AS (
    SELECT 
        s.product_id, 
        s.quantity,
        p.low_fat,
        p.product_retail_price,
        p.product_cost
    FROM (
        SELECT product_id, quantity FROM Sales_2017
        UNION ALL
        SELECT product_id, quantity FROM Sales_2018
    ) s
    JOIN Products p ON s.product_id = p.product_id
    WHERE p.product_brand = 'Hermanos'
),
HermanosReturns AS (
    SELECT 
        p.low_fat,
        SUM(r.quantity) AS Total_Returned_Items
    FROM Returns r
    JOIN Products p ON r.product_id = p.product_id
    WHERE p.product_brand = 'Hermanos'
    GROUP BY p.low_fat
),
HermanosStats AS (
    SELECT 
        CASE WHEN hs.low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS Product_Type,
        SUM(hs.quantity) AS Total_Items_Sold,
        SUM(hs.quantity * hs.product_retail_price) AS Total_Revenue, 
        SUM(hs.quantity * hs.product_cost) AS Total_Cost,
        SUM(hs.quantity * (hs.product_retail_price - hs.product_cost)) AS Total_Profit,
        ISNULL(MAX(hr.Total_Returned_Items), 0) AS Total_Returned_Items
    FROM HermanosSales hs
    LEFT JOIN HermanosReturns hr ON hs.low_fat = hr.low_fat
    GROUP BY hs.low_fat
)
SELECT 
    Product_Type,
    Total_Items_Sold,
    FORMAT(Total_Revenue, 'C', 'en-US') AS Total_Revenue,
    FORMAT(Total_Cost, 'C', 'en-US') AS Total_Cost,
    FORMAT(Total_Profit, 'C', 'en-US') AS Total_Profit,
    FORMAT(Total_Profit / NULLIF(Total_Items_Sold, 0), 'C', 'en-US') AS Profit_Per_Item,
    FORMAT(Total_Profit / NULLIF(Total_Revenue, 0), 'P') AS Profit_Margin, 
    FORMAT(CAST(Total_Returned_Items AS FLOAT) / NULLIF(Total_Items_Sold, 0), 'P') AS Return_Rate
FROM HermanosStats;

/* Q14: Hermanos Global Footprint
Regional breakdown of Hermanos brand profitability, margins, and quality metrics 
to guide localized expansion 
*/
WITH HermanosSales AS (
    SELECT 
        s.product_id, 
        s.quantity,
        c.customer_country,
        p.low_fat,
        p.product_retail_price,
        p.product_cost
    FROM (
        SELECT customer_id, product_id, quantity FROM Sales_2017
        UNION ALL
        SELECT customer_id, product_id, quantity FROM Sales_2018
    ) s
    JOIN Customers c ON s.customer_id = c.customer_id
    JOIN Products p ON s.product_id = p.product_id
    WHERE p.product_brand = 'Hermanos'
),
HermanosRegionalReturns AS (
    SELECT 
        st.store_country,
        p.low_fat,
        SUM(r.quantity) AS Total_Returned_Items
    FROM Returns r
    JOIN Stores st ON r.store_id = st.store_id
    JOIN Products p ON r.product_id = p.product_id
    WHERE p.product_brand = 'Hermanos'
    GROUP BY st.store_country, p.low_fat
),
HermanosCountryStats AS (
    SELECT 
        hs.customer_country,
        CASE WHEN hs.low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS Product_Type,
        SUM(hs.quantity) AS Total_Items_Sold,
        SUM(hs.quantity * hs.product_retail_price) AS Total_Revenue,
        SUM(hs.quantity * (hs.product_retail_price - hs.product_cost)) AS Total_Profit,
        ISNULL(MAX(hr.Total_Returned_Items), 0) AS Total_Returned_Items
    FROM HermanosSales hs
    LEFT JOIN HermanosRegionalReturns hr 
        ON hs.customer_country = hr.store_country 
        AND hs.low_fat = hr.low_fat
    GROUP BY hs.customer_country, hs.low_fat
)
SELECT 
    customer_country,
    Product_Type,
    Total_Items_Sold,
    FORMAT(Total_Revenue, 'C', 'en-US') AS Total_Revenue,
    FORMAT(Total_Profit, 'C', 'en-US') AS Total_Profit,
    FORMAT(Total_Profit / NULLIF(Total_Items_Sold, 0), 'C', 'en-US') AS Profit_Per_Item,
    FORMAT(Total_Profit / NULLIF(Total_Revenue, 0), 'P') AS Profit_Margin,
    FORMAT(CAST(Total_Returned_Items AS FLOAT) / NULLIF(Total_Items_Sold, 0), 'P') AS Return_Rate
FROM HermanosCountryStats
ORDER BY Total_Profit DESC;

-- 8. SQL Views & Data Preparation
/*
Customer Data Preparation for Power BI
- Dropped 'customer_acct_num' as it provides no analytical value for business dashboards.
- Merged 'first_name' and 'last_name' into 'full_name' for better visualization.
- Standardized 'gender', 'marital_status', and 'homeowner' to Upper Case for consistent filtering.
- Applied TRIM() to all text fields to remove unnecessary whitespace.
- Handled NULL/Empty values using ISNULL() and NULLIF() for cleaner data integrity.
- Created 'current_age' using DATEDIFF() to enable demographic age-group analysis.
*/
CREATE VIEW vw_CleanCustomers AS
SELECT 
    customer_id,   
    TRIM(first_name) + ' ' + TRIM(last_name) AS full_name, 
    ISNULL(NULLIF(TRIM(customer_address), ''), 'Unknown') AS customer_address,
    TRIM(customer_city) AS customer_city,
    TRIM(customer_state_province) AS customer_state_province,
    TRIM(customer_postal_code) AS customer_postal_code,
    TRIM(customer_country) AS customer_country,
    CAST(birthdate AS DATE) AS birthdate,
    UPPER(ISNULL(NULLIF(marital_status, ''), 'U')) AS marital_status, 
    yearly_income,
    UPPER(gender) AS gender,
    total_children,
    num_children_at_home,
    TRIM(education) AS education,
    CAST(acct_open_date AS DATE) AS acct_open_date,
    TRIM(member_card) AS member_card,
    TRIM(occupation) AS occupation,
    UPPER(homeowner) AS homeowner,
    
    DATEDIFF(YEAR, CAST(birthdate AS DATE), GETDATE()) AS current_age
FROM Customers;

/* 
Product Data Preparation for Power BI
- Standardized product names and brands using TRIM() to ensure clean grouping in visuals.
- Applied CAST(DECIMAL) to prices and costs for precise financial calculations.
- Transformed 'low_fat' and 'recyclable' flags into descriptive text labels ('Low Fat' vs 'Regular') for user-friendly reporting.
- Calculated 'unit_profit' at the SQL level to optimize Power BI performance.
*/
CREATE VIEW vw_CleanProducts AS
SELECT 
    product_id,
    TRIM(product_brand) AS product_brand,
    TRIM(product_name) AS product_name,
    product_sku,
    CAST(product_retail_price AS DECIMAL(10,2)) AS retail_price,
    CAST(product_cost AS DECIMAL(10,2)) AS product_cost,
    product_weight,
    CASE WHEN recyclable = 1 THEN 'Recyclable' ELSE 'Non-Recyclable' END AS recyclable_status,
    CASE WHEN low_fat = 1 THEN 'Low Fat' ELSE 'Regular' END AS fat_content,

    CAST((product_retail_price - product_cost) AS DECIMAL(10,2)) AS unit_profit
FROM Products;

/* 
Store & Region Data Preparation (Denormalization for Star Schema)
- Combined all columns from 'Stores' and 'Region' tables to create a comprehensive Dimension table.
- A LEFT JOIN was used to ensure all stores are included in the view even if they lack a matching region_id.
- Dropped 'region_id' from the final view to avoid redundancy after performing the LEFT JOIN.
- Formatted 'first_opened_date' and 'last_remodel_date' as DATE types for time-based store performance analysis.
- Calculated 'display_area_pct' to measure space efficiency across different store types.
*/
CREATE VIEW vw_CleanStores AS
SELECT 
    st.store_id,
    st.store_name,
    st.store_type,
    st.store_street_address,
    st.store_city,
    st.store_state,
    st.store_country,
    st.store_phone,
    r.sales_district,
    r.sales_region,
    CAST(st.first_opened_date AS DATE) AS first_opened_date,
    CAST(st.last_remodel_date AS DATE) AS last_remodel_date,
    st.total_sqft,
    st.grocery_sqft,

    CAST((st.grocery_sqft * 1.0 / st.total_sqft) * 100 AS DECIMAL(5,2)) AS display_area_pct
FROM Stores st
LEFT JOIN Region r ON st.region_id = r.region_id;

/* 
Calendar Dimension Table Preparation
- Standardized 'date' as 'date_key' to serve as the primary link for fact tables.
- Extracted time attributes (Year, Month, Quarter, Day Name) to enable granular time-series analysis.
- Used DATENAME() for readable labels (e.g., 'January', 'Monday') in dashboard slicers.
*/
CREATE VIEW vw_CleanCalendar AS
SELECT 
    CAST(date AS DATE) AS date_key,
    YEAR(CAST(date AS DATE)) AS year,
    MONTH(CAST(date AS DATE)) AS month_num,
    DATENAME(MONTH, CAST(date AS DATE)) AS month_name,
    DATEPART(QUARTER, CAST(date AS DATE)) AS quarter,
    DATENAME(WEEKDAY, CAST(date AS DATE)) AS day_name
FROM Calendar;

/* 
Returns Fact Table Preparation
- Formatted 'return_date' to DATE type to ensure a proper relationship with the Calendar table.
*/
CREATE VIEW vw_CleanReturns AS
SELECT 
    CAST(return_date AS DATE) AS return_date,
    product_id,
    store_id,
    quantity
FROM Returns;

/* 
Unified Sales Fact Table (2017-2018)
- Combined Sales_2017 and Sales_2018 using UNION ALL
- Casted all date fields to DATE type for consistent joining with the Calendar dimension
*/
CREATE VIEW vw_AllSalesFact AS
SELECT 
    CAST(transaction_date AS DATE) AS transaction_date,
    CAST(stock_date AS DATE) AS stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM Sales_2017
UNION ALL
SELECT 
    CAST(transaction_date AS DATE) AS transaction_date,
    CAST(stock_date AS DATE) AS stock_date,
    product_id,
    customer_id,
    store_id,
    quantity
FROM Sales_2018;

/* 
Demographic Analysis Preparation:
Retrieve the minimum and maximum customer ages calculated dynamicly based on the last transaction date
This range (Youngest & Oldest) is used to define accurate, data-driven thresholds for the Age Group segmentation
*/
WITH AllSales AS (
    SELECT transaction_date FROM Sales_2017
    UNION ALL
    SELECT transaction_date FROM Sales_2018
),
MaxTransaction AS (
    SELECT MAX(transaction_date) AS Last_Date FROM AllSales
),
CustomerAges AS (
    SELECT 
        DATEDIFF(YEAR, CAST(c.birthdate AS DATE), (SELECT Last_Date FROM MaxTransaction)) AS Age
    FROM Customers c
)
SELECT 
    MIN(Age) AS Youngest_Customer_Age,
    MAX(Age) AS Oldest_Customer_Age   
FROM CustomerAges;

/* CUSTOMER VIEW ENHANCEMENT
Added Features:
-- 1) RFM Segmentation: To group customers based on buying behavior (Recency, Frequency, Monetary)
-- 2) Age Grouping: To analyze customer demographics (Middle Age, Senior, etc.)
-- 3) Income Midpoint: Converted text income ranges to numeric values for Power BI aggregations
*/
ALTER VIEW vw_CleanCustomers AS
WITH AllSales AS (
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2017
    UNION ALL
    SELECT customer_id, transaction_date, quantity, product_id FROM Sales_2018
),
RFM_Base AS (
    SELECT 
        s.customer_id,
        DATEDIFF(DAY, MAX(s.transaction_date), (SELECT MAX(transaction_date) FROM AllSales)) AS Recency,
        COUNT(DISTINCT s.transaction_date) AS Frequency,
        SUM(s.quantity * p.product_retail_price) AS Monetary
    FROM AllSales s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY s.customer_id
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM RFM_Base
),
RFM_Final AS (
    SELECT 
        customer_id,
        Recency,
        Frequency,
        Monetary,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'VIP / Champions'
            WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score < 3 THEN 'New / Promising'
            WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk / Cant Lose Them'
            ELSE 'Lost / Hibernating'
        END AS Customer_Segment
    FROM RFM_Scores
)
SELECT 
    c.customer_id,   
    TRIM(c.first_name) + ' ' + TRIM(c.last_name) AS full_name, 
    ISNULL(NULLIF(TRIM(c.customer_address), ''), 'Unknown') AS customer_address,
    TRIM(c.customer_city) AS customer_city,
    TRIM(c.customer_state_province) AS customer_state_province,
    TRIM(c.customer_postal_code) AS customer_postal_code,
    TRIM(c.customer_country) AS customer_country,
    CAST(c.birthdate AS DATE) AS birthdate,
    DATEDIFF(YEAR, CAST(c.birthdate AS DATE), (SELECT MAX(transaction_date) FROM AllSales)) AS current_age,
    -- Age Group
    CASE 
        WHEN DATEDIFF(YEAR, c.birthdate, (SELECT MAX(transaction_date) FROM AllSales)) < 35 THEN 'Young Adult'
        WHEN DATEDIFF(YEAR, c.birthdate, (SELECT MAX(transaction_date) FROM AllSales)) BETWEEN 35 AND 50 THEN 'Middle Age'
        WHEN DATEDIFF(YEAR, c.birthdate, (SELECT MAX(transaction_date) FROM AllSales)) BETWEEN 51 AND 65 THEN 'Senior Adult'
        ELSE 'Old'
    END AS age_group,

    UPPER(ISNULL(NULLIF(c.marital_status, ''), 'U')) AS marital_status, 
    c.yearly_income,
    -- Income Midpoint
    CASE 
        WHEN c.yearly_income = '$10K - $30K' THEN 20000
        WHEN c.yearly_income = '$30K - $50K' THEN 40000
        WHEN c.yearly_income = '$50K - $70K' THEN 60000
        WHEN c.yearly_income = '$70K - $90K' THEN 80000
        WHEN c.yearly_income = '$90K - $110K' THEN 100000
        WHEN c.yearly_income = '$110K - $130K' THEN 120000
        WHEN c.yearly_income = '$130K - $150K' THEN 140000
        WHEN c.yearly_income = '$150K +' THEN 180000
        ELSE NULL
    END AS income_midpoint,
    
    UPPER(c.gender) AS gender,
    c.total_children,
    c.num_children_at_home,
    TRIM(c.education) AS education,
    CAST(c.acct_open_date AS DATE) AS acct_open_date,
    TRIM(c.member_card) AS member_card,
    TRIM(c.occupation) AS occupation,
    UPPER(c.homeowner) AS homeowner,
    -- RFM columns
    ISNULL(r.Recency, 0) AS Recency,
    ISNULL(r.Frequency, 0) AS Frequency,
    ISNULL(r.Monetary, 0) AS Monetary,
    ISNULL(r.RFM_Cell, '111') AS RFM_Cell,
    ISNULL(r.Customer_Segment, 'Lost / Hibernating') AS Customer_Segment
FROM Customers c
LEFT JOIN RFM_Final r ON c.customer_id = r.customer_id;

select * from vw_CleanCustomers

-- 9. CREATE STORED PROCEDURE TO AUTOMATE INDEXES
CREATE PROCEDURE dbo.sp_Run_PostLoad_Pipeline
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    PRINT 'Starting Database Optimization...';

    -- 1) Create Index on Sales_2017 if it does not exist
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sales2017_Product_Customer_Store')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Sales2017_Product_Customer_Store 
        ON dbo.Sales_2017 (product_id, customer_id, store_id);
        PRINT 'Index on Sales_2017 created.';
    END
    ELSE 
    BEGIN
        PRINT 'Index on Sales_2017 already exists.';
    END;

    -- 2) Create Index on Sales_2018 if it does not exist
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sales2018_Product_Customer_Store')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Sales2018_Product_Customer_Store 
        ON dbo.Sales_2018 (product_id, customer_id, store_id);
        PRINT 'Index on Sales_2018 created.';
    END
    ELSE 
    BEGIN
        PRINT 'Index on Sales_2018 already exists.';
    END;

    PRINT 'Optimization done. Ready for Power BI!';
END;

-- Execute the procedure to build performance indexes
EXEC dbo.sp_Run_PostLoad_Pipeline;

-- 10. POWER BI MEASURES vs DATABASE TOTALS

-- 1) m_sales
SELECT 
    COUNT(*) AS [Total Sales], 
    SUM(s.quantity) AS [Total Quantity],
    FORMAT(SUM(s.quantity * p.retail_price), 'C', 'en-US') AS [Total Revenue],
    FORMAT(SUM(s.quantity * (p.retail_price - p.product_cost)), 'C', 'en-US') AS [Total Profit],
    FORMAT(SUM(s.quantity * (p.retail_price - p.product_cost)) / SUM(s.quantity * p.retail_price), 'P') AS [Profit Margin %],
    FORMAT(CAST((SELECT SUM(quantity) FROM vw_CleanReturns) AS FLOAT) / SUM(s.quantity), 'P') AS [Return Rate],
    FORMAT(SUM(s.quantity * p.retail_price) / COUNT(*), 'C', 'en-US') AS [Avg Order Value]
FROM vw_AllSalesFact s
JOIN vw_CleanProducts p ON s.product_id = p.product_id;

-- YOY Revenue Change & MOM Revenue Change
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(transaction_date) AS SaleYear,
        MONTH(transaction_date) AS SaleMonth,
        SUM(s.quantity * p.retail_price) AS Revenue
    FROM vw_AllSalesFact s
    JOIN vw_CleanProducts p ON s.product_id = p.product_id
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
),
GrowthAnalysis AS (
    SELECT *,
        LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth) AS PrevMonthRevenue,
        LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth) AS PrevYearRevenue
    FROM MonthlyRevenue
)
SELECT 
    SaleYear,
    SaleMonth,
    FORMAT(Revenue, 'C', 'en-US') AS Monthly_Revenue,
    FORMAT((Revenue - PrevMonthRevenue) / NULLIF(PrevMonthRevenue, 0), 'P') AS [MoM Revenue Change],
    FORMAT((Revenue - PrevYearRevenue) / NULLIF(PrevYearRevenue, 0), 'P') AS [YoY Revenue Change]
FROM GrowthAnalysis
ORDER BY SaleYear DESC, SaleMonth DESC;

-- 2) m_customer
SELECT 
    COUNT(customer_id) AS [Total Customer],
    SUM(CASE WHEN marital_status = 'M' THEN 1 ELSE 0 END) AS [Married Customers],
    CAST(SUM(CASE WHEN homeowner = 'Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(10,4)) AS [Homeowners %],
    AVG(income_midpoint) AS [Avg Yearly_Income],
    -- Average Customer Value
    (SELECT SUM(s.quantity * p.retail_price) 
     FROM vw_AllSalesFact s 
     JOIN vw_CleanProducts p ON s.product_id = p.product_id) 
     / COUNT(customer_id) AS [Avg Customer Value]
FROM vw_CleanCustomers;

-- 3) m_products
SELECT 
    COUNT(product_id) AS [Total Product],
    COUNT(DISTINCT product_brand) AS [Total Brand],
    -- Recyclable vs Non
    SUM(CASE WHEN recyclable_status = 'Recyclable' THEN 1 ELSE 0 END) AS [Recyclable Products],
    SUM(CASE WHEN recyclable_status = 'Non-Recyclable' THEN 1 ELSE 0 END) AS [Non-Recyclable Products],
    -- Averages
    AVG(retail_price) AS [Avg Product Value],
    AVG(product_cost) AS [Avg Product Cost],
    AVG(unit_profit) AS [Avg Unit Profit]
FROM vw_CleanProducts;

-- 4) m_store
SELECT 
    COUNT(store_id) AS [Total Store],
    COUNT(DISTINCT store_type) AS [Total Store Types],
    COUNT(DISTINCT store_city) AS [Total Cities],
    -- Averages
    AVG(total_sqft) AS [Avg Store Size],
    AVG(grocery_sqft) AS [Avg Grocery], 
    -- Revenue Per Store 
    (SELECT SUM(s.quantity * p.retail_price) 
     FROM vw_AllSalesFact s 
     JOIN vw_CleanProducts p ON s.product_id = p.product_id) 
     / COUNT(store_id) AS [Average Store Revenue],
    -- Profit Per Store 
    (SELECT SUM(s.quantity * (p.retail_price - p.product_cost)) 
     FROM vw_AllSalesFact s 
     JOIN vw_CleanProducts p ON s.product_id = p.product_id) 
     / COUNT(store_id) AS [Average Store Profit]
FROM vw_CleanStores;
