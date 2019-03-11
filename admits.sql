--All Acute Admissions (including pending)
--Drop All Tables


    DROP TABLE #AcAdm;

    DROP TABLE #AcDisch;

    DROP TABLE #AcAdm;

    DROP TABLE #SubDisch;
	
	DROP TABLE #indx;

	DROP TABLE #AcAdmEMPI;
--------------------------------------------------------------------------

SELECT R.REFERRAL_KEY
      ,R.PATIENT
      ,R.ACT_ADM_DT
      ,R.ACT_DISCH_DT
      ,PriorAcuteDisch=cast(null as smalldatetime)
      ,PriorAcuteAdm=cast(null as smalldatetime)
      ,PriorSubDisch=cast(null as smalldatetime)
      ,PriorSubAdm=cast(null as smalldatetime)
      ,b.DISCHARGE_DISPOSITION
INTO #AcAdm
-- select top 100 *
FROM DW3_ENC_BAR.dbo.REFERRL R (nolock)
JOIN DW3_ENC_BAR.dbo.DN517 RS (nolock)
  on RS.Record_Number=R.[STATUS]
JOIN DSS.dbo.BD_Admission_Types AT (nolock)
  on AT.ATKey=R.TYPE_OF_ADM
LEFT JOIN DW3_ENC_BAR.dbo.DN39 b (NOLOCK)
  ON r.DISCH_DISP = b.Record_Number
WHERE R.REF_TYPE in (1,29,30)
  and (RS.STATUS_TYPE='APPROVED'
  or  (RS.STATUS_TYPE='OTHER'
  and  RS.NAME like '%PEND%'))
--  and R.ACT_ADM_DT between DATEADD(yy,-1,DSS.dbo.dtm_FirstofYear(getdate())) and dateadd(d,-1,DSS.dbo.dtm_StripTime(getdate()))
    and R.ACT_ADM_DT > '1/1/2017'
  and (R.ACT_DISCH_DT is null
   or  R.ACT_DISCH_DT>=R.ACT_ADM_DT)
  and AT.DTKey=14 --adult acute
-- select top 100 * from #AcAdm
-- 87,967


---------------------------------------------------------------------------------------------------

--All Acute Discharges (including pending)
IF OBJECT_ID('#AcDisch') IS NOT NULL
    DROP TABLE #AcDisch;
    
SELECT R.REFERRAL_KEY
      ,R.PATIENT
      ,R.ACT_ADM_DT
      ,R.ACT_DISCH_DT
INTO #AcDisch
FROM DW3_ENC_BAR.dbo.REFERRL R (nolock)
JOIN DW3_ENC_BAR.dbo.DN517 RS (nolock)
  on RS.Record_Number=R.[STATUS]
JOIN DSS.dbo.BD_Admission_Types AT (nolock)
  on AT.ATKey=R.TYPE_OF_ADM
WHERE R.REF_TYPE in (1,29,30)
  and (RS.STATUS_TYPE='APPROVED'
  or  (RS.STATUS_TYPE='OTHER'
  and  RS.NAME like '%PEND%'))
  and R.ACT_ADM_DT is not null
  and (R.ACT_DISCH_DT is null
   or  (R.ACT_DISCH_DT>=R.ACT_ADM_DT
  -- and   R.ACT_DISCH_DT>=dateadd(d,-30,dateadd(yy,-1,DSS.dbo.dtm_FirstofYear(getdate())))))
    and   R.ACT_DISCH_DT>= '12/2/2016'))
  and AT.DTKey=14 --adult acute
-- select top 100 * from #AcDisch

---------------------------------------------------------------------------------------------------

--All SubAcute Discharges (including pending)
IF OBJECT_ID('#SubDisch') IS NOT NULL
    DROP TABLE #SubDisch;
    
SELECT R.REFERRAL_KEY
      ,R.PATIENT
      ,R.ACT_ADM_DT
      ,R.ACT_DISCH_DT
INTO #SubDisch
FROM DW3_ENC_BAR.dbo.REFERRL R (nolock)
JOIN DW3_ENC_BAR.dbo.DN517 RS (nolock)
  on RS.Record_Number=R.[STATUS]
WHERE R.REF_TYPE in (1,29,30)
  and (RS.STATUS_TYPE='APPROVED'
  or  (RS.STATUS_TYPE='OTHER'
  and  RS.NAME like '%PEND%'))
  and R.ACT_ADM_DT is not null
  and (R.ACT_DISCH_DT is null
   or  (R.ACT_DISCH_DT>=R.ACT_ADM_DT
  --and   R.ACT_DISCH_DT>=dateadd(d,-30,dateadd(yy,-1,DSS.dbo.dtm_FirstofYear(getdate())))))
    and   R.ACT_DISCH_DT>= '12/2/2016'))
  and R.TYPE_OF_ADM in (2,21) --subacute
-- select top 100 * from #SubDisch
  
---------------------------------------------------------------------------------------------------

--Remove Acute-to-Acute Transfers   
DELETE a
FROM #AcAdm a
JOIN #AcDisch b
  on b.PATIENT=a.PATIENT
 and b.REFERRAL_KEY!=a.REFERRAL_KEY
WHERE (b.ACT_ADM_DT<a.ACT_ADM_DT --MDS to any (including overlap)
  and  b.ACT_DISCH_DT>=a.ACT_ADM_DT)
   or (b.ACT_ADM_DT<a.ACT_ADM_DT --overlap open
  and  b.ACT_DISCH_DT is null)
   or (b.ACT_DISCH_DT=b.ACT_ADM_DT --SDD to ODS/MDS
  and  b.ACT_DISCH_DT=a.ACT_ADM_DT
  and  a.ACT_DISCH_DT>a.ACT_ADM_DT)
   or (b.ACT_DISCH_DT=b.ACT_ADM_DT --SDD to open
  and  b.ACT_DISCH_DT=a.ACT_ADM_DT
  and  a.ACT_DISCH_DT is null)
 
---------------------------------------------------------------------------------------------------

--Find last prior acute dates
UPDATE #AcAdm
SET #AcAdm.PriorAcuteDisch=
(select max(#AcDisch.ACT_DISCH_DT)
 from #AcDisch
 where #AcDisch.PATIENT=#AcAdm.PATIENT
   and #AcDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
   and #AcDisch.ACT_DISCH_DT between dateadd(d,-30,#AcAdm.ACT_ADM_DT) and dateadd(d,-1,#AcAdm.ACT_ADM_DT))

UPDATE #AcAdm
SET #AcAdm.PriorAcuteAdm=
(select max(#AcDisch.ACT_ADM_DT)
 from #AcDisch
 where #AcDisch.PATIENT=#AcAdm.PATIENT
   and #AcDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
   and #AcDisch.ACT_DISCH_DT=#AcAdm.PriorAcuteDisch)
WHERE #AcAdm.PriorAcuteDisch is not null

--Find last prior subacute dates
UPDATE #AcAdm
SET #AcAdm.PriorSubAdm=
(select max(#SubDisch.ACT_ADM_DT)
 from #SubDisch
 where #SubDisch.PATIENT=#AcAdm.PATIENT
   and #SubDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
   and #SubDisch.ACT_ADM_DT<#AcAdm.ACT_ADM_DT --overlapping open
   and #SubDisch.ACT_DISCH_DT is null)

--Find last prior subacute Discharge date
UPDATE #AcAdm
SET #AcAdm.PriorSubDisch=
(select max(#SubDisch.ACT_DISCH_DT)
 from #SubDisch
 where #SubDisch.PATIENT=#AcAdm.PATIENT
   and #SubDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
   and ((#SubDisch.ACT_DISCH_DT=#SubDisch.ACT_ADM_DT --SDD to ODS/MDS
   and   #SubDisch.ACT_DISCH_DT=#AcAdm.ACT_ADM_DT
   and   #AcAdm.ACT_DISCH_DT>#AcAdm.ACT_ADM_DT)
    or  (#SubDisch.ACT_DISCH_DT=#SubDisch.ACT_ADM_DT --SDD to open
   and   #SubDisch.ACT_DISCH_DT=#AcAdm.ACT_ADM_DT
   and   #AcAdm.ACT_DISCH_DT is null)
    or  (#SubDisch.ACT_ADM_DT<#AcAdm.ACT_ADM_DT --Any prior to within 30
   and   #SubDisch.ACT_DISCH_DT>=dateadd(d,-30,#AcAdm.ACT_ADM_DT))))
WHERE #AcAdm.PriorSubAdm is null
   
UPDATE #AcAdm
SET #AcAdm.PriorSubAdm=
(select max(#SubDisch.ACT_ADM_DT)
 from #SubDisch
 where #SubDisch.PATIENT=#AcAdm.PATIENT
   and #SubDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
   and #SubDisch.ACT_DISCH_DT=#AcAdm.PriorSubDisch)
WHERE #AcAdm.PriorSubDisch is not null

--ignore subacute if intervening acute
UPDATE #AcAdm
SET PriorSubAdm=null
   ,PriorSubDisch=null
WHERE PriorSubDisch<PriorAcuteDisch

---------------------------------------------------------------------------------------------------

--create index of keys
IF OBJECT_ID('#indx') IS NOT NULL
    DROP TABLE #indx;
    
SELECT ReadmitFrom=cast('Acute' as varchar(20))
      ,DischargeKey=#AcDisch.REFERRAL_KEY
      ,AdmitKey=#AcAdm.REFERRAL_KEY
      ,#AcAdm.PATIENT
INTO #indx
FROM #AcAdm (nolock)
JOIN #AcDisch (nolock)
  on #AcDisch.PATIENT=#AcAdm.PATIENT
 and #AcDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
 and #AcDisch.ACT_ADM_DT=#AcAdm.PriorAcuteAdm
 and #AcDisch.ACT_DISCH_DT=#AcAdm.PriorAcuteDisch
-- select top 100 * from #indx

---------------------------------------------------------------------------------------------------

INSERT INTO #indx
SELECT ReadmitFrom=cast('SubAcute' as varchar(20))
      ,DischargeKey=#SubDisch.REFERRAL_KEY
      ,AdmitKey=#AcAdm.REFERRAL_KEY
      ,#AcAdm.PATIENT
FROM #AcAdm (nolock)
JOIN #SubDisch (nolock)
  on #SubDisch.PATIENT=#AcAdm.PATIENT
 and #SubDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
 and #SubDisch.ACT_ADM_DT=#AcAdm.PriorSubAdm
 and #SubDisch.ACT_DISCH_DT is null
 and #AcAdm.PriorSubDisch is null

INSERT INTO #indx
SELECT ReadmitFrom=cast('SubAcute' as varchar(20))
      ,DischargeKey=#SubDisch.REFERRAL_KEY
      ,AdmitKey=#AcAdm.REFERRAL_KEY
      ,#AcAdm.PATIENT
FROM #AcAdm (nolock)
JOIN #SubDisch (nolock)
  on #SubDisch.PATIENT=#AcAdm.PATIENT
 and #SubDisch.REFERRAL_KEY!=#AcAdm.REFERRAL_KEY
 and #SubDisch.ACT_ADM_DT=#AcAdm.PriorSubAdm
 and #SubDisch.ACT_DISCH_DT=#AcAdm.PriorSubDisch
-- select top 100 * from #indx
-- select distinct ReadmitFrom from #indx

IF OBJECT_ID('#AcAdmEMPI') IS NOT NULL
    DROP TABLE #AcAdmEMPI;

SELECT a.*, b.EMPI
INTO #AcAdmEMPI
-- select top 100 *
-- select count(*)
FROM #AcAdm a
	INNER JOIN DW3_ENC_BAR.dbo.LU_EMPI b (NOLOCK)
  ON a.PATIENT = b.LPI AND b.LPI_SYSTEM_KEY = 1 AND Rel_Term_Dt IS NULL
select * from #AcAdmEMPI