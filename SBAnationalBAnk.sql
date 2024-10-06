create database SBAnational;
use SBAnational;
CREATE TABLE Loans (
    LoanNr_ChkDgt BIGINT PRIMARY KEY,
    Name VARCHAR(255),
    City VARCHAR(100),
    State CHAR(2),
    Zip INT,
    Bank VARCHAR(255),
    ApprovalDate DATE,
    ApprovalFY INT,
    DisbursementGross DECIMAL(12, 2),
    SBA_Appv DECIMAL(12, 2),
    MIS_Status VARCHAR(50),
    LowDoc CHAR(1)
);
INSERT INTO Loans (LoanNr_ChkDgt, Name, City, State, Zip, Bank, ApprovalDate, ApprovalFY, DisbursementGross, SBA_Appv, MIS_Status, LowDoc)
VALUES 
(1000024006, 'LANDMARK BAR & GRILLE (THE)', 'NEW PARIS', 'IN', 46526, '1ST SOURCE BANK', '1997-02-28', 1997, 40000.00, 32000.00, 'P I F', 'Y'),
(1000034009, 'WHITLOCK DDS, TODD M.', 'BLOOMINGTON', 'IN', 47401, 'GRANT COUNTY STATE BANK', '1997-02-28', 1997, 287000.00, 215250.00, 'P I F', 'N'),
(1000044001, 'BIG BUCKS PAWN & JEWELRY, LLC', 'BROKEN ARROW', 'OK', 74012, '1ST NATL BK & TR CO OF BROKEN', '1997-02-28', 1997, 35000.00, 28000.00, 'P I F', 'Y'),
(1000054004, 'ANASTASIA CONFECTIONS, INC.', 'ORLANDO', 'FL', 32801, 'FLORIDA BUS. DEVEL CORP', '1997-02-28', 1997, 229000.00, 229000.00, 'P I F', 'N'),
(1000064005, 'SMITH MACHINE SHOP', 'FORT WORTH', 'TX', 76102, 'TEXAS CAPITAL BANK', '1997-02-28', 1997, 50000.00, 40000.00, 'CHGOFF', 'Y');

select * from Loans;
-- Average DisbursementGross and SBA_Appv for each Loan Outcome --
SELECT MIS_Status, 
       AVG(DisbursementGross) AS Avg_DisbursementGross, 
       AVG(SBA_Appv) AS Avg_SBA_Appv
FROM Loans
GROUP BY MIS_Status;
-- Count of LowDoc (Y/N) for each Loan Outcome: --
SELECT MIS_Status, 
       LowDoc, 
       COUNT(*) AS LoanCount
FROM Loans
GROUP BY MIS_Status, LowDoc;

-- Step 2: Use a CTE to rank top 5 customers by bank balance
WITH Ranked_Customers AS (
    SELECT 
        LoanNr_ChkDgt, 
        Name, 
         DisbursementGross,
        ROW_NUMBER() OVER (ORDER BY DisbursementGross DESC) AS Ranks
    FROM Loans
    WHERE MIS_Status = 'P I F'  -- Only select customers who have not defaulted
)
-- Select the top 5 customers by bank balance
SELECT 
    LoanNr_ChkDgt, 
    Name, 
   DisbursementGross,
    Ranks

FROM Ranked_Customers;

-- Step 3: Combine eligibility check and ranking
WITH Ranked_Customers AS (
    SELECT 
        LoanNr_ChkDgt, 
        Name, 
        DisbursementGross, 
        ROW_NUMBER() OVER (ORDER BY DisbursementGross DESC) AS Ranks
    FROM Loans
    WHERE MIS_Status = 'P I F'  -- Only select customers who have not defaulted
)
-- Select and combine eligibility and ranking
SELECT 
    L.LoanNr_ChkDgt, 
    L.Name, 
    L.City, 
    L.State, 
    L.Zip, 
    L.Bank, 
    L.ApprovalDate, 
    L.DisbursementGross, 
    L.SBA_Appv, 
    L.MIS_Status, 
    L.LowDoc,
    CASE
        WHEN L.SBA_Appv > 50000 AND L.MIS_Status = 'P I F' THEN 'Eligible'
        ELSE 'Not Eligible'
    END AS Loan_Eligibility,
    RC.Ranks
FROM Loans L
LEFT JOIN Ranked_Customers RC
    ON L.LoanNr_ChkDgt = RC.LoanNr_ChkDgt
WHERE RC.Ranks <= 5 OR RC.Ranks IS NULL;  -- Show top 5 ranked customers or all customers for eligibility


