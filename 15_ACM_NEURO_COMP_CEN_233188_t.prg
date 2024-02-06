/********************************************************************************************************************
 
        Source file name:		cust_script:15_acm_neuro_comp_cen_233188.prg
        Object name:        	15_acm_neuro_comp_cen_233188
        Implementation date: 	Jul 01, 2022
 
        Executing from:			DA2 -> Published Reports 
        Test Execution Script: 	EXECUTE 15_acm_neuro_comp_cen_233188 "MINE", 4363216.00 go
 		Purpose: 				This report displays Neurosciences Compliance Census
 
        Associated Layout
        /programs:				NA
 
        Special notes:
 
*********************************************************************************************************************
                      GENERATED MODIFICATION CONTROL LOG                 *
*********************************************************************************************************************
 Mod Date     		Engineer     	    		MCGA/OPAS 				Comments
 --- -------- 		------------ 				------------ 		-------------------------------------------------
 000 Jul 01, 2022	Steve Czubek             	MCGA#233188			Initial version.
 001 10/25/2022		Kim Frazier					Task				Add unit/room/bed
 																	SW Assessment complete column, date/by name
 002 1/26/2024		Kim FRazier					mcga 345759			Add column Init Assessment info if SW performed it
*********************************************************************************************************************/
drop program 15_ACM_NEURO_COMP_CEN_233188_t:dba go
create program 15_ACM_NEURO_COMP_CEN_233188_t:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Facility" = VALUE(    4363210.00)
	, "eMail" = "" 

with OUTDEV, facility, email



%i cust_script:SC_CPS_GET_PROMPT_LIST.inc
declare fac_parser = vc with protect, noconstant("1=1")
set fac_parser = GetPromptList(2, "ed.loc_facility_cd")
if (fac_parser = "1=1")
    set fac_parser = 
"ed.loc_facility_cd in (633867.0,4363210.0,4362818.0,4363058.0,446795444.0,4364516.0,465210143.0,465209542.0,4363156.0,4363216.0)"
endif
declare ATTENDINGPHYSICIAN = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 333, "ATTENDINGPHYSICIAN"))
declare cnt = i4 with protect, noconstant(0)
declare MRN    = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 319, "MRN"))
declare FINNBR = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 319, "FINNBR"))
declare INPATIENT = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 71, "INPATIENT"))
declare OBSERVATION = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 71, "OBSERVATION"))
declare event_component_cd = f8 with noconstant(uar_get_code_by("MEANING",18189,"CLINCALEVENT"))

declare currTime = vc with protect, constant(format(cnvtdatetime(curdate, curtime3),"_YYYYMMDDHHMMSS;;q"))
if(curdomain = "B41")
	set currentdomain = "d_b41/"
else
	set currentdomain = "d_p41/temp/"
endif
declare filename = vc with protect, constant(build2("/cerner/", currentdomain, "neuro_census", currTime, ".csv"))
declare email_subject = vc with protect, constant("Neurosciences Compliance Census")
declare email_body = vc with protect, constant(concat("neuro_census", currTime, ".dat"));;;must be unique to this object
declare aix_command = vc with noconstant("")
declare aix_cmdlen = i4 with noconstant(0)
declare aix_cmdstatus = i4 with noconstant(0)
declare email_address = vc with protect, public ;001
set email_address = $email
;	constant(concat("lauren.a.barber@medstar.net,Heather.y.daniels@gunet.georgetown.edu,Lakeisha.coleman@gunet.georgetown.edu,",
;	"Isabella.N.Pyne@gunet.georgetown.edu,brian.v.butler@medstar.net,samantha.dejean@medstar.net,anya.l.mabrey@medstar.net,",
;	"tge2@gunet.georgetown.edu,ernestine.o.dorsey@gunet.georgetown.edu,raa6@gunet.georgetown.edu,",
;	"amber.d.pennel@gunet.georgetown.edu,srb01@gunet.georgetown.edu"))


/*001 get list of order sets to filter on
1.	NEURO CCM Intracerebral Hemorrhage Admit to ICU
2.	NEURO CCM Stroke Ischemic Admit to ICU non- alteplase
3.	NEURO CCM Stroke Ischemic Admit to ICU Post tPA
4.	NEURO Intracerebral Hemorrhage Admit Med/Surg/IMC
5.	NEURO Stroke Ischemic/ TIA Admit to Med/ Surg/ IMC
6.	NSURG CCM Subarachnoid Hemorrhage SAH Pre-Treatment ICU
*/
free record ord_sets
record ord_sets(
1 qual[*]
2 order_cd = f8

)
select into "NL:"
 from pathway_catalog pc
where pc.description_key  like "NEURO INTRACEREBRAL HEMORRHAGE ADMIT TO ICU*"
	or pc.description_key like "NEURO CCM STROKE ISCHEMIC ADMIT TO ICU NON-TPA*"
	or pc.description_key like "NEURO CCM STROKE ISCHEMIC ADMIT TO ICU/IMCU POST-TPA*"
	or pc.description_key like "NEURO INTRACEREBRAL HEMORRHAGE ADMIT MED/SURG/IMC*"
	or pc.description_key like "NEURO STROKE ISCHEMIC / TIA ADMIT TO MED / SURG / IMC*"
	or pc.description_key like "NSURG CCM SUBARACHNOID HEMORRHAGE SAH PRE-TREATMENT ICU*"
head report
scnt = 0
detail
scnt = scnt + 1
stat = alterlist(ord_sets->qual,scnt)
ord_sets->qual[scnt].order_cd = pc.pathway_catalog_id
with nocounter	
call echorecord(ord_sets)
;001 end
	
free record rpt_data
record rpt_data
(
	1 qual[*]
		2 encntr_id = f8
		2 encounter_type = vc
		2 Admission_Date = vc
		2 Patient_Name = vc
		2 MRN = vc
		2 FIN = vc
		2 Primary_Payor = vc
		2 Attending_Physician = vc	
		2 Service = vc
		2 LOS = f8
		2 pathway = vc
		2 pt_unit = vc 
		2 pt_location = vc ;room/bed
		2 sw_assessment = vc
		2 init_assessment = vc ;002

)

select into "nl:"
from 
	encntr_domain ed 
	,encntr_prsnl_reltn epr
	,prsnl ps
	,encounter e
	,encntr_alias ea
	,person p
	,encntr_plan_reltn ehpr
	,health_plan hp

plan ed
	where ed.active_ind = 1
	and parser(fac_parser)
	and ed.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
	and ed.loc_bed_cd > 0
join epr
	where epr.encntr_id = ed.encntr_id
	and epr.active_ind = 1
	and epr.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
	and epr.encntr_prsnl_r_cd = ATTENDINGPHYSICIAN
join ps
	where ps.person_id = epr.prsnl_person_id
	;001 and ps.name_full_formatted in ("Denny, MD, Mary Carter","Edwardson, MD, Matthew A") 
	and ps.active_ind = 1
join e
	where e.encntr_id = ed.encntr_id

join ea
	where ea.encntr_id = e.encntr_id
	and ea.active_ind = 1
	and ea.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
join p
	where p.person_id = ed.person_id
join ehpr
	where ehpr.encntr_id = e.encntr_id
	and ehpr.priority_seq in (0, 1)
	and ehpr.end_effective_dt_tm > cnvtdatetime(curdate, curtime)
join hp
	where hp.health_plan_id = ehpr.health_plan_id 


order ed.encntr_id
head report
	cnt = 0
head ed.encntr_id
	if (mod(cnt, 10) = 0)
		stat = alterlist(rpt_data->qual, cnt + 10)
	endif
	cnt = cnt + 1
	rpt_data->qual[cnt].Admission_Date = format(e.reg_dt_tm, ";;q")
	rpt_data->qual[cnt].Patient_Name = p.name_full_formatted
	rpt_data->qual[cnt].Service = uar_get_code_display(ed.med_service_cd)
	if (e.disch_dt_tm > 0)
	rpt_data->qual[cnt].LOS = cnvtint(
	datetimediff(e.disch_dt_tm,
	 DATETIMEFIND(e.reg_dt_tm,"D","B","B"), 1)
	 )
	else
	rpt_data->qual[cnt].LOS = cnvtint(
	datetimediff(cnvtdatetime(curdate, curtime),
	 DATETIMEFIND(e.reg_dt_tm,"D","B","B"), 1)
	 )
	endif
	if (rpt_data->qual[cnt].LOS < 1)
		rpt_data->qual[cnt].LOS = 1
	endif

	rpt_data->qual[cnt].encntr_id = ed.encntr_id
	rpt_data->qual[cnt].Attending_Physician = ps.name_full_formatted
	rpt_data->qual[cnt].encounter_type = uar_get_code_display(e.encntr_type_cd)
	rpt_data->qual[cnt].Primary_Payor = hp.plan_name
	rpt_data->qual[cnt].Pt_unit = trim(uar_get_code_display(ed.loc_nurse_unit_cd))
	rpt_data->qual[cnt].Pt_location = build2(trim(uar_get_code_display(ed.loc_room_cd)), "-",
									trim(uar_get_code_display(ed.loc_bed_cd)))
	
detail

	if (ea.encntr_alias_type_cd = MRN)
		rpt_data->qual[cnt].MRN = ea.alias
	elseif (ea.encntr_alias_type_cd = FINNBR)
		rpt_data->qual[cnt].FIN = ea.alias
	endif

foot report
	stat = alterlist(rpt_data->qual, cnt)
with nocounter

; 001 get pathway we care about
declare n = i2 with public,protect
declare pos = i2 with public,protect
select into "NL:"
from (dummyt d with seq = size(rpt_data->qual,5))
	,pathway pw
plan d
join pw
where pw.encntr_id = rpt_data->qual[d.seq].encntr_id 
detail
 pos = locateval(n,1,size(ord_sets->qual,5),pw.pathway_catalog_id,ord_sets->qual[n].order_cd)
if(pos > 0)
rpt_data->qual[d.seq].pathway = pw.description
endif
with nocounter


;GET SOCIAL WORK ASSESSMENT DETAILS   19902500775.00
select into "nl:"
this_date = format(ce2.verified_dt_tm, "MM-DD-YYYY")
from 
	dcp_forms_activity dfa
	,dcp_forms_Activity_comp dfac
    ,clinical_event ce2
    ,(dummyt d with seq = size(rpt_data->qual, 5))
    ,prsnl ps
plan d
 
join dfa
  where dfa.encntr_id = rpt_data->qual[d.seq].encntr_id
    and dfa.dcp_forms_ref_id = 19902500775.00 ;SW Assessment form
    and dfa.form_status_cd in (25,34,35)
    and dfa.active_ind = 1
join dfac
  where dfac.dcp_forms_activity_id = dfa.dcp_forms_activity_id
    and dfac.component_cd = event_component_cd
 
join ce2
  where ce2.parent_event_id = dfac.parent_entity_id
    and ce2.valid_until_dt_tm > cnvtdatetime(curdate, curtime)
    and ce2.result_status_cd in  (25,34,35)
    and ce2.event_id != ce2.parent_event_id
join ps
	where ps.person_id = ce2.verified_prsnl_id
order by
	d.seq
	,ce2.verified_dt_tm
head d.seq
	null
detail
rpt_data->qual[d.seq].sw_assessment = build2(this_date, " by " ,trim(ps.name_full_formatted))

with nocounter

;GET INITIAL ASSESSMENT DETAILS   
select into "nl:"
this_date = format(ce2.verified_dt_tm, "MM-DD-YYYY")
from 
	dcp_forms_activity dfa
	,dcp_forms_Activity_comp dfac
    ,clinical_event ce2
    ,(dummyt d with seq = size(rpt_data->qual, 5))
    ,prsnl ps
    ,encntr_prsnl_reltn epr
plan d
 
join dfa
  where dfa.encntr_id = rpt_data->qual[d.seq].encntr_id
    and dfa.dcp_forms_ref_id =   19676314995.00 ;Initial Discharge planning Assessment form
    and dfa.form_status_cd in (25,34,35)
    and dfa.active_ind = 1
join dfac
  where dfac.dcp_forms_activity_id = dfa.dcp_forms_activity_id
    and dfac.component_cd = event_component_cd
 
join ce2
  where ce2.parent_event_id = dfac.parent_entity_id
    and ce2.valid_until_dt_tm > cnvtdatetime(curdate, curtime)
    and ce2.result_status_cd in  (25,34,35)
    and ce2.event_id != ce2.parent_event_id
join ps
	where ps.person_id = ce2.verified_prsnl_id
join epr
	where epr.encntr_id = ce2.encntr_id
	and epr.prsnl_person_id = ps.person_id
	and epr.encntr_prsnl_r_cd =      666813.00;social worker
order by
	d.seq
	,ce2.verified_dt_tm
head d.seq

rpt_data->qual[d.seq].init_assessment= build2(this_date, " by " ,trim(ps.name_full_formatted))

with nocounter

if ($outdev != "OPS")
select into $outdev
Patient_Name = substring(1, 25, rpt_data->qual[d.seq].Patient_Name) ,
MRN = substring(1, 12, rpt_data->qual[d.seq].MRN), 
FIN = substring(1, 12, rpt_data->qual[d.seq].FIN),
Unit = substring(1, 20, rpt_data->qual[d.seq].pt_UNIT),
RoomBed = substring(1, 20, rpt_data->qual[d.seq].Pt_Location),
Admission_Date = rpt_data->qual[d.seq].Admission_Date,
Primary_Payor = substring(1, 20, rpt_data->qual[d.seq].Primary_Payor) ,
Attending_Physician = substring(1, 25, rpt_data->qual[d.seq].Attending_Physician),
Encounter_Type = substring(1, 15, rpt_data->qual[d.seq].encounter_type), 
LOS = rpt_data->qual[d.seq].LOS ,
service = substring(1, 20, rpt_data->qual[d.seq].Service), 
Pathway = substring(1, 70, rpt_data->qual[d.seq].pathway)
,SW_Assessment = substring(1, 50, rpt_data->qual[d.seq].sw_assessment) ;001
, Init_DC_Planning_assessment  = substring(1, 50, rpt_data->qual[d.seq].init_assessment) ;002
from 
	(dummyt d with seq = size(rpt_data->qual, 5))
plan d
where rpt_data->qual[d.seq].pathway > "" ;001 added filter based on pw
order d.seq
with format, separator = " "

else

select into value(filename)
Patient_Name = substring(1, 25, rpt_data->qual[d.seq].Patient_Name) ,
MRN = substring(1, 12, rpt_data->qual[d.seq].MRN), 
FIN = substring(1, 12, rpt_data->qual[d.seq].FIN),
Unit = substring(1, 20, rpt_data->qual[d.seq].pt_UNIT),
RoomBed = substring(1, 20, rpt_data->qual[d.seq].Pt_Location),
Admission_Date = rpt_data->qual[d.seq].Admission_Date,
Primary_Payor = substring(1, 20, rpt_data->qual[d.seq].Primary_Payor) ,
Attending_Physician = substring(1, 25, rpt_data->qual[d.seq].Attending_Physician),
Encounter_Type = substring(1, 15, rpt_data->qual[d.seq].encounter_type), 
LOS = rpt_data->qual[d.seq].LOS ,
service = substring(1, 20, rpt_data->qual[d.seq].Service) ,
Pathway = substring(1, 70, rpt_data->qual[d.seq].pathway)
,SW_Assessment = substring(1, 50, rpt_data->qual[d.seq].sw_assessment) ;001
, Init_DC_Planning_assessment = substring(1, 50, rpt_data->qual[d.seq].init_assessment) ;002
from 
	(dummyt d with seq = size(rpt_data->qual, 5))
plan d
where rpt_data->qual[d.seq].pathway > "" ;001 added filter based on pw
order d.seq
with heading, pcformat('"', ',', 1), format=stream, format, nocounter, compress
	if (size(rpt_data->qual, 5) = 0)
	Select into (value(EMAIL_BODY))
		line01 = build2("NO DATA FOUND FOR THE GIVEN CRITERIA. Run Date and Time: ",
				        format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q")),
		line02 = build2("CLL Object name: ",trim(cnvtlower(curprog)))
	from dummyt
	Detail
	col 01 line01
	row +2
	col 01 line02
	with format,  format = variable   ,   maxcol = 200
	
	set  aix_command  = build2 ( "cat ", email_body ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,email_subject , "' ", email_address)
	set aix_cmdlen = size(trim(aix_command))
	set aix_cmdstatus = 0
	set dclstatus = -1
      	set dclstatus = dcl(aix_command, aix_cmdlen, aix_cmdstatus)

	else	
	Select into (value(EMAIL_BODY))
		line01 = build2("Run Date and Time: ",
				        format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q")),
		line02 = build2("CLL Object name: ",trim(cnvtlower(curprog))) 
	from dummyt
	Detail
	col 01 line01
	row +2
	col 01 line02
	with format,  format = variable   ,   maxcol = 200
	
	set  aix_command  = build2 ( "cat ", email_body ," | tr -d \\r"
									, " | mailx  -S from='report@medstar.net' -s '"
									, email_subject , "' -a ", filename, " ", email_address)
	set aix_cmdlen = size(trim(aix_command))
	set aix_cmdstatus = 0
	call dcl(aix_command,aix_cmdlen, aix_cmdstatus)
	endif
endif


#exit_script
end
go

