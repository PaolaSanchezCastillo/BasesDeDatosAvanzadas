





CREATE DATABASE [AdventureWorks2017_Paola]
 CONTAINMENT = NONE
 ON  PRIMARY 
(NAME = N'AdventureWorks2017', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017.mdf' , 
	SIZE = 270336KB , 
	MAXSIZE = 2048GB, 
	FILEGROWTH = 65536KB 
), 
FILEGROUP [humanResources] 
( NAME = N'HumanResources', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017_HumanResources.ndf' , 
	SIZE = 61440KB , 
	MAXSIZE = 2048GB, 
	FILEGROWTH = 8192KB ), 
FILEGROUP [Person] 
( NAME = N'Person', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017_Person.ndf' , 
	SIZE = 61440KB ,
	MAXSIZE = 2048GB, 
	FILEGROWTH = 8192KB ), 
FILEGROUP [production] 
( NAME = N'Production', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017_production.ndf' , 
	SIZE = 61440KB , 
	MAXSIZE = 2048GB, 
	FILEGROWTH = 8192KB ), 
FILEGROUP [Purchasing] 
( NAME = N'Purchasing', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017_Purchasing.ndf' , 
	SIZE = 61440KB , 
	MAXSIZE = 2048GB, 
	FILEGROWTH = 8192KB ), 
FILEGROUP [Sales] 
( NAME = N'Sales', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017_Sales.ndf' , 
	SIZE = 61440KB , 
	MAXSIZE = 2048GB, 
	FILEGROWTH = 8192KB 
)
LOG ON 
( NAME = N'AdventureWorks2017_log', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\AdventureWorks2017_log.ldf' , 
	SIZE = 73728KB , 
	MAXSIZE = 2048GB , 
	FILEGROWTH = 65536KB )
GO





/********* SCRIPT UTILIZADO  PARA CREAR ESQUEMAS Y TABLAS *******/

CREATE SCHEMA [Sales]
GO

CREATE TABLE [Sales].[SalesPerson](
	[BusinessEntityID] [int] NOT NULL,
	[TerritoryID] [int] NULL,
	[SalesQuota] [money] NULL,
	[Bonus] [money] NOT NULL,
	[CommissionPct] [smallmoney] NOT NULL,
	[SalesYTD] [money] NOT NULL,
	[SalesLastYear] [money] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesPerson_BusinessEntityID] PRIMARY KEY CLUSTERED 
(
	[BusinessEntityID] ASC
)
) ON [Sales]

GO













USE [AdventureWorks2017_Paola]
GO

CREATE LOGIN [webServices] 
WITH PASSWORD=N'12060904Pa', 
DEFAULT_DATABASE=[AdventureWorks2017_Paola], 
DEFAULT_LANGUAGE=[Español], 
CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF 






GO

CREATE USER [webServices] FOR LOGIN [webServices] WITH DEFAULT_SCHEMA=[dbo]
GO

ALTER ROLE [db_datareader] ADD MEMBER [webServices]
GO

ALTER ROLE [db_datawriter] ADD MEMBER [webServices]
GO

DENY DELETE TO [webServices]
GO


/****** Se crea un sp generico de busqueda ******/

CREATE PROCEDURE searchCatalog
(@name VARCHAR(MAX))
AS
BEGIN

 DECLARE @sql NVARCHAR(MAX) ='SELECT * FROM '+@name;


 PRINT @Sql;

 EXECUTE sp_executesql @Sql;

END



GRANT EXECUTE ON OBJECT::searchCatalog  
    TO webServices;




CREATE DATABASE Users; 





USE Users; 
GO 

DENY SELECT TO [webServices]; 

/* Creación de las tablas*/

CREATE Table Users (
    idUser INT IDENTITY PRIMARY KEY,
    userName VARCHAR(50) NOT NULL,
    psw VARBINARY(8000) NOT NULL
);

GO

CREATE Table Roles (
    idRol INT IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

GO

CREATE Table userRoles (
    idRol INT,
    idUser INT,
	FOREIGN KEY (idRol) REFERENCES roles(idRol),
	FOREIGN KEY (idUser) REFERENCES Users(idUser),
	PRIMARY KEY (idRol,idUser)
);

GO

/*Inserción de los valores para las pruebas */

INSERT INTO Roles
VALUES('Supervisor');

INSERT INTO Users (
    UserName
    ,psw
    )
VALUES (
    'supervisor'
    ,ENCRYPTBYPASSPHRASE('password', '1206Supervisor')

	);
GO

INSERT INTO userRoles
VALUES (1,1);


/*Creación de los sp */

CREATE PROCEDURE searchUser
(@usr VARCHAR(100),  @psw VARCHAR(1000))
AS
BEGIN

DECLARE @idRol INT = (SELECT idRol
FROM userRoles ur
INNER JOIN Users u
	ON ur.idUser = u.idUser
WHERE CONCAT(username,CONVERT(VARCHAR(MAX), DECRYPTBYPASSPHRASE('password', psw))) = CONCAT(@usr, @psw));

 IF(@idRol != 0)
   BEGIN
   SELECT @idRol
   END
   ELSE SELECT 'El usuario no existe'
END
GO






GRANT EXECUTE ON OBJECT::searchUser  
    TO webServices;
	







/***************************************************************************************/

/*
Se crea la base  AdventureWorksDW2017  con el fin de  tener una base analitica.
La misma se pobla con procesos desde la base transaccional, se cuenta con un usuario que realiza
unicamente consultas y al igual que al usuario webServices no le aplicamos la politica de expiración ni obligamos a 
que cambie contraseña.

*/

CREATE LOGIN [analytics] WITH PASSWORD=N'12060904Pa', 
DEFAULT_DATABASE=[AdventureWorksDW2017], 
DEFAULT_LANGUAGE=[Español], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER ROLE [db_datareader] ADD MEMBER [analytics]
GO

USE AdventureWorksDW2017
GO
CREATE USER [analytics] FOR LOGIN [analytics] WITH DEFAULT_SCHEMA=[dbo]
GO




SELECT * FROM sys.filegroups;

EXEC sp_who;

SELECT 
    DB_NAME(dbid) as DBName, 
    COUNT(dbid) as NumberOfConnections,
    loginame as LoginName
FROM
    sys.sysprocesses
WHERE 
    dbid > 0
GROUP BY 
    dbid, loginame
;



SELECT DS.name AS DataSpaceName 
  ,AU.type_desc AS AllocationDesc 
  ,AU.total_pages / 128 AS TotalSizeMB 
  ,AU.used_pages / 128 AS UsedSizeMB 
  ,AU.data_pages / 128 AS DataSizeMB 
  ,SCH.name AS SchemaName 
  ,OBJ.type_desc AS ObjectType       
  ,OBJ.name AS ObjectName 
  ,IDX.type_desc AS IndexType 
  ,IDX.name AS IndexName 
FROM sys.data_spaces AS DS 
 INNER JOIN sys.allocation_units AS AU 
     ON DS.data_space_id = AU.data_space_id 
 INNER JOIN sys.partitions AS PA 
     ON (AU.type IN (1, 3)  
         AND AU.container_id = PA.hobt_id) 
        OR 
        (AU.type = 2 
         AND AU.container_id = PA.partition_id) 
 INNER JOIN sys.objects AS OBJ 
     ON PA.object_id = OBJ.object_id 
 INNER JOIN sys.schemas AS SCH 
     ON OBJ.schema_id = SCH.schema_id 
 LEFT JOIN sys.indexes AS IDX 
     ON PA.object_id = IDX.object_id 
        AND PA.index_id = IDX.index_id 
ORDER BY DS.name 
    ,SCH.name 
    ,OBJ.name 
    ,IDX.name
