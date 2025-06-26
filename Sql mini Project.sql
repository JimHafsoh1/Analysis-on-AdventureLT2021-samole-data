--Cleaning SalesLT.Customer

Select*
from SalesLT.Customer
Select MiddleName,FirstName,LastName 
From SalesLT.Customer
where MiddleName is Null

-- Altering and Updating my Table, Setting Nulls in Middlename to Blank in SalesLT.Customer
Update SalesLT.Customer
Set MiddleName=' '
Where MiddleName is Null

Alter Table SalesLT.Customer
Add Full_Name Varchar (50)

Update SalesLT.Customer
Set Full_Name= FirstName+' '+
        Case 
		WHEN MiddleName =' ' Then ' '
		Else MiddleName+ ' '
		End +
		LastName
--Dropping Column that wont be use
Alter Table SalesLT.Customer
Drop Column Suffix
Select*
from SalesLT.Customer

--Creating Revenue column in SalesLT.SalesOrderDetail
Select*
From SalesLT.SalesOrderDetail

--Checking if there is null in 'Orderqty' and 'Unit price' before Calculating Revenue
Select OrderQty, Unitprice
From SalesLT.SalesOrderDetail
Where Unitprice is Null 

--Creating Revenue Column
Alter Table SalesLT.SalesOrderDetail
Add Revenue Int

Update SalesLT.SalesOrderDetail
set Revenue = OrderQty*UnitPrice

--Checking SalesLT.Address to see if there is Null or error
Select*
From SalesLT.Address

Select AddressLine2
From SalesLT.Address
Where AddressLine2 is not null

--Changing Column name In SalesLt.SalesorderHeader , from Shipto AddressID TO AddressId
Exec sp_rename 'SalesLT.SalesOrderHeader.ShipToAddressID', 'AddressID', 'COLUMN';
Select*
From SalesLT.SalesOrderHeader
-- Question 1:- Top 10 Customers order by Revenue
Select top 10 
Full_Name, Revenue, City, CountryRegion
From  SalesLT.SalesOrderHeader
Join SalesLT.SalesOrderDetail on SalesLT.SalesOrderHeader.SalesOrderID=SalesLT.SalesOrderDetail.SalesOrderID
join SalesLT.Address on SalesLT.SalesOrderHeader.AddressID=SalesLT.Address.AddressID
Join  SalesLT.Customer on SalesLT.SalesOrderHeader.CustomerID=SalesLT.Customer.CustomerID
Group by Full_Name, Revenue, City, CountryRegion
Order by Revenue desc

-- Question 2:- 4 Distinct Customer segments using the Total Revenue
With Revenuepercustomer As(
   Select  soh.CustomerID,CompanyName, Revenue
   From SalesLT.Customer c
   Join SalesLT.SalesOrderHeader soh on c.CustomerID=soh.CustomerID
   Join SalesLT.SalesOrderDetail sod on soh .SalesOrderID=sod.SalesOrderID
   Group by soh.CustomerID, CompanyName, Revenue
   ),
     RankedCustomer As (
	 Select*,
	 NTILE(4) Over(order by Revenue DESC) as RevenueQuartile
	 From Revenuepercustomer
	 ),
	 Segmentedcustomer As(
	 Select CustomerID, CompanyName, Revenue,
	 Case RevenueQuartile
	 When 1 then 'Platinum'
	 When 2 then 'Gold'
	 When 3 then 'Silver'
	 When 4 then 'Bronze'
	 End as Segment
	 From RankedCustomer
	 )
	 Select*
	 From Segmentedcustomer
	 Order by Revenue Desc
	 

--Cleaning Data to use for Question 3
Select*
From SalesLT.Product
Select*
From SalesLT.SalesOrderHeader
Select OrderDate
From SalesLT.SalesOrderHeader
Where OrderDate is null

Select Name, ProductCategoryID
From SalesLT.Product
Where ProductCategoryID is null
Update  SalesLT.Product
Set Size= ' ' 
Where Size is null

Select Name,
     Left(Name,
	 Case when charindex(',', Name)>0 Then Charindex(',', Name)-1
	 Else Len(Name) 
	 End
	  ) as CleanedValue
	  From SalesLT.Product
Alter Table SalesLT.Product
Add ProductName Varchar(100)

UPDATE SalesLT.Product
SET ProductName = LTRIM(RTRIM(
    LEFT(Name,
        CASE 
            WHEN CHARINDEX(',', Name) > 0 Then CHARINDEX(',',Name) -1
            ELSE LEN(Name)
        END
    )
));

Alter Table SalesLT.ProductCategory
  Add CategorygroupName Varchar(50)
  UPDATE SalesLT.ProductCategory
   SET CategorygroupName = 
    CASE ParentProductCategoryID
        WHEN 1 THEN 'Bike'
        WHEN 2 THEN 'Component'
        WHEN 3 THEN 'Clothing'
        WHEN 4 THEN 'Accessories'
        ELSE 'Other'
    END;
  Select *
  From SalesLT.ProductCategory
  Alter Table SalesLT.ProductCategory
  Drop ProductCategoryName

  Select Distinct Name
  From SalesLT.ProductCategory


--Question 3:-What Product with Their respective categories Did our Customers buy on our last day of business?
  WITH LastOrderDate AS (
    SELECT MAX(OrderDate) AS LastDay
    FROM SalesLT.SalesOrderHeader
)
 SELECT c.CustomerID, p.ProductID, ProductName, CategorygroupName, OrderDate
  From SalesLT.SalesOrderHeader soh
  Join SalesLT.Customer c on soh.CustomerID=c.CustomerID
  Join SalesLT.SalesOrderDetail sod on soh.SalesOrderID=sod.SalesOrderID
  Join SalesLT.Product p on sod.ProductID=p.ProductID
  Join SalesLT.ProductCategory spc on p.ProductCategoryID=spc.ProductCategoryID
  Order by OrderDate, CustomerID

  -- Question 4:- Create a view that stores customer segment that stores the details( Id, Name,revenue ) for customers and there segment 
  Create view 
  vw_Customersegment as	      
WITH CustomerRevenue AS (
    SELECT 
        c.CustomerID,
        c.CompanyName,
        od.Revenue
    FROM 
        SalesLT.Customer c
    JOIN 
        SalesLT.SalesOrderHeader oh ON c.CustomerID = oh.CustomerID
    JOIN 
        SalesLT.SalesOrderDetail od ON oh.SalesOrderID = od.SalesOrderID
    GROUP BY 
        c.CustomerID, c.CompanyName, od.Revenue
)

SELECT
    cr.CustomerID,
    cr.CompanyName,
    cr.Revenue,
    CASE 
        WHEN cr.Revenue >= 10000 THEN 'Platinum'
        WHEN cr.Revenue >= 5000 THEN 'Gold'
        WHEN cr.Revenue >= 2000 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerSegment
FROM 
    CustomerRevenue cr
	
--Question 5:- What are the top 3 Selling Product ( include ProductName) in each Category(Include Categoryname) by Revenue
WITH ProductRevenueRanked AS (
    SELECT 
        p. ProductName,
        pc. CategorygroupName,
        od. Revenue,
        RANK() OVER (ORDER BY Revenue DESC) AS RankNum
    FROM 
        SalesLT.Product p
    JOIN 
        SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
    JOIN 
        SalesLT.SalesOrderDetail od ON p.ProductID = od.ProductID
    GROUP BY 
        p.ProductName, pc.CategorygroupName, od.Revenue
)

SELECT 
    ProductName,
    CategorygroupName,
    Revenue
FROM 
    ProductRevenueRanked
WHERE 
    RankNum <= 3
ORDER BY 
    Revenue DESC;

 









