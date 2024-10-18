/************************************************************************************************
 Program Name:		Medication Admin Extract
 Object Name:       0_MED_ADMIN_EXTRACT
 Source File:       0_MED_ADMIN_EXTRACT.prg
 Purpose:			Extract for Bonnie Levin/Jeff Janis
 Executed from:     Explorer Menu / OPS
 Programs Executed: N/A
 Special Notes:     This is for investigating COD vs COA
**************************************************************************************************
                                  MODIFICATION CONTROL LOG
**************************************************************************************************
 Mod  Date        Developer             OPAS/MCGA           Comment
 ---  ----------  --------------------  ------            	--------------------------------------
 000  01.24.2019  David T Smith		    MCGA 215242    		Initial Release
 001  10.14.2019  HPG					MCGA 217624			Modify Prompt to Include St. Mary's
 *********************************END OF ALL MODCONTROL BLOCKS*************************************/
drop program 0_MED_ADMIN_EXTRACT_NU go
create program 0_MED_ADMIN_EXTRACT_NU
 
prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Facility" = VALUE(0             )
	, "Nurse Unit" = VALUE(0             )
	, "Administrations From" = "SYSDATE"
	, "Administrations to" = "SYSDATE"
	, "Include Not Done/Not Given?" = 1 

with OUTDEV, FAC, NURSEUNIT, START_DT, END_DT, TYPE
;***************************************************************************************************
;                            	RECORD STRUCTURES
;***************************************************************************************************
free record admin
record admin (
		1 qual[*]
            2 fac = vc
            2 nurse_unit = vc
			2 admin_by = vc
			2 catalog_cd = f8
			2 event_type = vc
			2 catalog_desc = vc
			2 admin_id = f8
			2 reg_dt_tm = dq8
			2 pid = f8
			2 eid = f8
			2 FIN = vc
			2 pt_name = vc
			2 CDM = vc
			2 order_id = f8
			2 parent_order_id = f8
			2 bill_item_id = f8
			2 ndc = vc
			2 disp_line = vc
 
			)
            


;***************************************************************************************************
;                            	VARIABLE DECLARATIONS
;***************************************************************************************************
declare FIN_CD = f8 with noconstant(uar_get_code_by("DISPLAYKEY",319,"FINNBR"))


;***************************************************************************************************
;                            	Program Start
;***************************************************************************************************



;***************************************************************************************************
;                            	GET MEDICATION ADMINISTRATIONS
;***************************************************************************************************
if($TYPE=1);EXCLUDE NOT GIVEN/NOT DONE
	select into "nl:"
 
	 from med_admin_event mae
	      ,orders o
	      ,clinical_event ce
	      ,person p
	      ,encounter e
	      ,prsnl pr
	      ,encntr_alias ea
	      ,bill_item bi
 
	plan mae where mae.beg_dt_tm  between cnvtdatetime($START_DT)
									  and cnvtdatetime($END_DT)
		    and  mae.end_dt_tm between cnvtdatetime($START_DT)
									  and cnvtdatetime($END_DT)
		   	and mae.event_type_cd = 4055412.00  ;ADMINISTERED
 
	join ce where ce.event_id = mae.event_id
			and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
 
	join e where e.encntr_id = ce.encntr_id
			and (   (e.loc_facility_cd in ($FAC))
                 or (0 in ($FAC)
                     and e.loc_facility_cd in (   633867.00  ;Franklin Square
                                              ,  4363210.00  ;Georgetown     
                                              ,  4364516.00  ;NationalRehab  
                                              ,  4363156.00  ;Union          
                                              ,  4363216.00  ;WashingtonHosp 
                                              ,465209542.00  ;St. Mary's     
                                              ,446795444.00  ;Montgomery     
                                              ,  4363058.00  ;Harbor         
                                              ,  4362818.00  ;GoodSamHosp    
                                              ,465210143.00  ;Southern MD  
                                              )
                    )
                )
			and (   (e.loc_nurse_unit_cd in ($NURSEUNIT))
                 or (0 in ($NURSEUNIT))
                )
			and e.encntr_type_cd in(309310.00	;ED
								   ,309308.00	;IP
								   ,309312.00)	;OBS
 
	join o where o.order_id = mae.template_order_id
			and o.catalog_cd not in(8413250.00 		;NICOTINE PATCH REMOVAL
									,101977237.00	;LIDOCAINE PATCH REMOVAL
									,2778917.00)	;FLUSH AS NEEDED
 
 
	join p where p.person_id = o.person_id
 
	join pr where pr.person_id = ce.performed_prsnl_id
 
	join ea where ea.encntr_id = ce.encntr_id
	     and ea.encntr_alias_type_cd= FIN_CD
	     and ea.active_ind = 1
	     and ea.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
 
	join bi where bi.ext_parent_reference_id = o.catalog_cd
 
	order by mae.event_id
 
	Head Report
	admins = 0
 
	Head mae.event_id
	admins = admins + 1
	STAT=ALTERLIST(ADMIN->qual,ADMINS)
 
	ADMIN->QUAL[ADMINS].event_type = uar_get_code_display(mae.event_type_cd)
	ADMIN->QUAL[ADMINS].pt_name = p.name_full_formatted
	ADMIN->QUAL[ADMINS].pid = p.person_id
	ADMIN->QUAL[ADMINS].eid = ce.encntr_id
	ADMIN->QUAL[ADMINS].reg_dt_tm = mae.beg_dt_tm
	ADMIN->QUAL[ADMINS].admin_by = pr.name_full_formatted
	ADMIN->QUAL[ADMINS].admin_id = mae.event_id
	ADMIN->QUAL[ADMINS].catalog_cd = o.catalog_cd
	ADMIN->QUAL[ADMINS].catalog_desc = uar_get_code_display(o.catalog_cd)
	ADMIN->QUAL[ADMINS].FIN = CNVTALIAS(ea.alias, ea.alias_pool_cd)
	ADMIN->QUAL[ADMINS].ORDER_ID = o.order_id
	ADMIN->QUAL[ADMINS].PARENT_ORDER_ID = o.template_order_id
	ADMIN->QUAL[ADMINS].BILL_ITEM_ID = bi.bill_item_id
	ADMIN->QUAL[ADMINS].DISP_line = o.clinical_display_line
	
    ADMIN->QUAL[ADMINS].fac = uar_get_code_display(e.loc_facility_cd)
	ADMIN->QUAL[ADMINS].nurse_unit = uar_get_code_display(e.loc_nurse_unit_cd)
    
    
 
	with nocounter, time=1000
elseif($TYPE=2);EXCLUDE NOT GIVEN/NOT DONE
	select into "nl:"
 
	 from med_admin_event mae
	      ,clinical_event ce
	      ,orders o
	      ,person p
	      ,encounter e
	      ,prsnl pr
	      ,encntr_alias ea
	      ,bill_item bi
 
	plan mae where mae.beg_dt_tm  between cnvtdatetime($START_DT)
									  and cnvtdatetime($END_DT)
		       and  mae.end_dt_tm between cnvtdatetime($START_DT)
									  and cnvtdatetime($END_DT)
			   and mae.event_type_cd in(4055414.00	;NOT DONE
   									   ,4055415.00	;NOT GIVEN
   									   ,4055412.00)	;ADMINISTERED
 
	join ce where ce.event_id = mae.event_id
			and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
 
	join e where e.encntr_id = ce.encntr_id
			and (   (e.loc_facility_cd in ($FAC))
                 or (0 in ($FAC)
                     and e.loc_facility_cd in (   633867.00  ;Franklin Square
                                              ,  4363210.00  ;Georgetown     
                                              ,  4364516.00  ;NationalRehab  
                                              ,  4363156.00  ;Union          
                                              ,  4363216.00  ;WashingtonHosp 
                                              ,465209542.00  ;St. Mary's     
                                              ,446795444.00  ;Montgomery     
                                              ,  4363058.00  ;Harbor         
                                              ,  4362818.00  ;GoodSamHosp    
                                              ,465210143.00  ;Southern MD  
                                              )
                    )
                )
			and (   (e.loc_nurse_unit_cd in ($NURSEUNIT))
                 or (0 in ($NURSEUNIT))
                )
			and e.encntr_type_cd in(309310.00	;ED
								   ,309308.00	;IP
								   ,309312.00)	;OBS
 
	join o where o.order_id = mae.template_order_id
 
	join p where p.person_id = o.person_id
		and o.catalog_cd not in(8413250.00 		;NICOTINE PATCH REMOVAL
									,101977237.00	;LIDOCAINE PATCH REMOVAL
									,2778917.00)	;FLUSH AS NEEDED
 
 
 
	join pr where pr.person_id = ce.performed_prsnl_id
 
	join ea where ea.encntr_id = ce.encntr_id
	     and ea.encntr_alias_type_cd= FIN_CD
	     and ea.active_ind = 1
	     and ea.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
 
	join bi where bi.ext_parent_reference_id = o.catalog_cd
 
	order by mae.event_id
 
	Head Report
	admins = 0
 
	Head mae.event_id
	admins = admins + 1
	STAT=ALTERLIST(ADMIN->qual,ADMINS)
 
	ADMIN->QUAL[ADMINS].event_type = uar_get_code_display(mae.event_type_cd)
	ADMIN->QUAL[ADMINS].pt_name = p.name_full_formatted
	ADMIN->QUAL[ADMINS].pid = p.person_id
	ADMIN->QUAL[ADMINS].eid = ce.encntr_id
	ADMIN->QUAL[ADMINS].reg_dt_tm = mae.beg_dt_tm
	ADMIN->QUAL[ADMINS].admin_by = pr.name_full_formatted
	ADMIN->QUAL[ADMINS].admin_id = mae.event_id
	ADMIN->QUAL[ADMINS].catalog_cd = o.catalog_cd
	ADMIN->QUAL[ADMINS].catalog_desc = uar_get_code_display(o.catalog_cd)
	ADMIN->QUAL[ADMINS].FIN = CNVTALIAS(ea.alias, ea.alias_pool_cd)
	ADMIN->QUAL[ADMINS].ORDER_ID = o.order_id
	ADMIN->QUAL[ADMINS].PARENT_ORDER_ID = o.template_order_id
	ADMIN->QUAL[ADMINS].BILL_ITEM_ID = bi.bill_item_id
	ADMIN->QUAL[ADMINS].DISP_line = o.clinical_display_line
	
    ADMIN->QUAL[ADMINS].fac = uar_get_code_display(e.loc_facility_cd)
	ADMIN->QUAL[ADMINS].nurse_unit = uar_get_code_display(e.loc_nurse_unit_cd)
 
 
	with nocounter, time=1000
endif
;***************************************************************************************************
;                            	GET CDM
;***************************************************************************************************
Select into "nl:"
 
from (DUMMYT D1 with SEQ=SIZE(ADMIN->QUAL,5))
	 ,CHARGE C
	 ,INTERFACE_CHARGE IC
 
PLAN D1
where SIZE(ADMIN->QUAL,5) > 0
JOIN C WHERE C.order_id = ADMIN->QUAL[D1.SEQ].ORDER_ID
JOIN IC WHERE IC.charge_item_id = c.charge_item_id
 
Order by d1.seq
 
Head d1.seq
ADMIN->QUAL[D1.SEQ].CDM = ic.prim_cdm
ADMIN->QUAL[D1.SEQ].NDC = ic.ndc_ident
with nocounter, time=1000
;***************************************************************************************************
;                            	OUTPUTTING SPREADSHEET
;***************************************************************************************************
Select into $OUTDEV
 LOC                = trim(substring(1,100,ADMIN->QUAL[D1.SEQ].fac))
,NURSEUNIT          = trim(substring(1,100,ADMIN->QUAL[D1.SEQ].nurse_unit))
,FIN				= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].FIN))
,ENCOUNTER_ID       = ADMIN->QUAL[D1.seq].eid
,PATIENT_NAME		= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].PT_NAME))
,ADMIN_EVENT_TYPE 	= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].EVENT_TYPE))
,ADMIN_BY 			= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].admin_by))
,SERVICE_DATE		= trim(substring(1,100,format(ADMIN->QUAL[D1.SEQ].reg_dt_tm, "@SHORTDATETIME")))
,PRODUCT			= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].catalog_desc))
,CLINICAL_DISPLAY	= trim(substring(1,150,	ADMIN->QUAL[D1.SEQ].DISP_line))
,CDM				= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].CDM))
,CATALOG_CD 		= ADMIN->QUAL[D1.SEQ].catalog_cd
;,BILL_ITEM_ID		= ADMIN->QUAL[D1.SEQ].BILL_ITEM_ID
;,ORDER_ID 			= ADMIN->QUAL[D1.SEQ].ORDER_ID
;,PARENT_ORDER_ID    = ADMIN->QUAL[D1.SEQ].PARENT_ORDER_ID
,NDC_IDENTIFIER		= trim(substring(1,100,ADMIN->QUAL[D1.SEQ].NDC))
 
from (DUMMYT D1 with SEQ=SIZE(ADMIN->QUAL,5))
PLAN D1
where SIZE(ADMIN->QUAL,5) > 0
 
ORDER BY PATIENT_NAME,PRODUCT
 
with nocounter, time=1000, format, separator=" "
;***************************************************************************************************
;                            	END OF PROGRAM
;***************************************************************************************************
end
go
 

