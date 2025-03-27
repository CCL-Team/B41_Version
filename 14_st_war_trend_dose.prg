drop program 14_st_war_trend_dose:dba go
create program 14_st_war_trend_dose:dba

/*************************************************************************
 Program Title:   Warfarin Trending and dosage tracking

 Object name:     14_st_war_trend_dose
 Source file:     14_st_war_trend_dose.prg

 Purpose:

 Tables read:

 Executed from:

 Special Notes:   N/A

***********************************************************************************************************************
                  MODIFICATION CONTROL LOG                  
***********************************************************************************************************************
Mod Date       Analyst              MCGA     Comment        
--- ---------- -------------------- -------- --------------------------------------------------------------------------
001 03/26/2019 Michael Mayes        214978   Initial release
002 12/17/2024 WXL168               347867   Change inr transcribed to inr
003 03/12/2025 Michael Mayes        PEND     Changes here broke the component... fixing.  Debating an INC... but this 
                                             pointed out that the comp would need adjustments too.

*************END OF ALL MODCONTROL BLOCKS* ***************************************************************************/

%i cust_script:0_rtf_template_format.inc

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/


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

record cells(
    1 cells[*]
        2 size = i4
)

record cells2(
    1 cells[*]
        2 size = i4
)

;if any changes to this RS are necessary, take a look at mp_st_war_trend_dose (and the frontend component) as well.
;probably should be in an include instead.
if(validate(dosing->cnt) = 0)
    record dosing(
        1 cnt      = i2
        1 qual [*]
            2 person_id    = f8
            2 event_id     = f8
            2 lcv_dt_tm    = dq8
            2 par_event_id = f8
            2 encntr_id    = f8
            2 date         = dq8
            2 date_str     = vc
            2 trans_inr    = vc
            2 dose_str     = vc
            2 dose_1_tab   = vc
            2 dose_2_tab   = vc
            2 sun_dose_str = vc
            2 sun_1_dose   = vc
            2 sun_2_dose   = vc
            2 mon_dose_str = vc
            2 mon_1_dose   = vc
            2 mon_2_dose   = vc
            2 tue_dose_str = vc
            2 tue_1_dose   = vc
            2 tue_2_dose   = vc
            2 wed_dose_str = vc
            2 wed_1_dose   = vc
            2 wed_2_dose   = vc
            2 thu_dose_str = vc
            2 thu_1_dose   = vc
            2 thu_2_dose   = vc
            2 fri_dose_str = vc
            2 fri_1_dose   = vc
            2 fri_2_dose   = vc
            2 sat_dose_str = vc
            2 sat_1_dose   = vc
            2 sat_2_dose   = vc
            2 com_event_id = f8
            2 comment_txt  = vc
            2 wk_dose      = f8
            2 wk_dose_str  = vc
            2 per_chng     = f8
            2 per_chng_str = vc
    )
endif

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare trend_row            (  title = vc, cells_rs = vc(ref), dosing_rs = vc(ref), row_num = i4) = vc
declare calc_dose            (result1 = vc,  result2 = vc     , dose1     = vc,      dose2   = vc) = vc
declare decode_dose          (  value = vc)                                                        = f8
declare trailing_zero_removal( result = f8)                                                        = vc

/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header         = vc  with protect, noconstant('')
declare tmp_str        = vc  with protect, noconstant('')
declare comment_str    = vc  with protect, noconstant(' ')
declare table_2_str    = vc  with protect, noconstant(' ')

declare act_cd         = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'ACTIVE'))
declare mod_cd         = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'MODIFIED'))
declare auth_cd        = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'AUTH'))
declare alt_cd         = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'ALTERED'))

declare dose_1_mg_cd   = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Tablet Dose'))
declare dose_2_mg_cd   = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Tablet Dose 2'))

declare dose_tot_wk_cd = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Total Weekly Dose'))

declare dose_1_sun_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Sunday Dose'))
declare dose_1_mon_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Monday Dose'))
declare dose_1_tue_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Tuesday Dose'))
declare dose_1_wed_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Wednesday Dose'))
declare dose_1_thu_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Thursday Dose'))
declare dose_1_fri_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Friday Dose'))
declare dose_1_sat_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Saturday Dose'))
declare dose_2_sun_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Sunday Dose 2'))
declare dose_2_mon_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Monday Dose 2'))
declare dose_2_tue_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Tuesday Dose 2'))
declare dose_2_wed_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Wednesday Dose 2'))
declare dose_2_thu_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Thursday Dose 2'))
declare dose_2_fri_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Friday Dose 2'))
declare dose_2_sat_cd  = f8  with protect, constant(uar_get_code_by('DESCRIPTION', 72, 'Saturday Dose 2'))

declare comment_cd     = f8  with protect, constant(uar_get_code_by( 'DISPLAYKEY', 72, 'ANTICOAGDOSINGCOMMENTS'))

declare compress_cd  = f8  with protect, constant(uar_get_code_by(     'MEANING', 120, 'OCFCOMP'))

declare lcv_dt_tm      = dq8 with protect

declare dosing_pos     = i4  with protect, noconstant(0)
declare idx            = i4  with protect, noconstant(0)


/***********************************************************************
DESCRIPTION: Find most recent results
***********************************************************************/
select into 'nl:'
  from clinical_event ce

 where ce.person_id         = p_id;39362402 ;
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   and ce.event_cd          in (  dose_tot_wk_cd,

                                  dose_1_mg_cd,
                                  dose_1_sun_cd, dose_1_mon_cd, dose_1_tue_cd,
                                  dose_1_wed_cd, dose_1_thu_cd, dose_1_fri_cd, dose_1_sat_cd,
                                  dose_2_mg_cd,
                                  dose_2_sun_cd, dose_2_mon_cd, dose_2_tue_cd,
                                  dose_2_wed_cd, dose_2_thu_cd, dose_2_fri_cd, dose_2_sat_cd,
                                  comment_cd
                               )
order by ce.event_end_dt_tm desc
head ce.event_end_dt_tm
    dosing_pos = locateval(idx, 1, size(dosing->qual, 5), ce.event_end_dt_tm, dosing->qual[idx]->lcv_dt_tm)

    if(dosing_pos = 0 and dosing->cnt < 10)
        dosing->cnt = dosing->cnt + 1

        stat = alterlist(dosing->qual, dosing->cnt)

        dosing_pos = dosing->cnt

        ;defaulting so I don't have to do it later.
        dosing->qual[dosing_pos]->trans_inr    = ' '
        dosing->qual[dosing_pos]->dose_str     = ' '

        dosing->qual[dosing_pos]->sun_dose_str = ' '
        dosing->qual[dosing_pos]->mon_dose_str = ' '
        dosing->qual[dosing_pos]->tue_dose_str = ' '
        dosing->qual[dosing_pos]->wed_dose_str = ' '
        dosing->qual[dosing_pos]->thu_dose_str = ' '
        dosing->qual[dosing_pos]->fri_dose_str = ' '

        dosing->qual[dosing_pos]->wk_dose_str  = ' '
        dosing->qual[dosing_pos]->per_chng_str = ' '

        dosing->qual[dosing_pos]->sun_1_dose   = ' '
        dosing->qual[dosing_pos]->mon_1_dose   = ' '
        dosing->qual[dosing_pos]->tue_1_dose   = ' '
        dosing->qual[dosing_pos]->wed_1_dose   = ' '
        dosing->qual[dosing_pos]->thu_1_dose   = ' '
        dosing->qual[dosing_pos]->fri_1_dose   = ' '
        dosing->qual[dosing_pos]->sat_1_dose   = ' '

        dosing->qual[dosing_pos]->sun_2_dose   = ' '
        dosing->qual[dosing_pos]->mon_2_dose   = ' '
        dosing->qual[dosing_pos]->tue_2_dose   = ' '
        dosing->qual[dosing_pos]->wed_2_dose   = ' '
        dosing->qual[dosing_pos]->thu_2_dose   = ' '
        dosing->qual[dosing_pos]->fri_2_dose   = ' '
        dosing->qual[dosing_pos]->sat_2_dose   = ' '

        dosing->qual[dosing_pos]->encntr_id    = ce.encntr_id
        dosing->qual[dosing_pos]->event_id     = ce.event_id
        dosing->qual[dosing_pos]->par_event_id = ce.parent_event_id
        dosing->qual[dosing_pos]->lcv_dt_tm    = ce.event_end_dt_tm
        dosing->qual[dosing_pos]->date         = ce.event_end_dt_tm
        dosing->qual[dosing_pos]->date_str     = format(ce.event_end_dt_tm, '@SHORTDATETIME')
        dosing->qual[dosing_pos]->person_id     = ce.PERSON_ID ;002
    endif
detail
    if(ce.event_end_dt_tm = dosing->qual[dosing_pos]->lcv_dt_tm
       and
       dosing_pos != 0)
        case(ce.event_cd)
        of dose_tot_wk_cd:
            dosing->qual[dosing_pos]->wk_dose     = cnvtreal(trim(ce.result_val, 3))
            dosing->qual[dosing_pos]->wk_dose_str = concat(trim(ce.result_val, 3), ' mg')

         ;of  5103209: dosing->qual[dosing_pos]->trans_inr    = trim(ce.result_val, 3);002

        of   dose_1_mg_cd: dosing->qual[dosing_pos]->dose_1_tab   = trim(ce.result_val, 3)
        of   dose_2_mg_cd: dosing->qual[dosing_pos]->dose_2_tab   = trim(ce.result_val, 3)

        of  dose_1_sun_cd: dosing->qual[dosing_pos]->sun_1_dose   = trim(ce.result_val, 3)
        of  dose_1_mon_cd: dosing->qual[dosing_pos]->mon_1_dose   = trim(ce.result_val, 3)
        of  dose_1_tue_cd: dosing->qual[dosing_pos]->tue_1_dose   = trim(ce.result_val, 3)
        of  dose_1_wed_cd: dosing->qual[dosing_pos]->wed_1_dose   = trim(ce.result_val, 3)
        of  dose_1_thu_cd: dosing->qual[dosing_pos]->thu_1_dose   = trim(ce.result_val, 3)
        of  dose_1_fri_cd: dosing->qual[dosing_pos]->fri_1_dose   = trim(ce.result_val, 3)
        of  dose_1_sat_cd: dosing->qual[dosing_pos]->sat_1_dose   = trim(ce.result_val, 3)

        of  dose_2_sun_cd: dosing->qual[dosing_pos]->sun_2_dose   = trim(ce.result_val, 3)
        of  dose_2_mon_cd: dosing->qual[dosing_pos]->mon_2_dose   = trim(ce.result_val, 3)
        of  dose_2_tue_cd: dosing->qual[dosing_pos]->tue_2_dose   = trim(ce.result_val, 3)
        of  dose_2_wed_cd: dosing->qual[dosing_pos]->wed_2_dose   = trim(ce.result_val, 3)
        of  dose_2_thu_cd: dosing->qual[dosing_pos]->thu_2_dose   = trim(ce.result_val, 3)
        of  dose_2_fri_cd: dosing->qual[dosing_pos]->fri_2_dose   = trim(ce.result_val, 3)
        of  dose_2_sat_cd: dosing->qual[dosing_pos]->sat_2_dose   = trim(ce.result_val, 3)

        of     comment_cd: dosing->qual[dosing_pos]->com_event_id = ce.event_id
        endcase

endif
with nocounter

/*************************************************************************
002 pull the inr and transcribed in
************************************************************************/
declare temp_event_id = f8



declare looper = i4 with noconstant(dosing->cnt)
while(looper > 0)
    select into "nl:"
        form =  dosing->qual[looper]->par_event_id
        ,dt= trim(format(ce3.event_end_dt_tm,'@SHORTDATE'))

    from
    clinical_event ce3

    where ce3.PERSON_ID =  dosing->qual[looper]->person_id
            and ce3.view_level        =  1
            and ce3.VALID_UNTIL_DT_TM >= cnvtdatetime(curdate,curtime3)
            AND ce3.EVENT_TAG         != "In Error"
            and ce3.event_cd          in ( 823772313.00
                                         , 5103209.00
                                         )
             AND CE3.EVENT_END_DT_TM    <= CNVTDATETIME(dosing->qual[looper]->lcv_dt_tm)
             and ce3.result_status_cd  in ( 23.00   ;Active
                                          , 34.00 ;Modified
                                          , 25.00 ;Auth (Verified)
                                          ,  35.00    ;Modified
                                          )

    order by form, ce3.EVENT_END_DT_TM desc

    head form

        if(ce3.event_id != temp_event_id)
            dosing->qual[looper]->trans_inr = concat(trim(ce3.result_val, 3), '   ',dt)
            ;build2(trim(ce3.result_val,3) ,"      " DT)
            temp_event_id = ce3.event_id
        endif
    WITH NOCOUNTER

    set looper = looper - 1

endwhile


/***********************************************************************
DESCRIPTION: Find comment blob if present
***********************************************************************/
select into 'nl:'
  from ce_blob cb
     , (dummyt d with seq = value(dosing->cnt))
  plan d
    where dosing->cnt                       >  0
      and dosing->qual[d.seq]->com_event_id >  0.0
  join cb
   where cb.event_id                        =  dosing->qual[d.seq]->com_event_id
detail
    ;Stealing this comment and code from my 14_amb_post_proc_phone, but the comment is still valid.
    ;Who knows if this blob uncompression works... my values don't look compressed so I used the simplest uncompress I could find
    ;I also don't know if RTF could be involved here... I doubt it, but since everyone else was doing it, I did too.
    uncomp_blob = notrim(fillstring(32767," "))
    final_blob  = notrim(fillstring(32767," "))

    if(cb.compression_cd = compress_cd)
        call uar_ocf_uncompress(cb.BLOB_CONTENTS, size(cb.BLOB_CONTENTS), uncomp_blob, size(uncomp_blob), 0)
    else
        uncomp_blob = substring(1, findstring("ocf_blob", cb.BLOB_CONTENTS) - 1, cb.BLOB_CONTENTS)
    endif

    ;strip any rtf
    if(substring(1, 5, uncomp_blob)= "{\rtf")
        call uar_rtf2(uncomp_blob, size(uncomp_blob), final_blob, size(final_blob), 0, 0)
    else
        final_blob = uncomp_blob
    endif

     dosing->qual[d.seq]->comment_txt = final_blob
with nocounter



for (looper = 1 to dosing->cnt)
    if(dosing->qual[looper]->dose_1_tab > ' ')
        set dosing->qual[looper]->dose_str = concat(dosing->qual[looper]->dose_1_tab, ' mg')

        if(dosing->qual[looper]->dose_2_tab > ' ')
            set dosing->qual[looper]->dose_str = concat(dosing->qual[looper]->dose_str, ' ',
                                                        dosing->qual[looper]->dose_2_tab, ' mg')
        endif
    else
        if(dosing->qual[looper]->dose_2_tab > ' ')
            set dosing->qual[looper]->dose_str = concat(dosing->qual[looper]->dose_2_tab, ' mg')
        endif
    endif

    set dosing->qual[looper]->sun_dose_str =
        calc_dose(dosing->qual[looper]->sun_1_dose, dosing->qual[looper]->sun_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)
    set dosing->qual[looper]->mon_dose_str =
        calc_dose(dosing->qual[looper]->mon_1_dose, dosing->qual[looper]->mon_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)
    set dosing->qual[looper]->tue_dose_str =
        calc_dose(dosing->qual[looper]->tue_1_dose, dosing->qual[looper]->tue_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)
    set dosing->qual[looper]->wed_dose_str =
        calc_dose(dosing->qual[looper]->wed_1_dose, dosing->qual[looper]->wed_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)
    set dosing->qual[looper]->thu_dose_str =
        calc_dose(dosing->qual[looper]->thu_1_dose, dosing->qual[looper]->thu_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)
    set dosing->qual[looper]->fri_dose_str =
        calc_dose(dosing->qual[looper]->fri_1_dose, dosing->qual[looper]->fri_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)
    set dosing->qual[looper]->sat_dose_str =
        calc_dose(dosing->qual[looper]->sat_1_dose, dosing->qual[looper]->sat_2_dose,
                  dosing->qual[looper]->dose_1_tab, dosing->qual[looper]->dose_2_tab)

    ;(cur week  dose - last week dose) / last_week * 100?
    if(looper < dosing->cnt and looper <= dosing->cnt) ;We can't do this calc until we have a value to compare against
        set dosing->qual[looper]->per_chng     =
             ((dosing->qual[looper]->wk_dose - dosing->qual[looper + 1]->wk_dose) / dosing->qual[looper + 1]->wk_dose) * 100

        set dosing->qual[looper]->per_chng_str = cnvtstring(dosing->qual[looper]->per_chng, 11, 2)
    endif
endfor


;Presentation
;Set up table information
;defaulting full table size, we might not use it all.
set stat = alterlist(cells->cells, 11)


set cells->cells[ 1]->size =  2000
set cells->cells[ 2]->size =  3000
set cells->cells[ 3]->size =  4000
set cells->cells[ 4]->size =  5000
set cells->cells[ 5]->size =  6000
set cells->cells[ 6]->size =  7000
set cells->cells[ 7]->size =  8000
set cells->cells[ 8]->size =  9000
set cells->cells[ 9]->size = 10000
set cells->cells[10]->size = 11000
set cells->cells[11]->size = 12000


;setting real table size
set stat = alterlist(cells->cells, dosing->cnt + 1) ;amount of columns plus our headers


;RTF header
set header = notrim(build2(rhead))


set tmp_str = wr


if(dosing->cnt > 0)
    set tmp_str = concat(tmp_str, trend_row('Date'             , cells, dosing, 1))
    set tmp_str = concat(tmp_str, trend_row('INR'              , cells, dosing, 2)) ;002
    ;set tmp_str = concat(tmp_str, trend_row('Transcribed INR'  , cells, dosing, 2))
    set tmp_str = concat(tmp_str, trend_row('Dose Tab MG'      , cells, dosing, 3))

    set tmp_str = concat(tmp_str, trend_row('Sunday Dose'      , cells, dosing, 4))
    set tmp_str = concat(tmp_str, trend_row('Monday Dose'      , cells, dosing, 5))
    set tmp_str = concat(tmp_str, trend_row('Tuesday Dose'     , cells, dosing, 6))
    set tmp_str = concat(tmp_str, trend_row('Wednesday Dose'   , cells, dosing, 7))
    set tmp_str = concat(tmp_str, trend_row('Thursday Dose'    , cells, dosing, 8))
    set tmp_str = concat(tmp_str, trend_row('Friday Dose'      , cells, dosing, 9))
    set tmp_str = concat(tmp_str, trend_row('Saturday Dose'    , cells, dosing, 10))

    set tmp_str = concat(tmp_str, trend_row('Total Weekly Dose', cells, dosing, 11))
    set tmp_str = concat(tmp_str, trend_row('Dosage Change %'  , cells, dosing, 12))
    set tmp_str = concat(tmp_str, ' ', reol)


    ;Man I am fighting some weird stuff in dyndocs when this smart template is used.  After the table I can't have normal text.
    ;I'm going to try and get around this by just doing another table.

    set stat = alterlist(cells2->cells, 1)
     set cells2->cells[ 1]->size =  12000

    for(idx = 1 to dosing->cnt)
        if(dosing->qual[idx]->comment_txt > ' ')
            if(comment_str = ' ')
                set comment_str = notrim(build2(' Dosing Comments:', reol))
            endif

            set comment_str = notrim(build2(comment_str
                                           , '    '
                                           , dosing->qual[idx]->date_str
                                           , ': '
                                           , dosing->qual[idx]->comment_txt
                                           , reol
                                           )
                                    )
        endif
    endfor


    set table_2_str = rtf_row(cells2, 0)
    set table_2_str = notrim(build2(table_2_str, rtf_cell(comment_str, 1)))

    set tmp_str = concat(tmp_str, table_2_str)
endif

call include_line(build2(header, tmp_str,  RTFEOF))

;build reply text
for (cnt = 1 to drec->line_count)
    set  reply -> text  =  concat ( reply -> text, drec -> line_qual [ cnt ]-> disp_line )
endfor

set reply->text =  build2(header, tmp_str,  RTFEOF)
set drec->status_data->status = "S"
set reply->status_data->status = "S"



/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
subroutine trend_row(title, cells_rs, dosing_rs, row_num)
    declare tr_ret_string = vc
    declare tr_looper     = i4
    declare tr_last_cell  = i2

    if(row_num in (11, 3))
        set tr_ret_str = concat(rtf_row(cells_rs, 1), rtf_cell(concat(wbb, title, wr), 0))
    else
        set tr_ret_str = concat(rtf_row(cells_rs, 1), rtf_cell(title, 0))
    endif


    for(tr_looper = 1 to dosing_rs->cnt)
        set tr_last_cell = 0

        if(tr_looper = dosing_rs->cnt)
            set tr_last_cell = 1
        endif

        case(row_num)
        of  1: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->date_str,                     tr_last_cell))
        of  2: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->trans_inr,                    tr_last_cell))
        of  3: set tr_ret_str = concat(tr_ret_str, rtf_cell(concat(wbb, dosing_rs->qual[tr_looper]->dose_str, wr) ,   tr_last_cell))

        of  4: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->sun_dose_str,                 tr_last_cell))
        of  5: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->mon_dose_str,                 tr_last_cell))
        of  6: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->tue_dose_str,                 tr_last_cell))
        of  7: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->wed_dose_str,                 tr_last_cell))
        of  8: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->thu_dose_str,                 tr_last_cell))
        of  9: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->fri_dose_str,                 tr_last_cell))
        of 10: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->sat_dose_str,                 tr_last_cell))

        of 11: set tr_ret_str = concat(tr_ret_str, rtf_cell(concat(wbb, dosing_rs->qual[tr_looper]->wk_dose_str, wr), tr_last_cell))
        of 12: set tr_ret_str = concat(tr_ret_str, rtf_cell(dosing_rs->qual[tr_looper]->per_chng_str,                 tr_last_cell))
        endcase
    endfor

    return(tr_ret_str)
end


/*  calc_dose
    This is mainly used to change the factional strings into numbers in order to calculate the daily dose
    Since we are doing this here, we might as well do the math to come up with a MG number, which is returned
    as a float.

    NOTES-
        The results should be for the same day

    Input:
        result1 (vc) - This is result string coming from a dropdown in the powerform.  We'll manually change it to a real.
        result2 (vc) - This is result string coming from a dropdown in the powerform.  We'll manually change it to a real.
        dose1   (vc) - This is a vc result coming from a powerform.  It should be in MGs.
        dose2   (vc) - This is a vc result coming from a powerform.  It should be in MGs.

    Output:
        vc           - Total dosage of the day in MG (if there is a number we'll put an mg)
*/
subroutine calc_dose(result1, result2, dose1, dose2)
    declare res_1_float = f8 with protect, noconstant(0.0)
    declare res_2_float = f8 with protect, noconstant(0.0)
    declare dos_1_float = f8 with protect, noconstant(0.0)
    declare dos_2_float = f8 with protect, noconstant(0.0)

    declare ret_float   = f8 with protect, noconstant(0.0)
    declare ret_val     = vc with protect, noconstant('')
    declare ret_str     = vc with protect, noconstant('')

    set res_1_float = decode_dose(result1)
    set res_2_float = decode_dose(result2)
    set dos_1_float = cnvtreal(dose1)
    set dos_2_float = cnvtreal(dose2)

    set ret_float     = (res_1_float * dos_1_float) + (res_2_float * dos_2_float)

    if(ret_float > 0.0)

        set ret_val = concat(trailing_zero_removal(ret_float), ' mg')
    else
        set ret_val = ' '
    endif

    return(ret_val)
end


/*  trailing_zero_removal
    They wanted us to remove trailing zeros if they are present for this.

    Input:
        result (f8) - The float value to return in string format, without trailing zeros, decimal only if relevant.

    Output:
        vc          - Total dosage of the day as a string
*/
subroutine trailing_zero_removal(result)

    declare ret_str = vc with protect, noconstant('')

    set ret_str = trim(cnvtstring(ret_float, 11, 2), 3)

    set ret_str = replace(ret_str, '.00', '')

    return(ret_str)
end



/*  decode_dose
    This is used to change the string to a value for mathing.

    Input:
        value (vc) - value coming from powerform (1, 1 1/2, 1/2, etc.)

    Output:
        f8         - value as a real for mathing.
*/
subroutine decode_dose(value)
    declare dd_ret_val = f8

    ;I know it is a bit gross to do this this, and a maintenance nightmare, but coming up with parsing for this
    ; is equally silly.
    case(value)
    of ' '    :
    of '0'    : set dd_ret_val = 0.0
    of '1/2'  : set dd_ret_val = 0.5
    of '1'    : set dd_ret_val = 1.0
    of '1 1/2': set dd_ret_val = 1.5
    of '2'    : set dd_ret_val = 2.0
    of '2 1/2': set dd_ret_val = 2.5
    of '3'    : set dd_ret_val = 3.0
    of '3 1/2': set dd_ret_val = 3.5
    of '4'    : set dd_ret_val = 4.0
    of '4 1/2': set dd_ret_val = 4.5
    of '5'    : set dd_ret_val = 5.0
    of '5 1/2': set dd_ret_val = 5.5
    endcase

    return(dd_ret_val)

end


#exit_program

call echorecord(dosing)
call echorecord(drec)

call echo(reply->text)

end
go
