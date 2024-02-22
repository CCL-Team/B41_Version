/*****************************************************************************************************************
 
                                      Script Name:    13_mp_cir_ref_tracker.prg
                                      Description:    Mpage to populate list of active inpatient referrals and status
                                      Date Written:   January 14, 2020
                                      Written by:     Simeon Akinsulie
******************************************************************************************************************
                                            Special Instructions
******************************************************************************************************************
  CIR Referral Tracker mPage - service driver
  sample execute commands for debug
  execute 13_mp_cir_ref_tracker "MINE", "WriteRefStatus", 181390573, 16399460, 'Pending Additional Information' go
  execute 13_MP_CIR_REF_TRACKER ^MINE^,^GetActiveReferrals^,^{"request_in":{"sLoc":"4364516"}}^ go
******************************************************************************************************************
                                            Revision Information
******************************************************************************************************************
Rev    Date     By             		Comments
------ -------- ---------------- ----------------------------------------------------------------------------------
001    01/14/20 Simeon Akinsulie    Initial Release
002    03/24/20 Simeon Akinsulie    Remove Test patients
003    05/11/21 Kim Frazier			TASK4402249 Remove Outerjoin on FIN & MRN to remove corrupted pt accounts
004    02/15/21 Kim Frazier 		Add  2 totals:Discharges remaining, Arrived admissions
									separate sched admits & projected admits
005	   06/07/22 Kim FRazier			233876 Limit count to only 'today's' sched/projected admits
006    02/16/24 Michael Mayes       INC0525013 - Break/fix - filter cancelled surg.  This lands on med_service.
******************************************************************************************************************/
 
drop program 13_mp_cir_ref_tracker go
create program 13_mp_cir_ref_tracker
call echo("Start prg")
 
; subroutines / services
 
declare GetActiveReferrals(sReq=vc) = null
declare GetActiveReferrals2(sReq=vc) = null
declare GetCensusReferralHist(startDt=vc, fac_cd=f8) = null
declare getCensus(dfac=f8, bDate=dq8, eDate=dq8) = null
declare GetActions(n0=i1) = null
declare CollectDefault(sParamKey=vc,dPSId=f8) = null
declare WriteComments(eId=f8,pId=f8,sComment=vc) = null
 
declare WriteComments2(eId=f8,pId=f8,sComment=vc) = null
 
declare WriteDefault(sParamKey=vc,dPSId=f8,sReq=vc) = null
 
declare WriteRefStatus(eId=f8,pId=f8,dActStatus=vc) = null
declare WriteHealthMaint(sReq=vc) = null
 
 
 
; modular record structs
record ref(
  1 ords[*]
    2 sSpecialty = vc
    2 dSynId = f8
)
 
; modular variables
declare sTmp = vc with protect
declare nCnt = i4 with protect, noconstant(0)
declare n = i4 with protect, noconstant(0)
declare index = i4
declare num = i4 with noconstant(0),public
 
; ****************************************************
; **************** Service Driver ********************
; ****************************************************
/*Initialize audit row written to CCL_REPORT_AUDIT*/
%i cclsource:ccl_rpt_audit.inc
declare _audit_flag = i2 with protect, noconstant(0)
set _outputDev = $1
;set _params = build2("^MINE^,^",$2,"^")
set _params = build2("^MINE^,^",$2,"^");_params = build2("^MINE^,^",$2,"^")
Call echo("About to:")
call echo(build2("_params:",_params))
set _audit_flag = CCL_INIT_AUDIT( CURPROG, "MPage" )
 
 
 
call echo($2)
if($2 = "INIT")
  	call InitPage(cnvtreal($3))
elseif($2 ="getStatusDTA")
	call getStatusDTA(0)
elseif($2 = "GetActiveReferrals")
	call echo("Calling GetActiveReferrals")
	call echo(format(sysdate,"hh:mm:ss;;D"))
	;set _params = build2(_params,",^",$3,"^")
	call GetActiveReferrals(value($3))
elseif($2 = "GetCensusReferralHist")
	call echo("Calling GetCensusReferralHist")
	call echo(format(sysdate,"hh:mm:ss;;D"))
	record reply(
		1 history[*]
			2 hist_date = vc
			2 dtcomp = dq8
			2 cen_total = i4
			2 cen_admit = i4
			2 cen_discharge = i4
			2 ref_total = i4
			2 ref_internal = i4
			2 ref_external = i4
	)
	call GetCensusReferralHist(value($3),cnvtreal(parameter(4, 1)))
	set _memory_reply_string = cnvtrectojson(reply, 4)
	call echo(_memory_reply_string)
elseif($2 = "CollectDefault")
  call CollectDefault(value($3), cnvtreal(parameter(4, 1)))
elseif($2 = "WriteComments")
	declare eid = f8
	declare pid = f8
	declare comment = vc
	set eid = cnvtreal($3)
	set pid = cnvtreal(parameter(4,0))
	set comment = value(parameter(5, 0))
	call echo(build2(eid,' - ',pid,' - ',comment))
  	call WriteComments(eid,pid,comment)
elseif($2 = "WriteComments2")
	declare eid = f8
	declare pid = f8
	declare comment = vc
	set eid = cnvtreal($3)
	set pid = cnvtreal(parameter(4,0))
	set comment = value(parameter(5, 0))
	call echo(build2(eid,' - ',pid,' - ',comment))
  	call WriteComments2(eid,pid,comment)
elseif($2 = "WriteRefStatus")
	declare eid = f8
	declare pid = f8
	declare comment = vc
	set eid = cnvtreal($3)
	set pid = cnvtreal(parameter(4,0))
	set comment = value(parameter(5, 0))
	call echo(build2(eid,' - ',pid,' - ',comment))
  	call WriteRefStatus(eid,pid,comment)
elseif($2 = "WriteAudit")
  call WriteAudit(value($3), value(parameter(4, 1)))
endif
; ****************************************************
; ************* Service Driver (end) *****************
; ****************************************************
 
 
subroutine GetActiveReferrals(sReq)
 
	declare sParserLoc = vc
	call echo("Got here")
	set stat = cnvtjsontorec(sReq)
	call echorecord(request_in)
 
 	if(request_in->sLoc = "0")
		set sParserLoc = "1 = 1"
	else
		set sParserLoc = concat("e.loc_facility_cd  in(", request_in->sLoc, ")")
	endif
 	call echo(sParserLoc)
 	record reply(
	1 pnd_cnt = i4
	1 extCnt = i4
    1 intCnt = i4
  	1 actvL2 = i4
  	1 actv35 = i4
  	1 actvG5 = i4
  	1 current_census = i4
  	1 anti_admit = i4
  	1 proj_admit = i4 	;004 krf
  	1 sched_admit = i4	;004 krf added
  	1 disch_remaining = i4 ;004 kfr added
  	1 adm_arrived = i4 	;004 KRF added
	1 pending[*]
		2 encntr_id = f8
	 	2 person_id = f8
	 	2 antic_admission_pt_id = f8
	 	2 person = vc
	 	2 p_dob = vc
	 	2 p_age = vc
	 	2 p_gender = vc
	 	2 fin = vc
	 	2 mrn = vc
	 	2 reg_dt_tm = dq8			;current
	 	2 referral_dt_tm = dq8		;DtTm of Inpatient Referral Location
	 	2 referral_dt_tm_vc = vc		;DtTm of Inpatient Referral Location
	 	2 inpt_reg_dt_tm = dq8	 	;Only for Inpatient encounter types
	 	2 encntr_beg_dt_tm = dq8	;redundant (compare to referral_dt_tm)
	 	2 encntr_type = vc			;current
	 	2 encntr_type_cd = f8		;current
	 	2 loc_nurse_unit = vc		;current
	 	2 referral_source = vc
		2 outcome_type = vc				;encounter type
		2 p_act_days = i4
	    2 p_liaison_name = vc
		2 al_uname = vc
		2 is_pending = vc
		2 non_admit_reason = vc
		2 internal_external = vc
		2 ins[*]
			3 s_ins = vc
	1 output[*]
		2 encntr_id = f8
	 	2 person_id = f8
	 	2 antic_admission_pt_id = f8
	 	2 person = vc
	 	2 p_dob = vc
	 	2 p_age = vc
	 	2 p_gender = vc
	 	2 fin = vc
	 	2 mrn = vc
	 	2 reg_dt_tm = dq8			;current
	 	2 referral_dt_tm = dq8		;DtTm of Inpatient Referral Location
	 	2 referral_dt_tm_vc = vc		;DtTm of Inpatient Referral Location
	 	2 inpt_reg_dt_tm = dq8	 	;Only for Inpatient encounter types
	 	2 encntr_beg_dt_tm = dq8	;redundant (compare to referral_dt_tm)
	 	2 encntr_type = vc			;current
	 	2 encntr_type_cd = f8		;current
	 	2 loc_nurse_unit = vc		;current
	 	2 referral_source = vc
		2 outcome_type = vc				;encounter type
		2 p_act_days = i4
	    2 p_liaison_name = vc
	    2 p_admission_rep = vc
		2 al_uname = vc
		2 is_pending = vc
		2 non_admit_reason = vc
		2 internal_external = vc
		2 status = vc
		2 refstatus = vc
		2 ins[*]
			3 s_ins = vc
		2 s_comment = vc
      	2 s_comment_his[*]
      		3 s_comment_dt = vc
      		3 s_comment_val = vc
      		3 s_comment_prsnl = vc
	1 history[*]
		2 hist_date = vc
		2 dtcomp = dq8
		2 cen_total = i4
		2 cen_admit = i4
		2 cen_discharge = i4
		2 ref_total = i4
		2 ref_internal = i4
		2 ref_external = i4
	1 liaisons[*]
		2 al_name = vc
		2 al_uname = vc
		2 actvL2 = i4
	  	2 actv35 = i4
	  	2 actvG5 = i4
	  	2 al_total = i4
)
 
declare real_start = vc
declare real_end = vc
 
declare var_fin = f8 with noconstant(uar_get_code_by("DISPLAYKEY",319,"FINNBR"))
declare var_mrn = f8 with noconstant(uar_get_code_by("DISPLAYKEY",319,"MRN"))
declare mf8_71_inpt_referral = f8 with constant(uar_get_code_by("DISPLAYKEY",71,"INPATIENTREFERRAL"))
declare mf8_71_preadmit = f8 with constant(uar_get_code_by("DISPLAYKEY",71,"PREADMIT")) ;309313.00
declare mf8_34_can_surg = f8 with constant(uar_get_code_by("DISPLAYKEY",34,"CANCELLEDSURGERY")) ;5048023.00   ;006
declare index = i4
declare pos = i4
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Get OP and IP Patient in the last 30days		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
call echo(" *  	  Get OP and IP Patient in the last 30days		  	  *")
select into "nl:"
	from encounter e
/*;003 start - removed these
		,(left join encntr_alias	fin
			on(fin.encntr_id = e.encntr_id
			and fin.encntr_alias_type_cd = 1077
			and fin.active_ind = 1))
		,(left join encntr_alias	mrn
			on(mrn.encntr_id = e.encntr_id
			and mrn.encntr_alias_type_cd = 1079
			and mrn.active_ind = 1))
003 end */
		,(left join cust_antic_admission_pt caap
			on(caap.encntr_id = e.encntr_id
				and caap.person_id = e.person_id
				and caap.active_ind = 1))
		, encntr_alias fin 							;003 Added
		, encntr_alias mrn 							;003 Added
		,person pe
	plan e
		where e.reg_dt_tm > cnvtdate(cnvtlookbehind("30,d"),0000)
		and e.beg_effective_dt_tm between cnvtdate(cnvtlookbehind("30,d"),0000) and cnvtdatetime(curdate, 2359)
		and ((e.disch_dt_tm > cnvtdate(cnvtlookbehind("30,d"),0000))or(e.disch_dt_tm = null))
		and e.encntr_type_cd in (MF8_71_INPT_REFERRAL,MF8_71_PREADMIT) ;(607971507, 309313)
        and e.med_service_cd != mf8_34_can_surg  ;006
		and parser(sParserLoc);e.loc_facility_cd = 4364516
		and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
	join fin
	where fin.encntr_id = e.encntr_id 				;003 added
	and fin.active_ind = 1 							;003 added
	and fin.encntr_alias_type_cd = 1077 			;003 added
	join mrn
	where mrn.encntr_id = e.encntr_id 				;003 added
	and mrn.active_ind = 1 							;003 added
	and mrn.encntr_alias_type_cd = 1079 			;003 added
	join caap
	join pe
		where pe.person_id = e.person_id
		and pe.active_ind = 1
		and pe.name_last_key not in("IMOC", "ZZ*") ;002 Removed Test patients
	order by e.encntr_id
	head report
		cnt = 0
	head e.encntr_id
		cnt = cnt + 1
		if(mod(cnt,100) = 1)
			stat = alterlist(reply->pending, cnt + 99)
		endif
		if(e.encntr_type_cd = MF8_71_INPT_REFERRAL)
			reply->pending[cnt].outcome_type = "OT"
		elseif(e.encntr_type_cd = MF8_71_PREADMIT)
			reply->pending[cnt].outcome_type = "IP"
		endif
		reply->pending[cnt].encntr_id = e.encntr_id
		reply->pending[cnt].person_id = e.person_id
		reply->pending[cnt].person = pe.name_full_formatted
		reply->pending[cnt].p_age = cnvtage(pe.birth_dt_tm)
		reply->pending[cnt].p_dob = format(pe.birth_dt_tm,'mm/dd/yyyy ;;d')
		if(cnvtupper(uar_get_code_display(pe.sex_cd)) = 'FEMALE')
			reply->pending[cnt].p_gender = 'F'
		elseif(cnvtupper(uar_get_code_display(pe.sex_cd)) = 'MALE')
			reply->pending[cnt].p_gender = 'M'
		else
			reply->pending[cnt].p_gender = 'U'
		endif
		reply->pending[cnt].reg_dt_tm = e.reg_dt_tm
		reply->pending[cnt].fin = fin.alias
		reply->pending[cnt].mrn = mrn.alias
		reply->pending[cnt].encntr_type = uar_get_code_display(e.encntr_type_cd)
		reply->pending[cnt].encntr_type_cd = e.encntr_type_cd
		reply->pending[cnt].encntr_beg_dt_tm = e.beg_effective_dt_tm
		reply->pending[cnt].loc_nurse_unit = uar_get_code_display(e.loc_nurse_unit_cd)
		reply->pending[cnt].referral_source = uar_get_code_display(e.refer_facility_cd)
		reply->pending[cnt].antic_admission_pt_id = caap.cust_antic_admission_pt_id
		;reply->pending[cnt].is_pending = 'y'
 
		if(cnvtlower(trim(uar_get_code_display(e.refer_facility_cd),3)) in ('*medstar*','franklin square hospital ctr',
		'*washington hospital center*'))
	 		reply->pending[cnt].internal_external = "Internal"
	 	else
	 		reply->pending[cnt].internal_external = "External"
	 	endif
	foot report
		stat = alterlist(reply->pending, cnt)
	with nocounter
 
	call echorecord(reply)
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Get OP and IP Patient in the last 30days		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
	declare mf8_72_dcp = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"DCPGENERICCODE"))
	;declare mf8_72_dcp = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"DCPGENERICCODE"))
	declare MF8_72_PREADM_WITHDRAWAL_DEN = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PREADMPRIMARYREASONFORWITHDRAWALDEN"))
	declare MF8_72_ASOFDATE = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"ASOFDATE"))
	declare fm_72_insurance = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"INSURANCE"))
	declare fm_72_hosp_service = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"HOSPITALSERVICE"))
	declare fm_72_ptmedacc = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PATIENTMEDICALLYACCEPTEDAPPROPRIATE"))
	declare fm_72_prim_reason = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PRIMARYREASONFORNONADMISSION"))
	declare fm_72_oth_reason = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"OTHERREASONFORNONADMISSION"))
 
	select into "nl:"
	d.seq
	from (dummyt d with seq = size(reply->pending,5)),
	clinical_event ce,clinical_event ce2,clinical_event ce3
	plan d
	join ce
		where ce.encntr_id = reply->pending[d.seq].encntr_id
;		and ce.event_cd =  1889022177.00
		and ce.valid_until_dt_tm >= cnvtdatetime("31-DEC-2100")
		and ce.result_status_cd in (25, 34, 35)
	join ce2 where ce2.parent_event_id = ce.event_id
		and ce2.event_cd = mf8_72_dcp
	join ce3 where ce3.parent_event_id = ce2.event_id
		and ce3.event_cd = 1889022177.00
;		in (mf8_72_preadm_withdrawal_den,
;		 					mf8_72_asofdate,
;		 					fm_72_insurance,
;		 					fm_72_hosp_service,
;							fm_72_ptmedacc,
;							fm_72_oth_reason,  ;002
;	 						fm_72_prim_reason);  1889022177.00
	order by ce.encntr_id
	head report
		count = 0
	head ce.encntr_id
		if(ce.encntr_id = 178954829)
			call echo(build2("Found GMan with Result: ",ce3.result_val))
		endif
			reply->pending[d.seq].is_pending = 'n'
			reply->pending[d.seq].non_admit_reason = trim(ce3.result_val,3)
			count = count + 1
	with nocounter, time = 60
	call echo(reply->intCnt)
	call echo(reply->extCnt)
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Encounter Location Hx		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
	select into "nl:"
	referral_date = format(elh.beg_effective_dt_tm,"dd-mmm-yyyy;;q"),
	p_act_days = cnvtint(datetimecmp(cnvtdatetime(CURDATE, curtime3),elh.beg_effective_dt_tm))
	from	encntr_loc_hist	elh
	plan elh
		where expand(index,1,size(reply->pending,5),elh.encntr_id,reply->pending[index].encntr_id)
		and elh.encntr_type_cd = mf8_71_inpt_referral
	order by elh.encntr_id, elh.transaction_dt_tm
	head elh.encntr_id
		dateStart = 0
		pos = locateval(index,1,size(reply->pending,5),elh.encntr_id,reply->pending[index].encntr_id)
		reply->pending[pos].referral_dt_tm = elh.beg_effective_dt_tm
		dateStart = findstring("-",referral_date,1,0)
		if(dateStart >0)
			dateMonth = substring(dateStart+1,3,referral_date)
			reply->pending[pos].referral_dt_tm_vc =
				replace(referral_date,dateMonth,cnvtcap(dateMonth))
		else
			reply->pending[pos].referral_dt_tm_vc = referral_date
		endif
		reply->pending[pos].p_act_days = p_act_days
 
	with expand = 1
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Load Main RS		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
	select into "nl:"
	d.seq
	from (dummyt d with seq = size(reply->pending,5))
	plan d where reply->pending[d.seq].is_pending != 'n'
	head report
		cnt = 0
	detail
		cnt = cnt + 1
		stat = alterlist(reply->output,cnt)
		reply->output[cnt].encntr_id = reply->pending[d.seq].encntr_id
		reply->output[cnt].person_id = reply->pending[d.seq].person_id
		reply->output[cnt].person = reply->pending[d.seq].person
		reply->output[cnt].p_age = reply->pending[d.seq].p_age
		reply->output[cnt].p_dob = reply->pending[d.seq].p_dob
		reply->output[cnt].p_gender = reply->pending[d.seq].p_gender
		reply->output[cnt].reg_dt_tm = reply->pending[d.seq].reg_dt_tm
		reply->output[cnt].referral_dt_tm  = reply->pending[d.seq].referral_dt_tm
		reply->output[cnt].referral_dt_tm_vc  = reply->pending[d.seq].referral_dt_tm_vc
		reply->output[cnt].fin = reply->pending[d.seq].fin
		reply->output[cnt].mrn = reply->pending[d.seq].mrn
		reply->output[cnt].encntr_type = reply->pending[d.seq].encntr_type
		reply->output[cnt].encntr_type_cd = reply->pending[d.seq].encntr_type_cd
		reply->output[cnt].encntr_beg_dt_tm = reply->pending[d.seq].encntr_beg_dt_tm
		reply->output[cnt].loc_nurse_unit = reply->pending[d.seq].loc_nurse_unit
		reply->output[cnt].referral_source = reply->pending[d.seq].referral_source
		reply->output[cnt].is_pending = reply->pending[d.seq].is_pending
		reply->output[cnt].p_act_days = reply->pending[d.seq].p_act_days
		reply->output[cnt].antic_admission_pt_id = reply->pending[d.seq].antic_admission_pt_id
		if(trim(reply->pending[d.seq].internal_external,3) = "Internal")
	 		reply->intCnt = reply->intCnt + 1
	 	elseif(trim(reply->pending[d.seq].internal_external,3) = "External")
	 		reply->extCnt = reply->extCnt + 1
	 	endif
	 	if(reply->output[cnt].is_pending != 'n')
			if(reply->output[cnt].p_act_days<= 2)
				reply->actvL2 = reply->actvL2 + 1
			elseif(reply->output[cnt].p_act_days <= 5)
			 	reply->actv35 = reply->actv35 + 1
			elseif(reply->output[cnt].p_act_days >5)
			 	reply->actvG5 = reply->actvG5 + 1
			endif
		endif
	foot report
		reply->pnd_cnt = cnt
	with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
;collect Referral Status
;---------------------------------------------------------------------------------------------------------------------------------
 
 call echo("collect valid action status")
  ; collect valid action status
  declare dActStatus = f8
  set dActStatus = uar_get_code_by("DISPLAYKEY", 72, "CIRACTIONSTATUSREFMP")
  select into "nl:"
    dttm = cnvtdatetime(ce.event_end_dt_tm)
  from
    (dummyt d with seq = size(reply->output,5)),
    clinical_event ce
  plan d
  join ce where
    ce.encntr_id = reply->output[d.seq].encntr_id and
    ce.event_cd = dActStatus and
    ce.valid_until_dt_tm > sysdate
  order d.seq, dttm desc
 
  head d.seq
    reply->output[d.seq].refstatus  = trim(ce.result_val)
  with nocounter, time = 20
 
;---------------------------------------------------------------------------------------------------------------------------------
;collect comments
;---------------------------------------------------------------------------------------------------------------------------------
  call echo('collect action comments')
  	declare dActComments = f8
	  set dActComments = uar_get_code_by("DISPLAYKEY", 72, "CIRACTIONCOMMENTSREFMP")
	  select into "nl:"
		from (dummyt d with seq = size(reply->output,5)),
			clinical_event ce,
			prsnl p
		plan d
		join ce
			where ce.encntr_id = reply->output[d.seq].encntr_id
			and ce.event_cd = dActComments
			and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
			;and ce.view_level = 1
		join p
			where p.person_id = ce.performed_prsnl_id
		order by d.seq, ce.event_end_dt_tm desc
	 	head d.seq
			nCmnt = 0
		    reply->output[d.seq].s_comment = trim(ce.result_val)
		  	detail
			  	nCmnt = nCmnt + 1
			  	stat = alterlist(reply->output[d.seq].s_comment_his, nCmnt)
			  	reply->output[d.seq].s_comment_his[nCmnt].s_comment_dt = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm;;D")
			    reply->output[d.seq].s_comment_his[nCmnt].s_comment_val = trim(ce.result_val,3)
			    reply->output[d.seq].s_comment_his[nCmnt].s_comment_prsnl = trim(p.name_full_formatted,3)
  		 with nocounter, time = 20
	call echo('End Collect Action Comments')
 
 
 
;---------------------------------------------------------------------------------------------------------------------------------
;collect encounter Liaison
;---------------------------------------------------------------------------------------------------------------------------------
	call echo("Starting Liaison")
	call echo(format(sysdate,"hh:mm:ss;;D"))
	declare currentTypeCd = f8 with constant (uar_get_code_by ("DISPLAY_KEY" ,213 ,"CURRENT" )) ,protect
	declare admission_liaison_cd = f8 with public,constant( 2211266825.00)
	declare admission_rep_cd = f8 with public,constant( 2211268091.00)
	Select into "NL:"
	 result = trim(ce.result_val)
	 from (dummyt d with seq = size(reply->output,5)),
	 	clinical_event ce
	 plan d
	 join ce
		 where ce.encntr_id = reply->output[d.seq].encntr_id
		 and ce.event_cd in (admission_liaison_cd ,admission_rep_cd)
		 and ce.result_status_cd in (23,25,34,35)
		 and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime)
	 order by ce.encntr_id, ce.event_cd,ce.event_end_dt_tm desc ;last one stored is most recent
	 head report
	 	lcount = 0
		 head ce.encntr_id
		 	null
			head ce.event_cd
			 	case(ce.event_cd)
			 		of admission_liaison_cd:
			 			reply->output[d.seq].p_liaison_name = result
			 			if(size(reply->liaisons,5)>0)
			 				lcount = locateval(num, 1, size(reply->liaisons,5), result , reply->liaisons[num].al_name)
			 			endif
			 			if(lcount = 0)
			 				lcount = size(reply->liaisons,5) + 1
			 				stat = alterlist(reply->liaisons,lcount)
			 			endif
			 			reply->liaisons[lcount].al_name = result
			 			reply->liaisons[lcount].al_total = reply->liaisons[lcount].al_total + 1
						if(reply->output[d.seq].p_act_days <= 2)
							reply->liaisons[lcount].actvL2 = reply->liaisons[lcount].actvL2 + 1
						elseif(reply->output[d.seq].p_act_days <= 5)
						 	reply->liaisons[lcount].actv35 = reply->liaisons[lcount].actv35 + 1
						else
						 	reply->liaisons[lcount].actvG5 = reply->liaisons[lcount].actvG5 + 1
						endif
			 		of admission_rep_cd:
			 	  		reply->output[d.seq].p_admission_rep =result
			 	  endcase
	with nocounter
 
;---------------------------------------------------------------------------------------------------------------------------------
;collect status
;---------------------------------------------------------------------------------------------------------------------------------
	call echo("Starting collect status")
	select into 'nl:'
	from (dummyt d with seq = size(reply->output,5)),
		cust_antic_admission_pt caap
	plan d
	join caap
		where caap.active_ind = 1
		and caap.projected_status in ('Scheduled','Projected')
		and caap.encntr_id = reply->output[d.seq].encntr_id
	order by caap.encntr_id, caap.projected_dt_tm desc
 	head caap.encntr_id
 		reply->output[d.seq].status = caap.projected_status
 		call echo(build2(reply->output[d.seq].person," ",caap.projected_status))
	with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
;Get Anticipated Admissions CCL Audit Log
;---------------------------------------------------------------------------------------------------------------------------------
	call echo("Starting Anticipated Admissions")
	call echo(format(sysdate,"hh:mm:ss;;D"))
 
	declare inpatientreferralCd = f8 with public, constant(uar_get_code_by("DISPLAY_KEY",71,"INPATIENTREFERRAL"))
	declare preadmitCd = f8 with public, constant(uar_get_code_by("DISPLAY_KEY",71,"PREADMIT"))
	declare loa_cd = f8 with public, constant(uar_get_code_by("DISPLAYKEY",71,"NRHLEAVEOFABSENCE"))
 
	select into 'nl:'
	from cust_antic_admission_pt caap
		,encounter e
	plan caap
		where caap.active_ind = 1
		and caap.projected_status in ('Scheduled','Projected')
		and caap.projected_dt_tm between cnvtdatetime(curdate,0) and cnvtdatetime(curdate,235959) ;005 added
	join e
		where e.encntr_id = caap.encntr_id
			and e.person_id = caap.person_id
			and  parser(sParserLoc) ; e.loc_facility_cd = 4364516 ; $fac
			and e.encntr_type_cd in (inpatientreferralCd,preadmitCd,loa_cd);(607971507.00,309313.00,  607970233.00) ;002
	order by caap.projected_dt_tm,e.encntr_id
	head report
		encntrCnt = 0
	head caap.projected_status
		null
	head e.encntr_id
		reply->anti_admit = reply->anti_admit + 1
;004
	if(	caap.projected_status = 'Scheduled')
		reply->sched_admit += 1
	else
		reply->proj_admit += 1
	endif
;004 end
	with nocounter,time=60
 
	set startdt = format(datetimefind(cnvtdatetime(CURDATE, curtime2),"d","e","e"),"mmddyyyy;;q")
	call echo(Build2("StartDTTT:",startdt))
	call GetCensusReferralHist(startdt,cnvtreal(request_in->sLoc))
	set reply->current_census = reply->history[7].cen_total
	call CollectInsurance(0)
	declare errmsg = C132
  	if (error(errmsg, 0) > 0)
		call ccl_write_audit(CURPROG, "MPage", "FAILED", size(reply->output,5))
	else
		call ccl_write_audit(CURPROG, "MPage", "SUCCESS", size(reply->output,5))
	endif
 
	set _memory_reply_string = cnvtrectojson(reply, 4)
	call echo(_memory_reply_string)
end
 
	subroutine GetCensusReferralHist(startdt, fac_cd)
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Declare Start and End Dates		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
		set startdt = replace(startdt,"/","")
		set real_start = format(datetimefind(cnvtdatetime(cnvtdate(startdt)-6, curtime2),"d","b","b"),"dd-mmm-yyyy hh:mm:ss;;q")
		set real_end = format(datetimefind(cnvtdatetime(cnvtdate(startdt), curtime2),"d","e","e"),"dd-mmm-yyyy hh:mm:ss;;q")
		call echo(build2("start: ",real_start," - end: ",real_end))
		set stat  = alterlist(reply->history,7)
 		declare thisDate = dq8
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Pre Load Reply Record Structure	  	  *
;---------------------------------------------------------------------------------------------------------------------------------
		for(index =0 to 6)
			set thisDate = cnvtdate(startdt)-(6-index)
		 	set reply->history[index+1].dtcomp = cnvtdatetime(thisDate, 2359)
		 	;set reply->history[index+1].hist_date = FORMAT(thisDate,"MM/DD/YYYY ;;D")
			set reply->history[index+1].hist_date = FORMAT(CNVTDATE(startdt)-(6-index),"MM/DD/YYYY ;;D")
			call echo(reply->history[index+1].hist_date)
		endfor
 
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Get Referral History*
;---------------------------------------------------------------------------------------------------------------------------------
		record temp(
			1 qual[*]
				2 date = vc
				2 encntr_id = f8
				2 Ref_type = vc
		)
		select into "nl:"
			Ref_type = if(cnvtlower(uar_get_code_display(e.refer_facility_cd)) in ('*medstar*','*washington hospital center*'))
				"internal"
			else
				"external"
			endif
		from encounter e,
		encntr_loc_hist elh
		plan e where e.reg_dt_tm > cnvtdatetime(REAL_START)
			and e.beg_effective_dt_tm between cnvtdatetime(REAL_START) and cnvtdatetime(REAL_END)
			and ((e.disch_dt_tm > cnvtdatetime(REAL_START))
				or(e.disch_dt_tm = null))
			and e.encntr_type_cd in (607971507,309308,309313.00)
			and e.loc_facility_cd = fac_cd ;4364516
			and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
		join elh
			where elh.encntr_id = e.encntr_id
			and elh.encntr_type_cd = 607971507
			and elh.beg_effective_dt_tm != null
		order by e.encntr_id
		head report
			cnt = 0
		head e.encntr_id
			cnt = cnt + 1
			if(mod(cnt,100) = 1)
				stat = alterlist(temp->qual, cnt + 99)
			endif
		 	temp->qual[cnt].date = FORMAT(DATETIMEFIND(CNVTDATETIME(e.beg_effective_dt_tm),"D","B","B"),"MM/DD/YYYY ;;D")
		 	; cnvtdatetime(DATETIMEFIND(CNVTDATETIME(e.beg_effective_dt_tm),"D","B","B"))
			temp->qual[cnt].encntr_id = e.encntr_id
			temp->qual[cnt].Ref_type = Ref_type
		foot report
			stat = alterlist(temp->qual,cnt)
		with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Count and Load Reply Record with Referral Aggregates	  	  *
;---------------------------------------------------------------------------------------------------------------------------------
		declare num = i4
		select into "nl:"
		date = temp->qual[d.seq].date,
		eid = temp->qual[d.seq].encntr_id
		from (dummyt d with seq=size(temp->qual,5))
		plan d
		order by date, eid
		head date
			total = 0
			internal = 0
			external = 0
			detail
				total = total + 1
				if(trim(temp->qual[d.seq].Ref_type,3) = "internal")
					internal = internal + 1
				else
					external = external + 1
				endif
		foot date
			pos = locateval(num, 1, size(reply->history,5), date , reply->history[num].hist_date)
			reply->history[pos].ref_external = external
			reply->history[pos].ref_internal = internal
			reply->history[pos].ref_total = total
		with nocounter
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	 GET THE ANTICIPATED ADMITS / Aggregate and Load Reply Record Structure	  	  *
;---------------------------------------------------------------------------------------------------------------------------------
 
		;declare inpatientCd = f8 with public, constant(uar_get_code_by("DISPLAY_KEY",71,"INPATIENT"))
		SELECT INTO 'nl:'
		status_date =  FORMAT(DATETIMEFIND(CNVTDATETIME(e.reg_dt_tm),"D","B","B"),"MM/DD/YYYY ;;D")
		FROM encounter e
			,cust_antic_admission_pt caap
		plan e
			where e.loc_facility_cd = fac_cd ;4364516
			and e.reg_dt_tm between cnvtdatetime(REAL_START) and cnvtdatetime(REAL_END)
			and e.encntr_type_cd = 309308.00
		join caap
			where caap.encntr_id = e.encntr_id
		order by status_date
 
		Head Report
			count = 0
			Head status_date
			admit = 0
			detail
		 		admit = admit + 1
		 	foot status_date
		 		pos = locateval(num, 1, size(reply->history,5), status_date , reply->history[num].hist_date)
		 		reply->history[pos].cen_admit = admit
		 		;reply->history[pos].cen_total = admit
		WITH nocounter, time = 60
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	 GET THE DISCHARGED PATIENTS / Aggregate and Load Reply Record Structure	  	  *
;---------------------------------------------------------------------------------------------------------------------------------
 
		SELECT INTO 'nl:' ;status_dt_tm = format(e.disch_dt_tm,"@SHORTDATETIME")
		status_date =  FORMAT(DATETIMEFIND(CNVTDATETIME(e.disch_dt_tm),"D","B","B"),"MM/DD/YYYY ;;D")
		FROM encounter   e
			,cust_antic_admission_pt   caap
		plan E where e.disch_dt_tm  between cnvtdatetime(REAL_START) and cnvtdatetime(REAL_END)
				and e.loc_facility_cd = fac_cd ;4364516
				and e.encntr_type_cd = 309308.00
		join caap where caap.encntr_id = e.encntr_id
		order by status_date
 
		Head Report
			count = 0
			Head status_date
			discharge = 0
			detail
		 		discharge = discharge + 1
		 	foot status_date
		 		pos = locateval(num, 1, size(reply->history,5), status_date , reply->history[num].hist_date)
		 		reply->history[pos].cen_discharge = discharge
		 		;reply->history[pos].cen_total = reply->history[pos].cen_total + discharge
		with nocounter, time = 60
;---------------------------------------------------------------------------------------------------------------------------------
;	 *004  	 GET ANTICIPATED DISCHARGES / Aggregate and Load Reply Record Structure	  	  *
;---------------------------------------------------------------------------------------------------------------------------------
declare censusCd = f8 with constant(uar_get_code_by('DISPLAY_KEY',339,'CENSUS')), protect
declare inpatientCd = f8 with public, constant(uar_get_code_by("DISPLAY_KEY",69,"INPATIENT"))
declare gshonl5Cd = f8  with public, constant(uar_get_code_by("DISPLAY_KEY",220,"GSHONL5"));002 add
declare gsh5estCd = f8  with public, constant(uar_get_code_by("DISPLAY_KEY",220,"GSH5EST"));002 add (GSH5EAST in B41)
declare nrh3wnrCd = f8  with public, constant(7351586.00);004 uar_get_code_by("DISPLAY_KEY",220,"NRH3WNR"))
declare nrh3enrCd = f8  with public, constant(7351002.00);004 uar_get_code_by("DISPLAY_KEY",220,"NRH3ENR"))
declare nrh2wnrCd = f8  with public, constant(uar_get_code_by("DISPLAY_KEY",220,"NRH2WNR"))
declare nrh2enrCd = f8  with public, constant(uar_get_code_by("DISPLAY_KEY",220,"NRH2ENR"))
declare placeHolderCd = f8  with public, constant(uar_get_code_by("DISPLAY_KEY",53,"PLACEHOLDER"))
declare anticipatedDischDateCd = f8 with constant(uar_get_code_by('DISPLAY_KEY',72,'ANTICIPATEDDISCHARGEDATE')), protect
 
select into 'nl:'
 
from encntr_domain ed
	,encounter e
	,clinical_event ce
	,ce_date_result cdr
 
plan ed
	where ed.loc_facility_cd = fac_cd
		and ed.active_ind = 1
		and ed.encntr_domain_type_cd = censusCd
		and ed.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
		and ((ed.loc_facility_cd = 4362818 and ed.loc_nurse_unit_cd in (gshonl5Cd, gsh5estCd));003 add
			or (ed.loc_facility_cd = 4364516 and ed.loc_nurse_unit_cd in (nrh3wnrCd,nrh3enrCd,nrh2wnrCd,nrh2enrCd)))
 
join e
	where e.encntr_id = ed.encntr_id
		and e.encntr_type_class_cd = inpatientCd
 
join ce;pull last charted anticipated discharge date
	where ce.encntr_id = e.encntr_id
		and ce.person_id = e.person_id
		and ce.event_cd = anticipatedDischDateCd
		and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
		and ce.result_status_cd in (25,34,35)
		and ce.event_tag != "In Error" ;007
		and ce.event_class_cd != placeHolderCd
		and ce.event_end_dt_tm = (select max(ce2.event_end_dt_tm) from clinical_event ce2
									where ce2.encntr_id = ce.encntr_id
										and ce2.person_id = ce.person_id
										and ce2.event_cd = anticipatedDischDateCd
										and ce2.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
										and ce2.result_status_cd in (25,34,35)
										and ce2.event_tag != "In Error" ;007
										and ce2.event_class_cd != placeHolderCd
								)
 
join cdr
	where cdr.event_id = ce.event_id
		and cdr.result_dt_tm between cnvtdatetime(curdate,0) and cnvtdatetime(curdate,235959)
 
		Head Report
			discharge = 0
		detail
		 	discharge = discharge + 1
		Foot Report
		 	reply->disch_remaining = discharge
 
		with nocounter, time = 60
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *004  	 GET THE ARRIVED ADMITS / Aggregate and Load Reply Record Structure	  	  *
;---------------------------------------------------------------------------------------------------------------------------------
 
		SELECT INTO 'nl:'
		FROM encounter e
			,cust_antic_admission_pt caap
		plan e
			where e.loc_facility_cd = fac_cd ;4364516
			and e.reg_dt_tm between cnvtdatetime(curdate,0) and cnvtdatetime(curdate,235959)
			and e.encntr_type_cd = 309308.00
		join caap
		where caap.encntr_id = e.encntr_id
		head report
		count = 0
		detail
		count += 1
		foot report
		reply->adm_arrived = count
		with nocounter, time = 60
 
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Get Daily Census*
;---------------------------------------------------------------------------------------------------------------------------------
		 set bDate =cnvtdatetime(cnvtdate(startdt)-6, 2359)
		 set eDate =cnvtdatetime(cnvtdate(startdt), 2359)
		 call getCensus(fac_cd, bDate, eDate)
	end
 
 	subroutine getCensus(dfac, bDate, eDate)
		free record CENSUS_REPLY
		record CENSUS_REPLY(
			1 aggregate[*]
		    	2 date = vc
		    	2 total = i4
		    	2 dtcomp = dq8
		)
		record _nu(
		  1 units[*]
		    2 dCd = f8
		)
		record CENSUS_REQUEST(
		  1 dFac = f8
		  1 units[*]
		    2 dCd = f8
		)
		; default only GSH rehab units if all units selected at GSH
		if(dfac = 4362818)
		  set stat = alterlist(CENSUS_REQUEST->units, 4)
		  ;set CENSUS_REQUEST->units[1].dCd =     4369689.00;uar_get_code_by("DISPLAYKEY", 220, "GSH2EST")
		  ;set CENSUS_REQUEST->units[2].dCd =     4369691.00;uar_get_code_by("DISPLAYKEY", 220, "GSH2WST")
		  set CENSUS_REQUEST->units[3].dCd =     4369697.00;uar_get_code_by("DISPLAYKEY", 220, "GSH5EST")	;MOD004
		  set CENSUS_REQUEST->units[4].dCd =  2024820777.00;uar_get_code_by("DISPLAYKEY", 220, "GSHONL5")	;MOD004
 
		elseif(dfac = 4364516);MOD003 - We only want the nursing units
		  set stat = alterlist(CENSUS_REQUEST->units, 5)
		  set CENSUS_REQUEST->units[1].dCd =     4368979.00;uar_get_code_by("DISPLAYKEY", 220, "NRH2ENR")
		  set CENSUS_REQUEST->units[2].dCd =     7350734.00;uar_get_code_by("DISPLAYKEY", 220, "NRH2WNR")
		  set CENSUS_REQUEST->units[3].dCd = 	 7351002.00 ;uar_get_code_by("DISPLAYKEY", 220, "NRH3ENR")
		  set CENSUS_REQUEST->units[4].dCd = 	 7351586.00 ;uar_get_code_by("DISPLAYKEY", 220, "NRH3WNR")
		  set CENSUS_REQUEST->units[5].dCd =  2274956503.00;uar_get_code_by("DISPLAYKEY", 220, "NRHNACN")
;		  [1:36 PM] Frazier, Kim R
;    	  declare nrh3wnrCd = f8  with public, constant(7351586.00) ;007 added
;		  declare nrh3enrCd = f8  with public, constant(7351002.00) ;007 added
 
		endif
 
		call echorecord(CENSUS_REQUEST)
		declare _nUnits = i4 with protect
		declare _nUnit = i4 with protect, noconstant(0)
		declare _n = i4 with protect
		declare _nEnc = i4 with protect, noconstant(0)
		declare _bAllUnits = i1 with protect
 
		set _nUnits = size(CENSUS_REQUEST->units, 5)
		set _bAllUnits = evaluate(_nUnits, 0, 1, 0)
		set _dIP = uar_get_code_by("DISPLAYKEY", 71, "INPATIENT")
		set _dOBS = uar_get_code_by("DISPLAYKEY", 71, "OBSERVATION")
		call echo(build2("_bAllUnits:",_bAllUnits))
 
		; first collect all IP units within facility.
		; must do this regardless of which units are specified because
		; this is needed for encntr_domain index
		select into "nl:"
		from
		  nurse_unit nu
		plan nu where
		  nu.loc_facility_cd = dfac and
		  nu.active_ind = 1
		order nu.location_cd
 
		head nu.location_cd
		  _nUnit = _nUnit + 1
		  if(mod(_nUnit, 20) = 1)
		    stat = alterlist(_nu->units, _nUnit + 19)
		  endif
		  _nu->units[_nUnit].dCd = nu.location_cd
		with nocounter
 
		; get building_cd (for better encntr_domain index)
		set _dBldg = 0.0
		select into "nl:"
		from
		  location_group lg
		plan lg where
		  lg.parent_loc_cd = dfac and
		  lg.root_loc_cd = 0.0 and
		  lg.active_ind = 1
 
		head report
		  _dBldg = lg.child_loc_cd
		with nocounter
 
		select into "nl:"
		from
		  encntr_domain ed,
		  encounter e,
		  encntr_loc_hist elh,
		  person p
		plan ed where
		  ed.loc_facility_cd = dfac and
		  ed.loc_building_cd = _dBldg and
		  expand(_n, 1, _nUnit, ed.loc_nurse_unit_cd, _nu->units[_n].dCd) and ; must do this for solid index
		  ed.end_effective_dt_tm > sysdate and ; not discharged
		  ed.beg_effective_dt_tm <= cnvtdatetime(eDate) ; they had to be here sometime before the census end date
		join e where
		  e.encntr_id = ed.encntr_id and
		  e.encntr_type_cd in(_dIP, _dOBS)
		join elh where
		  elh.encntr_id = e.encntr_id and
		  elh.active_ind = 1 and
		  (expand(_n, 1, _nUnits, elh.loc_nurse_unit_cd, CENSUS_REQUEST->units[_n].dCd)) and
		  elh.beg_effective_dt_tm <= cnvtdatetime(eDate) and ; they had to be here on/before the census end date
		  elh.end_effective_dt_tm >= cnvtdatetime(bDate) ; they left on/after the census begin date
		join p where
		  p.person_id = e.person_id
		  and
		  p.name_last_key not in("IMOC", "ZZ*")
		order e.encntr_id, elh.encntr_loc_hist_id
 
		head e.encntr_id
		  null
		head elh.encntr_loc_hist_id
		  ; collect timeframes when active in specified units
		  for(cnt=1 to size(reply->history,5))
		  	if(ed.beg_effective_dt_tm <= cnvtdatetime(reply->history[cnt].dtcomp) and
		  	elh.beg_effective_dt_tm <= cnvtdatetime(reply->history[cnt].dtcomp) and
		  	elh.end_effective_dt_tm >= cnvtdatetime(reply->history[cnt].dtcomp))
		  		reply->history[cnt].cen_total = reply->history[cnt].cen_total + 1
		  	endif
		  endfor
		with nocounter
 
		; collect discharged census
		select into "nl:"
		from
		  encounter e,
		  encntr_loc_hist elh,
		  person p
		plan e where
		  e.disch_dt_tm >= cnvtdatetime(bDate) and
		  e.reg_dt_tm <= cnvtdatetime(eDate) and
		  e.loc_facility_cd = dfac and
		  e.encntr_type_cd in(_dIP, _dOBS)
		join elh where
		  elh.encntr_id = e.encntr_id and
		  elh.active_ind = 1 and
		 ; expand(_n, 1, _nUnit, elh.loc_nurse_unit_cd, _nu->units[_n].dCd) ;and				;MOD002
		   expand(_n, 1, size(_nu->units,5), elh.loc_nurse_unit_cd, _nu->units[_n].dCd) and		;MOD002 - Changed to Size() function
		 (expand(_n, 1, size(CENSUS_REQUEST->units,5), elh.loc_nurse_unit_cd, CENSUS_REQUEST->units[_n].dCd)) and ;MOD002 - Changed to Size() function
		  elh.beg_effective_dt_tm <= cnvtdatetime(eDate) and
		  elh.end_effective_dt_tm >= cnvtdatetime(bDate)
		join p where
		  p.person_id = e.person_id and
		  p.name_last_key not in("IMOC", "ZZ*")
		order e.encntr_id, elh.encntr_loc_hist_id
 
		head e.encntr_id
		  for(cnt=1 to size(reply->history,5))
		  	if(e.disch_dt_tm >= cnvtdatetime(reply->history[cnt].dtcomp) and
		  	e.reg_dt_tm <= cnvtdatetime(reply->history[cnt].dtcomp) and
		  	elh.beg_effective_dt_tm <= cnvtdatetime(reply->history[cnt].dtcomp) and
		  	elh.end_effective_dt_tm >= cnvtdatetime(reply->history[cnt].dtcomp))
		  		reply->history[cnt].cen_total = reply->history[cnt].cen_total + 1
		  	endif
		  endfor
		with nocounter
 	end
 
	subroutine CollectInsurance(p0)
	  select into "nl:"
	    dttm = cnvtdatetime(epr.beg_effective_dt_tm)
	  from
	    (dummyt d with seq = size(reply->output,5)),
	    encntr_plan_reltn epr,
	    health_plan hp,
	    organization o
	  plan d
	  join epr where
	    epr.encntr_id = reply->output[d.seq].encntr_id  and
	    epr.active_ind = 1 and
	    epr.end_effective_dt_tm > sysdate
	  join hp where
	    hp.health_plan_id = epr.health_plan_id
	  join o where
	    o.organization_id = epr.organization_id
	  order d.seq, epr.priority_seq, dttm desc
 
	  head d.seq
	    nIns = 0
 
	  head epr.priority_seq
	    nIns = nIns + 1
	    stat = alterlist(reply->output[d.seq].ins, nIns)
	    reply->output[d.seq].ins[nIns].s_ins = trim(o.org_name)
	  with nocounter
 
	end
 
	subroutine getStatusDTA(p0)
		record reply
		(
			1 items[*]
				2 nomenclature_id = f8
				2 display = vc
		)
 
 
		;obtain list of nomenclature values for a dta
		select into 'nl:'
		from code_value cv
		where cv.code_set = 100722
		order by cv.display
		head report
			nomenCnt = 0
			detail
				nomenCnt = nomenCnt + 1
				stat = alterlist(reply->items,nomenCnt)
				reply->items[nomenCnt].display = cv.display
				reply->items[nomenCnt].nomenclature_id = cv.code_value
		with nocounter
		call echo(build2("Count: ",size(reply->items,5)))
		set _memory_reply_string = cnvtrectojson(reply, 4)
		call echo(_memory_reply_string)
	end
 
 
	subroutine CollectDefault(sParamKey, dPSId)
	  set dParam = uar_get_code_by("DISPLAYKEY", 100705, sParamKey)
	  set _memory_reply_string = "-1"
 
	  select into "nl:"
	  from
	    cust_mpage_data cmd
	  plan cmd where
	    cmd.prsnl_id = dPSId and
	    cmd.data_cd = dParam
 
	  head report
	    _memory_reply_string = trim(cmd.value_txt)
	  with nocounter
	end
 
	; build and save json formatted param string of submitted parameters
	subroutine WriteDefault(sParam, dPSId, sReq)
	  declare sParamKey = vc
	  declare sParamWrite = vc
 
	  if(sParam = "GetPopIncoming")
	    set sParamKey = "REFERRALORDERS"
	  elseif(sParam = "GetPopOutgoing")
	    set sParamKey = "REFERRALORDERS"
	  else
	    set sParamKey = "RADORDERS"
	  endif
 
	  set dParam = uar_get_code_by("DISPLAYKEY", 100705, sParamKey)
	  set dParamId = 0.0
 
	  ;  record request_in(
	  ;    1 sDtBeg = vc
	  ;    1 sDtEnd = vc
	  ;    1 sSpec = vc
	  ;    1 sPrv = vc
	  ;    1 sStatus = vc
	  ;    1 sRange = vc
	  ;    1 sLoc = vc
	  ;    1 sAct = vc
	  ;    1 sTab = c1
	  ;  )
	  set stat = cnvtjsontorec(sReq)
 
	  ; date range check
	  if(request_in->sRange in("undefined", "Custom Range"))
	    set request_in->sRange = "Today"
	  endif
 
	  ; name and id of each provider must be saved away
	  declare sPrvParam = vc
	  if(request_in->sPrv = "0")
	    set sPrvParam = trim(" ")
	  else
	    set sPrvParam = concat("ps.person_id in(", request_in->sPrv, ")")
	    select into "nl:"
	    from
	      prsnl ps
	    plan ps where
	      parser(sPrvParam)
	    order ps.name_full_formatted
 
	    head report
	      sPrvParam = trim(" ")
 
	    detail
	      sPrvParam = concat(sPrvParam, ',{"id":"', trim(cnvtstring(ps.person_id), 3),
	        '","text":"', trim(ps.name_last), ', ', trim(ps.name_first), '"}'
	      )
 
	    foot report
	      sPrvParam = replace(sPrvParam, ",{", "{", 1)
	    with nocounter
	  endif
 
	  ; put together param string to be saved
	  set sParamWrite = concat(
	    '{',
	      '"range":"', trim(request_in->sRange), '",',
	      '"spc":[', evaluate(request_in->sSpec, "'0'", trim(" "), trim(request_in->sSpec)), '],',
	      '"prv":[', sPrvParam, '],',
	      '"sts":[', evaluate(request_in->sStatus, "0", trim(" "), trim(request_in->sStatus)), '],',
	      '"loc":[', evaluate(request_in->sLoc, "0", trim(" "), trim(request_in->sLoc)), '],',
	      '"act":[', evaluate(request_in->sAct, "'0'", trim(" "), trim(request_in->sAct)), ']',
	    '}'
	  )
 
	  ; check if we should update or insert
	  select into "nl:"
	  from
	    cust_mpage_data cmd
	  plan cmd where
	    cmd.prsnl_id = dPSId and
	    cmd.data_cd = dParam
 
	  head report
	    dParamId = cmd.cust_mpage_data_id
	  with nocounter
 
	  if(dParamId > 0)
	    update from
	      cust_mpage_data cmd
	    set
	      cmd.value_txt = sParamWrite
	    where
	      cmd.cust_mpage_data_id = dParamId
	    with nocounter
	  else
	    insert into
	      cust_mpage_data cmd
	    set
	      cmd.cust_mpage_data_id = seq(cust_mpage_data_seq, nextval),
	      cmd.data_cd = dParam,
	      cmd.prsnl_id = dPSId,
	      cmd.value_txt = sParamWrite
	    plan cmd
	    with nocounter
	  endif
	  commit
 
	  ; ***********************************
	  ; ******** save default tab *********
	  set dParam = uar_get_code_by("DISPLAYKEY", 100705, "DEFAULTTABREFMGMT")
	  set dParamId = 0.0
 
	  ; check if we should update or insert
	  select into "nl:"
	  from
	    cust_mpage_data cmd
	  plan cmd where
	    cmd.prsnl_id = dPSId and
	    cmd.data_cd = dParam
 
	  head report
	    dParamId = cmd.cust_mpage_data_id
	  with nocounter
 
	  if(dParamId > 0)
	    update from
	      cust_mpage_data cmd
	    set
	      cmd.value_txt = request_in->sTab
	    where
	      cmd.cust_mpage_data_id = dParamId
	    with nocounter
	    commit
	    ; exit routine
	    return
	  endif
 
	  ; inserting at this point
	  insert into
	    cust_mpage_data cmd
	  set
	    cmd.cust_mpage_data_id = seq(cust_mpage_data_seq, nextval),
	    cmd.data_cd = dParam,
	    cmd.prsnl_id = dPSId,
	    cmd.value_txt = request_in->sTab
	  plan cmd
	  with nocounter
	  commit
	end
 
	subroutine GetFreq(p0)
	  free record reply
	  record reply(
	    1 items[*]
	      2 id = vc
	      2 text = vc
	  )
	  	set stat = alterlist(reply->items,4)
	    set reply->items[1].id = '251'
	    set reply->items[1].text = "Day(s)"
	    set reply->items[2].id = '323'
	    set reply->items[2].text = "Weeks"
	    set reply->items[3].id = '303'
	    set reply->items[3].text = "Months"
	    set reply->items[4].id = '324'
	    set reply->items[4].text = "Years"
	  	;call ccl_write_audit(CURPROG, "MPage", "SUCCESS", size(reply->items,5))
		set _memory_reply_string = cnvtrectojson(reply, 4)
		call echo(_memory_reply_string)
	end
 
 
	subroutine GetReasonCd(p0)
	  free record reply
	  record reply(
	    1 items[*]
	      2 id = vc
	      2 text = vc
	  )
	  	set stat = alterlist(reply->items,3)
	   	set reply->items[1].id = "56641762"
	    set reply->items[1].text = "Parent or Guardian Request"
	    set reply->items[2].id = "56641770"
	    set reply->items[2].text = "Patient Risk Factors"
	    set reply->items[3].id = "56641766"
	    set reply->items[3].text = "Patient Request"
	  	set _memory_reply_string = cnvtrectojson(reply, 4)
		call echo(_memory_reply_string)
	end
 
	subroutine GetActions(p0)
	  free record reply
	  record reply(
	    1 items[*]
	      2 id = vc
	      2 text = vc
	  )
 
	  set n = 0
 
	  select into "nl:"
	  from
	    code_value cv
	  plan cv where
	    cv.code_set = 100589 and
	    cv.active_ind = 1
	  order cv.collation_seq
 
	  detail
	    n = n + 1
	    stat = alterlist(reply->items, n)
	    reply->items[n].id = trim(cnvtstring(cv.code_value), 3)
	    reply->items[n].text = trim(cv.display)
	  with nocounter
	  declare errmsg = C132
	  	if (error(errmsg, 0) > 0)
			call ccl_write_audit(CURPROG, "MPage", build2("FAILED - ",errmsg), size(reply->items,5))
		else
			call ccl_write_audit(CURPROG, "MPage", "SUCCESS", size(reply->items,5))
		endif
 
	  set _memory_reply_string = cnvtrectojson(reply, 4)
	end
 
	subroutine WriteComments(dEId, dPId, sComments)
		set sComments = replace(sComments, "%UP%", "^")
	  	call echo(sComments)
	  	set dtUpdt = cnvtdatetime(curdate, curtime3)
	  	set dRecStatCd = uar_get_code_by("DISPLAYKEY", 48, "ACTIVE")
	  	set dAuth = uar_get_code_by("DISPLAYKEY", 8, "AUTHVERIFIED")
	  	set dVerify = uar_get_code_by("MEANING", 21, "VERIFY")
	  	set dPerform = uar_get_code_by("MEANING", 21, "PERFORM")
	  	set dComplete = uar_get_code_by("MEANING", 103, "COMPLETED")
	  	set dContrib = uar_get_code_by("MEANING", 89, "POWERCHART")
 
 
	  ; determine if modifying existing
	  set dActComments = uar_get_code_by("DISPLAYKEY", 72, "CIRACTIONCOMMENTSREFMP")
	  set dEventId = 0.0
 
	  ; call clinical_event server to update/insert ce_blob
	  set nApp = 1000012
	  set nReq = 1000012
	  set nTask = 1000012
 
	  set hApp = 0
	  set hTask = 0
	  set hStep = 0
	  set hReq = 0
 
	  ; initialize request
	  set stat = uar_CrmBeginApp(nApp, hApp)
	  set stat = uar_CrmBeginTask(hApp, nTask, hTask)
 
	  ; ***** Action Comments clin_event
	  set stat = uar_CrmBeginReq(hTask, "", nReq, hStep)
	  set hReq = uar_CrmGetRequest(hStep)
	  set hCE = uar_SrvGetStruct(hReq, "clin_event")
 
	  set stat = uar_SrvSetDouble(hCE, "person_id", dPId)
	  set stat = uar_SrvSetDouble(hCE, "encntr_id", dEId)
	  if(dEventId = 0.0)
	    set stat = uar_SrvSetShort(hReq, "ensure_type", 1)
	  else
	    set stat = uar_SrvSetShort(hReq, "ensure_type", 2)
	    set stat = uar_SrvSetDouble(hCE, "event_id", dEventId)
	  endif
	  set stat = uar_SrvSetDouble(hCE, "event_cd", dActComments)
	  set stat = uar_SrvSetDouble(hCE, "event_class_cd", uar_get_code_by("DISPLAYKEY", 53, "TXT"))
	  set stat = uar_SrvSetDouble(hCE, "event_reltn_cd", uar_get_code_by("DISPLAYKEY", 24, "R"))
	  set stat = uar_SrvSetLong(hCE, "view_level", 0)
	  set stat = uar_SrvSetShort(hCE, "publish_flag", 0)
	  set stat = uar_SrvSetShort(hCE, "publish_flag_ind", 1)
	  set stat = uar_SrvSetDouble(hCE, "result_status_cd", dAuth)
	  set stat = uar_SrvSetDate(hCE, "event_end_dt_tm", cnvtdatetime(dtUpdt))
	  set stat = uar_SrvSetDouble(hCE, "contributor_system_cd", dContrib)
	  set stat = uar_SrvSetDouble(hCE, "record_status_cd", dRecStatCd)
	  set stat = uar_SrvSetDouble(hCE, "updt_id", reqinfo->updt_id)
	  set stat = uar_SrvSetString(hCE, "event_tag", nullterm(trim(sComments)))
	  ; event prsnl (perform and verify)
	  set hEP = uar_SrvAddItem(hCE, "event_prsnl_list")
	  set stat = uar_SrvSetDate(hEP, "action_dt_tm", cnvtdatetime(dtUpdt))
	  set stat = uar_SrvSetDouble(hEP, "action_type_cd", dVerify)
	  set stat = uar_SrvSetDouble(hEP, "action_status_cd", dComplete)
	  set stat = uar_SrvSetShort(hEP, "action_dt_tm_ind", 1)
	  set stat = uar_SrvSetDouble(hEP, "person_id", reqinfo->updt_id)
	  set stat = uar_SrvSetDouble(hEP, "action_prsnl_id", reqinfo->updt_id)
	  set hEP2 = uar_SrvAddItem(hCE, "event_prsnl_list")
	  set stat = uar_SrvSetDate(hEP2, "action_dt_tm", cnvtdatetime(dtUpdt))
	  set stat = uar_SrvSetDouble(hEP2, "action_type_cd", dPerform)
	  set stat = uar_SrvSetDouble(hEP2, "action_status_cd", dComplete)
	  set stat = uar_SrvSetShort(hEP2, "action_dt_tm_ind", 1)
	  set stat = uar_SrvSetDouble(hEP2, "person_id", reqinfo->updt_id)
	  set stat = uar_SrvSetDouble(hEP2, "action_prsnl_id", reqinfo->updt_id)
	  ; string result
	  set hCERes = uar_SrvAddItem(hCE, "string_result")
	  set stat = uar_SrvSetString(hCERes, "string_result_text", nullterm(sComments))
	  set stat = uar_SrvSetDouble(hCERes, "string_result_format_cd", uar_get_code_by("DISPLAYKEY", 14113, "ALPHA"))
	  if(dEventId > 0)
	    set stat = uar_SrvSetDouble(hCERes, "event_id", dEventId)
	  endif
 
	  ; call server
	  set stat = uar_CrmPerform(hStep)
 
	  ; cleanup
	  call uar_CrmEndReq(hStep)
	  call uar_CrmEndTask(hTask)
	  call uar_CrmEndApp(hApp)
	  declare errmsg = C132
	  free record reply
	  record reply(
	  	1 s_comment_dt = vc
      	1 s_comment_val = vc
      	1 s_comment_prsnl = vc
      	1 s_status = vc
	  )
	  if (error(errmsg, 0) > 0)
		set reply->s_comment_dt = format(cnvtdatetime(dtUpdt), "mm/dd/yyyy hh:mm;;D")
	  	set reply->s_comment_val = trim(sComments)
	  	set reply->s_comment_prsnl = trim(p.name_full_formatted,3)
	  	set reply->s_status = errmsg
	  else
	  	select into "nl:"
	  	from prsnl p
	  	where p.person_id = reqinfo->updt_id
	  	and p.active_ind = 1
	  	and p.end_effective_dt_tm > sysdate
	  	head report
	  		reply->s_comment_dt = format(cnvtdatetime(dtUpdt), "mm/dd/yyyy hh:mm;;D")
	  		reply->s_comment_val = trim(sComments)
	  		reply->s_comment_prsnl = trim(p.name_full_formatted,3)
	  		reply->s_status = 'success'
	  	with nocounter
		;call ccl_write_audit(CURPROG, "MPage", "SUCCESS", size(reply->output,5))
	  endif
	  set _memory_reply_string = cnvtrectojson(reply, 4)
 
	end
 
	subroutine WriteComments2(dEId, dPId, sComments)
		set sComments = replace(sComments, "%UP%", "^")
	  	call echo(sComments)
	  	set dtUpdt = cnvtdatetime(curdate, curtime3)
	  	set dRecStatCd = uar_get_code_by("DISPLAYKEY", 48, "ACTIVE")
	  	set dAuth = uar_get_code_by("DISPLAYKEY", 8, "AUTHVERIFIED")
	  	set dVerify = uar_get_code_by("MEANING", 21, "VERIFY")
	  	set dPerform = uar_get_code_by("MEANING", 21, "PERFORM")
	  	set dComplete = uar_get_code_by("MEANING", 103, "COMPLETED")
	  	set dContrib = uar_get_code_by("MEANING", 89, "POWERCHART")
 
 
	  ; determine if modifying existing
	  set dActComments = uar_get_code_by("DISPLAYKEY", 72, "CIRACTIONCOMMENTSREFMP")
	  set dEventId = 0.0
 
	  free record reply
	  record reply(
	  	1 s_comment_dt = vc
      	1 s_comment_val = vc
      	1 s_comment_prsnl = vc
      	1 s_status = vc
	  )
 
	  	select into "nl:"
	  	from prsnl p
	  	where p.person_id = reqinfo->updt_id
	  	and p.active_ind = 1
	  	and p.end_effective_dt_tm > sysdate
	  	head report
	  		reply->s_comment_dt = format(cnvtdatetime(dtUpdt), "mm/dd/yyyy hh:mm;;D")
	  		reply->s_comment_val = trim(sComments)
	  		reply->s_comment_prsnl = trim(p.name_full_formatted,3)
	  		reply->s_status = 'success'
	  	with nocounter
		;call ccl_write_audit(CURPROG, "MPage", "SUCCESS", size(reply->output,5))
	  set _memory_reply_string = cnvtrectojson(reply, 4)
 
	end
 
	subroutine WriteRefStatus(dEId,dPId, sComments)
		set sComments = replace(sComments, "%UP%", "^")
	  	set dtUpdt = cnvtdatetime(curdate, curtime3)
	  	set dRecStatCd = uar_get_code_by("DISPLAYKEY", 48, "ACTIVE")
	  	set dAuth = uar_get_code_by("DISPLAYKEY", 8, "AUTHVERIFIED")
	  	set dVerify = uar_get_code_by("MEANING", 21, "VERIFY")
	  	set dPerform = uar_get_code_by("MEANING", 21, "PERFORM")
	  	set dComplete = uar_get_code_by("MEANING", 103, "COMPLETED")
	  	set dContrib = uar_get_code_by("MEANING", 89, "POWERCHART")
 
 
	  ; determine if modifying existing
	  set dActStatus = uar_get_code_by("DISPLAYKEY", 72, "CIRACTIONSTATUSREFMP")
	  set dEventId = 0.0
	  select into "nl:"
	  from
	    	clinical_event ce
	  plan ce
	  	where ce.encntr_id = dEId
	  	and ce.event_cd = dActStatus
	  	and ce.valid_until_dt_tm > sysdate
	  head report
	    dEventId = ce.event_id
	  with nocounter
	 call echo("here")
	  ; call clinical_event server to update/insert ce_blob
	  set nApp = 1000012
	  set nReq = 1000012
	  set nTask = 1000012
 
	  set hApp = 0
	  set hTask = 0
	  set hStep = 0
	  set hReq = 0
 
	  ; initialize request
	  set stat = uar_CrmBeginApp(nApp, hApp)
	  set stat = uar_CrmBeginTask(hApp, nTask, hTask)
 
	  ; ***** Action Status clin_event
	  set stat = uar_CrmBeginReq(hTask, "", nReq, hStep)
	  set hReq = uar_CrmGetRequest(hStep)
	  set hCE = uar_SrvGetStruct(hReq, "clin_event")
 
	  set stat = uar_SrvSetDouble(hCE, "person_id", dPId)
	  set stat = uar_SrvSetDouble(hCE, "encntr_id", dEId)
 
	  if(dEventId = 0.0)
	    set stat = uar_SrvSetShort(hReq, "ensure_type", 1)
	  else
	    set stat = uar_SrvSetShort(hReq, "ensure_type", 2)
	    set stat = uar_SrvSetDouble(hCE, "event_id", dEventId)
	  endif
	  set stat = uar_SrvSetDouble(hCE, "event_cd", dActStatus)
	  set stat = uar_SrvSetDouble(hCE, "event_class_cd", uar_get_code_by("DISPLAYKEY", 53, "TXT"))
	  set stat = uar_SrvSetDouble(hCE, "event_reltn_cd", uar_get_code_by("DISPLAYKEY", 24, "R"))
	  set stat = uar_SrvSetLong(hCE, "view_level", 0)
	  set stat = uar_SrvSetShort(hCE, "publish_flag", 0)
	  set stat = uar_SrvSetShort(hCE, "publish_flag_ind", 1)
	  set stat = uar_SrvSetDouble(hCE, "result_status_cd", dAuth)
	  set stat = uar_SrvSetDate(hCE, "event_end_dt_tm", cnvtdatetime(dtUpdt))
	  set stat = uar_SrvSetDouble(hCE, "contributor_system_cd", dContrib)
	  set stat = uar_SrvSetDouble(hCE, "record_status_cd", dRecStatCd)
	  set stat = uar_SrvSetDouble(hCE, "updt_id", reqinfo->updt_id)
	  set stat = uar_SrvSetString(hCE, "event_tag", nullterm(trim(sComments)))
	  ; event prsnl (perform and verify)
	  set hEP = uar_SrvAddItem(hCE, "event_prsnl_list")
	  set stat = uar_SrvSetDate(hEP, "action_dt_tm", cnvtdatetime(dtUpdt))
	  set stat = uar_SrvSetDouble(hEP, "action_type_cd", dVerify)
	  set stat = uar_SrvSetDouble(hEP, "action_status_cd", dComplete)
	  set stat = uar_SrvSetShort(hEP, "action_dt_tm_ind", 1)
	  set stat = uar_SrvSetDouble(hEP, "person_id", reqinfo->updt_id)
	  set stat = uar_SrvSetDouble(hEP, "action_prsnl_id", reqinfo->updt_id)
	  set hEP2 = uar_SrvAddItem(hCE, "event_prsnl_list")
	  set stat = uar_SrvSetDate(hEP2, "action_dt_tm", cnvtdatetime(dtUpdt))
	  set stat = uar_SrvSetDouble(hEP2, "action_type_cd", dPerform)
	  set stat = uar_SrvSetDouble(hEP2, "action_status_cd", dComplete)
	  set stat = uar_SrvSetShort(hEP2, "action_dt_tm_ind", 1)
	  set stat = uar_SrvSetDouble(hEP2, "person_id", reqinfo->updt_id)
	  set stat = uar_SrvSetDouble(hEP2, "action_prsnl_id", reqinfo->updt_id)
	  ; string result
	  set hCERes = uar_SrvAddItem(hCE, "string_result")
	  set stat = uar_SrvSetString(hCERes, "string_result_text", nullterm(sComments))
	  set stat = uar_SrvSetDouble(hCERes, "string_result_format_cd", uar_get_code_by("DISPLAYKEY", 14113, "ALPHA"))
	  if(dEventId > 0)
	    set stat = uar_SrvSetDouble(hCERes, "event_id", dEventId)
	  endif
 
	  ; call server
	  set stat = uar_CrmPerform(hStep)
 
	  ; cleanup
	  call uar_CrmEndReq(hStep)
	  call uar_CrmEndTask(hTask)
	  call uar_CrmEndApp(hApp)
	  set _memory_reply_string = trim(cnvtstring(dEId), 3)
	end
 
 
	subroutine WriteAudit(sParams, sDtBeg)
	  if(reqinfo->updt_app != 600005) ; exit if not coming from powerchart
	    set _memory_reply_string = "S"
	    return
	  endif
 
	  insert into ccl_report_audit c
	  set
	    c.report_event_id = seq(ccl_seq, NEXTVAL),
	    c.object_name = trim(cnvtupper(curprog)),
	    c.object_type = "MPAGE",
	    c.object_params = trim(substring(1, 2000, sParams)),
	    c.application_nbr = reqinfo->updt_app,
	    c.begin_dt_tm = cnvtdatetime(sDtBeg),
	    c.end_dt_tm = cnvtdatetime(curdate, curtime3),
	;    c.output_device= trim ( request -> output_device ),
	;    c.tempfile= trim ( request -> temp_file ),
	;    c.records_cnt=0 ,
	;    c.status="active" ,
	;    c.active_ind=1,
	;    c.omf_object_cd= request -> omf_object_cd ,
	;    c.long_text_id= _long_text_id ,
	    c.updt_dt_tm = cnvtdatetime(curdate, curtime3),
	    c.updt_id = reqinfo->updt_id,
	    c.updt_applctx = cnvtreal(reqinfo->updt_applctx),
	    c.updt_task = reqinfo->updt_task
	  with nocounter
	  commit
	  set _memory_reply_string = "S"
	end
end go
