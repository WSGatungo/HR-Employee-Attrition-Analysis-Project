-- #1 Create the Database
CREATE DATABASE hr_analytics;
USE hr_analytics;

-- #2 Verify the Import: Ensure all 1,470 records made it in safely.
SELECT COUNT(*) FROM hr_employee_attrition;

-- #3 EDA: Checking the Shape and Data Types of our dataset
DESCRIBE hr_employee_attrition;

-- #4 Checking for Missing Values (Nulls) in key columns
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS missing_employee_ids,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS missing_attrition,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS missing_department,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS missing_income
FROM hr_employee_attrition;

-- #5 Checking for Duplicate Records - To check for duplicate rows, you need to look at your unique identifier. 
-- #In this dataset, EmployeeNumber acts as the primary key. If any EmployeeNumber appears more than once, you have duplicate data.
SELECT 
    EmployeeNumber, 
    COUNT(*) AS occurrence_count
FROM hr_employee_attrition
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;

-- # This is a very common issue caused by a UTF-8 BOM (Byte Order Mark) that gets embedded in the first column name when the CSV file is exported/saved with certain encoding.
-- Rename the column (column is not named Age, but ï»¿Age)
ALTER TABLE hr_employee_attrition 
CHANGE `ï»¿Age` Age INT;
-- #6 To keep your project professional, create a clean view that drops static columns (EmployeeCount, Over18, StandardHours) and converts Attrition and OverTime into binary numeric flags (1 or 0). 
CREATE VIEW vw_hr_attrition_clean AS
SELECT 
    EmployeeNumber,
    Age,
    Department,
    JobRole,
    MaritalStatus,
    NumCompaniesWorked,
    TotalWorkingYears,
    TrainingTimesLastYear,
    MonthlyIncome,
    YearsAtCompany,
    YearsInCurrentRole,
    YearsSinceLastPromotion,
    YearsWithCurrManager,
    EnvironmentSatisfaction,
    JobSatisfaction,
    WorkLifeBalance,
    PerformanceRating,
    CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END AS Attrition_Flag,
    CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END AS OverTime_Flag
FROM hr_employee_attrition;

-- STEP 3: Deliverable 1: Top Factors Correlated with Attrition
-- We can find the drivers by checking the attrition rate across different employee sentiment and behavior groups.
-- #Impact of Overtime:
SELECT OverTime_Flag, COUNT(*) as Emp_Count, ROUND(AVG(Attrition_Flag)*100, 2) as Attrition_Rate
FROM vw_hr_attrition_clean GROUP BY OverTime_Flag;

-- Impact of Environment/Job Satisfaction (Low vs High):
SELECT JobSatisfaction, COUNT(*) as Emp_Count, ROUND(AVG(Attrition_Flag)*100, 2) as Attrition_Rate
FROM vw_hr_attrition_clean GROUP BY JobSatisfaction ORDER BY JobSatisfaction;

-- Deliverable 2: Comparison Across Segments (Dept, Salary, Tenure)
-- Departmental Attrition:
SELECT Department, COUNT(*) as Total_Employees, SUM(Attrition_Flag) as Exits,
       ROUND(AVG(Attrition_Flag)*100, 2) as Attrition_Rate
FROM vw_hr_attrition_clean GROUP BY Department ORDER BY Attrition_Rate DESC;

-- Salary Bands & Tenure Brackets: Use CASE WHEN to bucket the continuous numbers to see where the risk is highest.
SELECT 
    CASE 
        WHEN MonthlyIncome < 4000 THEN '1. Low (<$4k)'
        WHEN MonthlyIncome BETWEEN 4000 AND 8000 THEN '2. Mid ($4k-$8k)'
        ELSE '3. High (>$8k)'
    END AS Salary_Band,
    ROUND(AVG(Attrition_Flag)*100, 2) as Attrition_Rate
FROM vw_hr_attrition_clean GROUP BY 1 ORDER BY 1;