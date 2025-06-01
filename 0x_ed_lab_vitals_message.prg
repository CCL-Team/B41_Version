/*************************************************************************
 Program Title:   0x_ed_lab_vitals_message

 Object name:     0x_ed_lab_vitals_message
 Source file:     0x_ed_lab_vitals_message.prg

 Purpose:

 Tables read:

 Executed from:

 Special Notes:

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2025-02-12 Michael Mayes        351469 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 0x_ed_lab_vitals_message:dba go
create program 0x_ed_lab_vitals_message:dba


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare buildBody   (body_txt = vc (ref), tag = vc, style = vc, txt = vc) = null
declare buildTag    (tag = vc                     , style = vc, txt = vc) = vc
declare buildBullet (txt = vc)                                            = vc

/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
/*
record request(
    1 encntr_id   = f8
    1 person_id   = f8
    1 tracking_id = f8
)
*/

/*
free record reply
record reply(
    1 text  = vc
    1 format = i4
)
*/


free record pat_res_vit
record pat_res_vit(
    1 lab_ind           = i2
    1 vit_ind           = i2

    1 hema_ind          = i2
    1 hema_details
        2 result        = vc

    1 ele_creat_ind     = i2
    1 ele_creat_details
        2 result        = vc

    1 hypergly_ind      = i2
    1 hypergly_details
        2 result        = vc

    1 transamin_ind     = i2
    1 transamin_details
        2 result        = vc

    1 ele_tsh_ind       = i2
    1 ele_tsh_details
        2 result        = vc

    1 sup_inr_ind       = i2
    1 sup_inr_details
        2 result        = vc

    1 ele_bnp_ind       = i2
    1 ele_bnp_details
        2 result        = vc

    1 electro_ind       = i2
    1 electro_details
        2 result        = vc

    1 anemia_ind        = i2
    1 anemia_details
        2 result        = vc

    1 hr_ind            = i2
    1 hr_details
        2 high_low      = vc
        2 result        = vc

    1 dbp_ind           = i2
    1 dbp_details
        2 high_low      = vc
        2 result        = vc

    1 sbp_ind           = i2
    1 sbp_details
        2 high_low      = vc
        2 result        = vc

    1 o2_ind            = i2
    1 o2_details
        2 high_low      = vc
        2 result        = vc
)

/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare html_head   = vc with protect, constant('<html><body>')
declare html_body   = vc with protect, noconstant('')
declare html_foot   = vc with protect, constant('</body></html>')

declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'        ))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'      ))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'          ))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'       ))


;declare lab_uablood_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'UABLOOD'       ))
;declare lab_uablood2_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'UABLOOD'       ))
declare lab_uablood_cd     = f8  with protect,   constant(5091685.00)
declare lab_uablood2_cd    = f8  with protect,   constant(196547118.00)
declare lab_creat_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'CREATININE'    ))
declare lab_glu_bed        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'GLUCOSEBEDSIDE'))
declare lab_glu_ran        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'GLUCOSERANDOM '))
declare lab_alt_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ALT'           ))
declare lab_ast_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'AST'           ))
declare lab_tsh_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'TSH'           ))
declare lab_inr_cd         = f8  with protect,   constant(5103209.00)
declare lab_inr2_cd        = f8  with protect,   constant(823849493.00)
declare lab_bnp_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'BNP'           ))
declare lab_sodium_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'SODIUMLVL'     ))
declare lab_potass_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'POTASSIUMLVL'  ))
declare lab_calc_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'CALCIUMLVL'    ))
declare lab_magnes_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'MAGNESIUMLVL'  ))
declare lab_hgb_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HGB'))
declare lab_hct_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HCT'))
declare lab_rbc_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'RBC'))


/**************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('lab_uablood_cd :', lab_uablood_cd))
call echo(build('lab_uablood2_cd:', lab_uablood_cd))
call echo(build('lab_creat_cd   :', lab_creat_cd  ))
call echo(build('lab_glu_bed    :', lab_glu_bed   ))
call echo(build('lab_glu_ran    :', lab_glu_ran   ))
call echo(build('lab_alt_cd     :', lab_alt_cd    ))
call echo(build('lab_ast_cd     :', lab_ast_cd    ))
call echo(build('lab_tsh_cd     :', lab_tsh_cd    ))
call echo(build('lab_inr_cd     :', lab_inr_cd    ))
call echo(build('lab_inr2_cd    :', lab_inr2_cd   ))
call echo(build('lab_bnp_cd     :', lab_bnp_cd    ))
call echo(build('lab_sodoim_cd  :', lab_sodium_cd ))
call echo(build('lab_potass_cd  :', lab_potass_cd ))
call echo(build('lab_calc_cd    :', lab_calc_cd   ))
call echo(build('lab_magnes_cd  :', lab_magnes_cd ))
call echo(build('lab_hgb_cd     :', lab_hgb_cd    ))
call echo(build('lab_hct_cd     :', lab_hct_cd    ))
call echo(build('lab_rbc_cd     :', lab_rbc_cd    ))

/***********************************************************************
DESCRIPTION: Find LCV Results for the encounter
***********************************************************************/
select into 'nl:'

    result = if    (   ce.event_cd = lab_uablood_cd
                    or ce.event_cd = lab_uablood2_cd) 'HEMA'
             elseif(   ce.event_cd = lab_creat_cd   ) 'CREAT'
             elseif(   ce.event_cd = lab_glu_bed
                    or ce.event_cd = lab_glu_ran    ) 'GLU'
             elseif(   ce.event_cd = lab_alt_cd
                    or ce.event_cd = lab_ast_cd     ) 'TRANS'
             elseif(   ce.event_cd = lab_tsh_cd     ) 'TSH'
             elseif(   ce.event_cd = lab_inr_cd
                    or ce.event_cd = lab_inr2_cd    ) 'INR'
             elseif(   ce.event_cd = lab_bnp_cd     ) 'BNP'
             elseif(   ce.event_cd = lab_sodium_cd
                    or ce.event_cd = lab_potass_cd
                    or ce.event_cd = lab_calc_cd
                    or ce.event_cd = lab_magnes_cd  ) 'ELECTRO'
             elseif(   ce.event_cd = lab_hgb_cd    
                    or ce.event_cd = lab_hct_cd
                    or ce.event_cd = lab_magnes_cd  ) 'ANEMIA'
             endif
  from clinical_event ce
 where ce.encntr_id          =  request->encntr_id
   and ce.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
   and ce.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
   and ce.event_cd           in ( lab_uablood_cd
                                , lab_uablood2_cd
                                , lab_creat_cd
                                , lab_glu_bed
                                , lab_glu_ran
                                , lab_alt_cd
                                , lab_ast_cd
                                , lab_tsh_cd
                                , lab_inr_cd
                                , lab_inr2_cd
                                , lab_bnp_cd
                                , lab_sodium_cd
                                , lab_potass_cd
                                , lab_calc_cd
                                , lab_magnes_cd
                                , lab_hgb_cd
                                , lab_hct_cd
                                , lab_rbc_cd
                                )
   and ce.event_class_cd !=  226.00  ;GROUP
order by result, ce.event_end_dt_tm desc

head result

    if(ce.normalcy_cd != 214.00)   ;NORMAL

        pat_res_vit->lab_ind = 1

        case(result)

        of 'HEMA':
            pat_res_vit->hema_ind                  = 1
            pat_res_vit->hema_details->result      = trim(ce.result_val, 3)

        of 'CREAT':
            pat_res_vit->ele_creat_ind             = 1
            pat_res_vit->ele_creat_details->result = trim(ce.result_val, 3)

        of 'GLU':
            pat_res_vit->hypergly_ind              = 1
            pat_res_vit->hypergly_details->result  = trim(ce.result_val, 3)

        of 'TRANS':
            pat_res_vit->transamin_ind             = 1
            pat_res_vit->transamin_details->result = trim(ce.result_val, 3)

        of 'TSH':
            pat_res_vit->ele_tsh_ind               = 1
            pat_res_vit->ele_tsh_details->result   = trim(ce.result_val, 3)

        of 'INR':
            pat_res_vit->sup_inr_ind               = 1
            pat_res_vit->sup_inr_details->result   = trim(ce.result_val, 3)

        of 'BNP':
            pat_res_vit->ele_bnp_ind               = 1
            pat_res_vit->ele_bnp_details->result   = trim(ce.result_val, 3)

        of 'ELECTRO':
            pat_res_vit->electro_ind               = 1
            pat_res_vit->electro_details->result   = trim(ce.result_val, 3)
            
        of 'ANEMIA':
            ;They only want lows here
            if(ce.normalcy_cd in ( 209.00  ; EXTREMELOW
                                 , 211.00  ; LOW
                                 , 210.00  ; PANICLOW
                                 )
              )   
                pat_res_vit->anemia_ind                = 1
                pat_res_vit->anemia_details->result    = trim(ce.result_val, 3)
            endif
        endcase
    endif


with nocounter



/***********************************************************************
DESCRIPTION: Find LCV Results for the encounter
      NOTES: Because... readability I suppose... I'm doing these in a second
             query.
***********************************************************************/
select into 'nl:'
    result = if    (ce.event_cd in (     703550.00  ; APICALHEARTRATE
                                   ,  823719103.00  ; HRIABP
                                   ,    2700541.00  ; HEARTRATEMONITORED
                                   ,     703511.00  ; PERIPHERALPULSERATE
                                   , 3029434091.00  ; PERIPHERALPULSERATEREPEAT1
                                   , 3029446159.00  ; PERIPHERALPULSERATEREPEAT2
                                   )
                   )               'HR'
             elseif(ce.event_cd in (  102263267.00  ; ASSISTEDENDDIASTOLICPRESSUREDIP
                                   , 2805499813.00  ; BABYSCRIPTSDIASTOLICBP
                                   , 2268943195.00  ; DIASTOLICBPHOME
                                   , 4499431439.00  ; DIASTOLICBPTELEHEALTH
                                   ,  102224950.00  ; DIASTOLICBPAUTOMATED
                                   ,     703516.00  ; DIASTOLICBPMANUAL
                                   , 4117680683.00  ; DIASTOLICBPREPEAT
                                   , 3029451945.00  ; DIASTOLICBPREPEAT1
                                   , 3029450349.00  ; DIASTOLICBPREPEAT2
                                   , 3029450349.00  ; DIASTOLICBPREPEAT2
                                   ,  101724448.00  ; DIASTOLICBLOODPRESSURE
                                   , 1149558145.00  ; DIASTOLICBLOODPRESSUREALINE2
                                   , 1149558409.00  ; DIASTOLICBLOODPRESSUREALINE3
                                   ,  102250210.00  ; DIASTOLICBLOODPRESSUREDOPPLER
                                   ,  102257482.00  ; DIASTOLICBLOODPRESSUREWITHACTIVITY
                                   ,  102224874.00  ; DIASTOLICBLOODPRESSUREUAC
                                   ,  102263266.00  ; UNASSISTEDDIASTOLE
                                   , 1855256063.00  ; HOMEDIASTOLICBPREPEAT
                                   )
                   )               'DBP'
             elseif(ce.event_cd in (  102225188.00  ; ASSISTEDSYSTOLE
                                   , 2805499743.00  ; BABYSCRIPTSSYSTOLICBP
                                   , 2268908237.00  ; SYSTOLICBPHOME
                                   , 4499426903.00  ; SYSTOLICBPTELEHEALTH
                                   ,  102225120.00  ; SYSTOLICBPAUTOMATED
                                   ,     703501.00  ; SYSTOLICBPMANUAL
                                   , 4117688597.00  ; SYSTOLICBPREPEAT
                                   , 3029503857.00  ; SYSTOLICBPREPEAT1
                                   , 3029457129.00  ; SYSTOLICBPREPEAT2
                                   ,    2808512.00  ; SYSTOLICBLOODPRESSUREALINE1
                                   , 1149558107.00  ; SYSTOLICBLOODPRESSUREALINE2
                                   , 1149558365.00  ; SYSTOLICBLOODPRESSUREALINE3
                                   ,  101724444.00  ; SYSTOLICBLOODPRESSURE
                                   ,  102250207.00  ; SYSTOLICBLOODPRESSUREDOPPLER
                                   ,  102256973.00  ; SYSTOLICBLOODPRESSUREWITHACTIVITY
                                   ,  102225125.00  ; SYSTOLICBLOODPRESSUREUAC
                                   ,  102263263.00  ; UNASSISTEDSYSTOLE
                                   , 1855255549.00  ; HOMESYSTOLICBPREPEAT
                                   )
                   )               'SBP'
             elseif(ce.event_cd in (    3623994.00  ; SPO2
                                   )
                   )               'SPO2'
             endif

  from clinical_event ce

 where ce.encntr_id         =  request->encntr_id
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   and ce.event_cd          in (     703550.00  ; APICALHEARTRATE
                               ,  823719103.00  ; HRIABP
                               ,    2700541.00  ; HEARTRATEMONITORED
                               ,     703511.00  ; PERIPHERALPULSERATE
                               , 3029434091.00  ; PERIPHERALPULSERATEREPEAT1
                               , 3029446159.00  ; PERIPHERALPULSERATEREPEAT2

                               ,  102263267.00  ; ASSISTEDENDDIASTOLICPRESSUREDIP
                               , 2805499813.00  ; BABYSCRIPTSDIASTOLICBP
                               , 2268943195.00  ; DIASTOLICBPHOME
                               , 4499431439.00  ; DIASTOLICBPTELEHEALTH
                               ,  102224950.00  ; DIASTOLICBPAUTOMATED
                               ,     703516.00  ; DIASTOLICBPMANUAL
                               , 4117680683.00  ; DIASTOLICBPREPEAT
                               , 3029451945.00  ; DIASTOLICBPREPEAT1
                               , 3029450349.00  ; DIASTOLICBPREPEAT2
                               , 3029450349.00  ; DIASTOLICBPREPEAT2
                               ,  101724448.00  ; DIASTOLICBLOODPRESSURE
                               , 1149558145.00  ; DIASTOLICBLOODPRESSUREALINE2
                               , 1149558409.00  ; DIASTOLICBLOODPRESSUREALINE3
                               ,  102250210.00  ; DIASTOLICBLOODPRESSUREDOPPLER
                               ,  102257482.00  ; DIASTOLICBLOODPRESSUREWITHACTIVITY
                               ,  102224874.00  ; DIASTOLICBLOODPRESSUREUAC
                               ,  102263266.00  ; UNASSISTEDDIASTOLE
                               , 1855256063.00  ; HOMEDIASTOLICBPREPEAT

                               ,  102225188.00  ; ASSISTEDSYSTOLE
                               , 2805499743.00  ; BABYSCRIPTSSYSTOLICBP
                               , 2268908237.00  ; SYSTOLICBPHOME
                               , 4499426903.00  ; SYSTOLICBPTELEHEALTH
                               ,  102225120.00  ; SYSTOLICBPAUTOMATED
                               ,     703501.00  ; SYSTOLICBPMANUAL
                               , 4117688597.00  ; SYSTOLICBPREPEAT
                               , 3029503857.00  ; SYSTOLICBPREPEAT1
                               , 3029457129.00  ; SYSTOLICBPREPEAT2
                               ,    2808512.00  ; SYSTOLICBLOODPRESSUREALINE1
                               , 1149558107.00  ; SYSTOLICBLOODPRESSUREALINE2
                               , 1149558365.00  ; SYSTOLICBLOODPRESSUREALINE3
                               ,  101724444.00  ; SYSTOLICBLOODPRESSURE
                               ,  102250207.00  ; SYSTOLICBLOODPRESSUREDOPPLER
                               ,  102256973.00  ; SYSTOLICBLOODPRESSUREWITHACTIVITY
                               ,  102225125.00  ; SYSTOLICBLOODPRESSUREUAC
                               ,  102263263.00  ; UNASSISTEDSYSTOLE
                               , 1855255549.00  ; HOMESYSTOLICBPREPEAT

                               ,    3623994.00  ; SPO2
                               )
   and ce.event_class_cd    != 226.00   ;GROUP
order by result, ce.event_end_dt_tm desc

head result
    
    if(ce.normalcy_cd       != 214.00)   ;NORMAL
        pat_res_vit->vit_ind = 1

        case(result)
            of 'HR'  : pat_res_vit->hr_ind                = 1
                       pat_res_vit->hr_details->result    = trim(ce.result_val, 3)
                       pat_res_vit->hr_details->high_low  = trim(uar_get_code_description(ce.normalcy_cd))

            of 'DBP' : pat_res_vit->dbp_ind               = 1
                       pat_res_vit->dbp_details->result   = trim(ce.result_val, 3)
                       pat_res_vit->dbp_details->high_low = trim(uar_get_code_description(ce.normalcy_cd))

            of 'SBP' : pat_res_vit->sbp_ind               = 1
                       pat_res_vit->sbp_details->result   = trim(ce.result_val, 3)
                       pat_res_vit->sbp_details->high_low = trim(uar_get_code_description(ce.normalcy_cd))

            of 'SPO2': pat_res_vit->o2_ind                = 1
                       pat_res_vit->o2_details->result    = trim(ce.result_val, 3)
                       pat_res_vit->o2_details->high_low  = trim(uar_get_code_description(ce.normalcy_cd))

        endcase
    endif

with nocounter



;Presentation
declare temp_lab_foot = vc
if(    pat_res_vit->lab_ind = 0
   and pat_res_vit->vit_ind = 0)

    set reply->text = notrim(build2(html_head, html_foot))

else
    ; I can NOT get this to honor any styling... very annoying.
    if(pat_res_vit->lab_ind = 1)

        call buildBody(html_body, 'div', '', 'Your Lab Results Today showed evidence of:')

        if (pat_res_vit->hema_ind      = 1) call buildBody(html_body, 'div', '', buildBullet('Blood in your urine'        )) endif
        if (pat_res_vit->ele_creat_ind = 1) call buildBody(html_body, 'div', '', buildBullet('Abnormal kidney function'   )) endif
        if (pat_res_vit->hypergly_ind  = 1) call buildBody(html_body, 'div', '', buildBullet('High blood sugar'           )) endif
        if (pat_res_vit->transamin_ind = 1) call buildBody(html_body, 'div', '', buildBullet('Elevated liver enzymes'     )) endif
        if (pat_res_vit->ele_tsh_ind   = 1) call buildBody(html_body, 'div', '', buildBullet('Abnormal thyroid function'  )) endif
        if (pat_res_vit->sup_inr_ind   = 1)
            call buildBody(html_body, 'div', '', buildBullet(notrim(build2( 'Abnormal clotting function '
                                                                          , '(this may be related to medication you are taking)'
                                                                          )
                                                                   )
                                                            )
                          )
        endif
        if (pat_res_vit->ele_bnp_ind   = 1) call buildBody(html_body, 'div', '', buildBullet('Possible heart pumping dysfunction'))
        endif
        if (pat_res_vit->electro_ind   = 1) call buildBody(html_body, 'div', '', buildBullet('Abnormal electrolytes'       )) endif
        if (pat_res_vit->anemia_ind    = 1) call buildBody(html_body, 'div', '', buildBullet('Low blood counts (anemia)'   )) endif


        set temp_lab_foot = notrim('This may not be a serious problem but it is something that you should discuss with ')
        if(pat_res_vit->hema_ind = 1)
            set temp_lab_foot = notrim(build2(temp_lab_foot, 'either your primary care provider or with a Urologist.'))
        else
            set temp_lab_foot = notrim(build2(temp_lab_foot, 'your primary care provider.'))
        endif

        call buildBody(html_body, 'div', '', '&nbsp;')
        call buildBody(html_body, 'div', '', temp_lab_foot)

    endif

    if(pat_res_vit->vit_ind = 1)
        if(pat_res_vit->lab_ind = 1) call buildBody(html_body, 'div', '', '&nbsp;') endif

        call buildBody(html_body, 'div', 'margin-block-start: 1rem;', 'Your Vital signs Today showed evidence of:')

        if (pat_res_vit->hr_ind        = 1)
            call buildBody(html_body, 'div', '', buildBullet(notrim(build2( pat_res_vit->hr_details->high_low 
                                                                          , ' Heart Rate'
                                                                          )
                                                                   )
                                                            )
                          )
                                                            
        endif

        if (pat_res_vit->dbp_ind       = 1)
            call buildBody(html_body, 'div', '', buildBullet(notrim(build2(pat_res_vit->dbp_details->high_low
                                                                          , ' Diastolic Blood Pressure'
                                                                          )
                                                                   )
                                                            )
                          )
                                                            
        endif

        if (pat_res_vit->sbp_ind       = 1)
            call buildBody(html_body, 'div', '', buildBullet(notrim(build2(pat_res_vit->sbp_details->high_low
                                                                          , ' Systolic Blood Pressure'
                                                                          )
                                                                   )
                                                            )
                          )
                                                            
        endif

        if (pat_res_vit->o2_ind        = 1)
            call buildBody(html_body, 'div', '', buildBullet(notrim(build2(pat_res_vit->o2_details->high_low
                                                                          , ' SpO2'
                                                                          )
                                                                   )
                                                            )
                          )
        endif

        call buildBody(html_body, 'div', '', '&nbsp;')
        call buildBody(html_body, 'div', '', notrim(build2( 'This may not be a serious problem but it is something that you should'
                                                          , ' discuss with your primary care provider.'
                                                          )
                                                   )
                      )

    endif
    
    ;They don't want this anymore... PDF is still hosted... could remove it.
    ;call buildBody(html_body, 'div', '', '&nbsp;')
    ;call buildBody(html_body, 'div', '', notrim(build2( 'If you have difficulty connecting with your primary doctor after your '
    ;                                                  , 'emergency department visit and/or have any questions/ concerns '
    ;                                                  , 'regarding your results and next steps, you can always connect with a '
    ;                                                  , 'MedStar Health eVisit telehealth provider 24/7 by clicking '
    ;                                                  , '<a href='
    ;                                                  , '"https://www.medstarhealth.org/services/medstar-evisit-telehealth"'
    ;                                                  , '>here</a>'
    ;                                                  , ' or scan the QR code.'
    ;                                                  )
    ;                                           )
    ;              )
    ;;http://mhgrdceanp.cernerasp.com/mpage-content/tst41.mhgr_dc.cernerasp.com/custom_mpage_content/mpage_reference_files/EDVitalsLabsToken/qrCodeTeleHealth.png
    ;set html_body = notrim(build2(html_body, ^<img src='http://mhgrdceanp.cernerasp.com/mpage-content/tst41.mhgr_dc.cernerasp.com/^
    ;                                       ,  ^custom_mpage_content/mpage_reference_files/EDVitalsLabsToken/^
    ;                                       ,  ^qrCodeTeleHealth.png' ^
    ;                                       ,  ^style="display:block;margin-left:auto;margin-right:auto;text-align:center" />^
    ;                             )
    ;                      )
    

    set reply->text = notrim(build2(html_head, html_body, html_foot))
endif



set reply->format = 1
;set reply->text = ''  ;TODO Change this later


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
subroutine buildBody(body_txt, tag, style, txt)

    declare temp_txt = vc

    set temp_txt = buildTag(tag, style, txt)

    if(body_txt ='') set body_txt = temp_txt
    else             set body_txt = notrim(build2(body_txt, temp_txt))
    endif


end

subroutine buildTag (tag, style, txt)

    declare temp_txt = vc

    set temp_txt = notrim(build2('<', tag))

    if(style > ' ') set temp_txt = notrim(build2(temp_txt, ' style="', style, '"')) endif

    set temp_txt = notrim(build2(temp_txt, '>', txt, '</', tag, '>'))

    return(temp_txt)
end

subroutine buildBullet(txt)

    declare temp_txt = vc

    set temp_txt = notrim(build2('&nbsp;&nbsp;&nbsp;&#149; '))

    set temp_txt = notrim(build2(temp_txt, txt))

    return(temp_txt)
end



#exit_script

call echorecord(pat_res_vit)
call echorecord(reply)
call echo(reply->text)


if (pat_res_vit->hema_ind      = 1) call echo('hema_ind      found')     endif
if (pat_res_vit->ele_creat_ind = 1) call echo('ele_creat_ind found')     endif
if (pat_res_vit->hypergly_ind  = 1) call echo('hypergly_ind  found')     endif
if (pat_res_vit->transamin_ind = 1) call echo('transamin_ind found')     endif
if (pat_res_vit->ele_tsh_ind   = 1) call echo('ele_tsh_ind   found')     endif
if (pat_res_vit->sup_inr_ind   = 1) call echo('sup_inr_ind   found')     endif
if (pat_res_vit->ele_bnp_ind   = 1) call echo('ele_bnp_ind   found')     endif
if (pat_res_vit->electro_ind   = 1) call echo('electro_ind   found')     endif
if (pat_res_vit->anemia_ind    = 1) call echo('anemia_ind    found')     endif

if (pat_res_vit->hr_ind        = 1) call echo('hr_ind        found')     endif
if (pat_res_vit->dbp_ind       = 1) call echo('dbp_ind       found')     endif
if (pat_res_vit->sbp_ind       = 1) call echo('sbp_ind       found')     endif
if (pat_res_vit->o2_ind        = 1) call echo('o2_ind        found')     endif

if (pat_res_vit->hema_ind      = 0) call echo('hema_ind      not found') endif
if (pat_res_vit->ele_creat_ind = 0) call echo('ele_creat_ind not found') endif
if (pat_res_vit->hypergly_ind  = 0) call echo('hypergly_ind  not found') endif
if (pat_res_vit->transamin_ind = 0) call echo('transamin_ind not found') endif
if (pat_res_vit->ele_tsh_ind   = 0) call echo('ele_tsh_ind   not found') endif
if (pat_res_vit->sup_inr_ind   = 0) call echo('sup_inr_ind   not found') endif
if (pat_res_vit->ele_bnp_ind   = 0) call echo('ele_bnp_ind   not found') endif
if (pat_res_vit->electro_ind   = 0) call echo('electro_ind   not found') endif
if (pat_res_vit->anemia_ind    = 0) call echo('anemia_ind    not found') endif

if (pat_res_vit->hr_ind        = 0) call echo('hr_ind        not found') endif
if (pat_res_vit->dbp_ind       = 0) call echo('dbp_ind       not found') endif
if (pat_res_vit->sbp_ind       = 0) call echo('sbp_ind       not found') endif
if (pat_res_vit->o2_ind        = 0) call echo('o2_ind        not found') endif


end
go

