ALTER LOGIN sa WITH PASSWORD = 'FuturePotato?';

------------------------------
-- CREATE ARM SECURITY > LOGIN
------------------------------
DECLARE @sql NVARCHAR(MAX) = ''; 
SELECT @sql = @sql + 'ALTER AUTHORIZATION ON DATABASE::[' + name + '] TO [sa]; ' 
FROM sys.databases 
WHERE owner_sid = SUSER_SID('LukaszARM'); 
EXEC(@sql); 

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LukaszARM') 
DROP LOGIN [LukaszARM]; 

CREATE LOGIN [LukaszARM] 
WITH PASSWORD = 'FuturePotato?', 
CHECK_POLICY = OFF, 
CHECK_EXPIRATION = OFF;

-- Make LukaszARM sysadmin
ALTER SERVER ROLE [sysadmin] ADD MEMBER [LukaszARM];



-------------------------------------
-- CREATE VIEWPOINT SECURITY > LOGIN
-------------------------------------
DECLARE @sql2 NVARCHAR(MAX) = '';
SELECT 
    @sql2 = @sql2 + 'ALTER AUTHORIZATION ON DATABASE::[' + name + '] TO [sa]; '
FROM 
    sys.databases
WHERE 
    owner_sid = SUSER_SID('LukaszVP');
EXEC(@sql2);
IF EXISTS (
    SELECT 1 
    FROM sys.server_principals 
    WHERE name = 'LukaszVP'
)
    DROP LOGIN [LukaszVP];

CREATE LOGIN [LukaszVP]
WITH 
    PASSWORD = 'FuturePotato?',
    CHECK_POLICY = OFF,
    CHECK_EXPIRATION = OFF;
