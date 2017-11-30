数据库性能模型： mysql,sqlserver,redis 性能评分和报警
====
设计目的：
----
给ＤＢ实例的健康程度评分。<br> 
<br> 
程序开发： <br> 
把不同平台的不同格式的性能数据，拉到同一维度进行比较以判定实例健康程度<br> 
<br> 
编程语言：<br> 
SQL ：收集和评分的逻辑用存储过程和函数完成(跟数据库相关，最方便且dba最熟悉)<br> 
<br> 
监控数据来源：<br> 
用报表平台的任务功能收集：
1。第三方监控软件的数据：open-faclon,zabbix,cacti,aos (都是调api接口)
2.直接上数据库用指定的SQL 查出数据，需要三列：主机名，监控项，监控 

<br> 
简单的运行过程描述图：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/t1.png)  
<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/MYSQL性能模型.png)  
<br> 

综合展示页效果图（每一行代表一个群集实例）：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/Main.png)  
单个集群效果图：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/Detail.png)  

<br> 
<br> 
<br> 

