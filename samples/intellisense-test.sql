/* =============================================================================
   Jarvis IntelliSense — a scratch database to try it against.

   Run PART 1 once. Then work through PARTS 2 and 3 by hand, pressing the keys
   where it says. PART 4 drops the lot again.

   Everything lives in its own database, so nothing of yours is touched.
   ============================================================================= */


/* ---------------------------------------------------------------------------
   PART 1 — set up.  Run this, then make sure the query window is ON JarvisDemo
                     (the USE below does it, or pick it in the toolbar).
   --------------------------------------------------------------------------- */

IF DB_ID('JarvisDemo') IS NULL
    CREATE DATABASE JarvisDemo;
GO

USE JarvisDemo;
GO

-- A plain parent/child pair: one foreign key, which is the easy case.
CREATE TABLE dbo.Customers
(
    CustomerId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
    Name        NVARCHAR(200)     NOT NULL,
    Region      VARCHAR(50)       NULL
);
GO

-- Deliberately mixed: an identity, a computed column and a rowversion, none of
-- which may be written to. The INSERT and UPDATE completions must leave all three out.
CREATE TABLE dbo.Orders
(
    OrderId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
    OrderDate    DATETIME2(3)      NOT NULL CONSTRAINT DF_Orders_Date DEFAULT (SYSUTCDATETIME()),
    CustomerId   INT               NOT NULL CONSTRAINT FK_Orders_Customers
                                            REFERENCES dbo.Customers (CustomerId),
    Total        DECIMAL(18,2)     NOT NULL,
    TaxRate      DECIMAL(5,4)      NOT NULL CONSTRAINT DF_Orders_Tax DEFAULT (0.15),
    TotalWithTax AS (Total * (1 + TaxRate)),
    RowVer       ROWVERSION        NOT NULL
);
GO

-- Two foreign keys to the same table. Jarvis must refuse to choose between them.
CREATE TABLE dbo.Shipments
(
    ShipmentId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Shipments PRIMARY KEY,
    BillToCustomerId INT NOT NULL CONSTRAINT FK_Shipments_BillTo
                                  REFERENCES dbo.Customers (CustomerId),
    ShipToCustomerId INT NOT NULL CONSTRAINT FK_Shipments_ShipTo
                                  REFERENCES dbo.Customers (CustomerId)
);
GO

-- A two column key, so the predicate has to come out as two equalities in order.
CREATE TABLE dbo.Invoices
(
    Company   VARCHAR(10) NOT NULL,
    InvoiceNo INT         NOT NULL,
    Issued    DATE        NOT NULL,
    CONSTRAINT PK_Invoices PRIMARY KEY (Company, InvoiceNo)
);
GO

CREATE TABLE dbo.InvoiceLines
(
    Company    VARCHAR(10)   NOT NULL,
    InvoiceNo  INT           NOT NULL,
    LineNo     INT           NOT NULL,
    Amount     DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_InvoiceLines PRIMARY KEY (Company, InvoiceNo, LineNo),
    CONSTRAINT FK_InvoiceLines_Invoices FOREIGN KEY (Company, InvoiceNo)
        REFERENCES dbo.Invoices (Company, InvoiceNo)
);
GO

-- Points at itself. Which alias is the manager cannot be read off the names,
-- so Jarvis must leave this one alone.
CREATE TABLE dbo.Employees
(
    EmployeeId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Employees PRIMARY KEY,
    Name       NVARCHAR(200)     NOT NULL,
    ManagerId  INT               NULL CONSTRAINT FK_Employees_Manager
                                      REFERENCES dbo.Employees (EmployeeId)
);
GO

-- Related to nothing at all.
CREATE TABLE dbo.Holidays
(
    HolidayId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Holidays PRIMARY KEY,
    TheDate   DATE              NOT NULL
);
GO

-- ---------------------------------------------------------------------------
-- Named schemas, because a database that keeps nothing in dbo is the normal case.
-- ---------------------------------------------------------------------------

IF SCHEMA_ID('Sec') IS NULL EXEC('CREATE SCHEMA Sec');
IF SCHEMA_ID('Pms') IS NULL EXEC('CREATE SCHEMA Pms');
GO

CREATE TABLE Sec.Sec_Tb_Role
(
    RoleId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sec_Tb_Role PRIMARY KEY,
    RoleName NVARCHAR(100)     NOT NULL
);
GO

CREATE TABLE Sec.Sec_Tb_User
(
    UserId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sec_Tb_User PRIMARY KEY,
    UserName NVARCHAR(100)     NOT NULL,
    RoleId   INT               NOT NULL CONSTRAINT FK_Sec_Tb_User_Role
                                        REFERENCES Sec.Sec_Tb_Role (RoleId)
);
GO

CREATE TABLE Pms.Pms_Tb_Patron
(
    PatronId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Pms_Tb_Patron PRIMARY KEY,
    PatronCode VARCHAR(50)       NOT NULL,
    UserId     INT               NOT NULL CONSTRAINT FK_Pms_Tb_Patron_User
                                          REFERENCES Sec.Sec_Tb_User (UserId)
);
GO

-- The same table name in two schemas. Nothing may be assumed about which is meant.
CREATE TABLE Sec.Audit (AuditId INT IDENTITY(1,1) NOT NULL, Detail NVARCHAR(MAX) NULL);
GO
CREATE TABLE Pms.Audit (AuditId INT IDENTITY(1,1) NOT NULL, Note NVARCHAR(MAX) NULL);
GO

PRINT 'Ready. Now run: Jarvis > IntelliSense > Refresh Column Metadata';
GO


/* =============================================================================
   PART 2 — the tests.

   Before the first one: Jarvis > IntelliSense > Refresh Column Metadata.
   Watch the status bar for "JarvisDemo has 12 table(s) and view(s) ready."

   In each test, type the line EXACTLY as shown, leave the caret at the end,
   and press Tab. Ctrl+K, Ctrl+J does the same thing and tells you WHY when
   it declines, so use that whenever something does not happen.
   ============================================================================= */


-- 1. A join from a foreign key. -----------------------------------------------
--    Type this and press Tab at the end of the line.
--    Expect:  ON o.CustomerId = c.CustomerId

SELECT * FROM dbo.Customers c INNER JOIN dbo.Orders o


-- 2. The other way round. ------------------------------------------------------
--    Expect:  ON c.CustomerId = o.CustomerId

SELECT * FROM dbo.Orders o INNER JOIN dbo.Customers c


-- 3. No aliases: the table names are used instead. -----------------------------
--    Expect:  ON Orders.CustomerId = Customers.CustomerId

SELECT * FROM dbo.Customers JOIN dbo.Orders


-- 4. A two column key. ---------------------------------------------------------
--    Expect:  ON l.Company = i.Company AND l.InvoiceNo = i.InvoiceNo

SELECT * FROM dbo.Invoices i JOIN dbo.InvoiceLines l


-- 5. REFUSAL: two keys to the same table. --------------------------------------
--    Expect:  nothing written. Ctrl+K, Ctrl+J says
--             "dbo.Customers and dbo.Shipments are related 2 ways; write the ON yourself."

SELECT * FROM dbo.Customers c JOIN dbo.Shipments s


-- 6. REFUSAL: a table that points at itself. -----------------------------------
--    Expect:  nothing written.

SELECT * FROM dbo.Employees e JOIN dbo.Employees m


-- 7. REFUSAL: nothing relates these two. ---------------------------------------
--    Expect:  nothing. Ctrl+K, Ctrl+J says "no foreign key relates dbo.Holidays..."

SELECT * FROM dbo.Customers c JOIN dbo.Holidays h


-- 8. REFUSAL: the join already has an ON. --------------------------------------
--    Put the caret straight after "o" (before the ON) and press Tab.
--    Expect:  nothing, because there is already a predicate.

SELECT * FROM dbo.Customers c JOIN dbo.Orders o ON 1 = 1


-- 9. An INSERT column list. ----------------------------------------------------
--    Put the caret between the brackets and press Tab.
--    Expect:  OrderDate, CustomerId, Total, TaxRate
--    NOT expected: OrderId (identity), TotalWithTax (computed), RowVer (rowversion)

INSERT INTO dbo.Orders ()


-- 10. The same without brackets. ----------------------------------------------
--     Caret at the end of the line, after the space.
--     Expect:  (OrderDate, CustomerId, Total, TaxRate) written for you.

INSERT INTO dbo.Orders


-- 11. VALUES that follow an explicit column list. -----------------------------
--     Caret at the end, press Tab.
--     Expect:  (@CustomerId, @Total)

INSERT INTO dbo.Orders (CustomerId, Total) VALUES


-- 12. VALUES with no column list: every writable column. ----------------------
--     Expect:  (@OrderDate, @CustomerId, @Total, @TaxRate)

INSERT INTO dbo.Orders VALUES


-- 13. An UPDATE assignment list. ----------------------------------------------
--     Expect:  OrderDate = @OrderDate, CustomerId = @CustomerId,
--              Total = @Total, TaxRate = @TaxRate

UPDATE dbo.Orders SET


-- 14. REFUSAL: a list you have already started. -------------------------------
--     Caret after the comma. Expect nothing; the list is yours now.

INSERT INTO dbo.Orders (OrderDate, )


-- 15. REFUSAL: a half typed word. ---------------------------------------------
--     Caret straight after "Cust". Expect Tab to behave exactly as it always did,
--     which is the whole point: this is when SSMS IntelliSense is showing a list.

SELECT * FROM dbo.Orders o JOIN dbo.Cust


-- ---------------------------------------------------------------------------
-- Named schemas. This is the group to check if you keep nothing in dbo.
-- ---------------------------------------------------------------------------

-- 16. Write the schema in for me. ---------------------------------------------
--     Sec_Tb_User lives in Sec, and the query does not say so. Tab at the end.
--     Expect:  FROM Sec.Sec_Tb_User

SELECT * FROM Sec_Tb_User


-- 17. Press Tab twice: first the schema, then the join. -----------------------
--     1st Tab expect:  JOIN Sec.Sec_Tb_User
--     2nd Tab expect:  ON Sec_Tb_User.RoleId = r.RoleId

SELECT * FROM Sec.Sec_Tb_Role r JOIN Sec_Tb_User


-- 18. A join across two schemas. ----------------------------------------------
--     Expect:  ON p.UserId = u.UserId

SELECT * FROM Sec.Sec_Tb_User u JOIN Pms.Pms_Tb_Patron p


-- 19. Unqualified on BOTH sides still joins. ----------------------------------
--     Neither table is in dbo and neither says its schema. Expect it to work anyway:
--     ON u.RoleId = r.RoleId

SELECT * FROM Sec_Tb_Role r JOIN Sec_Tb_User u


-- 20. A column list for an unqualified table outside dbo. ---------------------
--     Caret between the brackets.
--     Expect:  UserName, RoleId   (UserId is an identity, so it is left out)

INSERT INTO Sec_Tb_User ()


-- 21. REFUSAL: the same name in two schemas. ----------------------------------
--     Expect:  nothing. Ctrl+K, Ctrl+J says
--              "Audit is in 2 schemas (Sec, Pms); write the one you mean."

SELECT * FROM Audit


-- 22. Already qualified: it says so rather than staying silent. ---------------
--     Ctrl+K, Ctrl+J expect: "Sec.Sec_Tb_User is already qualified."

SELECT * FROM Sec.Sec_Tb_User


-- 23. Expand * to columns (the older feature, worth re-checking). -------------
--     Caret on the *, press Tab.
--     Expect:  o.OrderId, o.OrderDate, o.CustomerId, ... (all of them this time)

SELECT * FROM dbo.Orders o


-- 24. Format what you just built. ---------------------------------------------
--     Ctrl+K, Ctrl+D. Try it under Jarvis > Active Style > Jarvis Gold too.

SELECT o.OrderId, c.Name, o.Total FROM dbo.Orders o INNER JOIN dbo.Customers c ON c.CustomerId = o.CustomerId WHERE o.Total > 100


/* =============================================================================
   PART 3 — the completion list.

   First: Jarvis > IntelliSense > Use Jarvis IntelliSense. That switches SSMS's
   own IntelliSense OFF and makes the Jarvis list come up on its own as you type.
   Switching it back off restores SSMS's IntelliSense.

   Ctrl+K, Ctrl+Space opens the list by hand at any time. Arrows move, Tab or
   Enter inserts, Esc closes.
   ============================================================================= */

-- 25. Tables, without knowing the schema. -------------------------------------
--     Caret after FROM, press Ctrl+K, Ctrl+Space.
--     Expect a list headed "Tables and views" holding Sec.Sec_Tb_User,
--     Pms.Pms_Tb_Patron, dbo.Orders and the rest, each showing its schema.
--     Now type  Tb_  and watch it narrow. Enter inserts the QUALIFIED name.

SELECT * FROM 


-- 26. Only one schema's tables. -----------------------------------------------
--     Caret straight after the dot.
--     Expect "Tables in Sec": Audit, Sec_Tb_Role, Sec_Tb_User — bare names,
--     because the schema is already written.

SELECT * FROM Sec.


-- 27. Columns of the table behind an alias. -----------------------------------
--     Caret straight after "u.".
--     Expect "Columns of Sec.Sec_Tb_User" with each column's type on the right,
--     and UserId marked "INT identity".

SELECT u. FROM Sec.Sec_Tb_User u


-- 28. Everything in scope, columns first. -------------------------------------
--     Caret after SELECT. Expect the two tables' columns at the top, qualified
--     u. and r. because there is more than one table, then the aliases, then
--     the rest of the catalogue underneath.

SELECT  FROM Sec.Sec_Tb_User u JOIN Sec.Sec_Tb_Role r ON r.RoleId = u.RoleId


-- 29. A loose match. -----------------------------------------------------------
--     Caret after FROM, open the list, then type  stu
--     Expect Sec.Sec_Tb_User to survive: the letters appear in order.

SELECT * FROM 


-- 30. Escape leaves everything as it was. -------------------------------------
--     Open the list, move around with the arrows, press Esc. Nothing changes.

SELECT * FROM 


/* =============================================================================
   PART 4 — clean up.
   ============================================================================= */

/*
USE master;
GO
ALTER DATABASE JarvisDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE JarvisDemo;
GO
*/



-- 31. Keywords, as you type. ---------------------------------------------------
--     With Use Jarvis IntelliSense ON, type this line and stop after "inn".
--     Expect the list to appear on its own with INNER JOIN as the FIRST row —
--     the whole construct, not a bare INNER. Enter writes both words.

SELECT * FROM Sec.Sec_Tb_User u inn


-- 32. Words run together. ------------------------------------------------------
--     Type "groupby". Expect GROUP BY. Same for "innerjoin", "isnotnull".

SELECT u.RoleId FROM Sec.Sec_Tb_User u groupby


-- 33. Keywords where a statement starts. ---------------------------------------
--     On an empty line, type "sel". Expect SELECT, SELECT DISTINCT, SELECT TOP.



-- 34. A column in scope beats a keyword. ---------------------------------------
--     Type "us" after SELECT. Expect UserName above UNION and UPDATE, because
--     the query being written comes first.

SELECT us FROM Sec.Sec_Tb_User u


-- 35. Functions and types. -----------------------------------------------------
--     "isnu" finds ISNULL. "nvarch" finds NVARCHAR.

DECLARE @x nvarch


-- 36. And back again. ----------------------------------------------------------
--     Switch Use Jarvis IntelliSense OFF. SSMS IntelliSense returns and the
--     Jarvis list stops appearing on its own — Ctrl+K, Ctrl+Space still opens it.


-- ---------------------------------------------------------------------------
-- Procedures, functions and views. Run this first to create them.
-- ---------------------------------------------------------------------------
/*
CREATE OR ALTER PROCEDURE Sec.Sec_Sp_User_Create @UserName NVARCHAR(100), @RoleId INT
AS
BEGIN
    INSERT INTO Sec.Sec_Tb_User (UserName, RoleId) VALUES (@UserName, @RoleId);
END
GO
CREATE OR ALTER PROCEDURE Pms.Pms_Sp_Patron_Create @PatronCode VARCHAR(50), @UserId INT
AS
BEGIN
    INSERT INTO Pms.Pms_Tb_Patron (PatronCode, UserId) VALUES (@PatronCode, @UserId);
END
GO
CREATE OR ALTER FUNCTION Sec.Sec_Fn_UserName (@UserId INT) RETURNS NVARCHAR(100)
AS
BEGIN
    RETURN (SELECT UserName FROM Sec.Sec_Tb_User WHERE UserId = @UserId);
END
GO
CREATE OR ALTER VIEW Sec.Sec_Vw_ActiveUser AS SELECT UserId, UserName FROM Sec.Sec_Tb_User;
GO
*/
-- Then: Jarvis > IntelliSense > Refresh Column Metadata.


-- 37. Procedures after EXEC. ---------------------------------------------------
--     Type "EXEC " then "Sp". Expect Sec.Sec_Sp_User_Create and
--     Pms.Pms_Sp_Patron_Create at the TOP, each marked "procedure".
--     No schema needed: the bare name finds them.

EXEC Sp


-- 38. A procedure has no columns and still appears. ----------------------------
--     Procedures are read by their own query for exactly this reason.

EXEC Pms_Sp_Patron


-- 39. A view is selectable, a procedure is not. --------------------------------
--     After FROM, expect Sec_Vw_ActiveUser above the Sp_ procedures.

SELECT * FROM Sec_


-- 40. A view's columns work behind an alias. -----------------------------------

SELECT v. FROM Sec.Sec_Vw_ActiveUser v


-- 41. A scalar function in a SELECT list. --------------------------------------

SELECT Sec_Fn FROM Sec.Sec_Tb_User


-- 42. Ctrl+Space opens the Jarvis list. ----------------------------------------
--     With Use Jarvis IntelliSense ON, put the caret after FROM and press
--     Ctrl+Space. Expect the Jarvis list, not SSMS's. Ctrl+J does the same.
--     Switch it OFF and those keys go back to SSMS.

SELECT * FROM 


-- 43. The whole predicate after ON. --------------------------------------------
--     Type up to "ON " and stop. With Use Jarvis IntelliSense on the list appears;
--     otherwise Ctrl+K, Ctrl+Space.
--     Expect  u.RoleId = r.RoleId  as the FIRST row, marked with the key name,
--     then the columns of both tables underneath.

SELECT * FROM Sec.Sec_Tb_Role r JOIN Sec.Sec_Tb_User u ON 


-- 44. Two keys: the list offers both. ------------------------------------------
--     Ctrl+K, Ctrl+J REFUSES here — it will not guess between BillTo and ShipTo.
--     The list shows both and lets you pick. That is the difference.

SELECT * FROM dbo.Customers c JOIN dbo.Shipments s ON 


-- 45. A self join offers both directions. --------------------------------------
--     Expect  m.ManagerId = e.EmployeeId  and  m.EmployeeId = e.ManagerId.

SELECT * FROM dbo.Employees e JOIN dbo.Employees m ON 


-- 46. A composite key comes as one row, AND included. ---------------------------

SELECT * FROM dbo.Invoices i JOIN dbo.InvoiceLines l ON 


-- 47. Tab straight after the table name. ---------------------------------------
--     Put the caret at the very end of the line — NO trailing space — and press Tab.
--     Expect  (UserName, RoleId)  written for you. UserId is an identity, so it is
--     left out.

INSERT INTO Sec.Sec_Tb_User


-- 48. Unqualified: two presses. ------------------------------------------------
--     1st Tab expect:  INSERT INTO Sec.Sec_Tb_User
--     2nd Tab expect:  INSERT INTO Sec.Sec_Tb_User (UserName, RoleId)

INSERT INTO Sec_Tb_User


-- 49. And the VALUES to match. -------------------------------------------------
--     Caret right after VALUES, no space. Expect (@UserName, @RoleId).

INSERT INTO Sec.Sec_Tb_User (UserName, RoleId) VALUES


-- 50. A name still being typed is left alone. ----------------------------------
--     Tab here does what Tab always did: "Sec_Tb_U" is not a table.

INSERT INTO Sec_Tb_U


-- 51. Space after ON brings the predicate up on its own. -----------------------
--     Type the two lines below. After you type the space following "ON", expect
--     the list to appear WITHOUT pressing anything, with the predicate first.

SELECT * FROM Sec.Sec_Tb_Role t1
INNER JOIN Sec.Sec_Tb_User t2 ON 


-- 52. And after the other openers. ---------------------------------------------
--     A space after each of these opens the list: FROM, JOIN, INTO, SET, VALUES,
--     WHERE, AND, EXEC, a comma, an opening bracket.

SELECT * FROM 


-- 53. A space anywhere else is left alone. -------------------------------------
--     After a table name comes an alias, so nothing opens here. Type a space at
--     the end and expect no list.

SELECT * FROM Sec.Sec_Tb_User 


-- 54. Aliases, numbered for you. -----------------------------------------------
--     Type up to FROM, pick a table from the list. Expect  Sec.Sec_Tb_Role t1.
--     Then type JOIN and pick another. Expect  t2, not t1 again.

SELECT * FROM 


-- 55. It counts past a gap. ----------------------------------------------------
--     t1 and t3 are taken, so the next one must be t2.

SELECT * FROM Sec.Sec_Tb_Role t1 JOIN Sec.Sec_Tb_User t3 JOIN 


-- 56. An alias you chose is never trodden on. ----------------------------------
--     "u" is not in the t series, so the next table still starts at t1.

SELECT * FROM Sec.Sec_Tb_User u JOIN 


-- 57. REFUSAL: an INSERT target takes no alias. --------------------------------
--     Expect just  Sec.Sec_Tb_User  with nothing after it: "INSERT INTO x t1"
--     does not parse.

INSERT INTO 


-- 58. REFUSAL: an alias is already there. --------------------------------------
--     Put the caret at the end of "Sec_Tb" and pick from the list. Expect the
--     name alone — never "Sec.Sec_Tb_User t1 u".

SELECT * FROM Sec_Tb u
