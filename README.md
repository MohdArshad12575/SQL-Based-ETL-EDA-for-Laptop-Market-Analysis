# SQL-Based-ETL-EDA-for-Laptop-Market-Analysis
# 📌 Laptop Data ETL and EDA using SQL

## 📖 Project Overview
This project focuses on **Extract, Transform, and Load (ETL)** and **Exploratory Data Analysis (EDA)** of laptop data using **SQL**. The dataset contains various specifications of laptops, such as brand, type, screen resolution, processor, RAM, storage type, GPU, operating system, weight, and price.

The goal is to:
- Clean and transform raw data using SQL.
- Perform exploratory data analysis (EDA) to derive insights.
- Store and structure the cleaned dataset for further use.

---

## 📂 Dataset Details
The dataset includes details of multiple laptop models with attributes like:
- **Company**: Laptop manufacturer (Apple, HP, Dell, Asus, etc.)
- **TypeName**: Category (Notebook, Ultrabook, etc.)
- **ScreenResolution**: Display specifications (e.g., 1920x1080)
- **CPU**: Processor details
- **RAM**: Memory size
- **Memory**: Storage type (SSD, HDD, Flash)
- **GPU**: Graphics card details
- **Operating System**: Installed OS
- **Weight**: Device weight
- **Price**: Laptop price

---

## 🛠️ ETL Process (Using SQL)
1. **Extract**: The raw data was loaded into a SQL database.
2. **Transform**:
   - Removed missing/duplicate values.
   - Standardized column names.
   - Extracted structured information (CPU brand, storage types, etc.).
   - Converted data formats (e.g., storage size from string to integer).
   - Categorized laptops based on specifications.
3. **Load**: The cleaned data was stored in a structured format.

✅ **Before vs After Cleaning**

Before:
![Image](https://github.com/user-attachments/assets/352f42ad-2d04-4d34-8ae7-8b737cc4f610)
After:
![Image](https://github.com/user-attachments/assets/81b2816a-ddc0-47c4-89ba-2df68ebdc1f3)

![Image](https://github.com/user-attachments/assets/7d2895c9-62e9-46e2-a532-9b394471b6e1)

---

## 📊 EDA Insights (Using SQL)
1. **Brand-wise Distribution**: Identified the most common laptop brands.
2. **Price Analysis**: Determined the price range of laptops by brand and specifications.
3. **Storage Trends**: Checked the dominance of SSD vs HDD.
4. **CPU Performance Trends**: Analyzed the impact of processor types on pricing.
5. **Screen Resolution Analysis**: Explored the relationship between resolution and price.
6. **RAM vs Price Analysis**: Found trends in how RAM affects laptop pricing.
7. **Weight vs Portability**: Evaluated the weight distribution across different categories.

---

## 🏆 Key SQL Queries Used
Here are some key queries used during ETL and EDA:

```sql
-- Extracting CPU brand from full CPU description
SELECT DISTINCT Cpu, 
       CASE 
           WHEN Cpu LIKE '%Intel%' THEN 'Intel'
           WHEN Cpu LIKE '%AMD%' THEN 'AMD'
           ELSE 'Other'
       END AS Cpu_Brand
FROM laptops;

-- Price distribution by laptop brand
SELECT Company, ROUND(AVG(Price), 2) AS Avg_Price, COUNT(*) AS Total_Laptops
FROM laptops
GROUP BY Company
ORDER BY Avg_Price DESC;

-- Identifying most common storage types
SELECT memory_type, COUNT(*) AS Count
FROM laptops
GROUP BY memory_type
ORDER BY Count DESC;
