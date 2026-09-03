select o.orderid,o.orderdate, c.companyname as Customer, sum(od.quantity*od.unitprice) as Total from dbo.orders o inner join dbo.customers c on c.customerid=o.customerid left outer join dbo.[Order Details] od on od.orderid=o.orderid where o.orderdate>='2024-01-01' and o.status in (1,2,3) and (c.country='ZA' or c.country = 'US') group by o.orderid,o.orderdate,c.companyname having sum(od.quantity*od.unitprice)>1000 order by Total desc
go
-- build a summary
create procedure dbo.usp_OrderSummary @from datetime, @to datetime = null, @minTotal money = 0 as
begin
set nocount on;
declare @rows int = 0, @msg nvarchar(200) = N'ok';
if @to is null set @to = getdate()
begin try
select case when t.Total > 10000 then 'A' when t.Total > 1000 then 'B' else 'C' end as Band, count(*) as Orders
from (select o.orderid, sum(od.quantity*od.unitprice) as Total from dbo.orders o join dbo.[Order Details] od on od.orderid = o.orderid where o.orderdate between @from and @to group by o.orderid) t
where t.Total >= @minTotal
group by case when t.Total > 10000 then 'A' when t.Total > 1000 then 'B' else 'C' end;
set @rows = @@rowcount
end try
begin catch
throw;
end catch
update dbo.AuditLog set LastRun = getdate(), RowCount = @rows, Message = @msg where JobName = 'OrderSummary'
return @rows
end
go
create table dbo.Widget(WidgetId int identity(1,1) not null primary key, Name nvarchar(100) not null, Price decimal(18,2) null, CreatedUtc datetime2(3) not null constraint DF_Widget_CreatedUtc default (sysutcdatetime()))
go
with recent as (select top (100) * from dbo.orders where orderdate > dateadd(day,-30,getdate()))
select r.orderid, r.orderdate from recent r where exists (select 1 from dbo.[Order Details] d where d.orderid = r.orderid)
