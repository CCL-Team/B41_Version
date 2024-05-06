/*************************************************************************
 Program Title: 
 
 Object name:   14_sbsm_magnet_adhoc
 Source file:   14_sbsm_magnet_adhoc.prg
 
 Purpose:       
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 03/26/2024 Michael Mayes        346801 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_sbsm_magnet_adhoc:dba go
create program 14_sbsm_magnet_adhoc:dba
 
prompt 
	"Output to File/Printer/MINE" = "MINE"

with OUTDEV

 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 per_id         = f8
        2 enc_id         = f8
        2 form_event_id  = f8 
                         
        2 pat_name        = vc
        2 dob             = dq8
        2 dob_txt         = vc
        2 mrn             = vc
        2 fin             = vc
        2 dos             = dq8
        2 dos_txt         = vc
        2 form_name       = vc
        2 res_pos_resp    = vc
        2 res_epds        = vc
        2 res_epds_pos    = vc
        2 res_epds_neg    = vc
        2 final_epds_txt  = vc
        2 res_cssrs       = vc
        2 res_cssrs_able  = vc
        2 final_cssrs_txt = vc
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'  ))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'    ))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED' ))

declare loc_cd             = f8  with protect,   constant(3338825195) ;MedStar WHC OB GYN Specialty Care

declare third_tri_form     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'SBSMTHIRDTRIMESTEROBBHFORM'      ))
declare post_part_form     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'SBSMPOSTPARTUMOBBHFORM'          ))
declare init_ob_form       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'SBSMINITIALOBBHFORM'             ))
                                                                                                                                 
                                                                                                                                 
declare pos_res_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'POSITIVERESPONSESREVIEWED'       ))
                                                                                                                                 
declare epds_score_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'EPDSSCORE'                       ))
declare epds_pos_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'DEPRESSIONSCREENINGPOSITIVE'     ))
declare epds_neg_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'DEPRESSIONSCREENINGNEGATIVE'     ))

declare cssrs_able_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'PTABLETOPARTICIPATEINCSSRSSCREEN'))
declare cssrs_score_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'CSSRSSCREENRISKLEVEL'            ))


;declare beg_dt_tm          = dq8 with protect,   constant(cnvtdatetime('01-APR-2020 00:00:00'))
;declare end_dt_tm          = dq8 with protect,   constant(cnvtdatetime('30-SEP-2022 23:59:59'))
declare beg_dt_tm          = dq8 with protect,   constant(cnvtdatetime('01-JUN-2021 00:00:00'))
declare end_dt_tm          = dq8 with protect,   constant(cnvtdatetime('31-AUG-2021 23:59:59'))


declare pos                = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('loc_cd        :', loc_cd        ))

call echo(build('third_tri_form:', third_tri_form))
call echo(build('post_part_form:', post_part_form))
call echo(build('init_ob_form  :', init_ob_form  ))

call echo(build('pos_res_cd    :', pos_res_cd    ))

call echo(build('epds_score_cd :', epds_score_cd ))
call echo(build('epds_pos_cd   :', epds_pos_cd   ))
call echo(build('epds_neg_cd   :', epds_neg_cd   ))

/**********************************************************************
DESCRIPTION: Gather form documentations 
      NOTES:  
***********************************************************************/
select into 'nl:'
  from clinical_event form
     , clinical_event sect
     , clinical_event res
     
     , encounter      e
     , person         p
     , encntr_alias   mrn
     , encntr_alias   fin
 
 where form.event_cd          in (third_tri_form, post_part_form, init_ob_form)
   and form.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
   and form.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
   and form.event_end_dt_tm between cnvtdatetime(beg_dt_tm) and cnvtdatetime(end_dt_tm)
   
   and sect.parent_event_id   = form.event_id
   and sect.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
   and sect.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
   
   and res.parent_event_id   = sect.event_id
   and res.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
   and res.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
   
   and e.encntr_id = form.encntr_id
   
   and p.person_id = form.person_id
   
   and mrn.encntr_id = e.encntr_id
   and mrn.encntr_alias_type_cd = 1079.00
   and mrn.active_ind = 1
   
   and fin.encntr_id = e.encntr_id
   and fin.encntr_alias_type_cd = 1077.00
   and fin.active_ind = 1

order by form.event_end_dt_tm, p.name_full_formatted, p.person_id

head p.person_id
    pos = data->cnt + 1
    data->cnt = pos
    
    stat = alterlist(data->qual, pos)
    
    data->qual[pos]->form_event_id = form.event_id
    
    data->qual[pos]->per_id        = p.person_id
    data->qual[pos]->enc_id        = e.encntr_id
                                   
    data->qual[pos]->pat_name      = trim(p.name_full_formatted, 3)
    data->qual[pos]->dob           = p.birth_dt_tm
    data->qual[pos]->dob_txt       = format(p.birth_dt_tm, '@SHORTDATE')
                                   
    data->qual[pos]->dos           = e.reg_dt_tm
    data->qual[pos]->dos_txt       = format(e.reg_dt_tm, '@SHORTDATE')
                                   
    data->qual[pos]->mrn           = cnvtalias(mrn.alias,mrn.alias_pool_cd)
    data->qual[pos]->fin           = cnvtalias(fin.alias,fin.alias_pool_cd)
                                   
    data->qual[pos]->form_name     = trim(uar_get_code_display(form.event_cd), 3)
    
detail
    case(res.event_cd)
    of pos_res_cd    : data->qual[pos]->res_pos_resp   = trim(res.result_val, 3)
    of epds_score_cd : data->qual[pos]->res_epds       = trim(res.result_val, 3)
    of epds_pos_cd   : data->qual[pos]->res_epds_pos   = trim(res.result_val, 3)
    of epds_neg_cd   : data->qual[pos]->res_epds_neg   = trim(res.result_val, 3)
    of cssrs_able_cd : data->qual[pos]->res_cssrs_able = trim(res.result_val, 3)
    of cssrs_score_cd: data->qual[pos]->res_cssrs      = trim(res.result_val, 3)
    endcase
    
with nocounter


for(looper = 1 to data->cnt)
    if(data->qual[looper]->res_epds > ' ')
        set data->qual[looper]->final_epds_txt = data->qual[looper]->res_epds
    endif
    
    if(data->qual[looper]->res_epds_pos > ' ')
        set data->qual[looper]->final_epds_txt = notrim(build2( data->qual[looper]->final_epds_txt, '; '
                                                              , data->qual[looper]->res_epds_pos
                                                              )
                                                       )
    endif
    
    if(data->qual[looper]->res_epds_neg > ' ')
        set data->qual[looper]->final_epds_txt = notrim(build2( data->qual[looper]->final_epds_txt, '; '
                                                              , data->qual[looper]->res_epds_neg
                                                              )
                                                       )
    endif
    
    if(data->qual[looper]->res_cssrs_able > ' ')
        set data->qual[looper]->final_cssrs_txt = data->qual[looper]->res_cssrs_able
    endif
    
    if(data->qual[looper]->res_cssrs > ' ')
        set data->qual[looper]->final_cssrs_txt = notrim(build2( data->qual[looper]->final_cssrs_txt, '; '
                                                               , data->qual[looper]->res_cssrs
                                                               )
                                                        )
    endif
    
endfor


 
;Presentation time
if (data->cnt > 0)
    
    select into $outdev
           PATIENT_NAME      = trim(substring(1, 100, data->qual[d.seq].pat_name       ))
         , DOB               = trim(substring(1,  15, data->qual[d.seq].dob_txt        ))
         , MRN               = trim(substring(1,  20, data->qual[d.seq].mrn            ))
         , FIN               = trim(substring(1,  20, data->qual[d.seq].fin            ))
         , DOS               = trim(substring(1,  15, data->qual[d.seq].dos_txt        ))
         , FORM              = trim(substring(1,  50, data->qual[d.seq].form_name      ))
         , POSITIVE_RESPONSE = trim(substring(1,  25, data->qual[d.seq].res_pos_resp   ))
         , EPDS_SCORE        = trim(substring(1,  25, data->qual[d.seq].final_epds_txt ))
         , CSSRS_SCREEN      = trim(substring(1,  25, data->qual[d.seq].final_cssrs_txt))

      from (dummyt d with SEQ = data->cnt)
    with format, separator = " ", time = 300

else
   select into $OUTDEV
     from dummyt
    detail
        row + 1
        col 1 "There were no results for your filter selections.."
        col 25
        row + 1
        col 1  "Please Try Your Search Again"
        row + 1
    with format, separator = " "
endif


 
 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script
;DEBUGGING
;call echorecord(data)

end
go
 
 

