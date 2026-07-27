-- RM_SystemSetting
insert into RM_SystemSetting values('AuthenticationMode','4');
update RM_SystemSetting set value=4 where name = 'AuthenticationMode'
SELECT * FROM RM_SystemSetting

--
exec sp_change_users_login 'AUTO_FIX', 'LukaszARM'
exec sp_change_users_login 'AUTO_FIX', 'LukaszVP'
go