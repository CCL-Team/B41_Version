/**************************************************************************************************
  Source File Name:   99_cir_disch_by_date.prg
  Object Name:        99_cir_disch_by_date
  Group Level:        0
  Arguments/Prompts:  Output distribution  		(default: MINE)
  Tables Updated:     n/a
  Input Files:        from Prompts
  Output Files:       n/a
  Reports Created:	  cir_discharges_<facility abbrev>_<date, 'MMDDYYYY'>.csv
  Special Notes:
  Department:		  Rehabilitation
  Program Initially
  Written By:         Nicole Williams, HPG
  Program Initially
  Written Date: 	  03/01/18
 
 **************************************************************************************************
  Program Modification:
 **************************************************************************************************
  Mod#  Mod By        Mod Date 	MCGA	Modification Purpose
 *--- -------------- ----------	-------	------------------------------------------------------------------*
  000 Nicole Williams 04/20/18	 		Introduction
  001 Nicole Williams 05/22/18   		Adding Encounter Type: NRH - Leave of Absence to population
  002 Nicole Williams 05/24/18   		New column: Encounter Type
  003 Jennifer King	  02/14/19 	214484	New columns:  Admit dt/tm, Patient Phone #
  004 Brian Twardy    04/10/2019 n/A	Emergency... added MMMC, MSMHC, and MSMH for Pat Parms
  005 HPG			  09/23/19  217624 	Modified FACIITY prompt to look up by CODE_VALUE instead of DISPLAY_KEY
  006 Jennifer King	  10/17/19	218442	Add columns for Invision disposition and Discharge to Living DTA
  007 Kim Frazier 	  02/06/2020 220393 Add Admission_Liaison column after Attending_Physician column.
										Add Admission_Rep after the Admission_Liaison column
 
 *************************************************************************************************/
drop program 13_cir_disch_by_date:dba go
create program 13_cir_disch_by_date:dba
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Facility:" = 4364921.00
	, "Discharge Start Date:" = "SYSDATE"
	, "Discharge End Date:" = "SYSDATE"
 
with OUTDEV, FACILITY, STARTDATE, ENDDATE
 
declare DEBUG_IND = i4 with noconstant(0)
set DEBUG_IND = 0
 
record enc(
1 cnt = i4
1 list[*]
2 encntr_id = f8
2 person_id = f8
2 transaction_id = f8
2 admt_trans_dt_tm = dq8
)
 
record disch(
	1 pts[*]
	  2 person = vc
	  2 person_id = f8
	  2 encntr_id = f8
	  2 encntr_type = vc
	  2 mrn = vc
	  2 fin = vc
	  2 unit_room = vc
	  2 phys_attending = vc
	  2 ins_primary = vc
	  2 ins_secondary = vc
	  2 ins_tertiary = vc
	  2 service = vc
	  2 admit_dt_tm = dq8
	  2 disch_dt_tm = dq8
	  2 admit_dt_tm_disp = vc
	  2 disch_dt_tm_disp = vc
	  2 pt_phone_home = vc ;003 - added
	  2 disposition = vc ;006  - added
	  2 disch_to_living = vc ;006  - added
 
 	  2 Admission_liaison = vc;007 added
 	  2 admission_rep = vc ;007 added
)
 
declare fac_fsh = f8 with constant(633868.00)		;	Franklin Square Hospital Center
declare fac_guh = f8 with constant(4366007.00)		;	Georgetown University Hospital
declare fac_gsh = f8 with constant(4364921.00)		;	Good Samaritan Hospital
declare fac_hbr = f8 with constant(4365513.00)		;	Harbor Hospital Center
declare fac_nrh = f8 with constant(4368977.00)		;	National Rehabilitation Hospital
declare fac_umh = f8 with constant(4365807.00)		;	Union Memorial Hospital
declare fac_whc = f8 with constant(4366129.00)		;	Washington Hospital Center
declare fac_smh = f8 with constant(522026385.00)	;   MedStar St Mary's Hospital		;;005
 
declare var_facility = f8
set var_facility = (if($FACILITY = fac_fsh)
						633867.00
					elseif ($FACILITY = fac_guh)
						4363210.00
					elseif ($FACILITY = fac_gsh)
						4362818.00
					elseif ($FACILITY = fac_hbr)
						4363058.00
					elseif ($FACILITY = fac_nrh)
						4364516.00
					elseif ($FACILITY = fac_umh)
						4363156.00
					elseif ($FACILITY = fac_whc)
						4363216.00
					elseif ($FACILITY = fac_smh)	;	005
						465209542.00				;	005
					endif)
;Output Variables
declare fx_name = vc with noconstant("")
declare fx_facility = vc with noconstant("")
declare fx_run_time = vc with noconstant("")
declare fx_date = vc with noconstant("")
declare var_start_date = vc with noconstant("")
declare var_end_date = vc with noconstant("")
declare var_sd = dq8
declare var_ed = dq8
 
declare file_created = vc with Protect
declare file_name = vc with Protect
declare output_date = vc with Protect
declare get_fac_disp = vc
declare get_f8_loc_cd = f8
declare getFac = vc with Protect
 
declare getTitleName = vc with noconstant("")
declare fts = dq8 with Protect
set fts = cnvtdatetime(CURDATE, curtime3)
set file_created = build2(format(fts,"MM;;d"),trim(cnvtstring(day(fts)),3),trim(cnvtstring(year(fts)),3))
 
set var_sd = cnvtdatetime($STARTDATE)
set var_ed = cnvtdatetime($ENDDATE)
set var_start_date = build2(format(var_sd,"MM/DD/YYYY;;d")," ",format(var_sd,"HH:MM;;d"))
set var_end_date = build2(format(var_ed,"MM/DD/YYYY;;d")," ",format(var_ed,"HH:MM;;d"))
 
set fx_name = "Medstar Discharges by Date"
set fx_run_time = build2("Run Time: ",format(CURDATE,"MM/DD/YYYY;;d")," ",format(curtime3,"HH:MM;3;m"))
set fx_date = build2("Date Range: ",var_start_date," - ",var_end_date)
 
set get_fac_disp = substring(1,1,trim(reflect(parameter(2,0)),3))
if(get_fac_disp = "F")
	set get_f8_loc_cd = parameter(2,0)
	case(get_f8_loc_cd)
	of fac_fsh:	set getTitleName = "fsh"
	of fac_guh:	set getTitleName = "guh"
	of fac_gsh:	set getTitleName = "gsh"
	of fac_hbr:	set getTitleName = "hbr"
	of fac_nrh:	set getTitleName = "nrh"
	of fac_umh:	set getTitleName = "umh"
	of fac_whc:	set getTitleName = "whc"
	of fac_smh: set getTitleNamw = "smh"	;
	endcase
endif
 
set file_name = build2("cir_discharges_",getTitleName,"_",file_created,".csv")
 
SELECT INTO "NL:"
FROM	CODE_VALUE	CV1
PLAN CV1 WHERE CV1.CODE_SET = 220
	and CV1.CODE_VALUE = var_facility
detail
	fx_facility = concat("Facilty: ",cv1.description)
WITH NOCOUNTER
;End Output Variables
 
declare var_fin = f8 with noconstant(uar_get_code_by("DISPLAYKEY",319,"FINNBR"))
declare var_mrn = f8 with noconstant(uar_get_code_by("DISPLAYKEY",319,"MRN"))
declare encntr_type_class_inpt = f8 with noconstant(uar_get_code_by("DISPLAYKEY",69,"INPATIENT"))
declare encntr_type_nrh_loa = f8 with noconstant(uar_get_code_by("DISPLAYKEY",71,"NRHLEAVEOFABSENCE")) ;607970233.00
declare encntr_type_inpt = f8 with noconstant(uar_get_code_by("DISPLAYKEY",71,"INPATIENT"))
declare text_event_class_cd = f8 with noconstant(uar_get_code_by("DISPLAYKEY",53,"TXT"))
declare group_event_class_cd = f8 with noconstant(uar_get_code_by("DISPLAYKEY",53,"GRP"))
declare date_event_class_cd = f8 with noconstant(uar_get_code_by("DISPLAYKEY",53,"DATE"))
declare phys_attending = f8 with constant(uar_get_code_by("DISPLAYKEY",333,"ATTENDINGPHYSICIAN"))
declare phys_referring = f8 with constant(uar_get_code_by("DISPLAYKEY",333,"REFERRINGPHYSICIAN"))
declare phys_admitting = f8 with constant(uar_get_code_by("DISPLAYKEY",333,"ADMITTINGPHYSICIAN"))
declare admis_liaison = f8 with constant(uar_get_code_by("DISPLAYKEY",333,"ADMISSIONSLIAISON")) ;903186787.00
declare inpatient_referral = f8 with constant(uar_get_code_by("DISPLAYKEY",71,"INPATIENTREFERRAL"))
declare pic_condit_logic = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PICCONDITIONALITYLOGIC")) ;823634037
declare pic_1 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC01STROKE")) ;823588003
declare pic_2 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC02BRAINDYSFUNCTION")) ;823588013
declare pic_3 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC03NEUROLOGICAL")) ;823588023
declare pic_4_trauma = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC04SPINALCORDDYSFUNCNONTRAUMATIC")) ;823588153
declare pic_4_notrauma = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC04SPINALCORDDYSFUNCTIONTRAUMATIC")) ;823588163
declare pic_5 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC05AMPUTATION")) ;823588033
declare pic_6 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC06ARTHRITIS")) ;823588143
declare pic_7 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC07PAIN")) ;823588073
declare pic_8 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC08ORTHOPEDICCONDITIONS")) ;823588173
declare pic_9 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC09CARDIAC")) ;823588083
declare pic_10 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC10PULMONARY")) ;823588093
declare pic_11 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC11BURNS")) ;823588043
declare pic_12 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC12CONGENITALDISORDERS")) ;823588063
declare pic_13 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC13OTHERDISABLINGIMPAIRMENTS")) ;823588103
declare pic_14 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC14MULTIPLETRAUMA")) ;823588053
declare pic_15 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC15DEVELOPMENTALDISABILITY")) ;823588113
declare pic_16 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC16DEBILITY")) ;823588123
declare pic_17 = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"PIC17MEDICALLYCOMPLEX")) ;823588133
declare pic_loss_cons_tbi = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"LOSSOFCONSCIOUSNESSATTIMEOFTBI")) ;1203489073
declare cir_refer_prov_ext = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"CIRREFERRINGPROVIDEREXTERNAL")) ;1055804747
declare cir_refer_prov_medstar = f8 with constant(uar_get_code_by("DISPLAYKEY",72,"REFERRINGPROVIDER")) ;823593887
declare hp_type_commercial = f8 with constant(uar_get_code_by("DISPLAYKEY",367,"COMMERCIAL")) ;681687.00
declare med_svc_rehabilitation = f8 with constant(uar_get_code_by("DISPLAYKEY",34,"REHABILITATION"))
 
declare admit_type_rehab = f8 with constant(5047218.00)
declare med_rehab = f8 with constant(313027.00)
declare admit_rehabilitation = f8 with constant(5047218.00);(uar_get_code_by("DISPLAYKEY",3,"REHABILITATION"))
 
;007 new
declare admission_liaison_cd = f8 with public,constant( 2211266825.00)
declare admission_rep_cd = f8 with public,constant( 2211268091.00)
;007 end new
 
declare nx = i4 with noconstant(0)
declare ndx = i4 with noconstant(0)
declare POS = i4 with noconstant(0)
declare nx2 = i4 with noconstant(0) ;006 - added
declare ndx2 = i4 with noconstant(0) ;006 - added
 
/******************************************\
 *			Patient Population			  *
\******************************************/
IF($FACILITY = fac_nrh)
SELECT INTO "NL:"
FROM	ENCOUNTER	E
	,  (LEFT JOIN ENCNTR_ALIAS	FIN
		ON(FIN.ENCNTR_ID = E.ENCNTR_ID
		AND FIN.ENCNTR_ALIAS_TYPE_CD = var_fin
		AND FIN.ACTIVE_IND = 1))
	,  (LEFT JOIN ENCNTR_ALIAS	MRN
		ON(MRN.ENCNTR_ID = E.ENCNTR_ID
		AND MRN.ENCNTR_ALIAS_TYPE_CD = var_mrn))
	,	PERSON	PE
 
PLAN E WHERE E.DISCH_DT_TM BETWEEN cnvtdatetime($STARTDATE) and cnvtdatetime($ENDDATE)
	and E.REG_DT_TM < cnvtdatetime($ENDDATE)
	and E.ENCNTR_TYPE_CD IN (encntr_type_inpt, encntr_type_nrh_loa)
	and E.LOC_FACILITY_CD = var_facility
JOIN FIN
JOIN MRN
JOIN PE WHERE PE.PERSON_ID = E.PERSON_ID
	and PE.ACTIVE_IND = 1
ORDER BY E.ENCNTR_ID
head report
	cnt = 0
head e.encntr_id
	bd_ind = 0
 	cnt = cnt + 1
	if(mod(cnt,100) = 1)
		stat = alterlist(disch->pts,cnt + 99)
	endif
 
	disch->pts[cnt].person = concat(trim(pe.name_last_key),", ",pe.name_first_key)
	disch->pts[cnt].person_id = pe.person_id
	disch->pts[cnt].encntr_id = e.encntr_id
	disch->pts[cnt].encntr_type = uar_get_code_display(e.encntr_type_cd)
	disch->pts[cnt].fin = fin.alias
	disch->pts[cnt].mrn = mrn.alias
	disch->pts[cnt].admit_dt_tm = e.reg_dt_tm
	disch->pts[cnt].disch_dt_tm = e.disch_dt_tm
	disch->pts[cnt].service = uar_get_code_display(e.med_service_cd)
	disch->pts[cnt].admit_dt_tm_disp = replace(replace(
									   build2(format(e.reg_dt_tm,"MM/DD/YY;;d")," ",format(e.reg_dt_tm,"hh:mm;;s")),
									   "am", "AM"), "pm", "PM")
	disch->pts[cnt].disch_dt_tm_disp = replace(replace(
									   build2(format(e.disch_dt_tm,"MM/DD/YY;;d")," ",format(e.disch_dt_tm,"hh:mm;;s")),
									   "am", "AM"), "pm", "PM")
 
	if(e.loc_nurse_unit_cd > 0)
		disch->pts[cnt].unit_room = trim(uar_get_code_display(e.loc_nurse_unit_cd))
		if(e.loc_room_cd > 0)
			disch->pts[cnt].unit_room = concat(disch->pts[cnt].unit_room," ",trim(uar_get_code_display(e.loc_room_cd)))
			if(e.loc_bed_cd > 0)
				disch->pts[cnt].unit_room = concat(disch->pts[cnt].unit_room,"-",trim(uar_get_code_display(e.loc_bed_cd)))
			endif
		else
			if(e.loc_bed_cd > 0)
				disch->pts[cnt].unit_room = concat(disch->pts[cnt].unit_room," ",trim(uar_get_code_display(e.loc_bed_cd)))
			endif
		endif
	endif
 
	disch->pts[cnt].disposition = trim(uar_get_code_display(e.disch_disposition_cd)) ;006 - added
 
foot report
	stat = alterlist(disch->pts,cnt)
WITH NOCOUNTER, time = 1000
 
else ;Non-NRH pts
SELECT INTO "NL:"
FROM	ENCOUNTER	E
	,  (LEFT JOIN ENCNTR_ALIAS	FIN
		ON(FIN.ENCNTR_ID = E.ENCNTR_ID
		AND FIN.ENCNTR_ALIAS_TYPE_CD = var_fin
		AND FIN.ACTIVE_IND = 1))
	,  (LEFT JOIN ENCNTR_ALIAS	MRN
		ON(MRN.ENCNTR_ID = E.ENCNTR_ID
		AND MRN.ENCNTR_ALIAS_TYPE_CD = var_mrn))
	,	PERSON	PE
 
PLAN E WHERE E.DISCH_DT_TM BETWEEN cnvtdatetime($STARTDATE) and cnvtdatetime($ENDDATE)
	and E.REG_DT_TM < cnvtdatetime($ENDDATE)
	and E.ENCNTR_TYPE_CD IN(309308.00,
							309310.00,
							309312.00,
							5048231.00,
							607970233.00,
							607970285.00,
							607970245.00,
							0.00)
	and E.LOC_FACILITY_CD = var_facility
	and E.ADMIT_TYPE_CD = admit_rehabilitation
	and E.MED_SERVICE_CD = med_svc_rehabilitation
JOIN FIN
JOIN MRN
JOIN PE WHERE PE.PERSON_ID = E.PERSON_ID
	and PE.ACTIVE_IND = 1
ORDER BY E.ENCNTR_ID
head report
	cnt = 0
head e.encntr_id
	bd_ind = 0
 	cnt = cnt + 1
	if(mod(cnt,100) = 1)
		stat = alterlist(disch->pts,cnt + 99)
	endif
 
	disch->pts[cnt].person = concat(trim(pe.name_last_key),", ",pe.name_first_key)
	disch->pts[cnt].person_id = pe.person_id
	disch->pts[cnt].encntr_id = e.encntr_id
	disch->pts[cnt].encntr_type = uar_get_code_display(e.encntr_type_cd)
	disch->pts[cnt].fin = fin.alias
	disch->pts[cnt].mrn = mrn.alias
	disch->pts[cnt].admit_dt_tm = e.reg_dt_tm
	disch->pts[cnt].disch_dt_tm = e.disch_dt_tm
	disch->pts[cnt].service = uar_get_code_display(e.med_service_cd)
	disch->pts[cnt].admit_dt_tm_disp = replace(replace(
									   build2(format(e.reg_dt_tm,"MM/DD/YY;;d")," ",format(e.reg_dt_tm,"hh:mm;;s")),
									   "am", "AM"), "pm", "PM")
	disch->pts[cnt].disch_dt_tm_disp = replace(replace(
									   build2(format(e.disch_dt_tm,"MM/DD/YY;;d")," ",format(e.disch_dt_tm,"hh:mm;;s")),
									   "am", "AM"), "pm", "PM")
 
	if(e.loc_nurse_unit_cd > 0)
		disch->pts[cnt].unit_room = trim(uar_get_code_display(e.loc_nurse_unit_cd))
		if(e.loc_room_cd > 0)
			disch->pts[cnt].unit_room = concat(disch->pts[cnt].unit_room," ",trim(uar_get_code_display(e.loc_room_cd)))
			if(e.loc_bed_cd > 0)
				disch->pts[cnt].unit_room = concat(disch->pts[cnt].unit_room,"-",trim(uar_get_code_display(e.loc_bed_cd)))
			endif
		else
			if(e.loc_bed_cd > 0)
				disch->pts[cnt].unit_room = concat(disch->pts[cnt].unit_room," ",trim(uar_get_code_display(e.loc_bed_cd)))
			endif
		endif
	endif
 
	disch->pts[cnt].disposition = trim(uar_get_code_display(e.disch_disposition_cd)) ;006 - added
 
foot report
	stat = alterlist(disch->pts,cnt)
WITH NOCOUNTER
 
endif
 
if(size(disch->pts,5) < 1)
	GO TO EXIT_SCRIPT
endif
 
/******************************************\
 *  	  Personnel Relationship(s)	  	  *
\******************************************/
SELECT INTO "NL:"
FROM	ENCNTR_PRSNL_RELTN	EPR,
		PRSNL	PR
PLAN EPR WHERE EXPAND(ndx,1,size(disch->pts,5),epr.encntr_id,disch->pts[ndx].encntr_id)
	and EPR.ENCNTR_PRSNL_R_CD IN (phys_attending)
	and EPR.END_EFFECTIVE_DT_TM > cnvtdatetime(curdate, curtime3)
	and EPR.ACTIVE_IND = 1
JOIN PR WHERE PR.PERSON_ID = EPR.PRSNL_PERSON_ID
	and PR.ACTIVE_IND = 1
ORDER BY EPR.ENCNTR_ID,EPR.BEG_EFFECTIVE_DT_TM, EPR.PRSNL_PERSON_ID
head epr.encntr_id
	POS = locateval(nx,1,size(disch->pts,5),epr.encntr_id,disch->pts[nx].encntr_id)
	px = 0
detail
	px = px + 1
	if(px = 1)
		disch->pts[POS].phys_attending = concat(trim(pr.name_last_key),", ",trim(pr.name_first_key))
	else
		disch->pts[POS].phys_attending =
						concat(disch->pts[POS].phys_attending,"; ",trim(pr.name_last_key),", ",trim(pr.name_first_key))
	endif
WITH EXPAND = 1
 
/******************************************\
 *  	Health Insurance Plan(s)	  	  *
\******************************************/
declare var_name_comm = vc with noconstant("")
SELECT INTO "NL:"
FROM	ENCOUNTER	E,
		ENCNTR_PLAN_RELTN	EPR,
		HEALTH_PLAN	HP,
		ORG_PLAN_RELTN   O,
		ORGANIZATION   ORG
PLAN E WHERE EXPAND(ndx,1,size(disch->pts,5),e.encntr_id,disch->pts[ndx].encntr_id)
JOIN EPR WHERE EPR.ENCNTR_ID = E.ENCNTR_ID
	and EPR.END_EFFECTIVE_DT_TM > E.REG_DT_TM
	and EPR.ACTIVE_IND = 1
JOIN HP WHERE HP.HEALTH_PLAN_ID = EPR.HEALTH_PLAN_ID
	and HP.ACTIVE_IND = 1
	and HP.END_EFFECTIVE_DT_TM > CNVTDATETIME(CURDATE, CURTIME3)
JOIN O WHERE O.HEALTH_PLAN_ID = HP.HEALTH_PLAN_ID
	and O.ORG_PLAN_RELTN_CD = 1200.00
	and O.ACTIVE_IND = 1
	and O.END_EFFECTIVE_DT_TM > CNVTDATETIME(CURDATE, CURTIME3)
JOIN ORG WHERE ORG.ORGANIZATION_ID = O.ORGANIZATION_ID
	and ORG.ACTIVE_IND = 1
	and ORG.END_EFFECTIVE_DT_TM > CNVTDATETIME(CURDATE, CURTIME3)
ORDER BY E.ENCNTR_ID, EPR.PRIORITY_SEQ
 
head e.encntr_id
	POS = locateval(nx,1,size(disch->pts,5),e.encntr_id,disch->pts[nx].encntr_id)
head epr.priority_seq
	var_name_comm = ""
	;var_name_comm = cnvtupper(hp.plan_name)
	var_name_comm = org.org_name
	if (epr.priority_seq = 1)
		disch->pts[POS]->ins_primary = var_name_comm
	elseif (epr.priority_seq = 2)
		disch->pts[POS]->ins_secondary = var_name_comm
	elseif (epr.priority_seq = 3)
		disch->pts[POS]->ins_tertiary = var_name_comm
	endif
WITH EXPAND = 1
 
 
 
;003 - added this section to add pt home phone number
/******************************************\
 *  	Patient Home Phone #  	  *
\******************************************/
 
SELECT INTO "NL:"
FROM	ENCOUNTER	E,
		PHONE PH
PLAN E WHERE EXPAND(ndx,1,size(disch->pts,5),e.encntr_id,disch->pts[ndx].encntr_id)
JOIN PH WHERE PH.PARENT_ENTITY_ID = e.person_id
	AND PH.PARENT_ENTITY_NAME = "PERSON"
	and PH.phone_type_cd = 170.00 ;home
	AND PH.ACTIVE_IND = 1
 
ORDER BY E.ENCNTR_ID
 
head e.encntr_id
	POS = locateval(nx,1,size(disch->pts,5),e.encntr_id,disch->pts[nx].encntr_id)
 
	disch->pts[POS]->pt_phone_home = trim(substring(1,25,ph.phone_num))
 
WITH EXPAND = 1
 
;call echojson (disch,$outdev)
;go to exit_script2
 
;003 - end section
 
/******************************************************\
 * 007 get cir admission Liaison & cir admission reg  *
\******************************************************/
 
 Select into "NL:"
 result = trim(ce.result_val)
 from (dummyt d with seq = size(disch->pts,5))
 , clinical_event ce
 plan d
 join ce
 where ce.encntr_id = disch->pts[d.seq].encntr_id
 and ce.event_cd in (admission_liaison_cd ,admission_rep_cd)
 and ce.result_status_cd in (23,25,35,34)
 and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime)
 order by d.seq,ce.event_end_dt_tm ;last one stored is most recent
 detail
 if(ce.event_cd = admission_liaison_cd)
 	disch->pts[d.seq].Admission_liaison  =result
 	else
 	disch->pts[d.seq].admission_rep =result
 	endif
with nocounter
;end 007
 
;006 - added section to add Discharge to Living Setting DTA
 
select into "nl:"
 
from
	encounter e
	,clinical_event ce
 
plan e
	where expand(ndx2,1,size(disch->pts,5),e.encntr_id,disch->pts[ndx2].encntr_id)
	and e.active_ind = 1
 
join ce
	where ce.encntr_id = e.encntr_id
	and ce.event_cd = 823528761.00 ;discharge to living setting
	and ce.result_status_cd in (25.00, 34.00, 35.00)
	and ce.valid_until_dt_tm > sysdate
 
ORDER BY E.ENCNTR_ID, ce.event_end_dt_tm desc
 
head e.encntr_id
 
	pos = locateval(nx2,1,size(disch->pts,5),e.encntr_id,disch->pts[nx2].encntr_id)
 
	disch->pts[pos]->disch_to_living = trim(substring(1,100,ce.result_val))
 
with nocounter, time = 600, expand = 1
 
;006 - end of added statement
 
 
 
#EXIT_SCRIPT
call echo(build("FILE NAME:", file_name))
 
if(DEBUG_IND = 1)
	for(x = 1 to size(disch->pts,5))
		call echo(build(disch->pts[X].person))
	endfor
endif
/******************************************\
 *  	       	   OUTPUT   	  	  	  *
\******************************************/
if(curqual > 0)
	call echo(build("[",value(size(disch->pts,5)),"] Discharges Returned"))
SELECT INTO $OUTDEV
	DCX = disch->pts[d1.seq].disch_dt_tm,
	PNX = disch->pts[d1.seq].person
FROM (DUMMYT D1 WITH SEQ = size(disch->pts,5))
ORDER BY DCX, PNX
head report
/*	col 0	"PATIENT_NAME"
	col 65	"MRN"
	col 75	"FIN"
	col 85	"UNIT_ROOM"
	col 105	"ATTENDING_PHYSICIAN"
	col 170	"PRIMARY_INSURANCE"
	col 205	"SECONDARY_INSURANCE"
	col 240	"TERTIARY_INSURANCE"
	col 275	"SERVICE"
	col 300	"DC_DATE_TIME"*/
 
	col 0  "PATIENT_NAME"
	col 65  "MRN"
	col 75  "FIN"
	col 85  "ENCNTR_TYPE"
	col 110  "UNIT_ROOM"
	col 130  "ATTENDING_PHYSICIAN"
	col 195  "ADMISSION_LIAISON" ;007 ADDED
	COL 260  "ADMISSION_REP";007 ADDED
	col 325  "PRIMARY_INSURANCE"
	col 360  "SECONDARY_INSURANCE"
	col 395  "TERTIARY_INSURANCE"
	col 430  "SERVICE"
	col 455	 "ADMIT_DATE_TIME" ;003 - added
	col 475  "DC_DATE_TIME" ;003 - changed from 325 to 345
	col 495	 "PATIENT_PHONE_NUMBER" ;003 - added
	col 520  "INVISION_DISPOSITION" ;006 - added
	col 580	 "DISCHARGE_TO_LIVING_SETTING" ;006 - added
	row + 1
detail
	f_patient_name = substring(1,65,disch->pts[d1.seq].person),
	f_mrn = substring(1,10,disch->pts[d1.seq].mrn),
	f_fin = substring(1,10,disch->pts[d1.seq].fin),
	f_encntr_type = substring(1,25,disch->pts[d1.seq].encntr_type),
	f_unit_room = substring(1,20,disch->pts[d1.seq].unit_room),
	f_attending_physician = substring(1,65,disch->pts[d1.seq].phys_attending),
	f_primary_insurance = substring(1,35,disch->pts[d1.seq].ins_primary),
	f_secondary_insurance = substring(1,35,disch->pts[d1.seq].ins_secondary),
	f_tertiary_insurance = substring(1,35,disch->pts[d1.seq].ins_tertiary),
	f_service = substring(1,25,disch->pts[d1.seq].service),
	f_admit_date_time = substring(1,20,disch->pts[d1.seq].admit_dt_tm_disp), ;003 - added
	f_dc_date_time = substring(1,20,disch->pts[d1.seq].disch_dt_tm_disp)
	f_pt_phone_home = substring(1,25,disch->pts[d1.seq].pt_phone_home)
	f_disposition = substring(1,50,disch->pts[d1.seq].disposition) ;006 - added
	f_disch_to_living = substring(1,100,disch->pts[d1.seq].disch_to_living) ;006 - added
	f_assigned_liaison = substring(1,65,disch->pts[d1.seq].admission_liaison) ;007 new
	f_assigned_rep =     SUBSTRING(1,65,disch->pts[D1.seq].admission_rep ) ;007 new
 
/*	col 0	f_patient_name
	col 65	f_mrn
	col 75	f_fin
	col 85	f_unit_room
	col 105	f_attending_physician
	col 170	f_primary_insurance
	col 205	f_secondary_insurance
	col 240	f_tertiary_insurance
	col 275	f_service
	col 300	f_dc_date_time*/
 
	col 0    f_patient_name
	col 65   f_mrn
	col 75   f_fin
	col 85   f_encntr_type
	col 110  f_unit_room
	col 130  f_attending_physician
	col 195  f_assigned_liaison;007 add
	col 260  f_assigned_rep;007 add
 
	col 325  f_primary_insurance
	col 360  f_secondary_insurance
	col 395  f_tertiary_insurance
	col 430  f_service
	col 455  f_admit_date_time ;003 - added
	col 475  f_dc_date_time ;003 - changed position from 325 to 345
	col 495  f_pt_phone_home ;003 - added
	col 520  f_disposition ;006 - added
	col 580  f_disch_to_living ;006 - added
 
 
;	col 195  f_primary_insurance
;	col 230  f_secondary_insurance
;	col 265  f_tertiary_insurance
;	col 300  f_service
;	col 325  f_admit_date_time ;003 - added
;	col 345  f_dc_date_time ;003 - changed position from 325 to 345
;	col 365  f_pt_phone_home ;003 - added
;	col 390  f_disposition ;006 - added
;	col 450  f_disch_to_living ;006 - added
	row + 1
foot report
	row + 2
	col 0	fx_name		row + 1
	col 0	fx_facility	row + 1
	col 0	fx_run_time	row + 1
	col 0	fx_date		row + 3			;small deviation from example, verify
	col 0 	"** End of Report **"
WITH FORMAT, SEPARATOR = " ", MAXCOL = 1000, MAXROW = 1000
 
else
	call echo("No qualifying data found")
SELECT INTO $OUTDEV
FROM (DUMMYT D1 WITH SEQ = 1)
PLAN D1
head report
	col 0  "PATIENT_NAME"
	col 65  "MRN"
	col 75  "FIN"
	col 85  "ENCNTR_TYPE"
	col 110  "UNIT_ROOM"
	col 130  "ATTENDING_PHYSICIAN"
	col 195  "PRIMARY_INSURANCE"
	col 230  "SECONDARY_INSURANCE"
	col 265  "TERTIARY_INSURANCE"
	col 300  "SERVICE"
	col 325  "DC_DATE_TIME"
	row + 3
	col 0 	"      *No qualifying data found"
foot report
	row + 2
	col 0	fx_name		row + 1
	col 0	fx_facility	row + 1
	col 0	fx_run_time	row + 1
	col 0	fx_date		row + 3
	col 0 	"** End of Report **"
WITH FORMAT, SEPARATOR = " ", MAXCOL = 1000, MAXROW = 1000
 
endif
 
/** DO NOT REMOVE *******************************/
SELECT INTO "NL:"
D1.SEQ
FROM DUMMYT D1
WITH FORMAT,SEPARATOR = " ",MAXCOL = 1000, MAXROW = 1000
/************************************************/
 
#exit_script2
 
end
go
;execute 13_cir_disch_by_date "MINE",4368977.00,"17-FEB-2020 00:00:00","18L-FEB-2020 00:00:00",0 go
