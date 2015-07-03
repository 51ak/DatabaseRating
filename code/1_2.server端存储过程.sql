USE [dba_mana]
GO

/****** Object:  StoredProcedure [dbo].[usp_aos_counter_itemlist]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


 CREATE proc [dbo].[usp_aos_counter_itemlist]
 as
 set nocount on 
 declare @btime datetime
 declare @etime datetime
 select @btime=max(addtime) from aos_counter
 set @btime=isnull(@btime,'2015-5-28')
 set @etime=dateadd(minute,5,@btime)
 
declare @t table (
	[begintime] [int] NULL,
	[endtime] [int] NULL,
	[allwaysonid] [varchar](50) NOT NULL,
	[itemid] [int] NOT NULL,
	[pri_nodename] [varchar](50) NOT NULL,
	[itemtext] [varchar](4) NOT NULL,
	[addtime] [varchar](16) NULL
) 

 --select @btime,@etime 

 while( @etime<=getdate())
 begin
	print @etime
	INSERT INTO @t
			   ([begintime]
			   ,[endtime]
			   ,[allwaysonid]
			   ,[itemid]
			   ,[pri_nodename]
			   ,[itemtext]
			   ,[addtime])  
 	 SELECT  DATEDIFF(SECOND,{d'1970-01-01'}, dateadd(ms,3,dateadd(hour,-8,@btime))) as begintime,
	 DATEDIFF(SECOND,{d'1970-01-01'}, dateadd(hour,-8,@etime)) as endtime,
	[allwaysonid],b.itemid,[pri_nodename],b.itemtext,convert(varchar(16),@etime,120) as addtime

	  FROM [dba_mana].[dbo].[dba_alwayson_config] a
	  ,(  select 1 as itemid,'cpu' as itemtext union all
	 select 18,'iops' union all
	  select 24,'tcp' 
	)b 
	   where a.isonline=1
	set @btime=dateadd(minute,5,@btime)
	 set @etime=dateadd(minute,5,@etime)
end

select [begintime],[endtime],[allwaysonid],[itemid],[pri_nodename],[itemtext],[addtime] from @t


GO

/****** Object:  StoredProcedure [dbo].[usp_aos_count_valueget]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_aos_count_valueget](
@linkname varchar(50),
 @fkey varchar(50)
)
as
set nocount on 
--set @linkname='DBAGHotel102'
--set @fkey='CPU'

declare @etime datetime
declare @btime datetime
select  @etime=max(addtime) from aos_counter with(nolock)
set @btime=dateadd(day,-1,@etime)

  select right(convert(varchar(16) ,a.addtime,120),5) as 'Time',a.favg as Today__0__bar___0_solid,
--isnull(b.favg,0) as Yestoday__0__line__green_1_solid,
case when isnull(c.favg,0)<5  then  isnull(b.favg,a.favg) 
 when isnull(c.favg,0)>(a.favg*2) then convert(int,(isnull(c.favg,0)+isnull(b.favg,0))/2)
 else c.favg end  as LastWeek__0__line__green_1_dotted 
from [dbo].aos_counter  a with(nolock) 
left join (
select dateadd(day,1,addtime) as addtime,favg from  [dbo].aos_counter b with(nolock) 
where addtime between dateadd(day,-1,@btime) and dateadd(day,-1,@etime) and linkname=@linkname and fkey=@fkey
) b on a.addtime=b.addtime
left join (
select dateadd(day,7,addtime) as addtime,favg from  [dbo].aos_counter b with(nolock) 
where addtime between dateadd(day,-7,@btime) and dateadd(day,-7,@etime) and linkname=@linkname and fkey=@fkey
) c on a.addtime=c.addtime
where a.addtime between @btime and @etime  and a.linkname=@linkname and a.fkey=@fkey
order by a.addtime



GO

/****** Object:  StoredProcedure [dbo].[usp_sql_count_valueget]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_sql_count_valueget](
@linkname varchar(50),
 @fkey varchar(50),
 @daytype int=1
)
as
set nocount on 
if (@fkey in ('cpu','io','tcp'))
begin
	exec [dbo].[usp_sql_count_valueget_cpu] @linkname,@fkey,@daytype
end 
else 
begin
	exec [usp_sql_count_valueget_other]  @linkname,@fkey,@daytype
end

GO

/****** Object:  StoredProcedure [dbo].[usp_sql_count_valueget_cpu]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[usp_sql_count_valueget_cpu](
@linkname varchar(50),
 @fkey varchar(50),
 @daytype int=1
)
as
set nocount on 

/*
set @linkname='DBAGHotel102'
set @fkey='aos_cpu'
*/
declare @etime datetime
declare @btime datetime
select  @etime=max(addtime) from aos_counter with(nolock)
set @btime=dateadd(day,-@daytype,@etime)

	  select right(convert(varchar(16) ,a.addtime,120),5) as 'Time',a.favg as Today__0__bar___0_solid,
	--isnull(b.favg,0) as Yestoday__0__line__green_1_solid,
	case when isnull(c.favg,0)<5  then  isnull(b.favg,a.favg) 
	 when isnull(c.favg,0)>(a.favg*2) then convert(int,(isnull(c.favg,0)+isnull(b.favg,0))/2)
	 else c.favg end  as LastWeek__0__line__green_1_dotted 
	from [dbo].aos_counter  a with(nolock) 
	left join (
	select dateadd(day,1,addtime) as addtime,favg from  [dbo].aos_counter b with(nolock) 
	where addtime between dateadd(day,-1,@btime) and dateadd(day,-1,@etime) and linkname=@linkname and fkey=@fkey
	) b on a.addtime=b.addtime
	left join (
	select dateadd(day,7,addtime) as addtime,favg from  [dbo].aos_counter b with(nolock) 
	where addtime between dateadd(day,-7,@btime) and dateadd(day,-7,@etime) and linkname=@linkname and fkey=@fkey
	) c on a.addtime=c.addtime
	where a.addtime between @btime and @etime  and a.linkname=@linkname and a.fkey=@fkey
	order by a.addtime

GO

/****** Object:  StoredProcedure [dbo].[usp_sql_count_valueget_other]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_sql_count_valueget_other](
@linkname varchar(50),
 @fkey2 varchar(50),
 @daytype int=1
)
as
set nocount on 

/*
set @linkname='DBAGHotel102'
set @fkey='aos_cpu'
*/
declare  @fkey varchar(50)
declare @etime datetime
declare @btime datetime
select  @etime=max(addtime) from aos_counter with(nolock)
set @btime=dateadd(day,-@daytype,@etime)
select @fkey=[keyname] from [dbo].[dba_report_counter_config] where [keyengname]=@fkey2

		 select right(convert(varchar(16) ,a.addtime,120),5) as 'Time',a.fvalue as Today__0__bar___0_solid,
	--isnull(b.favg,0) as Yestoday__0__line__green_1_solid,
	case when isnull(c.fvalue,0)<5  then  isnull(b.fvalue,a.fvalue) 
	 when isnull(c.fvalue,0)>(a.fvalue*2) then convert(int,(isnull(c.fvalue,0)+isnull(b.fvalue,0))/2)
	 else c.fvalue end  as LastWeek__0__line__green_1_dotted 
	from [dbo].[sql_counter]  a with(nolock) 
	left join (
	select dateadd(day,1,addtime) as addtime,fvalue from  [dbo].[sql_counter] b with(nolock) 
	where addtime between dateadd(day,-1,@btime) and dateadd(day,-1,@etime) and linkname=@linkname and fkey=@fkey
	) b on a.addtime=b.addtime
	left join (
	select dateadd(day,7,addtime) as addtime,fvalue from  [dbo].[sql_counter] b with(nolock) 
	where addtime between dateadd(day,-7,@btime) and dateadd(day,-7,@etime) and linkname=@linkname and fkey=@fkey
	) c on a.addtime=c.addtime
	where a.addtime between @btime and @etime  and a.linkname=@linkname and a.fkey=@fkey
	order by a.addtime


GO

/****** Object:  StoredProcedure [dbo].[usp_aos_counter_add]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


  CREATE proc [dbo].[usp_aos_counter_add](
  @linkname varchar(50)
  ,@addtime datetime 
  ,@fkey varchar(50) 
  ,@fmin decimal(18,2)
  ,@fmax decimal(18,2)
  ,@favg decimal(18,2)
  )
  as

 declare  @fstatus int
 declare @fheight int 
 if @fkey='cpu' 
 begin
	set @fstatus=case when @favg<12 then 100 else 110-@favg end 


 end
 else if @fkey='iops' 
 begin
	set @fstatus=case when @favg<8500 then convert(int,100-@favg/85) else 0 end
 end
 else
 begin
	set @fstatus=case when @favg<7000 then convert(int,100-@favg/70) else 0 end
 end
 
 set @fheight=(case 
when  @fstatus between 0 and 39 then 3
when  @fstatus between 40 and 59 then 2
when  @fstatus between 60 and 79 then 1
else 0 end)

  insert into aos_counter (linkname,addtime,fkey,fmin,fmax,favg,fstatus,fheight) values(
  @linkname,@addtime,@fkey,@fmin,@fmax,@favg,@fstatus,@fheight
  )


GO

/****** Object:  StoredProcedure [dbo].[usp_report_ranktop_add]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_report_ranktop_add]
as
declare @btime datetime
declare @etime datetime
set @etime=getdate()


set @etime=convert(varchar(14),@etime,120)+'00'
set @btime=dateadd(hour,-1,@etime)
set  @etime=dateadd(ms,-3,@etime)



INSERT INTO [dbo].[report_ranktop]
           ([addtime]
           ,[fkey]
           ,[1]
           ,[2]
           ,[3]
           ,[4]
           ,[5]
           ,[6]
           ,[7]
           ,[8]
           ,[9]
		   ,[10]
           ,[11]
           ,[12]
           ,[13]
           ,[14]
           ,[15]
           ,[16]
           ,[17]
           ,[18]
           ,[19]
           ,[20]
           ,[21]
           ,[22]
           ,[23]
           ,[24]
           ,[25]
           ,[26]
           ,[27]
           ,[28]
           ,[29]
           ,[30]
           ,[31]
           ,[32]
           ,[33]
           ,[34]
           ,[35]
           ,[36]
           ,[37]
           ,[38]
           ,[39]
           ,[40]
           ,[41]
           ,[42]
           ,[43]
           ,[44]
           ,[45]
           ,[46]
           ,[47]
           ,[48]
           ,[49]
           ,[50]
           ,[51]
           ,[52]
           ,[53]
           ,[54]
           ,[55]
           ,[56]
           ,[57]
           ,[58]
           ,[59]
           ,[60])  
select @btime,* 
from  
(
--select a.row1,b.[allwaysonname] as linkname,a.[fkey] from(
SELECT row_number() over(partition by [fkey]  order by avg([fstatus])) as row1,[linkname]
		,[fkey]
		--,avg([favg]) as fvalue
  FROM [dbo].[sql_counter] with(nolock)  where addtime between @btime and @etime 
  group by [linkname],[fkey]
  union all
  SELECT row_number() over(partition by [fkey]  order by avg([fstatus])) as row1,[linkname]
		,lower([fkey]) as [fkey]
		--,avg([fstatus])   as fvalue
  FROM [dbo].[aos_counter] with(nolock)  where addtime between @btime and @etime 
  group by [linkname],[fkey]
  --)a join [dbo].[dba_alwayson_config] b on a.linkname=b.allwaysonid
) t
pivot ( max(linkname) for t.row1 in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19]	,[20]	,[21]	,[22]	,[23]	,[24]	,[25]	,[26]	,[27]	,[28]	,[29]	,[30]	,[31]	,[32]	,[33]	,[34]	,[35]	,[36]	,[37]	,[38]	,[39]	,[40]	,[41]	,[42]	,[43]	,[44]	,[45]	,[46]	,[47]	,[48]	,[49]	,[50]	,[51]	,[52]	,[53]	,[54]	,[55]	,[56]	,[57]	,[58]	,[59]	,[60]
)) as ourpivot


GO

/****** Object:  StoredProcedure [dbo].[usp_report_ranktop_top]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--exec usp_report_ranktop_top 'dbagcom101','aos_cpu'
CREATE proc [dbo].[usp_report_ranktop_top]
(
@linkname varchar(50),
@fkey varchar(50),
@isshort int=0
)
as
set nocount on 
declare @t table ( [allwaysonid] varchar(50),[allwaysonname] varchar(2000))

insert into @t([allwaysonid],[allwaysonname])
SELECT [allwaysonid]
      ,case when [allwaysonid]=@linkname and @isshort=1 then '<div style="background:yellow;width:100%">'+shortname+'</div>' 
       when [allwaysonid]=@linkname and @isshort=0 then '<div style="background:yellow;width:100%">'+[allwaysonname]+'</div>' 	
	    when  @isshort=1 then shortname 
	  else  [allwaysonname] end as [allwaysonname]
  FROM [dba_mana].[dbo].[dba_alwayson_config]  

select a.[addtime]
,b1.allwaysonname as [T1]
,b2.allwaysonname as [T2]
,b3.allwaysonname as [T3]
,b4.allwaysonname as [T4]
,b5.allwaysonname as [T5]
,b6.allwaysonname as [T6]
,b7.allwaysonname as [T7]
,b8.allwaysonname as [T8]
,b9.allwaysonname as [T9]
,b10.allwaysonname as [T10]
 from (
select top 50 convert(varchar(16),dateadd(hour,1,[addtime]),120) as [addtime], [1],[2],[3],[4],[5],[6],[7],[8],[9],[10] 
from  [dbo].[report_ranktop] with(nolock)
where [fkey]=@fkey
order by addtime desc
) a 
left join @t b1  on a.[1]=b1.allwaysonid
left join @t b2  on a.[2]=b2.allwaysonid
left join @t b3  on a.[3]=b3.allwaysonid
left join @t b4  on a.[4]=b4.allwaysonid
left join @t b5  on a.[5]=b5.allwaysonid
left join @t b6  on a.[6]=b6.allwaysonid
left join @t b7  on a.[7]=b7.allwaysonid
left join @t b8  on a.[8]=b8.allwaysonid
left join @t b9  on a.[9]=b9.allwaysonid
left join @t b10  on a.[10]=b10.allwaysonid



GO

/****** Object:  StoredProcedure [dbo].[usp_aos_count_valueget_]    Script Date: 2015/6/24 15:54:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_aos_count_valueget_](
 @fkey varchar(50)='cpu'
)
as
set nocount on 

--set @linkname='DBAGHotel102'
--set @fkey='CPU'

declare @etime datetime
declare @btime datetime
select  @etime=max(addtime) from aos_counter with(nolock)
set @btime=dateadd(day,-1,@etime)

  select cc.[allwaysonname] as linkname,right(convert(varchar(16) ,a.addtime,120),5) as 'Time',a.favg as Today__0__bar___0_solid,
--isnull(b.favg,0) as Yestoday__0__line__green_1_solid,
case when isnull(c.favg,0)<5  then  isnull(b.favg,a.favg) 
 when isnull(c.favg,0)>(a.favg*2) then convert(int,(isnull(c.favg,0)+isnull(b.favg,0))/2)
 else c.favg end  as LastWeek__0__line__green_1_dotted 
from [dbo].aos_counter  a with(nolock) 
left join (
select linkname,dateadd(day,1,addtime) as addtime,favg from  [dbo].aos_counter b with(nolock) 
where addtime between dateadd(day,-1,@btime) and dateadd(day,-1,@etime)  and fkey=@fkey
) b on a.addtime=b.addtime and a.linkname=b.linkname
left join (
select linkname,dateadd(day,7,addtime) as addtime,favg from  [dbo].aos_counter b with(nolock) 
where addtime between dateadd(day,-7,@btime) and dateadd(day,-7,@etime) and fkey=@fkey
) c on a.addtime=c.addtime and a.linkname=c.linkname
left join [dbo].[dba_alwayson_config] cc on a.linkname=cc.[allwaysonid]
where a.addtime between @btime and @etime  and a.fkey=@fkey

order by  a.linkname,a.addtime



GO

/****** Object:  StoredProcedure [dbo].[usp_remote_PublicationTokenResult_add]    Script Date: 2015/6/24 15:54:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[usp_remote_PublicationTokenResult_add] 
(@addtime datetime
,@linkname varchar(50)
,@DBNAME varchar(200)
,@Publication varchar(200)
,@Subscriber varchar(200)
,@SubscriberDB varchar(200)
,@tokenid int
,@DistributorLatency int
,@SubscriberLatency int
,@OverallLatency int
,@CreatedTime datetime)
as
if exists(select * from [dbo].[remote_PublicationResult]  WHERE [linkname] = @linkname and [Publication] = @Publication and  [Subscriber] = @Subscriber and [SubscriberDB] = @SubscriberDB)
begin
	UPDATE [dbo].[remote_PublicationResult]
	SET [DBNAME] = @DBNAME,[DistributorLatency] = @DistributorLatency,[SubscriberLatency] = @SubscriberLatency,[OverallLatency] = @OverallLatency,[CreatedTime] = @CreatedTime
	WHERE [linkname] = @linkname and [Publication] = @Publication and  [Subscriber] = @Subscriber and [SubscriberDB] = @SubscriberDB
end
else 
begin
	INSERT INTO [dbo].[remote_PublicationResult]
	([linkname],[Publication],[Subscriber],[SubscriberDB],[DBNAME],[DistributorLatency],[SubscriberLatency],[OverallLatency],[CreatedTime])
	VALUES
	(@linkname,@Publication,@Subscriber,@SubscriberDB,@DBNAME,@DistributorLatency,@SubscriberLatency,@OverallLatency,@CreatedTime)
end

INSERT INTO [dbo].[remote_PublicationTokenResult]
([addtime],[linkname],[DBNAME],[Publication],[Subscriber],[SubscriberDB],[tokenid],[DistributorLatency],[SubscriberLatency],[OverallLatency],[CreatedTime])
VALUES(@addtime ,@linkname ,@DBNAME ,@Publication,@Subscriber,@SubscriberDB ,@tokenid ,@DistributorLatency ,@SubscriberLatency ,@OverallLatency ,@CreatedTime )


GO

/****** Object:  StoredProcedure [dbo].[usp_report_dashboard_NEW_get]    Script Date: 2015/6/24 15:54:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_report_dashboard_NEW_get]
( @ftype int=1 )
as
/*
declare @btime  datetimecpu_watittime	runnable_tasks_count
<div class="progress"><span class="success" style="width: 80%;"><span>80</span></span></div>	
<div class="progress"><span class="success" style="width: 100%;"><span>100</span></span></div>
select @btime=max(addtime) from [dba_mana].[dbo].[sql_counter]

*/

declare @max_sqltime datetime
declare @max_aostime datetime

select @max_aostime=max(addtime) from aos_counter with(nolock) where addtime<dateadd(second,-30,getdate())
select @max_sqltime=max(addtime) from sql_counter with(nolock) where addtime<dateadd(second,-30,getdate())



select 
'<a href="?report_action=v&report_ptname=dn7apzxkbcjgt9ol4rmis318hq&fdpara__1='+[allwaysonid]+'" style="height:30px;line-height:30px;padding-left:5px;"><b>'+[allwaysonname]+'</b></a><span class="f_666" style="font-size:9px">('+[pri_nodename]+')</span>' as [allwaysonname]

,case when all_height between 80 and 100  then
  '<span class="f_bold f_center f_success" style="padding-left:20px">'+convert(varchar(50),all_height)+'%</span>'
when all_height between 60 and 80  then
  '<span class="f_bold f_center f_info" style="padding-left:20px">'+convert(varchar(50),all_height)+'%</span>'
when all_height between 40 and 60  then
  '<span class="f_bold f_center f_warning" style="padding-left:20px">'+convert(varchar(50),all_height)+'%</span>'
else
'<span class="f_bold f_center f_danger" style="padding-left:20px">'+convert(varchar(50),all_height)+'%</span>'
end as Total_
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'CPU使用率'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=cpu&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[cpu_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull([cpu_value],''))+'%</span></span></div></a>' as [cpu]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'CPU等待'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=CpuWatittime&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[CpuWatittime_height]+'" style="width: 100%;"><span>'+replace(convert(varchar(50),isnull([CpuWatittime_value],'')),'.00','')+'</span></span></div></a>' as [CpuWatittime]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'CPU阻塞'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=RunnableTasksCount&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[RunnableTasksCount_height]+'" style="width: 100%;"><span>'+convert(varchar(50),convert(int,isnull([RunnableTasksCount_value],0)))+'</span></span></div></a>' as [RunnableTasksCount]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'可用内存'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=AvailablePhysicalMemory&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[AvailablePhysicalMemory_height]+'" style="width: 100%;"><span>'+replace(convert(varchar(50),isnull([AvailablePhysicalMemory_value],'')),'.00','')+'G</span></span></div></a>' as [AvailablePhysicalMemory]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'生存周期'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=Pagelifeexpectancy&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[Pagelifeexpectancy_height]+'" style="width: 100%;"><span>'+convert(varchar(50),convert(int,(isnull([Pagelifeexpectancy_value],0)/3600)))+'h</span></span></div></a>' as [Pagelifeexpectancy]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'IOPS'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=io&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[io_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[io_value]),''))+'</span></span></div></a>' as [io]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'IO阻塞'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=PendingDiskIOCount&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[PendingDiskIOCount_height]+'" style="width: 100%;"><span>'+replace(convert(varchar(50),isnull([PendingDiskIOCount_value],'')),'.00','')+'</span></span></div></a>' as [PendingDiskIOCount]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'TCP连接'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=tcp&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[tcp_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[tcp_value]),''))+'</span></span></div></a>' as [tcp]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'运行SQL'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=RunningCount&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[RunningCount_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[RunningCount_value]),''))+'</span></span></div></a>' as [RunningCount]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'连接数'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=ThreadCount&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[ThreadCount_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[ThreadCount_value]),''))+'</span></span></div></a>' as [ThreadCount]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'TPS'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=TPS&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[TPS_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[TPS_value]),''))+'</span></span></div></a>' as [TPS]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'QPS'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=QPS&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[QPS_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[QPS_value]),''))+'</span></span></div></a>' as [QPS]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'锁超时'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=LockTimeouts&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[LockTimeouts_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[LockTimeouts_value]),''))+'</span></span></div></a>' as [LockTimeouts]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'死锁'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=Deadlocks/sec&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[Deadlocks/sec_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull([Deadlocks/sec_value],''))+'</span></span></div></a>' as [Deadlocks/sec]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'日志'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=LogBytesFlushed&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[LogBytesFlushed_height]+'" style="width: 100%;"><span>'+convert(varchar(50),convert(decimal(18,2),isnull([LogBytesFlushed_value],0)/1024/1024))+'M</span></span></div></a>' as [LogBytesFlushed]
 ,'<a href="#" onclick="alertWin('''+[allwaysonname]+'事务'',''?report_action=v&report_ptname=danvxye9zpjk4o8rw5uf20m7sc&fdpara__1='+[allwaysonid]+'&fdpara__2=ActiveTransactions&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',540,400);"><div class="progress" style="margin:0 8px;"><span class="'+[ActiveTransactions_height]+'" style="width: 100%;"><span>'+convert(varchar(50),isnull(convert(int,[ActiveTransactions_value]),''))+'</span></span></div></a>' as [ActiveTransactions]
from 	(
select a.allwaysonname,a.pri_nodename,a.orderid,a.[allwaysonid]
,case when isnull(r_ss.fheight,85)+isnull(r_as.fheight,15) between 0 and 100 then 100-(isnull(r_ss.fheight,85)+isnull(r_as.fheight,15))
when isnull(r_ss.fheight,85)+isnull(r_as.fheight,15)>100 then 0 
when isnull(r_ss.fheight,85)+isnull(r_as.fheight,15)<0  then 100
end as all_height 
,isnull(r_s.[AvailablePhysicalMemory_value],0) as [AvailablePhysicalMemory_value], case  r_s.[AvailablePhysicalMemory_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [AvailablePhysicalMemory_height]
,isnull(r_s.[CpuWatittime_value],0) as [CpuWatittime_value], case  r_s.[CpuWatittime_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [CpuWatittime_height]
,isnull(r_s.[PendingDiskIOCount_value],0) as [PendingDiskIOCount_value], case  r_s.[PendingDiskIOCount_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [PendingDiskIOCount_height]
,isnull(r_s.[RunnableTasksCount_value],0) as [RunnableTasksCount_value], case  r_s.[RunnableTasksCount_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [RunnableTasksCount_height]
,isnull(r_s.[RunningCount_value],0) as [RunningCount_value], case  r_s.[RunningCount_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [RunningCount_height]
,isnull(r_s.[ThreadCount_value],0) as [ThreadCount_value], case  r_s.[ThreadCount_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [ThreadCount_height]
,isnull(r_s.[LockTimeouts_value],0) as [LockTimeouts_value], case  r_s.[LockTimeouts_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [LockTimeouts_height]
,isnull(r_s.[Deadlocks/sec_value],0) as [Deadlocks/sec_value], case  r_s.[Deadlocks/sec_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [Deadlocks/sec_height]
,isnull(r_s.[TPS_value],0) as [TPS_value], case  r_s.[TPS_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [TPS_height]
,isnull(r_s.[LogBytesFlushed_value],0) as [LogBytesFlushed_value], case  r_s.[LogBytesFlushed_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [LogBytesFlushed_height]
,isnull(r_s.[Pagelifeexpectancy_value],0) as [Pagelifeexpectancy_value], case  r_s.[Pagelifeexpectancy_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [Pagelifeexpectancy_height]
,isnull(r_s.[ActiveTransactions_value],0) as [ActiveTransactions_value], case  r_s.[ActiveTransactions_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [ActiveTransactions_height]
,isnull(r_s.[QPS_value],0) as [QPS_value], case  r_s.[QPS_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [QPS_height]
,isnull(r_a.[cpu_value],0) as [cpu_value], case  r_a.[cpu_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [cpu_height]
,isnull(r_a.[io_value],0) as [io_value], case  r_a.[io_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [io_height]
,isnull(r_a.[tcp_value],0) as [tcp_value], case  r_a.[tcp_height] when 0 then 'success' when 1 then 'info'   when 2 then 'warning'   else 'danger' end as [tcp_height]
 FROM [dba_mana].[dbo].[dba_alwayson_config] a
left join  (
SELECT [linkname]
,sum(case when [fkey]='AvailablePhysicalMemory' then [fvalue] else 0.00 end) as [AvailablePhysicalMemory_value] 
,sum(case when [fkey]='CpuWatittime' then [fvalue] else 0.00 end) as [CpuWatittime_value] 
,sum(case when [fkey]='PendingDiskIOCount' then [fvalue] else 0.00 end) as [PendingDiskIOCount_value] 
,sum(case when [fkey]='RunnableTasksCount' then [fvalue] else 0.00 end) as [RunnableTasksCount_value] 
,sum(case when [fkey]='RunningCount' then [fvalue] else 0.00 end) as [RunningCount_value] 
,sum(case when [fkey]='ThreadCount' then [fvalue] else 0.00 end) as [ThreadCount_value] 
,sum(case when [fkey]='Lock Timeouts/sec' then [fvalue] else 0.00 end) as [LockTimeouts_value] 
,sum(case when [fkey]='Number of Deadlocks/sec' then [fvalue] else 0.00 end) as [Deadlocks/sec_value] 
,sum(case when [fkey]='Transactions/sec' then [fvalue] else 0.00 end) as [TPS_value] 
,sum(case when [fkey]='Log Bytes Flushed/sec' then [fvalue] else 0.00 end) as [LogBytesFlushed_value] 
,sum(case when [fkey]='Page life expectancy' then [fvalue] else 0.00 end) as [Pagelifeexpectancy_value] 
,sum(case when [fkey]='Active Transactions' then [fvalue] else 0.00 end) as [ActiveTransactions_value] 
,sum(case when [fkey]='Batch Requests/sec' then [fvalue] else 0.00 end) as [QPS_value] 
,sum(case when [fkey]='AvailablePhysicalMemory' then [fheight] else 0 end) as [AvailablePhysicalMemory_height] 
,sum(case when [fkey]='CpuWatittime' then [fheight] else 0 end) as [CpuWatittime_height] 
,sum(case when [fkey]='PendingDiskIOCount' then [fheight] else 0 end) as [PendingDiskIOCount_height] 
,sum(case when [fkey]='RunnableTasksCount' then [fheight] else 0 end) as [RunnableTasksCount_height] 
,sum(case when [fkey]='RunningCount' then [fheight] else 0 end) as [RunningCount_height] 
,sum(case when [fkey]='ThreadCount' then [fheight] else 0 end) as [ThreadCount_height] 
,sum(case when [fkey]='Lock Timeouts/sec' then [fheight] else 0 end) as [LockTimeouts_height] 
,sum(case when [fkey]='Number of Deadlocks/sec' then [fheight] else 0 end) as [Deadlocks/sec_height] 
,sum(case when [fkey]='Transactions/sec' then [fheight] else 0 end) as [TPS_height] 
,sum(case when [fkey]='Log Bytes Flushed/sec' then [fheight] else 0 end) as [LogBytesFlushed_height] 
,sum(case when [fkey]='Page life expectancy' then [fheight] else 0 end) as [Pagelifeexpectancy_height] 
,sum(case when [fkey]='Active Transactions' then [fheight] else 0 end) as [ActiveTransactions_height] 
,sum(case when [fkey]='Batch Requests/sec' then [fheight] else 0 end) as [QPS_height] 
from sql_counter with(nolock) where addtime=@max_sqltime
group by [linkname]
) r_s on a.allwaysonid=r_s.linkname
left join 
(SELECT 
[linkname]
,sum(case when [fkey]='cpu' then favg else 0.00 end) as [cpu_value] 
,sum(case when [fkey]='iops' then favg else 0.00 end) as [io_value] 
,sum(case when [fkey]='tcp' then favg else 0.00 end) as [tcp_value] 
,sum(case when [fkey]='cpu' then [fheight] else 0 end) as [cpu_height] 
,sum(case when [fkey]='iops' then [fheight] else 0 end) as [io_height] 
,sum(case when [fkey]='tcp' then [fheight] else 0 end) as [tcp_height] 
FROM [dba_mana].[dbo].[aos_counter] with(Nolock)
    where [addtime]=@max_aostime
  group by [linkname])  r_a on a.allwaysonid=r_a.linkname
left join
(
select [linkname],sum([fheight]*5) as [fheight] from [dba_mana].[dbo].[aos_counter] with(nolock)
 where [addtime]=@max_aostime group by [linkname]

) r_as  on a.allwaysonid=r_as.linkname
left join
(
select [linkname],sum([fheight]*5) as [fheight] from [dbo].sql_counter with(nolock)
 where [addtime]=@max_sqltime group by [linkname]
 ) r_ss  on a.allwaysonid=r_ss.linkname

where a.isonline=1
) m
order by orderid desc




GO

/****** Object:  StoredProcedure [dbo].[usp_sql_counter_getmain]    Script Date: 2015/6/24 15:54:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[usp_sql_counter_getmain]
(@linkname varchar(50)=''
)
as
declare @max_sqltime datetime
declare @max_aostime datetime

select @max_aostime=max(addtime) from aos_counter with(nolock) where addtime between dateadd(minute,-30,getdate()) and  dateadd(second,-30,getdate())
select @max_sqltime=max(addtime) from sql_counter with(nolock) where addtime between dateadd(minute,-30,getdate()) and  dateadd(second,-30,getdate())

select [keytype]
,'<a href="#" onclick="alertWin('''+@linkname
+'的'+b.keychsname+''',''?report_action=v&report_ptname=d3vp87nfbuja0ieyzc51xm2q6r&fdpara__1='+@linkname
+'&fdpara__2='+b.keyname+'&authkey=dba6293&sessionkey={sessionkey}&rnd={rndnum}'',700,420);" title="'+b.keydesc+'">'+ b.keychsname+'</a>'
	 as keyname
,convert(varchar(50),fvalue) as fvalue,fstatus  FROM 
(SELECT fkey,fheight,fweight,fvalue,fstatus 
 from sql_counter  with(nolock)
 where addtime=@max_sqltime and linkname=@linkname
 union all
 SELECT [fkey],[fheight],5 as [fweight]
      ,[favg]
      ,[fstatus]
      
  FROM [dba_mana].[dbo].[aos_counter] with(nolock) where addtime=@max_sqltime and linkname=@linkname
  ) A
 join [dba_mana].[dbo].[dba_report_counter_config]  b on a.fkey=b.[keyname]
  


GO

/****** Object:  StoredProcedure [dbo].[usp_sql_counter_getgroup]    Script Date: 2015/6/24 15:54:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




  
CREATE proc [dbo].[usp_sql_counter_getgroup]
(@linkname varchar(50)=''
)
as
declare @max_sqltime datetime
declare @max_aostime datetime

select @max_aostime=max(addtime) from aos_counter with(nolock) where addtime between dateadd(minute,-30,getdate()) and  dateadd(second,-30,getdate())
select @max_sqltime=max(addtime) from sql_counter with(nolock) where addtime between dateadd(minute,-30,getdate()) and  dateadd(second,-30,getdate())

select [keytype],convert(int,(min(fstatus)+avg(fstatus)*3)/4)  FROM 
(SELECT fkey,fheight,fweight,fvalue,fstatus 
 from sql_counter  with(nolock)
 where addtime=@max_sqltime and linkname=@linkname
 union all
 SELECT [fkey],[fheight],5 as [fweight]
      ,[favg]
      ,[fstatus]
      
  FROM [dba_mana].[dbo].[aos_counter] with(nolock) where addtime=@max_sqltime and linkname=@linkname
  ) A
 join [dba_mana].[dbo].[dba_report_counter_config]  b on a.fkey=b.[keyname]
  
  group by [keytype]

GO

