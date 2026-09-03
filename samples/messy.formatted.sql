SELECT o.orderid, o.orderdate, c.companyname AS Customer, SUM(od.quantity * od.unitprice) AS Total
FROM dbo.orders o
INNER JOIN dbo.customers c
    ON c.customerid = o.customerid
LEFT OUTER JOIN dbo.[Order Details] od
    ON od.orderid = o.orderid
WHERE o.orderdate >= '2024-01-01' AND o.status IN (1, 2, 3) AND (c.country = 'ZA' OR c.country = 'US')
GROUP BY o.orderid, o.orderdate, c.companyname
HAVING SUM(od.quantity * od.unitprice) > 1000
ORDER BY Total DESC
GO

-- build a summary
CREATE PROCEDURE dbo.usp_OrderSummary
    @from DATETIME,
    @to DATETIME = NULL,
    @minTotal MONEY = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @rows INT = 0, @msg NVARCHAR(200) = N'ok';
    IF @to IS NULL
        SET @to = GETDATE()
    BEGIN TRY
        SELECT CASE WHEN t.Total > 10000 THEN 'A' WHEN t.Total > 1000 THEN 'B' ELSE 'C' END AS Band, COUNT(*) AS Orders
        FROM (
            SELECT o.orderid, SUM(od.quantity * od.unitprice) AS Total
            FROM dbo.orders o
            JOIN dbo.[Order Details] od
                ON od.orderid = o.orderid
            WHERE o.orderdate BETWEEN @from AND @to
            GROUP BY o.orderid
        ) t
        WHERE t.Total >= @minTotal
        GROUP BY CASE WHEN t.Total > 10000 THEN 'A' WHEN t.Total > 1000 THEN 'B' ELSE 'C' END;
        SET @rows = @@ROWCOUNT
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
    UPDATE dbo.AuditLog
    SET LastRun = GETDATE(), RowCount = @rows, Message = @msg
    WHERE JobName = 'OrderSummary'
    RETURN @rows
END
GO

CREATE TABLE dbo.Widget
(
    WidgetId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(18, 2) NULL,
    CreatedUtc DATETIME2(3) NOT NULL CONSTRAINT DF_Widget_CreatedUtc DEFAULT (SYSUTCDATETIME())
)
GO

WITH recent AS (
    SELECT TOP (100) *
    FROM dbo.orders
    WHERE orderdate > DATEADD(DAY, -30, GETDATE())
)
SELECT r.orderid, r.orderdate
FROM recent r
WHERE EXISTS (
    SELECT 1
    FROM dbo.[Order Details] d
    WHERE d.orderid = r.orderid
)
