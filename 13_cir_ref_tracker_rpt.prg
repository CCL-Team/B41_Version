/*****************************************************************************************************************
 
                                      Script Name:    13_cir_ref_tracker_rpt.prg
                                      Description:    Report/EMAIL to mimic Cir Operaional Dashboard mPage
                                      					- list of active inpatient referrals and status
                                      Date Written:   3/2/2023
                                      Written by:     KRF - Stolen from Simeon Akinsulie
******************************************************************************************************************
                                            Special Instructions
******************************************************************************************************************
  Copied from 13_MP_CIR_REF_TRACKER

******************************************************************************************************************
                                            Revision Information
******************************************************************************************************************
Rev    Date     By             	MCGA	Comments
------ -------- ----------------------- ----------------------------------------------------------------------------------
000    03/02/23 Kim FRazier		237341 	Initial Build Request to create report based on the mPage list
001    06/06/23 Kim Frazier		239175	select timing out, increase time from 60 to 600
002    02/16/24 Michael Mayes   346313  INC0525013 - Break/fix - filter cancelled surg.  This lands on med_service.
******************************************************************************************************************/
drop program 13_cir_ref_tracker_rpt go
create program 13_cir_ref_tracker_rpt 

prompt 
	"Output to File/Printer/MINE" = "MINE"                                      ;* Enter or select the printer or file name to sen
	, "Referring Facility:" = VALUE(*                                       )
	, "To Facility" = 4364516.00
	, "eMail" = "" 

with OUTDEV, rfacility, fac, email

%i cust_script:ccps_ld_security.inc
if (ISOPSJOB = 1 and curdomain != "P41") ;do not run in non-prod from ops
 go to EXIT_SCRIPT
endif
if($email > " " and findstring("@MEDSTAR.NET",cnvtupper($email),1,1) =0
			   and findstring("@GEORGETOWN.",cnvtupper($email),1,1) =0
			   and  findstring("@GUNET.",cnvtupper($email),1,1) =0)
select into $outdev
"Email must be directed to an approved Medstar email address."
from dummyt d
with nocounter
go to  EXIT_SCRIPT
endif


%i cust_script:SC_CPS_GET_PROMPT_LIST.inc
declare rfac_parser = vc with protect, noconstant("1=1")
set rfac_parser = GetPromptList(2, "e.refer_facility_cd")
call echo (rfac_parser)

declare sParserLoc = vc
set sParserLoc = concat("e.loc_facility_cd  =",cnvtstring(value($fac) ))
declare sFac = vc with public,protect,constant(trim(uar_get_code_display($fac)))
call echo(sParserLoc)
 	record mylist(
	1 pnd_cnt = i4
	1 extCnt = i4
    1 intCnt = i4
  	1 actvL2 = i4
  	1 actv35 = i4
  	1 actvG5 = i4
  	1 current_census = i4
  	1 anti_admit = i4
  	1 proj_admit = i4 
  	1 sched_admit = i4	
  	1 disch_remaining = i4 
  	1 adm_arrived = i4 	
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
/*      		
	1 history[*]
		2 hist_date = vc
		2 dtcomp = dq8
		2 cen_total = i4
		2 cen_admit = i4
		2 cen_discharge = i4
		2 ref_total = i4
		2 ref_internal = i4
		2 ref_external = i4
*/		
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
declare mf8_34_can_surg = f8 with constant(uar_get_code_by("DISPLAYKEY",34,"CANCELLEDSURGERY")) ;5048023.00   ;002
declare index = i4
declare pos = i4
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Get OP and IP Patient in the last 30days		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
call echo(" *  	  Get OP and IP Patient in the last 30days		  	  *")
select into "nl:"
	from encounter e

		,(left join cust_antic_admission_pt caap
			on(caap.encntr_id = e.encntr_id
				and caap.person_id = e.person_id
				and caap.active_ind = 1))
		, encntr_alias fin 							
		, encntr_alias mrn 							
		,person pe
	plan e
		where e.reg_dt_tm > cnvtdate(cnvtlookbehind("30,d"),0000)
		and e.beg_effective_dt_tm between cnvtdate(cnvtlookbehind("30,d"),0000) and cnvtdatetime(curdate, 2359)
		and ((e.disch_dt_tm > cnvtdate(cnvtlookbehind("30,d"),0000))or(e.disch_dt_tm = null))
		and e.encntr_type_cd in (MF8_71_INPT_REFERRAL,MF8_71_PREADMIT) ;(607971507, 309313)
        and e.med_service_cd != mf8_34_can_surg  ;003
		and parser(rfac_parser)
		and parser(sParserLoc);e.loc_facility_cd = 4364516
		and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
	join fin
	where fin.encntr_id = e.encntr_id 				
	and fin.active_ind = 1 							
	and fin.encntr_alias_type_cd = 1077 			
	join mrn
	where mrn.encntr_id = e.encntr_id 				
	and mrn.active_ind = 1 							
	and mrn.encntr_alias_type_cd = 1079 			
	join caap
	join pe
		where pe.person_id = e.person_id
		and pe.active_ind = 1
		and pe.name_last_key not in("IMOC", "ZZ*") ;Removed Test patients
	order by e.encntr_id
	head report
		cnt = 0
	head e.encntr_id
		cnt = cnt + 1
		if(mod(cnt,100) = 1)
			stat = alterlist(mylist->pending, cnt + 99)
		endif
		if(e.encntr_type_cd = MF8_71_INPT_REFERRAL)
			mylist->pending[cnt].outcome_type = "OT"
		elseif(e.encntr_type_cd = MF8_71_PREADMIT)
			mylist->pending[cnt].outcome_type = "IP"
		endif
		mylist->pending[cnt].encntr_id = e.encntr_id
		mylist->pending[cnt].person_id = e.person_id
		mylist->pending[cnt].person = pe.name_full_formatted
		mylist->pending[cnt].p_age = cnvtage(pe.birth_dt_tm)
		mylist->pending[cnt].p_dob = format(pe.birth_dt_tm,'mm/dd/yyyy ;;d')
		if(cnvtupper(uar_get_code_display(pe.sex_cd)) = 'FEMALE')
			mylist->pending[cnt].p_gender = 'F'
		elseif(cnvtupper(uar_get_code_display(pe.sex_cd)) = 'MALE')
			mylist->pending[cnt].p_gender = 'M'
		else
			mylist->pending[cnt].p_gender = 'U'
		endif
		mylist->pending[cnt].reg_dt_tm = e.reg_dt_tm
		mylist->pending[cnt].fin = fin.alias
		mylist->pending[cnt].mrn = mrn.alias
		mylist->pending[cnt].encntr_type = uar_get_code_display(e.encntr_type_cd)
		mylist->pending[cnt].encntr_type_cd = e.encntr_type_cd
		mylist->pending[cnt].encntr_beg_dt_tm = e.beg_effective_dt_tm
		mylist->pending[cnt].loc_nurse_unit = uar_get_code_display(e.loc_nurse_unit_cd)
		mylist->pending[cnt].referral_source = uar_get_code_display(e.refer_facility_cd)
		mylist->pending[cnt].antic_admission_pt_id = caap.cust_antic_admission_pt_id
		;mylist->pending[cnt].is_pending = 'y'
 
		if(cnvtlower(trim(uar_get_code_display(e.refer_facility_cd),3)) in ('*medstar*','franklin square hospital ctr',
		'*washington hospital center*'))
	 		mylist->pending[cnt].internal_external = "Internal"
	 	else
	 		mylist->pending[cnt].internal_external = "External"
	 	endif
	foot report
		stat = alterlist(mylist->pending, cnt)
	with nocounter
 
	call echorecord(reply)
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Get OP and IP Patient in the last 30days		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
	declare mf8_72_dcp = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"DCPGENERICCODE"))
	declare MF8_72_PREADM_WITHDRAWAL_DEN = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PREADMPRIMARYREASONFORWITHDRAWALDEN"))
	declare MF8_72_ASOFDATE = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"ASOFDATE"))
	declare fm_72_insurance = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"INSURANCE"))
	declare fm_72_hosp_service = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"HOSPITALSERVICE"))
	declare fm_72_ptmedacc = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PATIENTMEDICALLYACCEPTEDAPPROPRIATE"))
	declare fm_72_prim_reason = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PRIMARYREASONFORNONADMISSION"))
	declare fm_72_oth_reason = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"OTHERREASONFORNONADMISSION"))
 
	select into "nl:"
	d.seq
	from (dummyt d with seq = size(mylist->pending,5)),
	clinical_event ce,clinical_event ce2,clinical_event ce3
	plan d
	join ce
		where ce.encntr_id = mylist->pending[d.seq].encntr_id
		and ce.valid_until_dt_tm >= cnvtdatetime("31-DEC-2100")
		and ce.result_status_cd in (25, 34, 35)
	join ce2 where ce2.parent_event_id = ce.event_id
		and ce2.event_cd = mf8_72_dcp
	join ce3 where ce3.parent_event_id = ce2.event_id
		and ce3.event_cd = 1889022177.00

	order by ce.encntr_id
	head report
		count = 0
	head ce.encntr_id
		if(ce.encntr_id = 178954829)
			call echo(build2("Found GMan with Result: ",ce3.result_val))
		endif
			mylist->pending[d.seq].is_pending = 'n'
			mylist->pending[d.seq].non_admit_reason = trim(ce3.result_val,3)
			count = count + 1
	with nocounter, time = 1000 ;001
	call echo(mylist->intCnt)
	call echo(mylist->extCnt)
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Encounter Location Hx		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
	select into "nl:"
	referral_date = format(elh.beg_effective_dt_tm,"dd-mmm-yyyy;;q"),
	p_act_days = cnvtint(datetimecmp(cnvtdatetime(CURDATE, curtime3),elh.beg_effective_dt_tm))
	from	encntr_loc_hist	elh
	plan elh
		where expand(index,1,size(mylist->pending,5),elh.encntr_id,mylist->pending[index].encntr_id)
		and elh.encntr_type_cd = mf8_71_inpt_referral
	order by elh.encntr_id, elh.transaction_dt_tm
	head elh.encntr_id
		dateStart = 0
		pos = locateval(index,1,size(mylist->pending,5),elh.encntr_id,mylist->pending[index].encntr_id)
		mylist->pending[pos].referral_dt_tm = elh.beg_effective_dt_tm
		dateStart = findstring("-",referral_date,1,0)
		if(dateStart >0)
			dateMonth = substring(dateStart+1,3,referral_date)
			mylist->pending[pos].referral_dt_tm_vc =
				replace(referral_date,dateMonth,cnvtcap(dateMonth))
		else
			mylist->pending[pos].referral_dt_tm_vc = referral_date
		endif
		mylist->pending[pos].p_act_days = p_act_days
 
	with expand = 1
 
;---------------------------------------------------------------------------------------------------------------------------------
;	 *  	  Load Main RS		  	  *
;---------------------------------------------------------------------------------------------------------------------------------
	select into "nl:"
	d.seq
	from (dummyt d with seq = size(mylist->pending,5))
	plan d where mylist->pending[d.seq].is_pending != 'n'
	head report
		cnt = 0
	detail
		cnt = cnt + 1
		stat = alterlist(mylist->output,cnt)
		mylist->output[cnt].encntr_id = mylist->pending[d.seq].encntr_id
		mylist->output[cnt].person_id = mylist->pending[d.seq].person_id
		mylist->output[cnt].person = mylist->pending[d.seq].person
		mylist->output[cnt].p_age = mylist->pending[d.seq].p_age
		mylist->output[cnt].p_dob = mylist->pending[d.seq].p_dob
		mylist->output[cnt].p_gender = mylist->pending[d.seq].p_gender
		mylist->output[cnt].reg_dt_tm = mylist->pending[d.seq].reg_dt_tm
		mylist->output[cnt].referral_dt_tm  = mylist->pending[d.seq].referral_dt_tm
		mylist->output[cnt].referral_dt_tm_vc  = mylist->pending[d.seq].referral_dt_tm_vc
		mylist->output[cnt].fin = mylist->pending[d.seq].fin
		mylist->output[cnt].mrn = mylist->pending[d.seq].mrn
		mylist->output[cnt].encntr_type = mylist->pending[d.seq].encntr_type
		mylist->output[cnt].encntr_type_cd = mylist->pending[d.seq].encntr_type_cd
		mylist->output[cnt].encntr_beg_dt_tm = mylist->pending[d.seq].encntr_beg_dt_tm
		mylist->output[cnt].loc_nurse_unit = mylist->pending[d.seq].loc_nurse_unit
		mylist->output[cnt].referral_source = mylist->pending[d.seq].referral_source
		mylist->output[cnt].is_pending = mylist->pending[d.seq].is_pending
		mylist->output[cnt].p_act_days = mylist->pending[d.seq].p_act_days
		mylist->output[cnt].antic_admission_pt_id = mylist->pending[d.seq].antic_admission_pt_id
		if(trim(mylist->pending[d.seq].internal_external,3) = "Internal")
	 		mylist->intCnt = mylist->intCnt + 1
	 	elseif(trim(mylist->pending[d.seq].internal_external,3) = "External")
	 		mylist->extCnt = mylist->extCnt + 1
	 	endif
	 	if(mylist->output[cnt].is_pending != 'n')
			if(mylist->output[cnt].p_act_days<= 2)
				mylist->actvL2 = mylist->actvL2 + 1
			elseif(mylist->output[cnt].p_act_days <= 5)
			 	mylist->actv35 = mylist->actv35 + 1
			elseif(mylist->output[cnt].p_act_days >5)
			 	mylist->actvG5 = mylist->actvG5 + 1
			endif
		endif
	foot report
		mylist->pnd_cnt = cnt
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
    (dummyt d with seq = size(mylist->output,5)),
    clinical_event ce
  plan d
  join ce where
    ce.encntr_id = mylist->output[d.seq].encntr_id and
    ce.event_cd = dActStatus and
    ce.valid_until_dt_tm > sysdate
  order d.seq, dttm desc
 
  head d.seq
    mylist->output[d.seq].refstatus  = trim(ce.result_val)
  with nocounter, time = 200
 
;---------------------------------------------------------------------------------------------------------------------------------
;collect comments
;---------------------------------------------------------------------------------------------------------------------------------
/*
  call echo('collect action comments')
  	declare dActComments = f8
	  set dActComments = uar_get_code_by("DISPLAYKEY", 72, "CIRACTIONCOMMENTSREFMP")
	  select into "nl:"
		from (dummyt d with seq = size(mylist->output,5)),
			clinical_event ce,
			prsnl p
		plan d
		join ce
			where ce.encntr_id = mylist->output[d.seq].encntr_id
			and ce.event_cd = dActComments
			and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
			;and ce.view_level = 1
		join p
			where p.person_id = ce.performed_prsnl_id
		order by d.seq, ce.event_end_dt_tm desc
	 	head d.seq
			nCmnt = 0
		    mylist->output[d.seq].s_comment = trim(ce.result_val)
		  	detail
			  	nCmnt = nCmnt + 1
			  	stat = alterlist(mylist->output[d.seq].s_comment_his, nCmnt)
			  	mylist->output[d.seq].s_comment_his[nCmnt].s_comment_dt = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm;;D")
			    mylist->output[d.seq].s_comment_his[nCmnt].s_comment_val = trim(ce.result_val,3)
			    mylist->output[d.seq].s_comment_his[nCmnt].s_comment_prsnl = trim(p.name_full_formatted,3)
  		 with nocounter, time = 20
	call echo('End Collect Action Comments')
 */
 
 
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
	 from (dummyt d with seq = size(mylist->output,5)),
	 	clinical_event ce
	 plan d
	 join ce
		 where ce.encntr_id = mylist->output[d.seq].encntr_id
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
			 			mylist->output[d.seq].p_liaison_name = result
;			 			if(size(mylist->liaisons,5)>0)
;			 				lcount = locateval(num, 1, size(mylist->liaisons,5), result , mylist->liaisons[num].al_name)
;			 			endif
;			 			if(lcount = 0)
;			 				lcount = size(mylist->liaisons,5) + 1
;			 				stat = alterlist(mylist->liaisons,lcount)
;			 			endif
;			 			mylist->liaisons[lcount].al_name = result
;			 			mylist->liaisons[lcount].al_total = mylist->liaisons[lcount].al_total + 1
;						if(mylist->output[d.seq].p_act_days <= 2)
;							mylist->liaisons[lcount].actvL2 = mylist->liaisons[lcount].actvL2 + 1
;						elseif(mylist->output[d.seq].p_act_days <= 5)
;						 	mylist->liaisons[lcount].actv35 = mylist->liaisons[lcount].actv35 + 1
;						else
;						 	mylist->liaisons[lcount].actvG5 = mylist->liaisons[lcount].actvG5 + 1
;						endif
			 		of admission_rep_cd:
			 	  		mylist->output[d.seq].p_admission_rep =result
			 	  endcase
	with nocounter

;---------------------------------------------------------------------------------------------------------------------------------
;collect status
;---------------------------------------------------------------------------------------------------------------------------------
/*	call echo("Starting collect status")
	select into 'nl:'
	from (dummyt d with seq = size(mylist->output,5)),
		cust_antic_admission_pt caap
	plan d
	join caap
		where caap.active_ind = 1
		and caap.projected_status in ('Scheduled','Projected')
		and caap.encntr_id = mylist->output[d.seq].encntr_id
	order by caap.encntr_id, caap.projected_dt_tm desc
 	head caap.encntr_id
 		mylist->output[d.seq].status = caap.projected_status
 		call echo(build2(mylist->output[d.seq].person," ",caap.projected_status))
	with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
;Get Anticipated Admissions CCL Audit Log
;---------------------------------------------------------------------------------------------------------------------------------
/*
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
		mylist->anti_admit = mylist->anti_admit + 1
;004
	if(	caap.projected_status = 'Scheduled')
		mylist->sched_admit += 1
	else
		mylist->proj_admit += 1
	endif
;004 end
	with nocounter,time=60
 
	set startdt = format(datetimefind(cnvtdatetime(CURDATE, curtime2),"d","e","e"),"mmddyyyy;;q")
	call echo(Build2("StartDTTT:",startdt))
	call GetCensusReferralHist(startdt,cnvtreal(request_in->sLoc))
	;set mylist->current_census = mylist->history[7].cen_total
	call CollectInsurance(0)
	declare errmsg = C132
  	if (error(errmsg, 0) > 0)
		call ccl_write_audit(CURPROG, "MPage", "FAILED", size(mylist->output,5))
	else
		call ccl_write_audit(CURPROG, "MPage", "SUCCESS", size(mylist->output,5))
	endif
 */
;	set _memory_reply_string = cnvtrectojson(reply, 4)
;	call echo(_memory_reply_string)

/***********************************************************************************************
	OUTPUT
***********************************************************************************************/
IF($EMAIL = "")
SELECT INTO $OUTDEV
patient_name = mylist->output[d.seq].person ,
MRN = mylist->output[d.seq].mrn ,
FIN = mylist->output[d.seq].fin ,
gender = mylist->output[d.seq].p_gender ,
Liaison = mylist->output[d.seq].p_liaison_name ,
;Rep = mylist->output[d.seq].p_admission_rep ,
Days_active = mylist->output[d.seq].p_act_days ,
Referral_source = mylist->output[d.seq].referral_source ,
Current_Patient_location= mylist->output[d.seq].loc_nurse_unit, 
referral_status = mylist->output[d.seq].refstatus 

from (dummyt d with seq = size(mylist->output,5))
order by patient_name
with format, separator = " ", nocounter
else
declare currTime = vc with protect, constant(format(cnvtdatetime(curdate, curtime3),"_yyyymmddhhmmss;;q"))
declare filename = vc with protect, noconstant(build2("/cerner/d_p41/temp/",  "cir_ref_tracker", currTime, ".csv"))
declare email_subject = vc with protect
set email_subject = build2("MedStar Referral to " ,sFac ," Status report")
declare email_body = vc with protect, noconstant(concat("cir_ref_tracker", currTime, ".dat"));;;must be unique to this object
declare aix_command = vc with noconstant("")
declare aix_cmdlen = i4 with noconstant(0)
declare aix_cmdstatus = i4 with noconstant(0)
declare email_address = vc with protect, noconstant("")
set email_address = $email

SELECT INTO value(filename)
patient_name = mylist->output[d.seq].person ,
MRN = mylist->output[d.seq].mrn ,
FIN = mylist->output[d.seq].fin ,
gender = mylist->output[d.seq].p_gender ,
Liaison = mylist->output[d.seq].p_liaison_name ,
;Admission_liaison = mylist->output[d.seq].p_admission_rep ,
Days_active = mylist->output[d.seq].p_act_days ,
Referral_source = mylist->output[d.seq].referral_source ,
Current_Patient_location= mylist->output[d.seq].loc_nurse_unit, 
referral_status = mylist->output[d.seq].refstatus 

from (dummyt d with seq = size(mylist->output,5))
order by patient_name
with heading, pcformat('"', ',', 1), format=stream, format, nocounter, compress

	Select into (value(EMAIL_BODY))
		line01 = build2("Run Date and Time: ",
				        format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q")),
		line02 = build2("CLL Object name: ",trim(cnvtlower(curprog))) 
		,linefac = build2("Facility: ", trim(sfac));001 
		, whotoblame = "Custom Development handles incidents with this report.";001 
	from dummyt
	Detail
	col 01 line01
	row +2
	col 01 linefac;001 
	row + 2
	col 01 whotoblame;001 
	row + 1	
	col 01 line02
	with format,  format = variable   ,   maxcol = 200
	set  aix_command  = build2 ( "cat ", email_body ," | tr -d \\r"
									, " | mailx  -S from='report@medstar.net' -s '"
									, email_subject , "' -a ", filename, " ", email_address)
	set aix_cmdlen = size(trim(aix_command))
	set aix_cmdstatus = 0
	call dcl(aix_command,aix_cmdlen, aix_cmdstatus)
;select into $outdev
;build2("Report Emailed to", trim($email))
;from dummyt 
;with format, nocounter

endif

free record mylist
#exit_script
end go

;13_cir_ref_tracker_rpt "MINE",4363216.00,4364516.00,"" go
