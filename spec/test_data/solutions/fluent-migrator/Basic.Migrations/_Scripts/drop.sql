-- Drop the database
if EXISTS(select name from master.dbo.sysdatabases where name = '$(DATABASE_NAME)') begin
    drop database $(DATABASE_NAME)
end
GO