declare @type INT=1,
	@vendorid int=0,
	@facid int=1,
	@shiftdate datetime='01-01-1900',
	@shift varchar(max)='',
	@triptype varchar(10)='P'


	SELECT 
			locationString, 
			CONVERT(VARCHAR(50),t.updatedAt,0)  updatedAt, 
			lat, 
			lng, 
			TIME, 
			speed, 
			altitude, 
			bearing, 
			debug, 
			accuracy, 
			serviceProvider, 
			r.id deviceId,
			NULL AS trackingStatus,
			NULL AS empCode,
			NULL AS empName,
			0 AS stopNo, 
			ISNULL(r.tripType, '') AS tripType,
			ISNULL(r.shiftTime, '') AS shiftTime,
			--CASE WHEN actvehiclestarttime is not null and actvehicleendtime is not null THEN 'stopped' ELSE 'started' END AS facility,
			CASE WHEN actvehiclestarttime is not null and actvehicleendtime is not null THEN 'Completed' 
			WHEN actvehiclestarttime is not null and actvehicleendtime is null THEN 'Started' 
			WHEN actvehiclestarttime is null and actvehicleendtime is null then 'Not Started'
			else '' end as facility,
			ISNULL(dm.Contact,ISNULL(r.DriverContact,'')) AS driverContact,
			--ISNULL(r.vendorName,'') AS vendorName,
			isnull(vn.vendorName,'') as vendorName,
			ISNULL(dm.Name , ISNULL(r.DriverName,'') )AS DriverName,
			ISNULL(v.vehicleNo,'') as vehicle, 
			'---' AS Gender,
			CONVERT(VARCHAR,t.updatedAt,0) AS date_time,
			ISNULL(r.totalStop,0)AS totalEmp,
			ISNULL(v.vehicleRegistrationNo,'')  AS vehicleNo,
			ISNULL(r.remark, '')AS remark ,
			0 AS totalEmpBoarded,
			0 AS totalEmpNoShow,
			ISNULL(r.malecount, 0) AS totalEmpMale,
			ISNULL(r.femalecount, 0) AS totalEmpFemale,
			isnull(convert(varchar(50),r.actvehiclestarttime,0),'----') as actvehiclestarttime,
			isnull(convert(varchar(50),r.actvehicleendtime,0),'----') as actvehicleendtime,
			isnull(r.totaldist,0) as totaldist,
			isnull(r.isb2b,0) as isb2b,
			cast(ISNULL(r.pickmalecount, 0) as int) + cast(ISNULL(r.pickfemalecount, 0) as int) AS totalEmpP,
			cast(ISNULL(r.pickmalecount, 0) as int) AS totalEmpMaleP,
			cast(ISNULL(r.pickfemalecount, 0)as int) AS totalEmpFemaleP	


		 FROM
				
		ROUTE r 
		left outer join 
		  AppControl.dbo.GPSlogsmryv2 t
		on r.id = t.deviceId  and r.clientid=t.clientid  --and t.rn =1
		LEFT OUTER JOIN DriverMaster dm ON dm.id=r.driver
		left outer join vehicle v on v.id=dm.cabid 
		left outer join vendor vn on vn.id=r.vendorid
		 
		WHERE  ( isnull(r.vendorid,0)>= (case when @vendorid=0 then 0  else @vendorid  end) and r.facilityId=@facid 
		and  isnull(r.vendorid,0)<= (case when @vendorid=0 then (select max(id) from vendor )  else @vendorid  end)   
		AND (( (r.triptype='P' or isnull(r.isB2B,0)=1) and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN DATEADD(hh, -4, dateadd(n,330,getdate())) AND DATEADD(hh, 6, dateadd(n,330,getdate())))
		or (r.triptype='D' and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN  DATEADD(n, -240, dateadd(n,330,getdate())) and  DATEADD(n, 0, dateadd(n,330,getdate())))) 
		  and  (r.actVehicleStartTime IS NOT NULL) AND (r.actVehicleEndTime IS NULL) and
		 (@type=3 AND isnull(r.femalecount,0)>0))

       or (@type=4 AND r.id IN  --TripStartedNotEnded
						(SELECT     r.id FROM  ROUTE AS r 
						--inner JOIN
                                              --AppControl.dbo.GPSlogsmryv2 AS g ON g.deviceId COLLATE SQL_Latin1_General_CP1_CI_AS = r.Id
                            WHERE      (r.actVehicleStartTime IS NOT NULL) AND (r.actVehicleEndTime IS NULL) AND (r.shiftDate BETWEEN DATEADD(dd, - 1, CAST(dateadd(n,330,getdate()) AS DATE)) AND DATEADD(dd, 1, CAST(dateadd(n,330,getdate()) AS DATE)))
                        and  isnull(r.vendorid,0)>= (case when @vendorid=0 then 0  else @vendorid  end)
						and  isnull(r.vendorid,0)<= (case when @vendorid=0 then (select max(id) from vendor )  else @vendorid  end)
						and r.facilityId=@facid 
						)) 
		or (@type=1 AND r.id IN --TripNotStarted
						 (SELECT     r.Id FROM ROUTE AS r --LEFT OUTER JOIN
                                                   --AppControl.dbo.GPSlogsmryv2 AS g ON g.deviceId COLLATE SQL_Latin1_General_CP1_CI_AS  = r.Id
                            WHERE      (r.actVehicleStartTime IS NULL) AND (r.actVehicleEndTime IS NULL) --AND (g.deviceId IS NULL) 
                       			AND ((r.triptype='P' and dateadd(n,-360, CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME))<dateadd(n,330,getdate()))
							or (r.triptype='D' and dateadd(n,15,CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME)) <dateadd(n,330,getdate())))
						
							AND (( (r.triptype='P' or isnull(r.isB2B,0)=1) and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN DATEADD(hh, -4, dateadd(n,330,getdate())) AND DATEADD(hh, 6, dateadd(n,330,getdate())))
							or (r.triptype='D' and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN  DATEADD(n, -240, dateadd(n,330,getdate())) and  DATEADD(n, 0, dateadd(n,330,getdate())))
							
							
						)
						and  isnull(r.vendorid,0)>= (case when @vendorid=0 then 0  else @vendorid  end)
							and  isnull(r.vendorid,0)<= (case when @vendorid=0 then (select max(id) from vendor )  else @vendorid  end)
							and r.facilityId=@facid 
						))	
		or (@type=2 AND r.id IN --TripWithIdleState
						 (SELECT     g.deviceId COLLATE SQL_Latin1_General_CP1_CI_AS FROM ROUTE AS r INNER JOIN
                                                   AppControl.dbo.GPSlogsmryv2 AS g ON g.deviceId COLLATE SQL_Latin1_General_CP1_CI_AS = r.Id
                            WHERE      (r.actVehicleStartTime IS NOT NULL) AND (r.actVehicleEndTime IS NULL)
							AND (( (r.triptype='P' or isnull(r.isB2B,0)=1) and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN DATEADD(hh, -4, dateadd(n,330,getdate())) AND  DATEADD(hh, 6, dateadd(n,330,getdate())))
							or (r.triptype='D' and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN  DATEADD(n, -240, dateadd(n,330,getdate())) and DATEADD(n, 0, dateadd(n,330,getdate())))) 
							
							and  isnull(r.vendorid,0)>= (case when @vendorid=0 then 0  else @vendorid  end)
							and  isnull(r.vendorid,0)<= (case when @vendorid=0 then (select max(id) from vendor )  else @vendorid  end)
							and r.facilityId=@facid 
                            GROUP BY g.deviceId  COLLATE SQL_Latin1_General_CP1_CI_AS
                            HAVING      (MAX(g.updatedAt)  < DATEADD(n, - 5, dateadd(n,330,getdate())))
                        ))
        or (@type=5 AND r.id IN --TripWithOverSpeed
						 (SELECT     g.deviceId COLLATE SQL_Latin1_General_CP1_CI_AS FROM ROUTE AS r INNER JOIN
                                                   AppControl.dbo.GPSlogOverSpeed AS g ON g.deviceId COLLATE SQL_Latin1_General_CP1_CI_AS = r.Id AND g.clientid=r.ClientID
                            WHERE      
							(r.actVehicleStartTime IS NOT NULL) --AND (r.actVehicleEndTime IS NULL)
							AND (( (r.triptype='P'or isnull(r.isB2B,0)=1) and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN DATEADD(hh, -4, dateadd(n,330,getdate())) AND  DATEADD(hh, 6, dateadd(n,330,getdate())))
							or (r.triptype='D' and CAST(CONVERT(VARCHAR, r.shiftDate, 101) + ' ' + LEFT(r.shiftTime, 2) + ':' + RIGHT(LTRIM(RTRIM(r.shiftTime)), 2) AS DATETIME) BETWEEN  DATEADD(n, -240, dateadd(n,330,getdate())) and DATEADD(n, 0, dateadd(n,330,getdate())))) 
                            --and cast(g.speed as float)<35
							and  isnull(r.vendorid,0)>= (case when @vendorid=0 then 0  else @vendorid  end)
							and  isnull(r.vendorid,0)<= (case when @vendorid=0 then (select max(id) from vendor )  else @vendorid  end)
							and r.facilityId=@facid 
							GROUP BY g.deviceId  COLLATE SQL_Latin1_General_CP1_CI_AS
                            
                        ))
						order by r.shiftDate,r.shiftTime,r.tripType,r.id