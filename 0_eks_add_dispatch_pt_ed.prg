/*********************************************************************************************************************************
 Object name:       0_eks_add_dispatch_pt_ed
 Source file:       0_eks_add_dispatch_pt_ed.prg
 Purpose:			Automatically Adds Dispatch Health Patient Education
 Executed from:     Rule
 Programs Executed: N/A
 Special Notes:     MCGA 240642	
**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
 Mod  Date        Analyst               OPAS              	Comment
 ---  ----------  --------------------  ------            	----------------------------------------------------------------------
 001  10.17.2023  David Smith        	MCGA 240642			Initial Release
 002  12.27.2023  Michael Mayes         240477              Adding Spanish pat ed docs if patient primary language is Spanish.
*********************************END OF ALL MODCONTROL BLOCKS********************************************************************/
drop program 0_eks_add_dispatch_pt_ed go
create program 0_eks_add_dispatch_pt_ed

prompt 
	"Output Mode" = 0 

with oMode
/****************************************************************************************************
 					VARIABLE DECLARATIONS / RECORD STRUCTURE
*****************************************************************************************************/
set retval = -1	;initialize to failed
set log_message = " 0_eks_add_dispatch_pt_ed "
 
free record cust_request
record cust_request (
               1 encntr_id = f8
               1 person_id = f8
               1 sign_flag = i2
               1 pat_ed_suggested_ind = i2
               1 add_list[*]
                              2 relation_id = f8
                              2 blob = gvc
                              2 blob_length = i4
                              2 instruction_name = vc
                              2 pat_ed_domain_cd = f8
                              2 doc_lang_id_value = f8
                              2 key_doc_ident = vc
                              2 doc_types = vc
                              2 type_flag = i4 ;ks2488 5/18/2017
               1 update_list[*]
                              2 instruction_id = f8
                              2 relation_id = f8
                              2 blob = gvc
                              2 blob_length = i4
                              2 instruction_name = vc
                              2 pat_ed_domain_cd = f8
                              2 doc_lang_id_value = f8
                              2 key_doc_ident = vc
                              2 doc_types = vc
               1 delete_list[*]
                              2 instruction_id = f8
               1 event_id = f8
               1 no_upd_blob_ind = i2
               1 pat_ed_suggestion_ind = i2 ;ks2488 5/18/17
)
 
record  cust_reply
(
	1  qual [*]
		2  relation_id  =  f8
		2  instruction_id  =  f8
	1  status_data
		2  status  =  c1
		2  subeventstatus [*]
			3  operationname  =  c25
			3  operationstatus  =  c1
			3  targetobjectname  =  c25
			3  targetobjectvalue  =  vc
)
 
free record cust_request_fglb ;request structure for object fn_get_long_blob
record cust_request_fglb (
	1  parent_entity_name  =  vc
	1  content[*]
		2 parent_entity_id = f8
)
 
 
free record cust_reply_fglb ;reply structure for object fn_get_long_blob
record cust_reply_fglb (
	1  qual [*]
		2  long_blob_id  =  f8
		2  blob  =  vgc
		2  instruction_name  =  vc
		2  pat_ed_reltn_id  =  f8
		2  doctypes  =  vc
	1  status_data
		2  status  =  c1
		2  subeventstatus [*]
			3  operationname  =  c25
			3  operationstatus  =  c1
			3  targetobjectname  =  c25
			3  targetobjectvalue  =  vc
 
)
 
declare mf8_exitCareInpt = f8 with constant(uar_get_code_by("display",24849,"ExitCare Inpatient")),protect
 
;set request structure items
set cust_request->encntr_id = trigger_encntrid
set cust_request->person_id = trigger_personid
set cust_request->pat_ed_suggested_ind = 0
set cust_request_fglb->parent_entity_name = "PAT_ED_RELTN"


;002->
declare spanish_ind      = i2 with protect, noconstant(0)
declare pat_ed_reltn_key = vc with protect, noconstant('')


/**********************************************************************
DESCRIPTION: Check for Spanish as patient primary language
***********************************************************************/
select into 'nl:'

  from person p

 where p.person_id   = trigger_personid
   and p.active_ind  = 1
   and p.language_cd = 312741.00  ;Spanish, same in build and prod

detail
    spanish_ind = 1
    
with nocounter


call echo(build('spanish_ind:', spanish_ind))


/* This query was separated out below based on key.  Since they are the same besides that, and I'm adding a couple more
   keys, I'm going to consolidate a bit here by using and setting a variable.
*/


/****************************************************************************************************
 					DEFINE EDUCATION BASED ON oMODE PASSED
*****************************************************************************************************/
if($oMode = 1)
    if(spanish_ind = 0) set pat_ed_reltn_key = 'DISPATCHHEALTHEDTOHOMEDISCHARGEINSTRUCTIONS'
    else                set pat_ed_reltn_key = 'DISPATCHHEALTHEDBRIDGECAREDISCHARGEINSTRUCTIONSSPANISH'
    endif
    
elseif($oMode = 2)
    if(spanish_ind = 0) set pat_ed_reltn_key = 'DISPATCHHEALTHBRIDGECAREDISCHARGEINSTRUCTIONS'
    else                set pat_ed_reltn_key = 'DISPATCHHEALTHINPATIENTBRIDGECAREDISCHARGEINSTRUCTIONSSPANISH'     
    endif
    
else
	set log_message = concat("ERROR - No Education Option Passed from Rule")
	go to EXIT_PROGRAM

endif


call echo(build('pat_ed_reltn_key:', pat_ed_reltn_key))


;get parent_entity_id(s)
select into "nl:"
 
from pat_ed_reltn p
   , long_blob_reference lb

plan p where p.pat_ed_reltn_desc_key = pat_ed_reltn_key
        and p.pat_ed_domain_cd = mf8_exitCareInpt
        and p.active_ind = 1

join lb where lb.parent_entity_id = p.pat_ed_reltn_id
 
head report
    contentCnt = 0
detail
    contentCnt =  contentCnt + 1
    stat = alterlist(cust_request_fglb->content,contentCnt)
    cust_request_fglb->content[contentCnt].parent_entity_id = lb.parent_entity_id
with nocounter


call echorecord(cust_request_fglb)

;002<-

/****************************************************************************************************
 					GET BLOB DETAILS
*****************************************************************************************************/
execute fn_get_long_blob with replace("REQUEST","CUST_REQUEST_FGLB"),replace("REPLY","CUST_REPLY_FGLB")
 
set replySize = size(cust_reply_fglb,5)
set stat = alterlist(cust_request->add_list,replySize)
set cust_request->sign_flag = 1
set cust_request->event_id = 0
set cust_request->no_upd_blob_ind = 0
 
for(idx = 1 to replySize) 
	set cust_request->add_list[idx].doc_lang_id_value = 1
	set cust_request->add_list[idx].doc_types =  cust_reply_fglb->qual[idx].doctypes
	set cust_request->add_list[idx].instruction_name =  cust_reply_fglb->qual[idx].instruction_name
	set cust_request->add_list[idx].blob_length = size(cust_reply_fglb->qual[idx].blob)
	set cust_request->add_list[idx].relation_id = cust_reply_fglb->qual[idx].pat_ed_reltn_id
	set cust_request->add_list[idx].blob = cust_reply_fglb->qual[idx].blob
	set cust_request->add_list[idx].pat_ed_domain_cd = mf8_exitCareInpt
endfor

set stat = alterlist(cust_request->delete_list,0)
set stat = alterlist(cust_request->update_list,0)
/****************************************************************************************************
 					CHECK TO SEE IF VALID INSTRUCTION WAS LOADED
*****************************************************************************************************/
if(size(cust_request->add_list,5)= 0)
	set log_message = concat("ERROR - Check for Incorrect Display Key")
	go to EXIT_PROGRAM
endif
/****************************************************************************************************
 					CHECK IF EDUCATION ALREADY EXISTS FOR PATIENT
*****************************************************************************************************/
select into "nl:"
from pat_ed_document ped
	,pat_ed_doc_activity peda
plan ped
	where ped.encntr_id = cust_request->encntr_id
join peda
	where peda.pat_ed_doc_id = ped.pat_ed_document_id
		and peda.instruction_name = cust_reply_fglb->qual[1].instruction_name
with nocounter
 
;only add instructions if none exist
if(curqual = 0)
 
	execute fndis_add_upd_instruction with replace("REQUEST","CUST_REQUEST"),replace("REPLY","CUST_REPLY")
  
	if(cust_reply->status_data.status = "S")
		set retval = 100   ;if not found set to true 100
 
		set log_message = concat("Patient Education has been added for Encounter_ID ",trim(cnvtstring(cust_request->encntr_id)))
		set log_misc1 = concat("not available")
	else
		set retval = 100 ;if found set to true 100
		set log_message = concat("Patient Education not added Encounter_ID ",trim(cnvtstring(cust_request->encntr_id)))
	    set log_misc1 = cust_request->add_list.instruction_name
	endif
else
		set retval = 100   ;if not found set to true 100
 
		set log_message = concat("Patient Education not added for Encounter_ID ",trim(cnvtstring(cust_request->encntr_id)))
		set log_misc1 = concat("Instructions Already Exist")
 
endif
/****************************************************************************************************
 					RETURN CONTEXT VARS
*****************************************************************************************************/ 
#EXIT_PROGRAM
 
if(validate(link_template,0) = 0)
	set log_personid         =    trigger_personid
	set log_encntrid         =    trigger_encntrid
	set log_accessionid      =    trigger_accessionid
	set log_orderid          =    trigger_orderid 
else
	set log_accessionid      =    link_accessionid
	set log_orderid          =    link_orderid
	set log_encntrid         =    link_encntrid
	set log_personid         =    link_personid
	set log_taskassaycd      =    link_taskassaycd
	set log_clineventid      =    link_clineventid
endif
 
free record cust_request
/****************************************************************************************************
 					END OF PROGRAM
*****************************************************************************************************/ 
end go
 
 