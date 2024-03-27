/*************************************************************************
 Program Title: Social Needs Social Det Last Year (Social Needs Screening Questionnaire)

 Object name:   14_st_soc_det_1y
 Source file:   14_st_soc_det_1y.prg

 Purpose:

 Tables read:

 Executed from:

 Special Notes: This is actually copied from 14_st_soc_determinants, however
                They want a 1 year lookback across encounters.  Historically
                this was a LCV on the current encounter.

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA     Comment
--- ---------- -------------------- -------- -----------------------------
001 04/27/2023 Michael Mayes        237787   Initial release
002 10/27/2023 Michael Mayes        237787   (SCTASK0053826)  Way after validation... changes from... validation.  Removing some
                                             DTAs and adding reference text.
003 11/30/2023 Michael Mayes        344864   (SCTASK0059070) Adding another form.
004 03/07/2024 Michael Mayes        237787   We don't want the header any more.
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_soc_det_1y:dba go
create program 14_st_soc_det_1y:dba

%i cust_script:0_rtf_template_format.inc

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/


free record data
record data(
    1 form_event_id         = f8
    1 form_dt               = vc
    1 dtas
        2 trigger           = vc
        2 basics            = vc
        2 food_run          = vc
        2 food_last         = vc
        2 unab_pay          = vc
        2 place_live        = vc
        2 trans             = vc
        2 job               = vc
        2 util              = vc
        2 soc_need_score    = vc
        2 soc_need_risk     = vc
        2 soc_need_com      = vc
        2 aunt_ref          = vc
        2 aunt_ref_event_id = f8
        2 aunt_ref_type     = vc
        2 aunt_ref_org      = vc
)


record reply(
   1 text                       = vc
      1 status_data
         2 status               = c1
         2 subeventstatus[1]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header          = vc  with protect, noconstant('')
declare tmp_str         = vc  with protect, noconstant('')

declare act_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'          ))
declare mod_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'        ))
declare auth_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'            ))
declare altr_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'         ))

declare grp_cd          = f8  with protect, noconstant(uar_get_code_by(   'MEANING',    53, 'GRP'             ))

declare trigger_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSTRIGGERQUESTION'         ))
declare basics_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSHARDTOPAYFORBASICS'      ))
declare food_run_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSWORRIEDFOODWOULDRUNOUT'  ))
declare food_last_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSFOODDIDNTLAST'           ))
declare unab_pay_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSUNABLETOPAYRENTMORTGAGE' ))
declare place_live_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSNOPLACETOLIVELIVEWFAM'   ))
declare trans_cd          = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSNOACCESSTOTRANSPORTATION'))
declare job_cd            = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSHARDTOGETKEEPJOB'        ))
declare util_cd           = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSTHREATSOFUTILITYSHUTOFFS'))
declare soc_need_score_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSASSESSMENTSCORE'         ))
declare soc_need_risk_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSRISKLEVEL'               ))
declare soc_need_com_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSCOMMENTS'                ))
declare aunt_ref_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSAUNTBERTHAREFERRAL'      ))
declare aunt_ref_type_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSAUNTBERTHAREFERRALTYPE'  ))
declare aunt_ref_org_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SOCIALNEEDSAUNTBERTHAREFERRALORG'   ))


/**************************************************************
; DVDev Start Coding
**************************************************************/



/***********************************************************************
DESCRIPTION:  Retrieve LCV form for the patient
       NOTE:  One way to do this would be to pull off the form requirement
              in the first place.  But... I just made the same mod for
              the 7_social_needs_scrn_rpt, and they _explicitly_ wanted
              to check for the forms involved.  So I'm just adding the new
              forms and testing... not going this route just because it
              is easier in this case.  They actually asked for it.s
***********************************************************************/
select into 'nl:'
  from dcp_forms_ref           dfr
     , dcp_forms_activity      dfa
     , dcp_forms_activity_comp dfac
     , clinical_event          ce
 
 where dfr.description            in ( 'Social Needs Screening Questionnaire'
                                     , 'Community Health Advocate Forms'
                                     , 'Supporting Families During COVID'
                                     , 'ED MVP Tracking Form'
                                     )
   and dfr.active_ind             =  1
   and dfr.beg_effective_dt_tm    <= cnvtdatetime(curdate, curtime3)
   and dfr.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)

   and dfa.dcp_forms_ref_id       =  dfr.dcp_forms_ref_id
   and dfa.form_status_cd         in (act_cd, mod_cd, auth_cd, altr_cd)
   and dfa.active_ind             =  1
   and dfa.person_id              =  p_id
   and dfa.form_dt_tm             >= cnvtlookbehind('1,Y')

   and dfac.dcp_forms_activity_id = dfa.dcp_forms_activity_id
   and dfac.component_cd          = 10891.00  

   and ce.parent_event_id         =  dfac.parent_entity_id
   and ce.event_id                =  ce.parent_event_id
   and ce.event_class_cd          =  grp_cd
   and ce.valid_until_dt_tm       >= cnvtdatetime(curdate, curtime3)

order by ce.person_id, dfa.form_dt_tm desc
head ce.person_id

    data->form_event_id = ce.event_id

    data->form_dt       = format(dfa.form_dt_tm, 'MM/DD/YYYY')

with nocounter


/**********************************************************************
DESCRIPTION:  Find form data for the patient
***********************************************************************/
select into 'nl:'
  from clinical_event  ce2     ;group
     , clinical_event  ce3     ;result
     , ce_coded_result ccr
     
 where ce2.parent_event_id    =  data->form_event_id
   and ce2.event_id           != ce2.parent_event_id
   and ce2.valid_until_dt_tm  >= cnvtdatetime(curdate,curtime3)
   and ce2.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)

   and ce3.parent_event_id    =  ce2.event_id
   and ce3.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
   and ce3.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
                              
   and ccr.event_id           =  outerjoin(ce3.event_id)
   and ccr.valid_until_dt_tm  >  outerjoin(cnvtdatetime(curdate,curtime3))
   
order by ce3.event_end_dt_tm desc, ccr.sequence_nbr
detail
    case(ce3.event_cd)
    of trigger_cd       : data->dtas->trigger        = trim(ce3.result_val, 3)
    of basics_cd        : data->dtas->basics         = trim(ce3.result_val, 3)
    of food_run_cd      : data->dtas->food_run       = trim(ce3.result_val, 3)
    of food_last_cd     : data->dtas->food_last      = trim(ce3.result_val, 3)
    of unab_pay_cd      : data->dtas->unab_pay       = trim(ce3.result_val, 3)
    of place_live_cd    : data->dtas->place_live     = trim(ce3.result_val, 3)
    of trans_cd         : data->dtas->trans          = trim(ce3.result_val, 3)
    of job_cd           : data->dtas->job            = trim(ce3.result_val, 3)
    of util_cd          : data->dtas->util           = trim(ce3.result_val, 3)
    of soc_need_score_cd: data->dtas->soc_need_score = trim(ce3.result_val, 3)
    of soc_need_risk_cd : data->dtas->soc_need_risk  = trim(ce3.result_val, 3)
    of soc_need_com_cd  : data->dtas->soc_need_com   = trim(ce3.result_val, 3)
    of aunt_ref_cd      : data->dtas->aunt_ref       = trim(ce3.result_val, 3)
    of aunt_ref_org_cd  : data->dtas->aunt_ref_org   = trim(ce3.result_val, 3)

    ;I think this is the only special one... it has a potential other field we need to grab, and a bunch of ce_text_results.
    of aunt_ref_type_cd : 
        data->dtas->aunt_ref_event_id = ce3.event_id
        
        if(data->dtas->aunt_ref_type = '')
            data->dtas->aunt_ref_type = trim(ccr.descriptor, 3)
        else                          
            data->dtas->aunt_ref_type = concat(data->dtas->aunt_ref_type, ', ', trim(ccr.descriptor, 3))
        endif
    
    endcase

with nocounter


if(data->dtas->aunt_ref_event_id > 0)
    
    /**********************************************************************
    DESCRIPTION:  Check for other: string result in aunt bertha ref type.
    ***********************************************************************/
    select into 'nl:'
      from ce_string_result csr
         
     where csr.event_id          =  data->dtas->aunt_ref_event_id
       and csr.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
     
    detail
            
        if(data->dtas->aunt_ref_type = '')
            data->dtas->aunt_ref_type = trim(csr.string_result_text, 3)
        else                          
            data->dtas->aunt_ref_type = concat(data->dtas->aunt_ref_type, ', ', trim(csr.string_result_text, 3))
        endif


    with nocounter
    
endif



;Presentation

;RTF header
set header = rhead

;004->
;set tmp_str = notrim(build2(rh2bu, "Social Determinants", wr, reol))
set tmp_str = wr
;004<-

if(data->form_event_id > 0)

    ;002 During validation they said they don't want this anymore.
    ;set tmp_str = notrim(build2(tmp_str, "Performed on: ", data->form_dt, reol))

    if(data->dtas->trigger        = 'No')  
        set tmp_str = notrim(build2(tmp_str, "Screening Question: "         , data->dtas->trigger            , reol))
    endif
    
    
    if(data->dtas->basics         = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "Hard to Pay for basics: "     , data->dtas->basics             , reol))
    endif
    
    if(data->dtas->food_run       = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "Worried Food would run out: " , data->dtas->food_run           , reol))
    endif
    
    if(data->dtas->food_last      = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "Food didn't last: "           , data->dtas->food_last          , reol))
    endif
    
    if(data->dtas->unab_pay       = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "Unable to pay rent/mortgage: ", data->dtas->unab_pay           , reol))
    endif
    
    if(data->dtas->place_live     = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "No place to live/live w fam: ", data->dtas->place_live         , reol))
    endif
    
    if(data->dtas->trans          = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "No access to transportation: ", data->dtas->trans              , reol))
    endif
    
    if(data->dtas->job            = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "Hard to get/keep job: "       , data->dtas->job                , reol))
    endif
    
    if(data->dtas->util           = 'Yes') 
        set tmp_str = notrim(build2(tmp_str, "Threats of utility shutoffs: ", data->dtas->util               , reol))
    endif
    
    
    ;002 During validation they said they don't want this anymore.
    ;if(data->dtas->soc_need_score > ' ')
    ;    set tmp_str = notrim(build2(tmp_str, "Assessment Score: "           , data->dtas->soc_need_score     , reol))
    ;endif    
    ;
    ;if(data->dtas->soc_need_risk  > ' ')
    ;    set tmp_str = notrim(build2(tmp_str, "Risk Level: "                 , data->dtas->soc_need_risk      , reol))
    ;endif   
    ;
    ;if(data->dtas->soc_need_com   > ' ')
    ;    set tmp_str = notrim(build2(tmp_str, "Comments: "                   , data->dtas->soc_need_com       , reol))
    ;endif    
    ;
    ;set tmp_str = notrim(build2(tmp_str                                                                      , reol))
    ;
    ;
    ;if(data->dtas->aunt_ref       > ' ')
    ;    set tmp_str = notrim(build2(tmp_str, "SDOH Referral: "              , data->dtas->aunt_ref           , reol))
    ;endif                                                                   
    ;                                                                        
    ;if(data->dtas->aunt_ref_type  > ' ')                                    
    ;    set tmp_str = notrim(build2(tmp_str, "SDOH Referral Type: "         , data->dtas->aunt_ref_type      , reol))
    ;endif                                                                   
    ;                                                                        
    ;if(data->dtas->aunt_ref_org   > ' ')                                    
    ;    set tmp_str = notrim(build2(tmp_str, "SDOH Referral Org: "          , data->dtas->aunt_ref_org       , reol))
    ;endif


    ;002 Adding this.
    set tmp_str = notrim(build2(tmp_str                                                                      , reol))
    set tmp_str = notrim(build2(tmp_str, 'My ability to evaluate or manage the patient during this ED visit '
                                       , 'was directly affected by the above determinant(s) of health.'      , reol
                               )
                        )
endif


call include_line(build2(header, tmp_str, RTFEOF))


;build reply text
for (cnt = 1 to drec->line_count)
    set  reply -> text  =  concat ( reply -> text, drec -> line_qual [ cnt ]-> disp_line )
endfor


set drec->status_data->status  = "S"
set reply->status_data->status = "S"


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


call echorecord(reply)
call echorecord(drec)

call echorecord(data)

call echo(reply->text)

end
go

