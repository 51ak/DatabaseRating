SQLSERVER数据库性能评分SQL
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
系统使用的开源资源：<br> 
AOS:通过aos网页接口获得部分性能数据(也可以用cacti,nagios)<br> 
DBA报表：利用现有的报表平台提供数据展示及任务触发<br> 
<br> 
简单的运行过程描述图：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/t1.png)  
<br> 
综合展示页效果图（每一行代表一个群集实例）：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/Main.png)  
单个集群效果图：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/Detail.png)  

补充说明：<br> 
![](https://github.com/51ak/DatabaseRating/raw/master/screenshots/t0.png)  

