Create database Bank_Analysis ;

use Bank_Analysis;

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
CREATE TABLE Bank_Analysis_project (
    id INT,
    member_id INT,
    loan_amnt DECIMAL(10,2),
    funded_amnt DECIMAL(10,2),
    funded_amnt_inv DECIMAL(10,2),
    term VARCHAR(20),
    int_rate DECIMAL(5,2),
    installment DECIMAL(10,2),
    grade VARCHAR(5),
    sub_grade VARCHAR(5),
    emp_title VARCHAR(100),
    emp_length VARCHAR(20),
    home_ownership VARCHAR(20),
    annual_inc DECIMAL(15,2),
    verification_status VARCHAR(50),
    issue_d DATE,
    loan_status VARCHAR(50),
    pymnt_plan VARCHAR(5),
    `desc` TEXT,
    purpose VARCHAR(50),
    title VARCHAR(200),
    zip_code VARCHAR(20),
    addr_state VARCHAR(10),
    dti DECIMAL(10,2),
    delinq_2yrs INT,
    earliest_cr_line DATE,
    inq_last_6mths INT,
    mths_since_last_delinq INT,
    mths_since_last_record INT,
    open_acc INT,
    pub_rec INT,
    revol_bal DECIMAL(15,2),
    revol_util DECIMAL(10,2),
    total_acc INT,
    initial_list_status VARCHAR(5),
    out_prncp DECIMAL(15,2),
    out_prncp_inv DECIMAL(15,2),
    total_pymnt DECIMAL(15,2),
    total_pymnt_inv DECIMAL(15,2),
    total_rec_prncp DECIMAL(15,2),
    total_rec_int DECIMAL(15,2),
    total_rec_late_fee DECIMAL(10,2),
    recoveries DECIMAL(10,2),
    collection_recovery_fee DECIMAL(10,2),
    last_pymnt_d DATE,
    last_pymnt_amnt DECIMAL(10,2),
    next_pymnt_d DATE,
    last_credit_pull_d DATE,
    `Year` INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Excel File.csv'
INTO TABLE Bank_Analysis_project
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id,member_id,loan_amnt,funded_amnt,funded_amnt_inv,term,int_rate,installment,
grade,sub_grade,emp_title,emp_length,home_ownership,annual_inc,verification_status,
@issue_d,loan_status,pymnt_plan,`desc`,purpose,title,zip_code,addr_state,dti,
delinq_2yrs,@earliest_cr_line,inq_last_6mths,
@mths_since_last_delinq,
@mths_since_last_record,
open_acc,pub_rec,revol_bal,
@revol_util,
total_acc,initial_list_status,out_prncp,out_prncp_inv,total_pymnt,total_pymnt_inv,
total_rec_prncp,total_rec_int,total_rec_late_fee,recoveries,
collection_recovery_fee,
@last_pymnt_d,
last_pymnt_amnt,
@next_pymnt_d,
@last_credit_pull_d,
Year)

SET
issue_d = NULLIF(@issue_d,''),
earliest_cr_line = NULLIF(@earliest_cr_line,''),
mths_since_last_delinq = NULLIF(NULLIF(@mths_since_last_delinq,''),'NA'),
mths_since_last_record = NULLIF(NULLIF(@mths_since_last_record,''),'NA'),
revol_util = NULLIF(@revol_util,''),
last_pymnt_d = NULLIF(NULLIF(@last_pymnt_d,''),'1900-01-00'),

next_pymnt_d =
CASE
    WHEN @next_pymnt_d REGEXP '^[0-9]+$'
    THEN DATE_ADD('1899-12-30', INTERVAL @next_pymnt_d DAY)
    ELSE NULLIF(NULLIF(@next_pymnt_d,''),'1900-01-00')
END,

last_credit_pull_d = NULLIF(NULLIF(@last_credit_pull_d,''),'1900-01-00');

select * from bank_analysis_project;

select count(*) from bank_analysis_project;


-- KPI-1 Year wise loan amount Stats

SELECT 
    year,

    CONCAT(
        ROUND(SUM(COALESCE(loan_amnt, 0)) / 1000000.0, 2),
        ' M'
    ) AS total_loan_amount_millions,

    ROUND(
        SUM(COALESCE(loan_amnt, 0)) * 100.0
        / SUM(SUM(COALESCE(loan_amnt, 0))) OVER ,
        2
    ) AS loan_amount_percentage
FROM bank_analysis_project
GROUP BY year
ORDER BY year;

-- KPI-2 Grade and sub grade wise revol_bal

SELECT 
    grade,
    sub_grade,

    CONCAT(
        ROUND(SUM(COALESCE(revol_bal, 0)) / 1000000.0, 2),
        ' M'
    ) AS total_revolving_balance_millions,

    ROUND(
        SUM(COALESCE(revol_bal, 0)) * 100.0 
        / SUM(SUM(COALESCE(revol_bal, 0))) OVER ,
        2
    ) AS revol_bal_percentage
FROM bank_analysis_project
GROUP BY grade, sub_grade
ORDER BY grade, sub_grade;

-- KPI-3 Total Payment for Verified Status Vs Total Payment for Non Verified Status

SELECT 
    verification_status,

    CONCAT(
        ROUND(SUM(COALESCE(total_pymnt, 0)) / 1000000.0, 2),
        ' M'
    ) AS total_payment_millions,

    ROUND(
        SUM(COALESCE(total_pymnt, 0)) * 100.0 
        / SUM(SUM(COALESCE(	total_pymnt, 0))) OVER ,
        2
    ) AS payment_percentage
FROM bank_analysis_project
GROUP BY verification_status
ORDER BY SUM(COALESCE(total_pymnt, 0)) DESC;

-- KPI-4 State wise and month wise loan status

SELECT 
    addr_state,
    loan_status,
    COUNT(id) AS total_loans,
    SUM(loan_amnt) AS total_loan_amount
FROM bank_analysis_project
GROUP BY addr_state, loan_status
ORDER BY addr_state, loan_status;

-- KPI-5 Home ownership Vs last payment date stats

SELECT 
    home_ownership,
    YEAR(last_pymnt_d) AS last_payment_year,
    COUNT(id) AS total_loans,

    CONCAT(
        ROUND(SUM(COALESCE(total_pymnt, 0)) / 1000000.0, 2),
        ' M'
    ) AS total_payment_millions,

    ROUND(
        SUM(COALESCE(total_pymnt, 0)) * 100.0
        / SUM(SUM(COALESCE(total_pymnt, 0))) OVER ,
        2
    ) AS payment_percentage
FROM bank_analysis_project
GROUP BY home_ownership, YEAR(last_pymnt_d)
ORDER BY home_ownership, last_payment_year;




