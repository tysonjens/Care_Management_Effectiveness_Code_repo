/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
	  P.[EMPI]
	  ,DP.[Patient_SK]
	  ,P.[PTNT_DK]
	  --,S.[PTNT_DK]
	  ,S.[RGON_NM]
	  ,S.[HP_NM]
	  ,S.[LOB_SUB_CGY]
	  ,S.[CLNC_NM]
	  ,S.[ENT_TYPE]
	  ,DP.[DOB]
	  ,DP.[Sex]
	  ,DP.[Race]
	  ,DP.[Current_Member]
	  ,DP.[ZipCode]
	  ,DP.[Deceased_Flag]
	  ,DP.Eff_Date
      ,DP.End_Date
	  ,P.[PRGM_NM]
	  ,P.[ASGN_TMS]
	  ,P.[END_TMS]
	  ,P.[TNT_MKT_BK]
      ,P.[PRGM_STS]
	  ,P.[PRGM_STOP_RSN]
	  ,P.[ASGN_USR]
	  ,P.[PRIM_PRGM_FLAG]

  FROM [CIM_RPT].[dbo].[PTNT_PRGM] as P
  
  Join [CIM_RPT].[dbo].[PTNT_RPT_ATTR] as S on P.[PTNT_DK]=S.[PTNT_DK]
  Join [NATIONAL_ANALYTICS].[dbo].[DIM_PATIENT] DP ON P.EMPI = DP.[EMPI]

  Where P.[TNT_MKT_BK]='CA'
  AND P.[ASGN_TMS] > '2018-04-01'

  Group by
     P.[EMPI]
	  ,DP.[Patient_SK]
	  ,P.[PTNT_DK]
	  --,S.[PTNT_DK]
	  ,S.[RGON_NM]
	  ,S.[HP_NM]
	  ,S.[LOB_SUB_CGY]
	  ,S.[CLNC_NM]
	  ,S.[ENT_TYPE]
	  ,DP.[DOB]
	  ,DP.[Sex]
	  ,DP.[Race]
	  ,DP.[Current_Member]
	  ,DP.[ZipCode]
	  ,DP.[Deceased_Flag]
	  ,DP.Eff_Date
      ,DP.End_Date
	  ,P.[PRGM_NM]
	  ,P.[ASGN_TMS]
	  ,P.[END_TMS]
	  ,P.[TNT_MKT_BK]
      ,P.[PRGM_STS]
	  ,P.[PRGM_STOP_RSN]
	  ,P.[ASGN_USR]
	  ,P.[PRIM_PRGM_FLAG]

	--Select
		--	Min (MEMBER_EFF_DT)
			--,Max (MEMBER_TERM_DT)
	  
		--FROM [IADS_V3].[dbo].[LU_ELIGIBILITY]
