Select *
From NYSCrimes1990.dbo.PropertyCrimes

Select *
From NYSCrimes1990.dbo.ViolentCrimes

--Which counties had the most Violent crimes
Select Violent_Total, County, Year
From NYSCrimes1990.dbo.ViolentCrimes
Where Agency = 'County Total'
Order By Year DESC, Violent_Total DESC

--Which counties had the most Property crimes
Select Property_Total, County, Year
From NYSCrimes1990.dbo.PropertyCrimes
Where Agency = 'County Total'
Order By Year DESC, Property_Total DESC

--Of all crimes what percent have been Murder
Select vio.Year, vio.County,
CASE
WHEN vio.Violent_Total + pro.Property_Total = 0 THEN NULL
ELSE CONCAT(ROUND((cast(vio.Murder as float)/(cast(vio.Violent_Total as float) + cast(pro.Property_Total as float)) * 100),3),'%')
END as Murder_Percentage
From NYSCrimes1990.dbo.ViolentCrimes vio
Join NYSCrimes1990.dbo.PropertyCrimes pro
	On vio.Agency = pro.Agency AND vio.Year = pro.Year AND vio.County = pro.County
Where vio.Agency = 'County Total'
Group By vio.Year, vio.County,  vio.Murder, vio.Violent_Total, pro.Property_Total
Order BY vio.Year DESC, Murder_Percentage DESC

--Of all crimes what percent have been Burglary
Select vio.Year, vio.County,
CASE
WHEN vio.Violent_Total + pro.Property_Total = 0 THEN NULL
ELSE CONCAT(ROUND((cast(pro.Burglary as float)/(cast(vio.Violent_Total as float) + cast(pro.Property_Total as float)) *100),3),'%')
END as Burglary_Percentage
From NYSCrimes1990.dbo.ViolentCrimes vio
Join NYSCrimes1990.dbo.PropertyCrimes pro
	On vio.Agency = pro.Agency AND vio.Year = pro.Year AND vio.County = pro.County
Where vio.Agency = 'County Total'
Group By vio.Year, vio.County,  pro.Burglary, vio.Violent_Total, pro.Property_Total
Order BY vio.Year DESC, Burglary_Percentage DESC

--Total crime in each county for each year
Select DISTINCT(vio.County), vio.Year, SUM(vio.Violent_Total + pro.Property_Total) OVER (PARTITION BY vio.County, vio.Year) AS Total_Crime
From NYSCrimes1990.dbo.ViolentCrimes vio
Join NYSCrimes1990.dbo.PropertyCrimes pro
	On vio.Agency = pro.Agency AND vio.Year = pro.Year and vio.County = pro.County
Where vio.Agency <> 'County Total' OR vio.Region = 'New York City'
Order By vio.Year DESC, vio.County


--Temp Table
DROP Table if exists #PercentViolentPropertyCrime
Create Table #PercentViolentPropertyCrime
(
County nvarchar(max),
Year int,
Violent_Total bigint,
Property_Total bigint,
Total_Crime bigint,
)

Insert Into #PercentViolentPropertyCrime
Select vio.County, vio.Year, vio.Violent_Total, pro.Property_Total, 
SUM(vio.Violent_Total + pro.Property_Total) OVER (PARTITION BY vio.County, vio.Year) AS Total_Crime
From NYSCrimes1990.dbo.ViolentCrimes vio
Join NYSCrimes1990.dbo.PropertyCrimes pro
	On vio.Agency = pro.Agency AND vio.Year = pro.Year and vio.County = pro.County
Where vio.Agency <> 'County Total' OR vio.Region = 'New York City'

Select *
From #PercentViolentPropertyCrime
Order by 2 DESC

Select County, Year, Total_Crime, cast(Violent_Total as float)/cast(Total_Crime as float) *100 as Violent_Percentage
, cast(Property_Total as float)/cast(Total_Crime as float) *100 as Property_Percentage
From #PercentViolentPropertyCrime
Order by 2 DESC

--Views
Create View CountyTotalCrime as
Select DISTINCT(vio.County), vio.Year, SUM(vio.Violent_Total + pro.Property_Total) OVER (PARTITION BY vio.County, vio.Year) AS Total_Crime
From NYSCrimes1990.dbo.ViolentCrimes vio
Join NYSCrimes1990.dbo.PropertyCrimes pro
	On vio.Agency = pro.Agency AND vio.Year = pro.Year and vio.County = pro.County
Where vio.Agency <> 'County Total' OR vio.Region = 'New York City'

Create View ViolentCrimesView as
Select Violent_Total, County, Year
From NYSCrimes1990.dbo.ViolentCrimes
Where Agency = 'County Total'

Create View PropertyCrimesView as
Select Property_Total, County, Year
From NYSCrimes1990.dbo.PropertyCrimes
Where Agency = 'County Total'

--CTE
With VioProCrime (County, Year, Violent_Total, Property_Total, Total_Crime)
as
(
Select vio.County, vio.Year, vio.Violent_Total, pro.Property_Total, SUM(vio.Violent_Total + pro.Property_Total) OVER (PARTITION BY vio.County, vio.Year) AS Total_Crime
From NYSCrimes1990.dbo.ViolentCrimes vio
Join NYSCrimes1990.dbo.PropertyCrimes pro
	On vio.Agency = pro.Agency AND vio.Year = pro.Year and vio.County = pro.County
Where vio.Agency <> 'County Total' OR vio.Region = 'New York City'
)
Select County, Year, Total_Crime, cast(Violent_Total as float)/cast(Total_Crime as float) *100 as Violent_Percentage
, cast(Property_Total as float)/cast(Total_Crime as float) *100 as Property_Percentage
From VioProCrime
Group By County, Year, Violent_Total, Property_Total, Total_Crime
