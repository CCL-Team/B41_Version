/********************************************************************************************************************
 
        Source file name:		cust_script:15_acm_ur_productivity_238724.prg
        Object name:        	15_acm_ur_productivity_238724
        Implementation date: 	5/9/2023
 
        Executing from:			OPSJOB only

 		Purpose: 				This report displays Review details by review date/user occuring the previous day
 								for productivity.  Cannot be backdated without quality issues because of daily form 
 								changes.  Copied from 15_acm_ur_productivity_236368.prg.
 
        Associated Layout
        /programs:				NA
 
        Special notes:
 
*********************************************************************************************************************
                      GENERATED MODIFICATION CONTROL LOG                 *
*********************************************************************************************************************
 Mod Date     		Engineer     	    		MCGA/OPAS 				Comments
 --- -------- 		------------ 				------------ 		-------------------------------------------------
 000  5/9/2023		Kim Frazier					238724				Initial Build
 001  9/20/2023		Kim Frazier										Found history file to only pull when it was created
 003  11/20/2023	KRF						SCTASK0055898			Limit to 4 activity types
 003a																	Add prompt by type
 003b																	Add prompt by review created date, disch, admit
 																	
*********************************************************************************************************************/
drop program 15_acm_ur_productiv_238724_t:dba go
create program 15_acm_ur_productiv_238724_t:dba
prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Facility" = 0
	, "Begin Date" = "CURDATE"
	, "End Date" = "CURDATE"
	, "Date As:" = "1"
	, "Activity Types:" = 0
	, "Summary Data" = 0
	, "eMail" = "" 

with OUTDEV, facility, CREATE_BEG_DT, CREATE_END_DT, use_date_as, activity_type, 
	summaryFlag, EMAIL
%i cust_script:ccps_ld_security.inc	
if (ISOPSJOB = 1 and curdomain != "P41") ;do not run in non-prod from ops
 go to EXITSCRIPT
endif 
if($email > " " and findstring("@MEDSTAR.NET",cnvtupper($email),1,1) =0
			   and findstring("@GEORGETOWN.",cnvtupper($email),1,1) =0
			   and  findstring("@GUNET.",cnvtupper($email),1,1) =0)
select into $outdev
"Email must be directed to an approved Medstar email address."
from dummyt d
with nocounter
go to  EXITSCRIPT
endif
	declare dt_begin = vc with protect, constant($create_beg_dt)
	declare dt_end = vc with protect,constant($create_end_dt)
	
if( $outdev = "OPS")
	declare dt_begin = vc with protect, constant(format(cnvtdate(curdate-1),"dd-mmm-yyyy;;d"))
	declare dt_end = vc with protect,constant(dt_begin)
elseif($create_beg_dt <= "") ;001 added if so it won't overwrite the exiting create dt begin/end
	declare dt_begin = vc with protect, constant(format(cnvtdate(curdate),"dd-mmm-yyyy;;d"))
	declare dt_end = vc with protect,constant(dt_begin)
endif

declare dt_parser_ru = vc with protect,public
declare dt_review_parser = vc with public,protect
declare dt_create_parser = vc with public,protect ;001
set dt_parser_ru = concat("ecr.updt_dt_tm between cnvtdatetime(concat(dt_begin, ", '"', " 00:00", '"))', 
	" and cnvtdatetime(concat(dt_end, ", '"', " 23:59:59", '"))')
set dt_review_parser =concat("ecr.reviewed_dt_tm between cnvtdatetime(concat(dt_begin, ", '"', " 00:00", '"))', 
	" and cnvtdatetime(concat(dt_end, ", '"', " 23:59:59", '"))')
set dt_create_parser = 	concat("ra1.action_dt_tm between cnvtdatetime(concat(dt_begin, ", '"', " 00:00", '"))', 
	" and cnvtdatetime(concat(dt_end, ", '"', " 23:59:59", '"))') ;001
	
call echo(build("dt_review_parser ", dt_review_parser))



;003b by admit or disch date
declare dt_admit_parser = vc with protect,public, noconstant("1=1")
declare dt_disch_parser = vc with protect,public, noconstant("1=1")
if($use_date_as = "2")
	set dt_admit_parser = concat("e.reg_dt_tm between cnvtdatetime(concat(dt_begin, ", '"', " 00:00", '"))', 
	" and cnvtdatetime(concat(dt_end, ", '"', " 23:59:59", '"))')
elseif($use_date_as = "3") 
	set dt_disch_parser = concat("e.disch_dt_tm between cnvtdatetime(concat(dt_begin, ", '"', " 00:00", '"))', 
	" and cnvtdatetime(concat(dt_end, ", '"', " 23:59:59", '"))')
endif	



free record rpt_data
record rpt_data
(
	1 qual[*]
		2 encntr_id = f8
		2 facility = vc
		2 Patient_Name = vc
		2 Unit_Bed_Room = vc
		2 Primary_Payor = vc
		2 Secondary_Payor = vc
		2 Admission_Date = vc
		2 FIN = vc
		2 MRN = vc
		2 Discharge_Date = vc
		2 UM_Status = vc
		2 Review_Date = vc
		2 Review_Updated = vc
		2 Reviewer = vc

		2 clin_rev_id = f8
		2 Review_type = vc
		2 encntr_type = vc
		2 1st_level_outcome = vc
		2 complete_dt = dq8
		2 transmit_dt = dq8
		2 fax_status = vc
		2 content_source = vc
		2 review_result = vc		
		2 updt_dt_tm = dq8
		2 activity = vc ;001
		2 review_id = f8
		
)

%i cust_script:SC_CPS_GET_PROMPT_LIST.inc
declare sfac = vc with public,protect 
declare fac_parser = vc with protect, noconstant(GetPromptList(2, "e.loc_facility_cd"))
if (fac_parser = "1=1")
    set fac_parser = 
"e.loc_facility_cd in (633867.0,4363210.0,4362818.0,4363058.0,446795444.0,4364516.0,465210143.0,465209542.0,4363156.0,4363216.0)"
	set sfac = "ANY" 
else

	select into "NL:"
	from code_value cv
	where cv.code_value = $facility
	and cv.code_set = 220
	detail
	sfac = build2(trim(sfac),", ", trim(cv.display))
	foot report
	sfac = substring(2,size(sfac),sfac) ;remove 1st comma
	with nocounter
endif

;003a by activity type
declare action_parser = vc with protect,public, noconstant(GetPromptList(6, "ra.action_type_cd"))
call echo(action_parser)


declare cnt = i4 with protect, noconstant(0)
declare FINNBR = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 319, "FINNBR"))
declare MRN = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 319, "MRN"))
declare INPATIENT = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 71, "INPATIENT"))
declare OBSERVATION = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 71, "OBSERVATION"))
declare MANUAL = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 4002407, "MANUAL"))
declare currTime = vc with protect, constant(format(cnvtdatetime(curdate, curtime3),"_yyyymmddhhmmss;;q"))
if(curdomain = "B41")
	set currentdomain = "d_b41/"
else
	set currentdomain = "d_p41/temp/"
endif
declare filename = vc with protect, constant(build2("/cerner/", currentdomain, "rev_yesterday", currTime, ".csv"))
declare email_subject = vc with protect, constant("UR Productivity ")
declare email_body = vc with protect, constant(concat("rev_yesterday", currTime, ".dat"));;;must be unique to this object
declare aix_command = vc with noconstant("")
declare aix_cmdlen = i4 with noconstant(0)
declare aix_cmdstatus = i4 with noconstant(0)
declare email_address = vc with protect, public ;constant("kathryn.powers@medstar.net,olutoyin.idowu@medstar.net")
set email_address = $email 

if($use_date_as ="1") ;by review create date ;003b
	select into "nl:"
	content_source = uar_get_code_display(ecr.content_source_cd)
	,rev_type = evaluate2(if(uar_get_code_display(ecr.review_type_cd)> " ")
					uar_get_code_display(ecr.review_type_cd)
					else
					" (blank)"
					endif)
	,enc_type = uar_get_code_display(e.encntr_type_cd)
	,this_fac = uar_get_code_display(e.loc_facility_cd)
	,review_result = uar_get_code_display(ecr.review_result_cd)
	from 
		encntr_clin_review ecr
		,rcm_action ra
		,encounter e
		,encntr_care_mgmt ecm
		,person p
		,encntr_alias ea
		,encntr_alias pa
	;	,encntr_plan_reltn epr
	;	,health_plan hp
		,prsnl ps
	
	plan ecr
		where (parser(dt_review_parser) 
		OR
		(parser(dt_parser_ru)
			and ecr.encntr_clin_review_id = ecr.clinical_review_id) ;first instance
	
		)
		and exists(select clinical_review_id from encntr_clin_review where clinical_review_id = ecr.clinical_review_id and 
										version_dt_tm > cnvtdatetime(curdate,curtime) );filter out started, but not showing in Powerchart
	and exists( select ra1.rcm_action_id 
				from rcm_action ra1
				where ra1.parent_entity_name = "ENCNTR_CLIN_REVIEW"
				and ra1.parent_entity_id = ecr.encntr_clin_review_id
		    and ra1.action_type_cd in(   84472996.00) ;created
	;	    							,84473000.00) ;finalized
			and parser(dt_create_parser)
	)
	
	join ra ;001
		where ra.parent_entity_name = "ENCNTR_CLIN_REVIEW"
			and ra.parent_entity_id = ecr.encntr_clin_review_id
			and ra.action_type_cd in (84472996.00,84473000.00,  252929664.00,  252929671.00);003
			and parser(action_parser) ;003a
			
	join e
		where e.encntr_id = ecr.encntr_id
		and parser(fac_parser)
	
	join ecm
		where ecm.encntr_id = outerjoin(e.encntr_id)
		and ecm.active_ind = outerjoin(1)
	
	join p
		where p.person_id = e.person_id
		and p.name_full_formatted not like "ZZZ*"
	join ea
		where ea.encntr_id = e.encntr_id
		and ea.active_ind = 1
		and ea.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
		and ea.encntr_alias_type_cd =FINNBR
	join pa
		where pa.encntr_id = e.encntr_id
		and pa.active_ind = 1
		and pa.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
		and pa.encntr_alias_type_cd =MRN	
	;join epr
	;	where epr.encntr_id = e.encntr_id
	;	and epr.active_ind = 1
	;	and epr.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
	;join hp
	;	where hp.health_plan_id = epr.health_plan_id
	
	join ps
		where ps.person_id = ra.action_prsnl_id;001 ecr.updt_id
	
	order e.encntr_id,ecr.clinical_review_id,ra.rcm_action_id, ra.action_dt_tm
	head report
		cnt = 0
	head e.encntr_id
	NULL	
	;head ecr.clinical_review_id
	detail
		if (mod(cnt, 10) = 0)
			stat = alterlist(rpt_data->qual, cnt + 10)
		endif
		cnt = cnt + 1
		rpt_data->qual[cnt].encntr_id = e.encntr_id
		rpt_data->qual[cnt].facility = this_fac
		rpt_data->qual[cnt].Admission_Date = format(e.reg_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Discharge_Date = format(e.disch_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Unit_Bed_Room = uar_get_code_display(e.loc_nurse_unit_cd)
		rpt_data->qual[cnt].Patient_Name = p.name_full_formatted
		rpt_data->qual[cnt].UM_Status = trim(uar_get_code_display(ecm.utlztn_mgmt_status_cd))
		rpt_data->qual[cnt].Review_Date = format(ecr.reviewed_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Review_Updated = format(ecr.updt_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Reviewer = ps.name_full_formatted 
		rpt_data->qual[cnt].Review_type = rev_type
		rpt_data->qual[cnt].encntr_type = enc_type
		rpt_data->qual[cnt].clin_rev_id = ecr.clinical_review_id
		rpt_data->qual[cnt].complete_dt = ecr.reviewed_dt_tm
	;	rpt_data->qual[cnt].transmit_dt = ecr.transmitted_dt_tm
		rpt_data->qual[cnt].CONTENT_SOURCE= content_source
	;moved beloe	rpt_data->qual[cnt].review_result= review_result
		rpt_data->qual[cnt].updt_dt_tm = ra.action_dt_tm; ecr.updt_dt_tm
		
		rpt_data->qual[cnt].activity = uar_get_code_display(ra.action_type_cd) ;001 added column for validation
		rpt_data->qual[cnt].review_id = ecr.clinical_review_id ;001 added column for validation
	;detail
	;	if (epr.priority_seq in (1, 0))
	;		rpt_data->qual[cnt].Primary_Payor = hp.plan_name
	;	elseif (epr.priority_seq = 2)
	;		rpt_data->qual[cnt].Secondary_Payor = hp.plan_name
	;	endif
			rpt_data->qual[cnt].FIN = ea.alias
			rpt_data->qual[cnt].MRN = pa.alias
	
	foot report
		stat = alterlist(rpt_data->qual, cnt)
	with nocounter
	
else ;003b by admit or discharge	
	select into "nl:"
	content_source = uar_get_code_display(ecr.content_source_cd)
	,rev_type = evaluate2(if(uar_get_code_display(ecr.review_type_cd)> " ")
					uar_get_code_display(ecr.review_type_cd)
					else
					" (blank)"
					endif)
	,enc_type = uar_get_code_display(e.encntr_type_cd)
	,this_fac = uar_get_code_display(e.loc_facility_cd)
	,review_result = uar_get_code_display(ecr.review_result_cd)
	from 
		encntr_clin_review ecr
		,rcm_action ra
		,encounter e
		,encntr_care_mgmt ecm
		,person p
		,encntr_alias ea
		,encntr_alias pa
	;	,encntr_plan_reltn epr
	;	,health_plan hp
		,prsnl ps


	plan e
		where parser(dt_admit_parser)
		and parser(dt_disch_parser)
		and parser(fac_parser)
	
	join ecr
		where ecr.encntr_id = e.encntr_id
		and exists(select clinical_review_id from encntr_clin_review where clinical_review_id = ecr.clinical_review_id and 
										version_dt_tm > cnvtdatetime(curdate,curtime) );filter out started, but not showing in Powerchart
;	and exists( select ra1.rcm_action_id 
;				from rcm_action ra1
;				where ra1.parent_entity_name = "ENCNTR_CLIN_REVIEW"
;				and ra1.parent_entity_id = ecr.encntr_clin_review_id
;		    and ra1.action_type_cd in(   84472996.00) ;created
;	;	    							,84473000.00) ;finalized
;			;and parser(dt_create_parser)
;	)
	
	join ra ;001
		where ra.parent_entity_name = "ENCNTR_CLIN_REVIEW"
			and ra.parent_entity_id = ecr.encntr_clin_review_id
			and ra.action_type_cd in (84472996.00,84473000.00,  252929664.00,  252929671.00);003
			and parser(action_parser) ;003a
	;		and parser(dt_create_parser)
			

	
	join ecm
		where ecm.encntr_id = outerjoin(e.encntr_id)
		and ecm.active_ind = outerjoin(1)
	
	join p
		where p.person_id = e.person_id
		and p.name_full_formatted not like "ZZZ*"
	join ea
		where ea.encntr_id = e.encntr_id
		and ea.active_ind = 1
		and ea.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
		and ea.encntr_alias_type_cd =FINNBR
	join pa
		where pa.encntr_id = e.encntr_id
		and pa.active_ind = 1
		and pa.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
		and pa.encntr_alias_type_cd =MRN	

	
	join ps
		where ps.person_id = ra.action_prsnl_id;001 ecr.updt_id
	
	order e.encntr_id,ecr.clinical_review_id,ra.rcm_action_id, ra.action_dt_tm
	head report
		cnt = 0
	head e.encntr_id
	NULL	
	;head ecr.clinical_review_id
	detail
		if (mod(cnt, 10) = 0)
			stat = alterlist(rpt_data->qual, cnt + 10)
		endif
		cnt = cnt + 1
		rpt_data->qual[cnt].encntr_id = e.encntr_id
		rpt_data->qual[cnt].facility = this_fac
		rpt_data->qual[cnt].Admission_Date = format(e.reg_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Discharge_Date = format(e.disch_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Unit_Bed_Room = uar_get_code_display(e.loc_nurse_unit_cd)
		rpt_data->qual[cnt].Patient_Name = p.name_full_formatted
		rpt_data->qual[cnt].UM_Status = trim(uar_get_code_display(ecm.utlztn_mgmt_status_cd))
		rpt_data->qual[cnt].Review_Date = format(ecr.reviewed_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Review_Updated = format(ecr.updt_dt_tm, "MM-DD-YYYY")
		rpt_data->qual[cnt].Reviewer = ps.name_full_formatted 
		rpt_data->qual[cnt].Review_type = rev_type
		rpt_data->qual[cnt].encntr_type = enc_type
		rpt_data->qual[cnt].clin_rev_id = ecr.clinical_review_id
		rpt_data->qual[cnt].complete_dt = ecr.reviewed_dt_tm
	;	rpt_data->qual[cnt].transmit_dt = ecr.transmitted_dt_tm
		rpt_data->qual[cnt].CONTENT_SOURCE= content_source
	;moved beloe	rpt_data->qual[cnt].review_result= review_result
		rpt_data->qual[cnt].updt_dt_tm = ra.action_dt_tm; ecr.updt_dt_tm
		
		rpt_data->qual[cnt].activity = uar_get_code_display(ra.action_type_cd) ;001 added column for validation
		rpt_data->qual[cnt].review_id = ecr.clinical_review_id ;001 added column for validation
	;detail
	;	if (epr.priority_seq in (1, 0))
	;		rpt_data->qual[cnt].Primary_Payor = hp.plan_name
	;	elseif (epr.priority_seq = 2)
	;		rpt_data->qual[cnt].Secondary_Payor = hp.plan_name
	;	endif
			rpt_data->qual[cnt].FIN = ea.alias
			rpt_data->qual[cnt].MRN = pa.alias
	
	foot report
		stat = alterlist(rpt_data->qual, cnt)
	with nocounter
endif

;*********************************************************************
;***********Get payers ***********************
;*********************************************************************
select into "NL:"

from 
	(dummyt d with seq = size(rpt_data->qual, 5))
	,encntr_plan_reltn epr
	,health_plan hp
	
plan d	
join epr
	where epr.encntr_id = rpt_data->qual[d.seq].encntr_id 
	and epr.active_ind = 1
	and epr.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
join hp
	where hp.health_plan_id = epr.health_plan_id
detail
	if (epr.priority_seq in (1, 0))
		rpt_data->qual[d.seq].Primary_Payor = hp.plan_name
	elseif (epr.priority_seq = 2)
		rpt_data->qual[d.seq].Secondary_Payor = hp.plan_name
	endif
with nocounter
	
;*********************************************************************
;***********Get most recent outcome of review ***********************
;*********************************************************************
select into "NL:"
review_result = uar_get_code_display(ecr.review_result_cd)
from 
	(dummyt d with seq = size(rpt_data->qual, 5))
	,encntr_clin_review ecr
plan d
join ecr
where ecr.clinical_review_id = 	rpt_data->qual[d.seq].clin_rev_id 
and ecr.version_dt_tm > cnvtdatetime(curdate,curtime) ;most recent
order by d.seq, ecr.version_dt_tm
detail
rpt_data->qual[d.seq].review_result= review_result
with nocounter
;*********************************************************************
;***************Get comm for review? *******************************************
;*********************************************************************
select into "NL:"

from 
	(dummyt d with seq = size(rpt_data->qual, 5))
	,encntr_care_mgmt_comm_rltn ecmr
	,encntr_care_mgmt_comm ecmc
	plan d
	join ecmr
	where ecmr.parent_entity_name = "ENCNTR_CLIN_REVIEW"
	and ecmr.parent_entity_id = rpt_data->qual[d.seq].clin_rev_id 
	join ecmc
	where  ecmc.encntr_care_mgmt_comm_id = ecmr.encntr_care_mgmt_comm_id
detail
rpt_data->qual[d.seq].transmit_dt = ecmc.sent_dt_tm
rpt_data->qual[d.seq].fax_status = uar_get_code_display(ecmc.communication_status_cd)
with nocounter

/* output detail */

if( $summaryFlag = 0)
 if ($outdev != "OPS") ;detail to screen

	select into $outdev
	Facility= substring(1,50,rpt_data->qual[d.seq].facility),
	Reviewer = substring(1, 30, rpt_data->qual[d.seq].Reviewer),
	UM_Status = substring(1, 30, rpt_data->qual[d.seq].UM_Status), 
	Source = substring(1, 30,rpt_data->qual[d.seq].Content_source ),
	Review_type = substring(1, 30,rpt_data->qual[d.seq].Review_type ),
	Outcome =  substring(1, 30,rpt_data->qual[d.seq].Review_result ),
	Clin_Review_id = cnvtstring(rpt_data->qual[d.seq].clin_rev_id ),
	
	Unit = substring(1, 30, rpt_data->qual[d.seq].Unit_Bed_Room),
	Patient_Name = substring(1, 30, rpt_data->qual[d.seq].Patient_Name),
	Encounter_type = substring(1, 30,rpt_data->qual[d.seq].encntr_type ),
	FIN = substring(1, 30, rpt_data->qual[d.seq].FIN), 
	MRN = substring(1, 30, rpt_data->qual[d.seq].MRN), 
	Primary_Payor = substring(1, 30, rpt_data->qual[d.seq].Primary_Payor), 
	Secondary_Payor = substring(1, 30, rpt_data->qual[d.seq].Secondary_Payor), 
	Admission_Date = substring(1, 30, rpt_data->qual[d.seq].Admission_Date), 
	Discharge_Date = substring(1, 30, rpt_data->qual[d.seq].Discharge_Date), 
	 
	Review_Completed = format( rpt_data->qual[d.seq].complete_dt,"mm-dd-yyyy hh:mm;;d"), 
	Review_Transmitted = format( rpt_data->qual[d.seq].transmit_dt ,"mm-dd-yyyy hh:mm;;d"),
	Review_status = substring(1, 30,rpt_data->qual[d.seq].fax_status)
	,Update_dt_Tm = format(rpt_data->qual[d.seq].updt_dt_tm,"mm-dd-yyyy hh:mm;;d")
	,History_action = substring(1,20,rpt_data->qual[d.seq].Activity)
	,Review_id = cnvtstring(rpt_data->qual[d.seq].review_id)
	from 
		(dummyt d with seq = size(rpt_data->qual, 5))
	plan d
	order by facility,Reviewer,Review_Completed
	with format, separator = " "
	
 else ;email detail
	
	select into value(filename)
	Facility= substring(1,50,rpt_data->qual[d.seq].facility),
	Reviewer = substring(1, 30, rpt_data->qual[d.seq].Reviewer),
	UM_Status = substring(1, 30, rpt_data->qual[d.seq].UM_Status), 
	Source = substring(1, 30,rpt_data->qual[d.seq].Content_source ),
	Review_type = substring(1, 30,rpt_data->qual[d.seq].Review_type ),
	Outcome =  substring(1, 30,rpt_data->qual[d.seq].Review_result ),
	Clin_Review_id = cnvtstring(rpt_data->qual[d.seq].clin_rev_id ),
	
	Unit = substring(1, 30, rpt_data->qual[d.seq].Unit_Bed_Room),
	Patient_Name = substring(1, 30, rpt_data->qual[d.seq].Patient_Name),
	Encounter_type = substring(1, 30,rpt_data->qual[d.seq].encntr_type ),
	FIN = substring(1, 30, rpt_data->qual[d.seq].FIN), 
	MRN = substring(1, 30, rpt_data->qual[d.seq].MRN), 
	Primary_Payor = substring(1, 30, rpt_data->qual[d.seq].Primary_Payor), 
	Secondary_Payor = substring(1, 30, rpt_data->qual[d.seq].Secondary_Payor), 
	Admission_Date = substring(1, 30, rpt_data->qual[d.seq].Admission_Date), 
	Discharge_Date = substring(1, 30, rpt_data->qual[d.seq].Discharge_Date), 
	 
	Review_Completed = format( rpt_data->qual[d.seq].complete_dt,"mm-dd-yyyy hh:mm;;d"), 
	Review_Transmitted = format( rpt_data->qual[d.seq].transmit_dt ,"mm-dd-yyyy hh:mm;;d"),
	Review_status = substring(1, 30,rpt_data->qual[d.seq].fax_status)
	from 
		(dummyt d with seq = size(rpt_data->qual, 5))
	plan d
	order by facility,Reviewer,Review_Completed
	with heading, pcformat('"', ',', 1), format=stream, format, nocounter, compress
	
	endif ;email/MINE

else ;BUILD SUMMARY DATA

 free record summary
 record summary(
	1 qual[*] 
		2 prsnl_id = f8
		2 prsnl_name = vc
		2 reviewcount = i2
		2 fincount = i2
		2 umstat[*]
			3 UMstatus = vc
			3 um_rev_flag = c1
			3 rvcount = i2
			3 fincount = i2
;		2 revType[*]
;			3 reviewType = vc
;			3 rvcount = i2
;			3 fincount = i2
	)
declare n = i4 with public,protect
declare pos = i4 with public,protect	

;STORE SUMMARY BY um STATUS
select into "NL:"
this_reviewer = substring(1,50,rpt_data->qual[d.seq].Reviewer)
,this_fin =  substring(1,20,rpt_data->qual[d.seq].FIN )
,this_umstat = substring(1,40,rpt_data->qual[d.seq].UM_Status )
from (dummyt d with seq = size(rpt_data->qual,5))
order by this_Reviewer, this_FIN , this_umstat
head report
rcnt = 0
;fcnt = 0
umscnt = 0
rtcnt = 0
head this_reviewer
	rcnt += 1
	stat = alterlist(summary->qual,rcnt)
	;summary->qual[rcnt].prsnl_id 
	summary->qual[rcnt].prsnl_name = this_reviewer
	

	head this_fin
	summary->qual[rcnt].fincount += 1

	head this_umstat ;new umstat for new fin
	;call echo( build2("new fin",this_fin," - umstatus:" , this_umstat))
	n=0
	pos = locateval(n,1,size(summary->qual[rcnt].umstat,5),this_umstat,summary->qual[rcnt].umstat[n].UMstatus)
;	call echo(build2("POS =",cnvtstring(pos)))
	if(pos > 0)
	umscnt = pos
	else
;	call echo("add new umstatus")
	umscnt = size(summary->qual[rcnt].umstat,5) + 1 ;increase total size
	stat = alterlist(summary->qual[rcnt].umstat,umscnt)
	summary->qual[rcnt].umstat[umscnt].UMstatus = this_umstat
	summary->qual[rcnt].umstat[umscnt].um_rev_flag = "S"
	endif
	
	;call echo("inc fin count for um")
	summary->qual[rcnt].umstat[umscnt].fincount += 1
		detail
		;call echo("inc umstat review count")
		summary->qual[rcnt].umstat[umscnt].rvcount += 1 ;total by stat
		summary->qual[rcnt].reviewcount += 1			;total reviews

	foot this_umstat
	NULL

	foot this_fin
	NULL
foot this_reviewer
umscnt = 0
;fcnt = 0

with nocounter

;STORE SUMMARY BY REV TYPE
select into "NL:"
this_reviewer = substring(1,50,rpt_data->qual[d.seq].Reviewer)
,this_fin =  substring(1,20,rpt_data->qual[d.seq].FIN )
,this_rtype = substring(1,40,rpt_data->qual[d.seq].Review_type)
from (dummyt d with seq = size(rpt_data->qual,5))
order by this_Reviewer, this_FIN , this_rtype
head report
rcnt = 0
tcnt = 0
rtcnt = 0
head this_reviewer
	n=0
	pos = locateval(n,1,size(summary->qual,5),this_reviewer,summary->qual[n].prsnl_name )
	rcnt = pos

	head this_fin
	NULL;summary->qual[rcnt].fincount += 1

	head this_rtype ;new umstat for new fin
	;call echo( build2("new fin",this_fin," - umstatus:" , this_umstat))
	n=0
	pos = locateval(n,1,size(summary->qual[rcnt].umstat,5),this_rtype,summary->qual[rcnt].umstat[n].umstatus )

	if(pos = 0)
	;call echo("add new rev type")
	tcnt = size(summary->qual[rcnt].umstat,5) + 1
	stat = alterlist(summary->qual[rcnt].umstat,tcnt)
	summary->qual[rcnt].umstat[tcnt].umstatus = trim(this_rtype)
	summary->qual[rcnt].umstat[tcnt].um_rev_flag = "T"
	else
	tcnt = pos
	endif
	;call echo("inc fin count")
	summary->qual[rcnt].umstat[tcnt].fincount += 1
		detail
		;call echo("inc umstat review count")
		summary->qual[rcnt].umstat[tcnt].rvcount += 1 ;total by type


	foot this_rtype
	NULL

	foot this_fin
	NULL
foot this_reviewer
tcnt = 0
;fcnt = 0

with nocounter

;call echorecord(summary)


;TOTALS HOSPITAL WIDE/Multiple users


	select into "NL:"
	this_reviewer = "ZZZ"
	,this_fin =  substring(1,20,rpt_data->qual[d.seq].FIN )
	,this_umstat = substring(1,40,rpt_data->qual[d.seq].UM_Status )
	from (dummyt d with seq = size(rpt_data->qual,5))
	order by this_FIN , this_umstat
	head report
	
	umscnt = 0
	rtcnt = 0
	head this_reviewer
		rcnt = SIZE(summary->qual,5) + 1
		stat = alterlist(summary->qual,rcnt)
		;summary->qual[rcnt].prsnl_id 
		summary->qual[rcnt].prsnl_name =build2("Total for ", rpt_data->qual[d.seq].facility)
		
	
		head this_fin
		summary->qual[rcnt].fincount += 1
	
		head this_umstat ;new umstat for new fin
		
		n=0
		pos = locateval(n,1,size(summary->qual[rcnt].umstat,5),this_umstat,summary->qual[rcnt].umstat[n].UMstatus)
	
		if(pos > 0)
		umscnt = pos
		else
	
		umscnt = size(summary->qual[rcnt].umstat,5) + 1 ;increase total size
		stat = alterlist(summary->qual[rcnt].umstat,umscnt)
		summary->qual[rcnt].umstat[umscnt].UMstatus = this_umstat
		summary->qual[rcnt].umstat[umscnt].um_rev_flag = "S"
		endif
		
		summary->qual[rcnt].umstat[umscnt].fincount += 1
			detail
			summary->qual[rcnt].umstat[umscnt].rvcount += 1 ;total by stat
			summary->qual[rcnt].reviewcount += 1			;total reviews
	
		foot this_umstat
		NULL
	
		foot this_fin
		NULL
	foot this_reviewer
	umscnt = 0
	
	with nocounter

	; REV_TYPE	
	select into "NL:"
	this_reviewer =build2("Total for ", uar_get_code_display($facility))
	,this_fin =  substring(1,20,rpt_data->qual[d.seq].FIN )
	,this_rtype = substring(1,40,rpt_data->qual[d.seq].Review_type)
	from (dummyt d with seq = size(rpt_data->qual,5))
	order by this_Reviewer, this_FIN , this_rtype
	head report
	rcnt = 0
	tcnt = 0
	rtcnt = 0
	head this_reviewer
		n=0
		pos = locateval(n,1,size(summary->qual,5),this_reviewer,summary->qual[n].prsnl_name )
		rcnt = pos
	
		head this_fin
		NULL;summary->qual[rcnt].fincount += 1
	
		head this_rtype ;new umstat for new fin
		;call echo( build2("new fin",this_fin," - umstatus:" , this_umstat))
		n=0
		pos = locateval(n,1,size(summary->qual[rcnt].UMSTAT,5),this_rtype,summary->qual[rcnt].umstat[n].umstatus )
	
		if(pos = 0)
		call echo("add new rev type")
		tcnt = size(summary->qual[rcnt].umstat,5) + 1
		stat = alterlist(summary->qual[rcnt].umstat,tcnt)
		summary->qual[rcnt].umstat[tcnt].umstatus = trim(this_rtype)
		summary->qual[rcnt].umstat[tcnt].um_rev_flag = "T"
		else
		tcnt = pos
		endif
		;call echo("inc fin count")
		summary->qual[rcnt].umstat[tcnt].fincount += 1
			detail
			;call echo("inc umstat review count")
			summary->qual[rcnt].umstat[tcnt].rvcount += 1 ;total by stat
	
	
		foot this_rtype
		NULL
	
		foot this_fin
		NULL
	foot this_reviewer
	tcnt = 0
	;fcnt = 0
	
	with nocounter
	


free record outlines
record outlines(
	1 lines[*]
		2 line = vc
)


;BUILD SUMMARY OUTPUT LINES
select into "NL:"
DTYPE = summary->qual[D.seq].umstat[DA.seq].um_rev_flag
from (dummyt d with seq = size(summary->qual,5))
	,(dummyt da with seq = 1)
plan d
where maxrec(da, size(summary->qual[d.seq].umstat,5))
join da
order by d.seq,DTYPE , summary->qual[d.seq].umstat[da.seq].UMstatus 
head report
lcnt = 0
head d.seq
lcnt += 3
if(mod(lcnt,100) <= 3)
	stat = alterlist(outlines->lines,lcnt+100)
endif
outlines->lines[lcnt-2].line = summary->qual[d.seq].prsnl_name 
outlines->lines[lcnt-1].line = build("Unique Count of Patients: ",cnvtstring(summary->qual[d.seq].fincount ))
outlines->lines[lcnt].line = build("Count of Reviews: " , cnvtstring(summary->qual[d.seq].reviewcount ))
lcnt += 1
if(mod(lcnt,100) <= 3)
	stat = alterlist(outlines->lines,lcnt+100)
endif
HEAD DTYPE
IF(DTYPE = "S")
	outlines->lines[lcnt].line = "***Summary by UM Status***"
ELSE
	outlines->lines[lcnt].line = "***Summary by Review Type***"
ENDIF	

detail
;for (x = 1 to size(summary->qual[d.seq].umstat,5))
lcnt += 3
if(mod(lcnt,100) <= 3)
	stat = alterlist(outlines->lines,lcnt+100)
endif
outlines->lines[lcnt-2].line =summary->qual[d.seq].umstat[da.seq].UMstatus 
outlines->lines[lcnt-1].line = build2("  Unique Count of Patients ", cnvtstring(summary->qual[d.seq].umstat[da.seq].fincount ))
outlines->lines[lcnt].line = build2("  Count of Reviews ",  cnvtstring(summary->qual[d.seq].umstat[da.seq].rvcount ))
;endfor

foot d.seq
;add a blank after each person
lcnt += 1
if(mod(lcnt,100)= 1)
	stat = alterlist(outlines->lines,lcnt+100)
endif

foot report
stat = alterlist(outlines->lines,lcnt)
with nocounter
;call echorecord(outlines)

if ($outdev != "OPS")

	select into $outdev
	summary = substring(1,50,outlines->lines[d.seq].line)
	from (dummyt d with seq = size(outlines->lines,5))
	with format, nocounter
else
	select into filename
	summary = substring(1,50,outlines->lines[d.seq].line)
	from (dummyt d with seq = size(outlines->lines,5))
	with heading, pcformat('"', ',', 1), format=stream, format, nocounter, compress

endif;detail or summary

endif
if($email > " ")
	if (size(rpt_data->qual, 5) = 0)
	call echo("no records found")
	Select into (value(EMAIL_BODY))
		line01 = build2("NO DATA FOUND FOR THE GIVEN CRITERIA. Run Date and Time: ",
				        format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q")),
		line02 = build2("CLL Object name: ",trim(cnvtlower(curprog))) 
		,linefac = build2("Facility: ", trim(sfac))
		, whotoblame = "Custom Development handles incidents with this report."	
	from dummyt
	Detail
	col 01 line01
	row +2
	col 01 linefac
	row + 2
	col 01 whotoblame
	row + 1			
	col 01 line02
	with format,  format = variable   ,   maxcol = 200
	
	set  aix_command  = build2 ( "cat ", email_body ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,email_subject , "' ", email_address)
	set aix_cmdlen = size(trim(aix_command))
	set aix_cmdstatus = 0
	set dclstatus = -1
      	set dclstatus = dcl(aix_command, aix_cmdlen, aix_cmdstatus)

	else	
	call echo("records found")
	Select into (value(EMAIL_BODY))
		line01 = build2("Run Date and Time: ",
				        format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q")),
		line02 = build2("CLL Object name: ",trim(cnvtlower(curprog))) 
		,linefac = build2("Facility: ", trim(sfac))
		, whotoblame = "Custom Development handles incidents with this report."	
	from dummyt
	Detail
	col 01 line01
	row +2
	col 01 linefac
	row + 2
	col 01 whotoblame
	row + 1
	col 01 line02
	with format,  format = variable   ,   maxcol = 200
	
	set  aix_command  = build2 ( "cat ", email_body ," | tr -d \\r"
									, " | mailx  -S from='report@medstar.net' -s '"
									, email_subject , "' -a ", filename, " ", email_address)
	set aix_cmdlen = size(trim(aix_command))
	set aix_cmdstatus = 0
	call dcl(aix_command,aix_cmdlen, aix_cmdstatus)
	call echo("email with records sent")
	endif
endif

#exitscript
FREE RECORD SUMMARY
FREE RECORD OUTLINES
FREE RECORD RPT_DATA

end
go


