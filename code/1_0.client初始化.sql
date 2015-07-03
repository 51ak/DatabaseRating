USE [system]
GO

/****** Object:  Table [dbo].[dba_WaitType_log]    Script Date: 2015/6/24 11:19:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[dba_WaitType_log](
	[addtime] [datetime] NOT NULL,
	[RowNum] [int] NOT NULL,
	[WaitType] [nvarchar](60) NOT NULL,
	[Wait_S] [decimal](14, 2) NULL,
	[Resource_S] [decimal](14, 2) NULL,
	[Signal_S] [decimal](14, 2) NULL,
	[WaitCount] [bigint] NOT NULL,
	[Percentage] [decimal](4, 2) NULL,
	[AvgWait_S] [decimal](14, 4) NULL,
	[AvgRes_S] [decimal](14, 4) NULL,
	[AvgSig_S] [decimal](14, 4) NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[dba_report_counter_log]    Script Date: 2015/6/24 11:19:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[dba_report_counter_log](
	[addtime] [datetime] NOT NULL,
	[is_diff] [int] NULL,
	[counter_name] [varchar](200) NOT NULL,
	[cntr_value] [bigint] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[dba_report_counter_config]    Script Date: 2015/6/24 11:19:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[dba_report_counter_config](
	[keyname] [varchar](200) NOT NULL,
	[isprivate] [int] NOT NULL,
	[get_type] [varchar](10) NOT NULL,
	[cal_type] [varchar](10) NOT NULL,
	[get_sql] [varchar](max) NOT NULL,
	[cal_sql] [varchar](max) NOT NULL,
	[cn_weight] [int] NOT NULL DEFAULT ((0)),
	[keydesc] [nvarchar](500) NOT NULL DEFAULT (''),
PRIMARY KEY CLUSTERED 
(
	[keyname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO




USE [system]
GO

/****** Object:  StoredProcedure [dbo].[usp_dba_report_sysinfo]    Script Date: 2015/6/24 11:19:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[usp_dba_report_sysinfo]
as

DECLARE @ver varchar(128)
DECLARE @ProductVersion varchar(128)
DECLARE @verint int 

declare @ver_pos int 
set @ver=convert(varchar(128),@@version)
set @ver_pos=charindex('-',@ver)
if @ver_pos>0
begin
	set @ver=replace(replace(substring(@ver,0,@ver_pos),'Microsoft SQL Server ','SQL'),' ','')
	set @ver_pos=charindex('(',@ver)
	if @ver_pos>0
	begin
		set @ver=substring(@ver,0,@ver_pos)
	end
end

set @ProductVersion=convert(varchar(128),serverproperty('ProductVersion'))
set  @verint=SUBSTRING(@ProductVersion, 1, CHARINDEX('.', @ProductVersion) - 1)

declare @memsize int
if not exists (select * from sysobjects where id = object_id(N'dba_statistics') and OBJECTPROPERTY(id, N'IsUserTable') = 1)   
begin
	create table dba_statistics(memsize int)
	insert into dba_statistics(memsize) values(0)
end 
if @verint>=11
begin
	exec('update  dba_statistics set memsize=( select physical_memory_kb/1024/1024 as  memsize  FROM sys.dm_os_sys_info)')
end
else
begin
	exec('update  dba_statistics set memsize=(select physical_memory_in_bytes/1024/1024/1024 as  memsize FROM sys.dm_os_sys_info)')
end
select top 1 @memsize=memsize from dba_statistics

DECLARE @OSInfo nvarchar(100) 
Declare @OSProductName nvarchar(100) 
Declare @CSDVersion nvarchar(100) 

EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'ProductName', @OSProductName output;
EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'CSDVersion', @CSDVersion output;   
set @OSInfo=@OSProductName+' '+@CSDVersion

   
Declare @startup_type int                        
Declare @startuptype nvarchar(100)                        
Declare @start_username nvarchar(100)      

                    
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',N'SYSTEM\CurrentControlSet\Services\MSSQLSERVER',@value_name='Start',@value=@startup_type OUTPUT                        
EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',N'SYSTEM\CurrentControlSet\Services\MSSQLSERVER',@value_name='ObjectName',@value=@start_username OUTPUT  
                       
Set @startuptype= (select 'Start Up Mode' =                        
CASE                        
WHEN @startup_type=2 then 'AUTOMATIC'                        
WHEN @startup_type=3 then 'MANUAL'                        
WHEN @startup_type=4 then 'Disabled'                        
END)  


SELECT   
serverproperty('ComputerNamePhysicalNetBIOS') as MachineName
,@OSInfo as OS
,cpu_count  as LogicCpuCount
, cpu_count/hyperthread_ratio  AS  PhysicCpuCount
,@memsize AS MemSize
,max_workers_count AS MaxWorkersCoun
,@ver  AS	MSSQLVersion, 
serverproperty('edition') as MSSQLEdition,                                   
serverproperty('Productlevel') as MSSQLServicePack,                      
@ProductVersion as ProductVersion, 
@verint as ProductVersionInt,               
serverproperty('collation') as 'Collation'
,@startuptype  AS N'Startuptype'
,@start_username AS N'Startuser'                      
,serverproperty('Isclustered') as 'ISClustered'
,serverproperty('IsFullTextInstalled') as 'ISFullText' 
FROM sys.dm_os_sys_info 



GO

/****** Object:  StoredProcedure [dbo].[usp_dba_report_WaitType_info]    Script Date: 2015/6/24 11:19:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--grant execute on usp_dba_report_WaitType_info to dba_reader

CREATE proc [dbo].[usp_dba_report_WaitType_info]
as
set nocount on 
declare @lasttime_2 datetime
declare @lasttime datetime
declare @nowtime datetime
declare @diffi int 
select @nowtime=max(addtime) from [dbo].[dba_WaitType_log] with(nolock)
select @lasttime=max(addtime) from [dbo].[dba_WaitType_log] with(nolock) where addtime 
between dateadd(minute,-10,dateadd(hour,-1,@nowtime)) and dateadd(minute,10,dateadd(hour,-1,@nowtime))
select @lasttime_2=max(addtime) from [dbo].[dba_WaitType_log] with(nolock) where addtime
between dateadd(minute,-10,dateadd(hour,-1,@lasttime)) and dateadd(minute,10,dateadd(hour,-1,@lasttime))

if (@nowtime>@lasttime and @lasttime>@lasttime_2)
begin
SELECT a.[WaitType]
,case 
when (a.[Wait_S]-isnull(b.[Wait_S],0))>(isnull(b.[Wait_S],0)-isnull(c.[Wait_S],0)) then convert(varchar(50),convert(int,a.[Wait_S]-isnull(b.[Wait_S],0)))+'<span class="f_red">'+
convert(varchar(50),convert(int,(a.[Wait_S]-b.[Wait_S])-(isnull(b.[Wait_S],0)-isnull(c.[Wait_S],0))))+'</span>)'
when (a.[Wait_S]-isnull(b.[Wait_S],0))<(isnull(b.[Wait_S],0)-isnull(c.[Wait_S],0)) then convert(varchar(50),convert(int,a.[Wait_S]-isnull(b.[Wait_S],0)))+'<span class="f_green">'+
convert(varchar(50),convert(int,(a.[Wait_S]-b.[Wait_S])-(isnull(b.[Wait_S],0)-isnull(c.[Wait_S],0))))+'</span>)'
else convert(varchar(50),convert(int,a.[Wait_S]-b.[Wait_S]))  end as [Wait_S]
,case 
when (a.[WaitCount]-isnull(b.[WaitCount],0))>(isnull(b.[WaitCount],0)-isnull(c.[WaitCount],0)) then convert(varchar(50),convert(int,a.[WaitCount]-isnull(b.[WaitCount],0)))+'<span class="f_red">'+
convert(varchar(50),convert(int,(a.[WaitCount]-b.[WaitCount])-(isnull(b.[WaitCount],0)-isnull(c.[WaitCount],0))))+'</span>)'
when (a.[WaitCount]-isnull(b.[WaitCount],0))<(isnull(b.[WaitCount],0)-isnull(c.[WaitCount],0)) then convert(varchar(50),convert(int,a.[WaitCount]-isnull(b.[WaitCount],0)))+'<span class="f_green">'+
convert(varchar(50),convert(int,(a.[WaitCount]-b.[WaitCount])-(isnull(b.[WaitCount],0)-isnull(c.[WaitCount],0))))+'</span>)'
else convert(varchar(50),convert(int,a.[WaitCount]-b.[WaitCount]))  end as [WaitCount]
,case when a.[Percentage]>b.[Percentage] then convert(varchar(50),a.[Percentage])+'%(<span class="f_red">'+convert(varchar(50),(a.[Percentage]-b.[Percentage]))+'</span>)'
when a.[Percentage]<b.[Percentage] then convert(varchar(50),a.[Percentage])+'%(<span class="f_green">'+convert(varchar(50),(a.[Percentage]-b.[Percentage]))+'</span>)'
else convert(varchar(50),convert(varchar(50),a.[Percentage])+'%')  end as [Percentage]
from dbo.[dba_WaitType_log]  a 
left join (
SELECT [RowNum]
      ,[WaitType]
      ,[Wait_S]
      ,[WaitCount]
      ,[Percentage]
from dbo.[dba_WaitType_log] where addtime=@lasttime) b  on a.[WaitType]=b.[WaitType]
left join (
SELECT [RowNum]
      ,[WaitType]
      ,[Wait_S]
      ,[WaitCount]
      ,[Percentage]
from dbo.[dba_WaitType_log] where addtime=@lasttime_2) c  on a.[WaitType]=c.[WaitType]
where a.addtime=@nowtime
order by a.[RowNum]
end
else if (@nowtime>@lasttime )
begin
	
	SELECT a.[WaitType]
	,a.[Wait_S]-isnull(b.[Wait_S],0)  as [Wait_S]
	,a.[WaitCount]-isnull(b.[WaitCount],0) as [WaitCount]
	,case when a.[Percentage]>b.[Percentage] then convert(varchar(50),a.[Percentage])+'%(<span class="f_red">'+convert(varchar(50),(a.[Percentage]-b.[Percentage]))+'</span>)'
	when a.[Percentage]<b.[Percentage] then convert(varchar(50),a.[Percentage])+'%(<span class="f_green">'+convert(varchar(50),(a.[Percentage]-b.[Percentage]))+'</span>)'
	else convert(varchar(50),convert(varchar(50),a.[Percentage])+'%')  end as [Percentage]
	from dbo.[dba_WaitType_log]  a 
	left join (
	SELECT [RowNum]
		  ,[WaitType]
		  ,[Wait_S]
		  ,[WaitCount]
		  ,[Percentage]
	from dbo.[dba_WaitType_log] where addtime=@lasttime) b  on a.[WaitType]=b.[WaitType]
	where a.addtime=@nowtime
	order by a.[RowNum]
end
else
begin
	SELECT [WaitType]
      ,[Wait_S]
      ,[WaitCount]
      ,[Percentage]
	from dbo.[dba_WaitType_log] where addtime=@lasttime
	order by [RowNum]
end


GO

/****** Object:  StoredProcedure [dbo].[usp_dba_WaitType_log_add]    Script Date: 2015/6/24 11:19:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[usp_dba_WaitType_log_add]
as
;WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0
            AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER()
            AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC)
            AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'CLR_SEMAPHORE',    N'LAZYWRITER_SLEEP',
        N'RESOURCE_QUEUE',   N'SQLTRACE_BUFFER_FLUSH',
        N'SLEEP_TASK',       N'SLEEP_SYSTEMTASK',
        N'WAITFOR',          N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'CHECKPOINT_QUEUE', N'REQUEST_FOR_DEADLOCK_SEARCH',
        N'XE_TIMER_EVENT',   N'XE_DISPATCHER_JOIN',
        N'LOGMGR_QUEUE',     N'FT_IFTS_SCHEDULER_IDLE_WAIT',
        N'BROKER_TASK_STOP', N'CLR_MANUAL_EVENT',
        N'CLR_AUTO_EVENT',   N'DISPATCHER_QUEUE_SEMAPHORE',
        N'TRACEWRITE',       N'XE_DISPATCHER_WAIT',
        N'BROKER_TO_FLUSH',  N'BROKER_EVENTHANDLER',
        N'FT_IFTSHC_MUTEX',  N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'DIRTY_PAGE_POLL')
    )
	INSERT INTO [dbo].[dba_WaitType_log]
           ([addtime]
           ,[RowNum]
           ,[WaitType]
           ,[Wait_S]
           ,[Resource_S]
           ,[Signal_S]
           ,[WaitCount]
           ,[Percentage]
           ,[AvgWait_S]
           ,[AvgRes_S]
           ,[AvgSig_S])
SELECT
	getdate(),
	 [W1].[RowNum],
    [W1].[wait_type] AS [WaitType], 
    CAST ([W1].[WaitS] AS DECIMAL(14, 2)) AS [Wait_S],
    CAST ([W1].[ResourceS] AS DECIMAL(14, 2)) AS [Resource_S],
    CAST ([W1].[SignalS] AS DECIMAL(14, 2)) AS [Signal_S],
    [W1].[WaitCount] AS [WaitCount],
    CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage],
    CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4))
        AS [AvgWait_S],
    CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (14, 4))
        AS [AvgRes_S],
    CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (14, 4))
        AS [AvgSig_S] 
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2]
    ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS], 
    [W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount],
    [W1].[Percentage]
HAVING
    SUM ([W2].[Percentage]) - [W1].[Percentage] < 95; 




GO

/****** Object:  StoredProcedure [dbo].[usp_dba_report_counter_log_add]    Script Date: 2015/6/24 11:19:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_dba_report_counter_log_add]
as
set nocount on 
DECLARE @sqlstr varchar(max)
declare @output varchar(max) --,split
--declare @sqlstr_cnvalue varchar(max)
--declare @lasttime datetime
--select @lasttime=isnull(max(addtime),'2000-1-1') from dba_report_counter_log
--declare @nowtime datetime
--set @nowtime=getdate()
--set @sqlstr=''


set @output=''
select @output = coalesce(@output + ' or ' , '') + keyname from (
SELECT '([object_name] LIKE (''%'+B.get_sql+'%'') AND [counter_name] IN ('+''''+LEFT(groupstr,LEN(groupstr)-2)+'))' as keyname
 FROM (  
SELECT get_sql,(SELECT keyname+''',''' FROM dba_report_counter_config WHERE get_sql=A.get_sql FOR XML PATH('')) AS groupstr
 FROM dba_report_counter_config A  where get_type='calperf'
 GROUP BY get_sql  
) B  
)AS T
set @sqlstr='select ''{datetime}'',1,[counter_name],cntr_value FROM sys.dm_os_performance_counters WHERE   ([instance_name] = '''' OR [instance_name] = ''_Total'') AND ( 1=2 '+ @output+')'

set @output=''
select @output = coalesce(@output + ' union all 
' , '') + keyname from (
select 'select ''{datetime}'',0,'''+keyname+''',('+get_sql+')' keyname from dba_report_counter_config where get_type='sql' 
)AS T

set @sqlstr=@sqlstr+'
'+@output+' union all 
'
--print @sqlstr
set @output=''
select @output = coalesce(@output + ''',''' , '') + keyname from (SELECT keyname FROM dba_report_counter_config where get_type='perf')AS T
set @sqlstr=@sqlstr+'SELECT ''{datetime}'',0,[counter_name],[cntr_value] from sys.dm_os_performance_counters  with(nolock)                                                                         
WHERE   ([instance_name] = '''' OR [instance_name] = ''_Total'')
AND [counter_name] IN 	('''+@output+''')'

declare @nowtime datetime
set  @nowtime=convert(varchar(19),getdate(),120)
declare @lasttime datetime
select @lasttime=isnull(max(addtime),dateadd(day,-30,getdate())) from dba_report_counter_log
declare @diffi int
set @diffi=datediff(second,@lasttime,@nowtime)

set @sqlstr='insert into [dbo].dba_report_counter_log(addtime,is_diff,[counter_name],[cntr_value])
'+replace(@sqlstr,'{datetime}',convert(varchar(19),@nowtime,120))
--print @sqlstr
exec(@sqlstr)  

;with sr_last as(
select [counter_name],[cntr_value]  from [dbo].dba_report_counter_log where addtime=@lasttime
)
select a.[counter_name],c.cal_type,c.cal_sql,-1 as cn_status,[cn_weight],0 as cn_height,
case when c.get_type='calperf' then convert(decimal(18,2),(a.[cntr_value]-isnull(b.[cntr_value], a.[cntr_value]))/convert(decimal(18,2),@diffi))
else a.[cntr_value] end as  [cntr_value] ,@diffi as diffi
into #dba_counter_tmp
from  [dbo].dba_report_counter_log a
join [dbo].[dba_report_counter_config] c on a.counter_name=c.keyname
left join sr_last b on a.[counter_name]=b.[counter_name]
 where a.addtime=@nowtime


 set @output=''
select @output = coalesce(@output + ';
' , '') + keysql from (
 select 'update #dba_counter_tmp set cn_status=('+replace(cal_sql,'{0}',convert(varchar(50),[cntr_value]))+') where [counter_name]='''+[counter_name]+'''; '  as keysql  from #dba_counter_tmp where cal_type='sql'
 )AS T

--print @output
exec(@output)  

update #dba_counter_tmp set cn_height=(case 
when  cn_status between 0 and 39 then 3
when  cn_status between 40 and 59 then 2
when  cn_status between 60 and 79 then 1
else 0 end )

--REPLACE(REPLACE(REPLACE(convert(VARCHAR(50),rtrim([counter_name])),' ',''),'/','Per'),'-','') AS [counter_name]
select rtrim([counter_name]) AS [counter_name],cntr_value,cn_status,cn_weight,cn_height from #dba_counter_tmp
drop table #dba_counter_tmp


GO



USE [msdb]
GO

/****** Object:  Job [DBA3@WaitType_Monitor]    Script Date: 2015/6/24 11:21:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 2015/6/24 11:21:42 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA3@WaitType_Monitor', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [waittype]    Script Date: 2015/6/24 11:21:42 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'waittype', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
		exec usp_dba_WaitType_log_add
', 
		@database_name=N'system', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'minute', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140311, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



USE [system]
GO
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Active Temp Tables', 0, N'perf', N'sql', N'', N'case when {0}<1000 then 100-({0}/100) 
when {0}<3000 then 70-({0}/60) 
when {0}<30000 then 50-({0}/600) else 4  end

', 1, N'����ʹ�õ���ʱ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Active Transactions', 0, N'perf', N'sql', N'', N'case when {0}<10 then 100
when {0}<60 then 90-({0}/2) 
when {0}<200 then 60-({0}/4) else 0  end
', 1, N'���ڴ򿪵�����')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'AvailablePhysicalMemory', 0, N'sql', N'sql', N'select available_physical_memory_kb/1024/1024 FROM sys.dm_os_sys_memory WITH (NOLOCK)', N'case when {0}>30  then 100 
when  {0} between 8 and 30  then {0}+70
when {0} between 2 and 7 then {0}+50
else 33  end', 5, N'���������ڴ�(G)')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Batch Requests/sec', 0, N'calperf', N'sql', N'SQLServer:SQL Statistics', N'case when {0}<5 then 0 
when  {0}<8000 then 100-({0}/400) 
when  {0}<21000 then 70-({0}/700) 
when  {0}<40000 then 40-({0}/1000)  else 0  end', 1, N'QPS')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Broker Transaction Rollbacks', 0, N'perf', N'sql', N'', N'case when {0}<0.2 then 100-({0}*10) 
when {0}<1 then 100-({0}*30) 
when {0}<5 then 50-({0}*10) else 0  end', 5, N'�ع���������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Cache Entries Count', 0, N'perf', N'sql', N'', N'case when {0}<200000 then 100-({0}/20000) 
when {0}<1000000 then 70-({0}/20000) 
when {0}<10000000 then 50-({0}/200000) else 4  end', 0, N'��ǰ������Ŀ�� ')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Checkpoint pages/sec', 0, N'calperf', N'sql', N'SQLServer:Buffer Manager', N'case when {0}<500 then 100
when {0}<1500 then 100-({0}/30)  
when {0}<6000 then 50-({0}/120) else 0  end
', 1, N'�۲�ֵ��ÿ�뽫�ڴ�ҳˢ�������ϵ��������۲��ֵ�����������������ô�п������ڴ�ѹ����д��ѹ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Commit table entries', 0, N'perf', N'sql', N'', N'case when {0}<20 then 100
when {0}<50 then 100-({0})  
when {0}<200 then 50-({0}/4) else 0  end
', 1, N'�ύ����Ŀ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Connection Memory (KB)', 0, N'perf', N'sql', N'', N'case when {0}<200000 then 100-({0}/20000) 
when {0}<1000000 then 70-({0}/20000) 
when {0}<10000000 then 50-({0}/200000) else 4  end', 1, N'�������ӵ��ڴ�')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Connection Reset/sec', 0, N'calperf', N'sql', N'SQLServer:General Statistics', N'case when {0}<20000 then 100-({0}/2000) 
when {0}<100000 then 70-({0}/2000) 
when {0}<1000000 then 50-({0}/20000) else 4  end
', 1, N'ÿ����û�pool���ô������������Ӻ�')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'CpuWatittime', 0, N'sql', N'sql', N'SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,0)) FROM sys.dm_os_wait_stats WITH (NOLOCK) ', N'case when {0}<50 then 100-({0}*2) else 0 end ', 4, N'�ȴ�CPU��ʱ�䣬�����ܵȴ�ʱ���15%,cpu��ѹ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Data File(s) Size (KB)', 0, N'calperf', N'sql', N'SQLServer:Databases', N'case when {0}<200 then 100-({0}/20) 
when {0}<1000 then 70-({0}/20) 
when {0}<10000 then 50-({0}/200) else 4  end', 1, N'ÿ�������ļ�������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Full Scans/sec', 0, N'calperf', N'sql', N'SQLServer:Access Methods', N'
case when {0}<2000 then 100-({0}/200) 
when {0}<10000 then 70-({0}/200) 
when {0}<100000 then 50-({0}/2000) else 4  end
', 1, N'����SQL Server��ȫ��ɨ����Ŀ����ֵԽСԽ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Index Searches/sec', 0, N'calperf', N'sql', N'SQLServer:Access Methods', N'case when {0}<600000 then 100-({0}/60000) 
when {0}<3000000 then 70-({0}/60000) 
when {0}<60000000 then 50-({0}/1200000) else 4  end
', 1, N'ÿ��������������������������������Χɨ�衢���¶�λ��Χɨ�衢������֤ɨ��㡢��ȡ����������¼�Լ���������������ȷ�����еĲ���λ�á�')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Lock Requests/sec', 0, N'calperf', N'sql', N'SQLServer:Locks', N' case when {0}<200000 then 100-({0}/20000) 
when {0}<10000000 then 70-({0}/500000) 
when {0}<100000000 then 50-({0}/2000000) else 4  end ', 1, N'ÿ�������������ע�����ֵֻ������������һ���������ģ���Ϊ��һ��SQL�������N���������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Lock Timeouts/sec', 0, N'calperf', N'sql', N'SQLServer:Locks', N'case when {0}<2 then 100-({0}) 
when {0}<300 then 100-({0}/10) 
when {0}<1400 then 70-({0}/20) 
else 0  end', 5, N'ÿ������ʱ������ͨ����ζ������������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Log Bytes Flushed/sec', 0, N'calperf', N'sql', N'SQLServer:Databases', N'case when {0}<20000000 then 100-({0}/2000000) 
when {0}<100000000 then 70-({0}/2000000) 
when {0}<1000000000 then 50-({0}/20000000) else 4  end', 1, N'ÿ�뽫��־ˢ����̵��ֽ���')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Log File(s) Used Size (KB)', 0, N'calperf', N'sql', N'SQLServer:Databases', N'case when {0}<0 then 100 when {0}<1600 then 100-({0}/80) 
when {0}<8000 then 80-({0}/200) 
when {0}<30000 then 60-({0}/600) else 4  end
', 1, N'ÿ����־�������������Ǹ�������Ϊ�нضϣ�')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Log Flush Wait Time', 0, N'perf', N'sql', N'', N'case when {0}<100 then 100
when {0}<600 then 100-({0}/20)  
when {0}<1800 then 70-({0}/30) else 0  end
', 1, N'д����־�Ķ���������Ϊ������������Ӧ�������ĵȴ�ʱ�䣬�ᵼ��ǰ�˵��������ύ��������Ӱ��SQL Server���ܡ���ֵӦ���ھ������ʱ�䶼Ϊ0')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Log Flushes/sec', 0, N'calperf', N'sql', N'SQLServer:Databases', N'case when {0}<300 then 100-({0}/30) 
when {0}<2000 then 90-({0}/50) 
when {0}<20000 then 50-({0}/400) else 4  end
', 1, N'ÿ�뽫��־ˢ����̵�����')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Logins/sec', 0, N'calperf', N'sql', N'SQLServer:General Statistics', N'case when {0}<200 then 100-({0}/20) 
when {0}<1000 then 70-({0}/20) 
when {0}<10000 then 50-({0}/200) else 4  end', 1, N'ÿ������û���¼�������������ӳ�����û����������ֵһֱ�Ƚϴ󣬿��������ӳ�û�ú�')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Number of Deadlocks/sec', 0, N'calperf', N'sql', N'SQLServer:Locks', N'case when {0}<0.2 then 100-({0}*10) 
when {0}<1 then 100-({0}*30) 
when {0}<5 then 50-({0}*10) else 0  end', 5, N'ÿ��������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Page life expectancy', 0, N'perf', N'sql', N'', N'case when {0}<300 then {0}/10  when {0}<1000 then {0}/100 else 100  end', 3, N'')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Page reads/sec', 0, N'calperf', N'sql', N'SQLServer:Buffer Manager', N'case when {0}<500 then 100
when {0}<30000 then 100-({0}/600)  
when {0}<100000 then 50-({0}/2000) else 0  end
', 1, N'�۲�ֵ��ÿ�뷢�����������ݿ�ҳ��ȡ��������IO�ǰ���ģ������ֵ�Ӹ߲��£���ʹ�ø�������ݻ��棬����������Ч�Ĳ�ѯ����ͨ���ı����ݿ�����������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Page Splits/sec', 0, N'calperf', N'sql', N'SQLServer:Access Methods', N'case when {0}<200 then 100-({0}/20) 
when {0}<1000 then 70-({0}/20) 
when {0}<10000 then 50-({0}/200) else 4  end
', 1, N'ÿ��ҳ���ֵĴ���������ͨ���ʵ�������ά�����ߺõ�������������ⷢ����')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Page writes/sec', 0, N'calperf', N'sql', N'SQLServer:Buffer Manager', N'case when {0}<500 then 100
when {0}<3000 then 100-({0}/60)  
when {0}<10000 then 50-({0}/200) else 0  end
', 1, N'�۲�ֵ��ÿ�뷢�����������ݿ�ҳд��������Ӧ��ǰд��ѹ����ˮλ')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'PendingDiskIOCount', 0, N'sql', N'sql', N'SELECT AVG(pending_disk_io_count) FROM sys.dm_os_schedulers WITH (NOLOCK)', N'case when {0}<90 then 100-{0}  else 1  end', 1, N'�ȴ�IO�Ľ�����,ԽСԽ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Probe Scans/sec', 0, N'calperf', N'sql', N'SQLServer:Access Methods', N'case when {0}<600000 then 100-({0}/60000) 
when {0}<3000000 then 70-({0}/60000) 
when {0}<60000000 then 50-({0}/1200000) else 4  end
', 1, N'ÿ��������ֱ����������������в������һ���޶��е�̽��ɨ����')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Range Scans/sec', 0, N'calperf', N'sql', N'SQLServer:Access Methods', N'case when {0}<600000 then 100-({0}/60000) 
when {0}<3000000 then 70-({0}/60000) 
when {0}<60000000 then 50-({0}/1200000) else 4  end
', 1, N'ÿ��ͨ���������е��޶���Χ��ɨ������')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'RunnableTasksCount', 0, N'sql', N'sql', N'SELECT AVG(current_tasks_count) FROM sys.dm_os_schedulers WITH (NOLOCK)', N'case when {0}<90 then 100-{0} else 1  end', 1, N'�ŶӵĽ�����(ͨ���ǵ�cpu),ԽСԽ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'RunningCount', 0, N'sql', N'sql', N'select count(*) from Sys.dm_exec_sessions with(nolock) where [status]=''running''', N'case when {0}<10 then 100  when {0}<90  then 100-{0} else 0  end', 10, N'�������еĽ�����,ԽСԽ��')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'SQL Compilations/sec', 0, N'calperf', N'sql', N'SQLServer:SQL Statistics', N'case when {0}<200 then 100-({0}/20) 
when {0}<1000 then 70-({0}/20) 
when {0}<10000 then 50-({0}/200) else 4  end', 1, N'ÿ��ı���������ʾ�������·��������Ĵ��������� SQL Server ����伶���±��뵼�µı��롣�� SQL Server �û���ȶ���
��ֵ���ﵽ�ȶ�״̬')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'SQL Re-Compilations/sec', 0, N'calperf', N'sql', N'SQLServer:SQL Statistics', N'case when {0}<20 then 100
when {0}<50 then 100-({0})  
when {0}<200 then 50-({0}/4) else 0  end
', 1, N'����������±��뱻�����Ĵ�����һ����˵���������ý�С,�洢���������������Ӧ��ֻ����һ��. ����ü�������ֵ�ϸߣ��軻����ʽ��д�洢���̣��Ӷ������ر���Ĵ���')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'ThreadCount', 0, N'sql', N'sql', N'select count(*) from Sys.dm_exec_sessions with(nolock)', N'case when {0}<10 then 0 
when {0}<10000 then 100-({0}/200)  
when {0}<40000 then 50-({0}/800) else 0  end', 1, N'��ǰ��SQL������������sleep,running,pennding�ȣ������ֵͻ�� 1.��Ϊ�ж���2.������ѯ�޷��ܿ췵�ؽ��3.������û���ͷ�')
INSERT [dbo].[dba_report_counter_config] ([keyname], [isprivate], [get_type], [cal_type], [get_sql], [cal_sql], [cn_weight], [keydesc]) VALUES (N'Transactions/sec', 0, N'calperf', N'sql', N'SQLServer:Databases', N'case when {0}<5 then 0 
when  {0}<1600 then 100-({0}/80) 
when  {0}<4200 then 70-({0}/140) 
when  {0}<8000 then 40-({0}/200)  else 0  end', 5, N'TPS')



go
if  @@version like 'Microsoft SQL Server 2005%'
begin
	update  [dbo].[dba_report_counter_config] 
	set [get_sql]=N'select 5 as available_physical --DBCC MEMORYSTATUS'
	where [keyname]=N'AvailablePhysicalMemory'
end

