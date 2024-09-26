/*************************************************************************
 Program Title: Add IDHP Patient Education

 Object name:   0_eks_add_idhp_pat_edu
 Source file:   0_eks_add_idhp_pat_edu.prg

 Purpose:       Rule will use this to add a patient education handout
                upon creation of a DTA/CE for TYPE of visit.

                This DTA is currently on the:
                    Adult Amb Intake Form
                    Peds Amb Intake Form
                    Amb Vital Sign Form

                But they don't want this limited to these forms,
                but rather the DTA itself, in case it is added elsewhere

 Tables read:

 Executed from:

 Special Notes: The rule using this will be called 14_idhp_handout_pat_edu.

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
000 08/23/2022 Michael Mayes        234717 Initial Release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
  drop program 0_eks_add_idhp_pat_edu:dba go
create program 0_eks_add_idhp_pat_edu:dba


/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record cust_request
record cust_request(
    1 encntr_id             = f8
    1 person_id             = f8
    1 sign_flag             = i2
    1 pat_ed_suggested_ind  = i2
    1 add_list[*]
        2 relation_id       = f8
        2 blob              = gvc
        2 blob_length       = i4
        2 instruction_name  = vc
        2 pat_ed_domain_cd  = f8
        2 doc_lang_id_value = f8
        2 key_doc_ident     = vc
        2 doc_types         = vc
        2 type_flag         = i4
    1 update_list[*]
        2 instruction_id    = f8
        2 relation_id       = f8
        2 blob              = gvc
        2 blob_length       = i4
        2 instruction_name  = vc
        2 pat_ed_domain_cd  = f8
        2 doc_lang_id_value = f8
        2 key_doc_ident     = vc
        2 doc_types         = vc
    1 delete_list[*]
        2 instruction_id    = f8
    1 event_id              = f8
    1 no_upd_blob_ind       = i2
;   1 pat_ed_suggestion_ind = i2
)


record cust_reply(
    1  qual [*]
        2 relation_id           = f8
        2 instruction_id        = f8
    1  status_data
        2  status               = c1
        2  subeventstatus [*]
            3 operationname     = c25
            3 operationstatus   = c1
            3 targetobjectname  = c25
            3 targetobjectvalue = vc
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
        2  long_blob_id         = f8
        2  blob                 = vgc
        2  instruction_name     = vc
        2  pat_ed_reltn_id      = f8
        2  doctypes             = vc
    1  status_data
        2  status               = c1
        2  subeventstatus [*]
            3 operationname     = c25
            3 operationstatus   = c1
            3 targetobjectname  = c25
            3 targetobjectvalue = vc

)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare mvc_education_to_add    = vc  with protect, noconstant('IDHPMSHONLINESCHEDULINGTOOL')

/* I don't think we need this right now.
declare mf8_spanish_language_cd = f8  with protect, noconstant(uar_get_code_by("DISPLAYKEY",    36, "SPANISH"))
declare mf8_english_pt_educ_cd  = f8  with protect, noconstant(uar_get_code_by("DISPLAYKEY", 20600, "ENGLISH"))
declare mf8_spanish_pt_educ_cd  = f8  with protect, noconstant(uar_get_code_by("DISPLAYKEY", 20600, "SPANISH"))
declare mf8_spanish_doc_lang_id = f8  with protect, noconstant(cnvtreal(uar_get_definition(mf8_spanish_pt_educ_cd)))
*/

declare mf8_pt_doc_lang_id      = f8  with protect, noconstant(1)  ;Defaulting this to english... I think.

declare mi2_echo_level          = i2  with protect, noconstant(3)

declare mf8_exitCareInpt        = f8  with protect,   constant(uar_get_code_by("DISPLAY",24849,"ExitCare Inpatient"))


/*************************************************************
; DVDev Start Coding
**************************************************************/

set retval      = -1 ;initialize to failed
set log_message = " 0_eks_add_idhp_pat_edu failed during execution "


;set request structure items
IF(trigger_encntrid = 0)
    set cust_request->encntr_id = link_encntrid ; 00x SS updated trigger_encntrid to link_encntrid  - since we are dealing with AMB.
else
    set cust_request->encntr_id = trigger_encntrid
endif

set cust_request->person_id               = trigger_personid
set cust_request->pat_ed_suggested_ind    = 0
set cust_request_fglb->parent_entity_name = "PAT_ED_RELTN"


/* I don't think we need this right now.
; check the patient's preferred language
select p.language_cd
  from person p
 where p.person_id = trigger_personid

detail
    if(p.language_cd = mf8_spanish_language_cd )
        spanishFlag                  = 1
        mf8_pt_doc_lang_id           = 3.0
        mvc_education_to_add         = "MONOCLONALANTIBODYTHERAPEUTICSFAQSSPANISH"

    else
        vc_spanish_language_disp_key = ""
        mvc_education_to_add         = "FAQSFORCOVID19TREATMENTS"
        mf8_pt_doc_lang_id           = 1.0

    endif
with nocounter
*/

;get parent_entity_id(s)
select into "nl:"
  from pat_ed_reltn        p
     , long_blob_reference lb

  plan p
   where p.pat_ed_reltn_desc_key = mvc_education_to_add;"FAQSFORCOVID19TREATMENTS"
     and p.active_ind            = 1
     and p.pat_ed_domain_cd      = mf8_exitCareInpt

  join lb
   where lb.parent_entity_id = p.pat_ed_reltn_id

head report
    contentCnt = 0

detail
    contentCnt                                              = contentCnt + 1
    stat                                                    = alterlist(cust_request_fglb->content, contentCnt)
    cust_request_fglb->content[contentCnt].parent_entity_id = lb.parent_entity_id

with nocounter


execute fn_get_long_blob with replace("REQUEST", "CUST_REQUEST_FGLB"), replace("REPLY", "CUST_REPLY_FGLB")


set replySize = size(cust_reply_fglb,5)

set stat = alterlist(cust_request->add_list,replySize)


set cust_request->sign_flag       = 1
set cust_request->event_id        = 0
set cust_request->no_upd_blob_ind = 0


for(idx = 1 to replySize)
    set cust_request->add_list[idx].doc_lang_id_value = mf8_pt_doc_lang_id
    set cust_request->add_list[idx].doc_types         = cust_reply_fglb->qual[idx].doctypes
    set cust_request->add_list[idx].instruction_name  = cust_reply_fglb->qual[idx].instruction_name
    set cust_request->add_list[idx].blob_length       = size(cust_reply_fglb->qual[idx].blob)
    set cust_request->add_list[idx].relation_id       = cust_reply_fglb->qual[idx].pat_ed_reltn_id
    set cust_request->add_list[idx].blob              = cust_reply_fglb->qual[idx].blob
    set cust_request->add_list[idx].pat_ed_domain_cd  = mf8_exitCareInpt
endfor


set stat = alterlist(cust_request->delete_list,0)
set stat = alterlist(cust_request->update_list,0)


;check if education already exists for patient
select into "nl:"
  from pat_ed_document     ped
     , pat_ed_doc_activity peda

plan ped
    where ped.encntr_id        = cust_request->encntr_id

join peda
    where peda.pat_ed_doc_id   = ped.pat_ed_document_id
     and peda.instruction_name = cust_reply_fglb->qual[1].instruction_name

with nocounter


;only add instructions if none exist
if(curqual = 0)
    execute fndis_add_upd_instruction with replace("REQUEST","CUST_REQUEST"), replace("REPLY","CUST_REPLY")


    if(cust_reply->status_data.status = "S")
        set retval      = 100   ;if not found set to true 100
        set log_message = concat("Patient Education has been added for Encounter_ID ", trim(cnvtstring(cust_request->encntr_id)))
        set log_misc1   = concat("not available")

    else
        set retval      = 100 ;if found set to true 100
        set log_message = concat("Patient Education not added Encounter_ID "         , trim(cnvtstring(cust_request->encntr_id)))
        set log_misc1   = cust_request->add_list.instruction_name

    endif

else
        set retval      = 100   ;if not found set to true 100
        set log_message = concat("Patient Education not added for Encounter_ID "     , trim(cnvtstring(cust_request->encntr_id)))
        set log_misc1   = concat("Instructions Already Exist")

endif



/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script

call echorecord(cust_request     )
call echorecord(cust_reply       )
call echorecord(cust_request_fglb)
call echorecord(cust_reply_fglb  )


/*The following log values should be set by the program in the event
that the subsequent templates are used if eks_exec_ccl_l returns true.

Since the rule that calls this program has linked eks_exec_ccl_l the
else portion of the following statement will be executed.  The if portion
is provided as an example for setting the log values when the eks_exec_ccl_l
is not linked.
*/
if(validate(link_template, 0) = 0)
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

end go
