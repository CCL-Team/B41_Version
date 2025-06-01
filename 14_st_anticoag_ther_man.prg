/*************************************************************************
 Program Title: Anticoagulation Therapy Managment ST

 Object name:   14_st_anticoag_ther_man
 Source file:   14_st_anticoag_ther_man.prg

 Purpose:

 Tables read:

 Executed from:

 Special Notes:

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA     Comment
--- ---------- -------------------- -------- -----------------------------
001 08/25/2022 Michael Mayes        231716   Initial release
002 05/12/2023 Michael Mayes        236841   Adding a new DTA Last Telehealth consent signed date
003 08/05/2023 Michael Mayes        PEND     Correcting DTA label.
004 08/24/2023 Michael Mayes        240182   SCTASK0041111 And they changed it again.
005 08/24/2023 Michael Mayes        239727   SCTASK0039988 Adding new DTA
006 09/06/2023 Michael Mayes                 Task Pending They changed the DTA Display and broke this.
007 09/19/2024 Swetha Srini         SCTASK0113179 Event Code Update from TYPEOFVISIT to VISITTYPEAMB
008 05/30/2025 Michael Mayes        353328   SCTASK0167092 - Now we don't want Telehealth date on here... go figure.
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_anticoag_ther_man:dba go
create program 14_st_anticoag_ther_man:dba

%i cust_script:0_rtf_template_format.inc

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/


free record data
record data(
    1 per_id         = f8
    1 enc_id         = f8
    1 form_dt        = dq8
    1 ac_phy         = vc
    1 ord_phy        = vc
    1 info_giv       = vc
    1 info_giv_oth   = vc
    1 visitType       = vc
    1 doac_ind       = vc
    1 ac_start       = vc
    1 anti_stop      = vc
    1 ac_dur         = vc
    1 doac_dab       = vc
    1 doac_api       = vc
    1 doac_edo       = vc
    1 doac_riv       = vc
    1 dose_change    = vc  ;005
    1 pat_oth_ac     = vc
    1 ac_thera_cd    = vc
    1 has_bled       = vc
    ;1 tot_child_pugh = vc
    1 pugh_score_grd = vc
    ;1 telehealth     = vc  ;002  ;008 We don't want it anymore.
)



record reply(
   1 text = vc
      1 status_data
         2 status = c1
         2 subeventstatus[1]
            3 OperationName = c25
            3 OperationStatus = c1
            3 TargetObjectName = c25
            3 TargetObjectValue = vc
)




/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header            = vc  with protect, noconstant('')
declare tmp_str           = vc  with protect, noconstant(' ')

declare rtf_head          = vc  with protect,   constant(notrim('\plain \f1 \fs20 \b \ul \cb2 \pard \sl0 '))
declare rtf_bold          = vc  with protect,   constant(notrim('\plain \f1 \fs18 \b \cb2 '))

declare act_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'    ))
declare mod_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'  ))
declare auth_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'      ))
declare altr_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'   ))

declare ac_phy_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ANTICOAGORDERINGPHYSICIAN'          ))
declare ord_phy_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ORDERINGPHYSICIANANTICOAG'          ))
declare info_by_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'INFORMATIONGIVENBY'                 ))
declare visitTypeCd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'VISITTYPEAMB'              ))
declare doac_ind_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'DOACINDICATION'                     ))
declare ac_start_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ANTICOAGSTART'                      ))
declare anti_stop_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ANTICIPATEDSTOPDATE'                ))
declare ac_dur_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ANTICOAGDURATION'                   ))
declare doac_dab_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'DOACDABIGATRAN'                     ))
declare doac_api_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'DOACAPIXABAN'                       ))
declare doac_edo_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'DOACEDOXABAN'                       ))
declare doac_riv_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'DOACRIVAROXABAN'                    ))
declare pat_oth_ac_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PATIENTONOTHERANTICOAGULANT'        ))
declare ac_thera_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ANTICOAGULATIONTHERAPY'             ))
declare has_bled_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HASBLEDSCORE'                       ))
declare tot_child_pugh_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'TOTALCHILDPUGHSCORE'                ))
declare pugh_score_grd_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'CHILDPUGHSCOREGRADE'                ))
;011 Don't want it anymore.
;;002->
;declare telehealth_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'LASTTELEHEALTHCONSENTDATE'))  ;006
;;002<-
;005->
declare dose_change_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'DOACDOSECHANGERECOMMENDED'))
;005<-

;debug
call echo(build('ac_phy_cd        :', ac_phy_cd        ))
call echo(build('ord_phy_cd       :', ord_phy_cd       ))
call echo(build('info_by_cd       :', info_by_cd       ))
;call echo(build('visitTypeCd      :', visitTypeCd      ))
call echo(build('doac_ind_cd      :', doac_ind_cd      ))
call echo(build('ac_start_cd      :', ac_start_cd      ))
call echo(build('anti_stop_cd     :', anti_stop_cd     ))
call echo(build('ac_dur_cd        :', ac_dur_cd        ))
call echo(build('doac_dab_cd      :', doac_dab_cd      ))
call echo(build('doac_api_cd      :', doac_api_cd      ))
call echo(build('doac_edo_cd      :', doac_edo_cd      ))
call echo(build('doac_riv_cd      :', doac_riv_cd      ))
call echo(build('dose_change_cd   :', dose_change_cd   ))  ;005
call echo(build('pat_oth_ac_cd    :', pat_oth_ac_cd    ))
call echo(build('ac_thera_cd      :', ac_thera_cd      ))
call echo(build('has_bled_cd      :', has_bled_cd      ))
call echo(build('tot_child_pugh_cd:', tot_child_pugh_cd))
call echo(build('pugh_score_grd_cd:', pugh_score_grd_cd))
;call echo(build('telehealth_cd    :', telehealth_cd    ))  ;008 we don't want.


set data->ac_phy         = ' '
set data->ord_phy        = ' '
set data->info_giv       = ' '
set data->visitType       = ' '
set data->doac_ind       = ' '
set data->ac_start       = ' '
set data->anti_stop      = ' '
set data->ac_dur         = ' '
set data->doac_dab       = ' '
set data->doac_api       = ' '
set data->doac_edo       = ' '
set data->doac_riv       = ' '
set data->pat_oth_ac     = ' '
set data->ac_thera_cd    = ' '
set data->has_bled       = ' '
set data->tot_child_pugh = ' '
;set data->telehealth     = ' ' ;008 We don't want it anymore.
set data->dose_change    = ' '  ;005  


/**************************************************************
; DVDev Start Coding
**************************************************************/


/***********************************************************************
DESCRIPTION:  Get Form Results
      NOTES:
***********************************************************************/
select into 'nl:'
  from dcp_forms_ref           dfr
     , dcp_forms_activity      dfa
     , dcp_forms_activity_comp dfac
     , clinical_event          ce   ;form
     , clinical_event          ce2  ;group
     , clinical_event          ce3  ;result
     , ce_date_result          cdr
     , ce_coded_result         ccr
     , ce_string_result        csr

 where dfr.description            =  'DOAC Therapy Management'
   and dfr.active_ind             =  1
   and dfr.beg_effective_dt_tm    <= cnvtdatetime(curdate, curtime3)
   and dfr.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)

   and dfa.dcp_forms_ref_id       =  dfr.dcp_forms_ref_id
   and dfa.encntr_id              =  e_id
   and dfa.form_status_cd         in (act_cd, mod_cd, auth_cd, altr_cd)

   and dfac.dcp_forms_activity_id =  dfa.dcp_forms_activity_id

   and ce.parent_event_id         =  dfac.parent_entity_id
   and ce.valid_until_dt_tm       >= cnvtdatetime(curdate, curtime3)
   and ce.result_status_cd        in (act_cd, mod_cd, auth_cd, altr_cd)

   and ce2.parent_event_id        =  ce.event_id
   and ce2.event_id               != ce2.parent_event_id
   and ce2.valid_until_dt_tm      >= cnvtdatetime(curdate, curtime3)
   and ce2.result_status_cd       in (act_cd, mod_cd, auth_cd, altr_cd)

   and ce3.parent_event_id        =  ce2.event_id
   and ce3.event_id               != ce3.parent_event_id
   and ce3.EVENT_TAG              !=  "In Error"
   and ce3.valid_until_dt_tm      >= cnvtdatetime(curdate, curtime3)
   and ce3.result_status_cd       in (act_cd, mod_cd, auth_cd, altr_cd)

   and cdr.event_id               =  outerjoin(ce3.event_id)

   and ccr.event_id               =  outerjoin(ce3.event_id)
   and ccr.valid_until_dt_tm      >= outerjoin(cnvtdatetime(curdate, curtime3))

   and csr.event_id               =  outerjoin(ce3.event_id)
   and csr.valid_until_dt_tm      >= outerjoin(cnvtdatetime(curdate, curtime3))

order by ce.encntr_id, dfa.form_dt_tm desc

head ce.encntr_id
    data->form_dt = dfa.form_dt_tm
    data->per_id  = ce3.person_id
    data->enc_id  = ce3.encntr_id

detail
    if(dfa.form_dt_tm = data->form_dt)
        case(ce3.event_cd)
        of ac_phy_cd        : data->ac_phy           = trim(ce3.result_val, 3)
        of ord_phy_cd       : data->ord_phy          = trim(ce3.result_val, 3)
        of visitTypeCd      : data->visitType         = trim(ce3.result_val, 3)
        of doac_ind_cd      : data->doac_ind         = trim(ce3.result_val, 3)
        of ac_start_cd      : data->ac_start         = format(cdr.result_dt_tm, "MM/DD/YYYY")
        of anti_stop_cd     : data->anti_stop        = format(cdr.result_dt_tm, "MM/DD/YYYY")
        of ac_dur_cd        : data->ac_dur           = trim(ce3.result_val, 3)
        of doac_dab_cd      : data->doac_dab         = trim(ce3.result_val, 3)
        of doac_api_cd      : data->doac_api         = trim(ce3.result_val, 3)
        of doac_edo_cd      : data->doac_edo         = trim(ce3.result_val, 3)
        of doac_riv_cd      : data->doac_riv         = trim(ce3.result_val, 3)
        of dose_change_cd   : data->dose_change      = trim(ce3.result_val, 3)
        of pat_oth_ac_cd    : data->pat_oth_ac       = trim(ce3.result_val, 3)
        of ac_thera_cd      : data->ac_thera_cd      = trim(ce3.result_val, 3)
        of has_bled_cd      : data->has_bled         = trim(ce3.result_val, 3)
        ;of tot_child_pugh_cd: data->tot_child_pugh   = trim(ce3.result_val, 3)
        of pugh_score_grd_cd: data->pugh_score_grd   = trim(ce3.result_val, 3)
        ;008 Removing
        ;of telehealth_cd    : data->telehealth       = format(cdr.result_dt_tm, "MM/DD/YYYY")

        ;Multiselect dudes
        of info_by_cd:
            call echo(ce3.event_id)

            if(data->info_giv = '') data->info_giv   = trim(ccr.descriptor, 3)
            else                    data->info_giv   = concat(data->info_giv, '; ', trim(ccr.descriptor, 3))
            endif

            ;We want to grab this if it exists.  Concat at the end.
            if(csr.string_result_text > ' ')
                if(data->info_giv_oth = '') data->info_giv_oth = trim(csr.string_result_text, 3)
                endif
            endif

        endcase

    endif

with nocounter, uar_code(UAR_GET_DISPLAYKEY, d)

;quick checks for the other... need to concat if it is populated.
if(data->info_giv_oth > ' ') set data->info_giv = concat(data->info_giv, '; ', data->info_giv_oth)
endif

;Presentation

;RTF header
set header = notrim(build2(rhead, wr))

if(data->enc_id > 0)

    set header = notrim(build2(rhead, rtf_head))

    set tmp_str = notrim(build2(         rtf_bold, "Order Physician Anticoag:   "      , wr, data->ac_phy        , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Anticoag Ordering Physician:   "   , wr, data->ord_phy       , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Information Given by:   "          , wr, data->info_giv      , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Visit Type AMB:   "                 , wr, data->visitType      , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Anticoag Indication:   "           , wr, data->doac_ind      , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Anticoag Start:   "                , wr, data->ac_start      , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Anticoag Anticipated Stop:   "     , wr, data->anti_stop     , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Anticoag Duration:   "             , wr, data->ac_dur        , reol))


    if(data->doac_dab > ' ')
        set tmp_str = notrim(build2(tmp_str, rtf_bold, "DOAC Agent:   "                , wr, 'Dabigatran ' , data->doac_dab, reol))
    endif

    if(data->doac_api > ' ')
        set tmp_str = notrim(build2(tmp_str, rtf_bold, "DOAC Agent:   "                , wr, 'Apixaban '   , data->doac_api, reol))
    endif

    if(data->doac_edo > ' ')
        set tmp_str = notrim(build2(tmp_str, rtf_bold, "DOAC Agent:   "                , wr, 'Edoxaban '   , data->doac_edo, reol))
    endif

    if(data->doac_riv > ' ')
        set tmp_str = notrim(build2(tmp_str, rtf_bold, "DOAC Agent:   "                , wr, 'Rivaroxaban ', data->doac_riv, reol))
    endif

    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Dose Change Recommended:   "       , wr, data->dose_change   , reol))  ;005

    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Patient on Other Anticoagulant:   ", wr, data->pat_oth_ac    , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "CHADS2VASC Score:   "              , wr, data->ac_thera_cd   , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "HAS-BLED Score:   "                , wr, data->has_bled      , reol))
    set tmp_str = notrim(build2(tmp_str, rtf_bold, "Child Pugh Grade:   "              , wr, data->pugh_score_grd, reol))
    ;008 We are removing this.
    ;;002->
    ;set tmp_str = notrim(build2(tmp_str, rtf_bold, "Last Telehealth Consent Date:   "  ;003 004
    ;                                             , wr, data->telehealth, reol))
    ;;002<-

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
