/*************************************************************************
 Program Title:   CCM Duration Activities

 Object name:     14_st_ccm_ord_dur
 Source file:     14_st_ccm_ord_dur.prg

 Purpose:         The template will pull the Chronic Care orders and duration for the Person.

 Tables read:

 Executed from:

 Special Notes:   This was stolen from 14_st_cocm_ord_dur.  They are wanting to emulate the workflow
                  of the CoCM process.  But things are still being worked out it seems.

                  I'm copying much of the logic from there, since the intention is that these workflows
                  will eventually be similar.

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-10-23 Michael Mayes        349415 Initial release (Taken a base from 14_st_cocm_ord_dur)
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_ccm_ord_dur:dba go
create program 14_st_ccm_ord_dur:dba


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
%i cust_script:0_rtf_template_format.inc

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/

if(validate(reply) = 0)
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
endif




free record mesqual
record mesqual (
  1 mes_cnt          = i4
  1 mes_qual [*]
    2 mes_name       = vc
    2 mes_res        = vc
    2 mes_enc_id     = f8
    2 mes_duration   = vc
    2 mes_sum        = i2
    2 mes_person_id  = f8
    2 mes_pcp        = vc
    2 mes_patname    = vc
    2 mes_patdob     = vc
    2 mes_patempi    = vc
    2 mes_unit       = vc
    2 mes_text       = vc
    2 mes_order_id   = f8
    2 mes_start_date = dq8
)

;free record displayqual
;     record displayqual (
;  1 line_cnt     = i4
;  1 display_line = vc
;  1 line_qual [*]
;    2 disp_line  = vc
;)
;
;free record cocm_orders
;     record cocm_orders (
;  1 qual[*]
;    2 order_date    = vc
;    2 billable_cocm = vc
;)
;
free record cocm_duration
     record cocm_duration (
    1 det_cnt            = i4
    1 tot_dur            = i4
    1 details[*]         
        2 activity_dt    = vc
        2 activity_durr  = vc
        2 type           = vc
        2 role           = vc
        2 act_cnt        = i4
        2 acts[*]        
            3 activity   = vc
            
    1 forms_cnt          = f8
    1 forms[*]
        2 form_event_id  = f8
        2 form_dt_tm     = dq8
        2 form_dt_txt    = vc
        2 duration       = i4
        2 pos_txt        = vc
        2 bill_pract_ind = i2
            
    1 bill_tot_dur       = i4
    1 bill_forms_cnt     = f8
    1 bill_forms[*]
        2 form_event_id  = f8
        2 form_dt_tm     = dq8
        2 form_dt_txt    = vc
        2 duration       = i4
        2 pos_txt        = vc
        2 bill_pract_ind = i2
            
    1 desg_tot_dur       = i4
    1 desg_forms_cnt     = f8
    1 desg_forms[*]
        2 form_event_id  = f8
        2 form_dt_tm     = dq8
        2 form_dt_txt    = vc
        2 duration       = i4
        2 pos_txt        = vc
        2 bill_pract_ind = i2
    
    1 bill_chunk_cnt     = i4
    1 bill_chunk[*]
        2 duration       = i4
        2 activity_dt    = vc
        
    1 desg_chunk_cnt     = i4
    1 desg_chunk[*]
        2 duration       = i4
        2 activity_dt    = vc
    
    1 cpt_cnt            = i4
    1 cpt[*]
        2 cpt            = vc
        2 duration       = i4
        2 date_time      = vc
        2 description    = vc
        2 unit           = vc
        
)

record cells(
    1 cells[*]
        2 size = i4
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare set_row_dur (col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc, col5_txt = vc) = vc
declare set_row_ord (col1_txt = vc, col2_txt = vc                                             ) = vc
declare set_row_dur2(col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc               ) = vc

declare add_cpt_rs  ( rs        = vc(ref)
                    , cpt       = vc
                    , dur       = i4
                    , date_time = vc
                    , unit      = vc
                    , opt_desc  = vc(value, '')
                    ) = null


;/**************************************************************
;; DVDev DECLARED VARIABLES
;**************************************************************/
declare first_day_cur_month   = dq8
declare last_day_cur_month    = dq8
declare first_day_last_month  = dq8
declare last_day_last_month   = dq8
declare vfirst_day_last_month = vc
declare vlast_day_last_month  = vc
declare yearmonth             = vc

declare auth_cd    = f8 with protect,   constant(uar_get_code_by(   'MEANING', 8, 'AUTH'                                ))
declare mod_cd     = f8 with protect,   constant(uar_get_code_by(   'MEANING', 8, 'MODIFIED'                            ))
declare alter_cd   = f8 with protect,   constant(uar_get_code_by(   'MEANING', 8, 'ALTERED'                             ))

declare 4_CMRN     = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY',   4, 'COMMUNITYMEDICALRECORDNUMBER'      ))
declare 331_PCP    = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 331, 'PRIMARYCAREPHYSICIAN'              ))

declare rtf_table_ord   = vc with protect, noconstant('')
declare rtf_table_dur   = vc with protect, noconstant('')
declare rtf_table_dur2  = vc with protect, noconstant('')

declare output_rtf      = vc with protect

;declare is_initial_assm = c1 with protect, noconstant('n')
;
;declare firstpasshr     = i4 with protect, noconstant(60)
;declare firstpasshalfhr = i4 with protect, noconstant(31)
;
;declare firstpasscpt    = vc with protect, noconstant('99493')
;declare firstpassdesc   = vc with protect, noconstant('Subsequent psych care mgmt, 60 min/month - CoCM ')
;declare firstpassfilled = c1 with protect, noconstant('n')
;
;declare personid        = f8 with protect,   constant(request->person[1]->person_id)
;declare num             = i4 with public, noconstant (0)
;declare start           = i4 with public, noconstant (0)
;declare cumsum          = i4
;
;declare durationbalance = i4
declare totaldur        = i4
;declare duration_desc   = vc
;
declare index           = i4 with protect, noconstant(0)
declare pos             = i4 with protect, noconstant(0)
declare looper          = i4 with protect, noconstant(0)
declare looper2         = i4 with protect, noconstant(0)
declare whilepanic      = i4 with protect, noconstant(100)
declare whilepanic2     = i4 with protect, noconstant(100)
;declare index2          = i4 with public, noconstant(0)
;

declare ccm_ref_id   = f8 with protect, noconstant(0.0)
declare ccm_dur_cd   = f8 with protect, noconstant(0.0)
declare ccm_start_cd = f8 with protect, noconstant(0.0)
declare ccm_stop_cd  = f8 with protect, noconstant(0.0)
declare ccm_serv_cd  = f8 with protect, noconstant(0.0)


;
;/**************************************************************
;; DVDev Start Coding
;**************************************************************/
set drec->line_count          = 0
set drec->status_data->status = "f"

;TST
;set ccm_ref_id   = 24240931939.00
;set ccm_dur_cd   =  4567653829.00
;set ccm_start_cd =  4567653789.00
;set ccm_stop_cd  =  4567653809.00
;set ccm_serv_cd  =  4567653853.00
;set ccm_role_cd  =  0.00  ;NOTE THIS IS POST BUILD MOVE.. don't know this in TST

;BUILD
;set ccm_ref_id   = 24245090131.00
;set ccm_dur_cd   =  4568455597.00
;set ccm_start_cd =  4568455553.00
;set ccm_stop_cd  =  4568455577.00
;set ccm_serv_cd  =  4568455617.00
;set ccm_role_cd  =  4568455649.00


;PROD
set ccm_ref_id   = 31503381929.00
set ccm_dur_cd   =  5734894793.00
set ccm_start_cd =  5734866127.00
set ccm_stop_cd  =  5734861407.00
set ccm_serv_cd  =  5734880969.00
set ccm_role_cd  =  5734895299.00



set first_day_cur_month   = datetimefind(cnvtdatetime(curdate, 0), 'M', 'B', 'B')
set last_day_cur_month    = datetimefind(cnvtdatetime(curdate, 0), 'M', 'E', 'E')

set last_day_last_month   = datetimeadd(datetimefind(cnvtdatetime(curdate, 2359), 'M', 'B', 'E'), -1)
set first_day_last_month  = datetimefind(cnvtlookbehind('1,M'), 'M', 'B', 'B')

set vfirst_day_last_month = format(first_day_last_month,  'DD-MMM-YYYY HH:MM;;D')
set vlast_day_last_month  = format(last_day_last_month,   'DD-MMM-YYYY HH:MM;;D')
set year_month            = build2( year(cnvtlookbehind('1,M')),' '
                                  , evaluate( month(cnvtlookbehind('1,M'))
                                            ,  1, 'JAN'
                                            ,  2, 'FEB'
                                            ,  3, 'MAR'
                                            ,  4, 'APR'
                                            ,  5, 'MAY'
                                            ,  6, 'JUN'
                                            ,  7, 'JUL'
                                            ,  8, 'AUG'
                                            ,  9, 'SEP'
                                            , 10, 'OCT'
                                            , 11, 'NOV'
                                            , 12, 'DEC'
                                            )
                                  )


set output_rtf            = build2(output_rtf, wr, 'Monthly summary for: ', trim(year_month, 3))


call echo(build('first_day_cur_month  :', first_day_cur_month  ))
call echo(build('last_day_cur_month   :', last_day_cur_month   ))
call echo(build('last_day_last_month  :', last_day_last_month  ))
call echo(build('first_day_last_month :', first_day_last_month ))
call echo(build('vfirst_day_last_month:', vfirst_day_last_month))
call echo(build('vlast_day_last_month :', vlast_day_last_month ))
call echo(build('year_month           :', year_month           ))
call echo(build('output_rtf           :', output_rtf           ))





;/***********************************************************************
;DESCRIPTION: GET PCP
;***********************************************************************/
select distinct

  into "nl:"
       prov_type = uar_get_code_display(ppr.person_prsnl_r_cd)
     ,             ppr.active_status_dt_tm
     , pcp       = trim(pr.name_full_formatted)

  from person             p
     , person_alias       pa
     , person_prsnl_reltn ppr
     , prsnl              pr

  plan p
   where p.person_id              = p_id

  join pa
   where pa.person_id             =  p.person_id
     and pa.active_ind            =  1
     and pa.end_effective_dt_tm   >  cnvtdatetime(curdate, curtime3)
     and pa.person_alias_type_cd  =  4_cmrn

  join ppr
    where ppr.person_id           =  outerjoin(p.person_id        )
      and ppr.end_effective_dt_tm >  outerjoin(sysdate            )
      and ppr.active_ind          =  outerjoin(1                  )
      and ppr.manual_inact_ind    =  outerjoin(0                  )
      and ppr.person_prsnl_r_cd   =  outerjoin(331_pcp            )

  join pr
   where pr.person_id             =  outerjoin(ppr.prsnl_person_id)
     and pr.active_ind            =  outerjoin(1                  )

order by ppr.active_status_dt_tm desc

head  ppr.active_status_dt_tm

    stat                             = alterlist(mesqual->mes_qual, 1)
    mesqual->mes_qual[1].mes_pcp     = pcp
    mesqual->mes_qual[1].mes_patname = p.name_full_formatted
    mesqual->mes_qual[1].mes_patdob  = format(p.birth_dt_tm, 'MM/DD/YYYY;;Q')
    mesqual->mes_qual[1].mes_patempi = cnvtalias(pa.alias, pa.alias_pool_cd)

    output_rtf = build2(output_rtf, reol, 'Rendering provider: ', trim(PR.name_full_formatted                , 3))
    output_rtf = build2(output_rtf, reol, 'Patient Name: '      , trim(p.name_full_formatted                 , 3))
    output_rtf = build2(output_rtf, reol, 'DOB: '               , trim(format(p.birth_dt_tm, 'MM/DD/YYYY;;Q'), 3))
    output_rtf = build2(output_rtf, reol, 'EMPI: '              , trim(cnvtalias(pa.alias,pa.alias_pool_cd)  , 3), reol)

with nocounter , maxrec =1



;/***********************************************************************
;DESCRIPTION: Get Duration Logged
;***********************************************************************/
call echo('mmmtest duration')
select into 'nl:'

  from dcp_forms_activity      d
     , dcp_forms_activity_comp dfc
     , clinical_event          form
     , clinical_event          sec
     , clinical_event          dur
     , clinical_event          ce1
     , ce_date_result          dat1
     , clinical_event          ce2
     , ce_date_result          dat2
     , clinical_event          acts
     , ce_coded_result         ccr
     , clinical_event          role

  plan d
   where d.person_id                =  p_id
     and d.active_ind               =  1
     and d.dcp_forms_ref_id         =  ccm_ref_id
     and d.form_status_cd           in (25.00, 34.00, 35.00)

  join dfc
   where dfc.dcp_forms_activity_id  =  d.dcp_forms_activity_id
     and dfc.parent_entity_name     =  'CLINICAL_EVENT'

  join form
   where form.parent_event_id       =  dfc.parent_entity_id
     and form.event_id              =  form.parent_event_id
     and form.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')

  join sec
   where sec.parent_event_id        =   form.event_id
     and sec.valid_until_dt_tm      =   cnvtdatetime('31-DEC-2100 00:00:00.00')
     and sec.event_end_dt_tm   between  cnvtdatetime('01-JAN-1970 0000') and cnvtdatetime(curdate,curtime3)
     and sec.result_status_cd       in  (25.00, 33.00, 35.00)

  join dur
   where dur.parent_event_id        =   sec.event_id
     and dur.valid_until_dt_tm      >=  cnvtdatetime(curdate,curtime3)
     And dur.event_tag              !=  'In Error'
     and dur.event_cd               =   ccm_dur_cd  ;CCM Duration

  join ce1
   where ce1.parent_event_id      =  sec.event_id
     and ce1.valid_until_dt_tm    >= cnvtdatetime(curdate,curtime3)
     And ce1.event_tag            != 'In Error'
     and ce1.event_cd             =  ccm_start_cd  ;CCM Start Time
  
  join dat1
   where dat1.event_id              = ce1.event_id
     and dat1.valid_until_dt_tm     = cnvtdatetime('31-DEC-2100 00:00:00.00');003
     and dat1.result_dt_tm between cnvtdatetime(vFIRST_DAY_LAST_MONTH ) AND cnvtdatetime(vLAST_DAY_LAST_MONTH)
  
  join ce2
   where ce2.parent_event_id       =  sec.event_id
     and ce2.valid_until_dt_tm     >= cnvtdatetime(curdate,curtime3)
     and ce2.event_tag             != 'In Error'
     and ce2.event_cd              =  ccm_stop_cd  ;CCM Stop Time 
  
  join dat2
   where dat2.event_id              = ce2.event_id
     and dat2.valid_until_dt_tm     = cnvtdatetime('31-DEC-2100 00:00:00.00');003
     and dat2.result_dt_tm between cnvtdatetime(vFIRST_DAY_LAST_MONTH ) AND cnvtdatetime(vLAST_DAY_LAST_MONTH)

  join acts
   where acts.parent_event_id      =  sec.event_id
     and acts.valid_until_dt_tm    >= cnvtdatetime(curdate,curtime3)
     and acts.event_tag            != 'In Error'
     and acts.event_cd             =   ccm_serv_cd  ;CCM Care Management Services
     
  join ccr
   where ccr.event_id              =  acts.event_id
     and ccr.valid_until_dt_tm     >= cnvtdatetime(curdate, curtime3)

  join role
   where role.parent_event_id      =  outerjoin(sec.event_id)
     and role.valid_until_dt_tm    >= outerjoin(cnvtdatetime(curdate,curtime3))
     and role.event_tag            != outerjoin('In Error')
     and role.event_cd             =  outerjoin( ccm_role_cd)  ;Role Providing Services 
     
order by d.person_id, form.event_end_dt_tm, dat2.result_dt_tm, ccr.sequence_nbr

head form.event_id
    null

head dat2.result_dt_tm
    cocm_duration->det_cnt = cocm_duration->det_cnt + 1
    index                  = cocm_duration->det_cnt
    stat                   = alterlist(cocm_duration->details, index)
    
    COCM_DURATION->details[index].activity_dt   = FORMAT(dat2.result_dt_tm,  '@SHORTDATE')
    cocm_duration->details[index].activity_durr = dur.result_val
    cocm_duration->details[index].role          = trim(role.result_val, 3)
    cocm_duration->tot_dur                      = cocm_duration->tot_dur + cnvtint(dur.result_val)
    
    
   if(trim(role.result_val, 3) in ('MD', 'Nurse Practitioner'))
        cocm_duration->details[index].type = 'Billing practitioner'
   
        cocm_duration->bill_forms_cnt = cocm_duration->bill_forms_cnt + 1
        pos                           = cocm_duration->bill_forms_cnt
        stat                          = alterlist(cocm_duration->bill_forms, pos)
        
        cocm_duration->bill_forms[pos]->form_event_id  = form.event_id
        cocm_duration->bill_forms[pos]->form_dt_tm     = dat2.result_dt_tm
        cocm_duration->bill_forms[pos]->form_dt_txt    = FORMAT(dat2.result_dt_tm,  '@SHORTDATE')
        cocm_duration->bill_forms[pos]->pos_txt        = trim(role.result_val, 3)
        cocm_duration->bill_forms[pos]->duration       = cnvtint(dur.result_val)
        
        cocm_duration->bill_tot_dur = cocm_duration->bill_tot_dur + cnvtint(dur.result_val)
    else
        cocm_duration->details[index].type = 'Designated Staff'
        
        cocm_duration->desg_forms_cnt = cocm_duration->desg_forms_cnt + 1
        pos                           = cocm_duration->desg_forms_cnt
        stat                          = alterlist(cocm_duration->desg_forms, pos)
        
        cocm_duration->desg_forms[pos]->form_event_id  = form.event_id
        cocm_duration->desg_forms[pos]->form_dt_tm     = dat2.result_dt_tm
        cocm_duration->desg_forms[pos]->form_dt_txt    = FORMAT(dat2.result_dt_tm,  '@SHORTDATE')
        cocm_duration->desg_forms[pos]->pos_txt        = trim(role.result_val, 3)
        cocm_duration->desg_forms[pos]->duration       = cnvtint(dur.result_val)
        
        cocm_duration->desg_tot_dur = cocm_duration->desg_tot_dur + cnvtint(dur.result_val)
    endif
    
head ccr.sequence_nbr
    cocm_duration->details[index].act_cnt = cocm_duration->details[index].act_cnt + 1
    pos                                   = cocm_duration->details[index].act_cnt
    stat                                  = alterlist(cocm_duration->details[index].acts, pos)
    
    cocm_duration->details[index].acts[pos].activity = trim(ccr.descriptor, 3)

with  nocounter


/***********************************************************************
    Okay... now we have to scan across our durations to come up with CPTS... 
    
    First we see if the time was done on a designated staff, or a billing practitioner... which we "ind"-ed above.
    
    Here are the rest of the rules... we need 20 minutes before billing at all.
    Billing Practitioner
        We can bill 99491 for first 30 minutes...
        Then can bill any number of 99439
    
    Designated
        We can bill 99490 for first 20 minutes...
        Then can bill 99439 for 2 additional 20 minutes...
   
  
***********************************************************************/

;Chunk-itize
;declare leftover_bill = i4 with protect, noconstant(0)
;declare remander_ind  = i4 with protect, noconstant(0)   ;Used to move the date after we run out of remainder time.
;declare temp_date     = vc with protect, noconstant('')
;
;set index = 1
;if(cocm_duration->bill_forms_cnt > 0)
;    
;    ;Default the running total with our first position.  Set the date to that too.
;    set leftover_bill = cocm_duration->bill_forms[index]->duration
;    set temp_date     = cocm_duration->bill_forms[index]->form_dt_txt
;    
;    
;    ;Loop through each form
;    set whilepanic = 100
;    while(whilepanic > 0 and index <= cocm_duration->bill_forms_cnt)
;        
;        ;Pull off as many 30 minutes chunks as we can.
;        set whilepanic2 = 100
;        while(whilepanic2 > 0 and leftover_bill >= 30)
;            
;            set cocm_duration->bill_chunk_cnt = cocm_duration->bill_chunk_cnt + 1
;            set pos                           = cocm_duration->bill_chunk_cnt
;            set stat                          = alterlist(cocm_duration->bill_chunk, pos)
;            
;            set cocm_duration->bill_chunk[pos]->duration = 30
;            set cocm_duration->bill_chunk[pos]->activity_dt = temp_date
;            
;            set leftover_bill = leftover_bill - 30
;            
;            set whilepanic2 = whilepanic2 - 1
;        
;            ;We were working with a sub 30 minutes under the current date, and added it above, now we can reset the date.
;            if(remander_ind = 1)
;                set remander_ind = 0
;                set temp_date    = cocm_duration->bill_forms[index]->form_dt_txt
;            endif
;            
;        
;        endwhile
;        
;        ;There could be leftover time here, so don't move the date yet.  But we'll flag it as the remainder below.
;        
;        ;If we have more positions... move to the next index, and add that to the running total, we'll come back and process above.
;        if(index <= cocm_duration->bill_forms_cnt - 1)
;            
;            ;Move to next position
;            set index         = index + 1
;            
;            ;There is a chance we are out of time here... if that is the case, we want a new time now, for the next run.
;            if(leftover_bill = 0)
;                set temp_date    = cocm_duration->bill_forms[index]->form_dt_txt
;            else
;                set remander_ind  = 1  ; We want to use the current date one more time.
;            endif
;
;            ;Now since we are done checking leftover_bill, we can add to it for our next loop.
;            set leftover_bill = leftover_bill + cocm_duration->bill_forms[index]->duration
;
;        endif
;        
;        set whilepanic = whilepanic - 1
;    endwhile
;    
;    if(leftover_bill > 0)
;        
;        set cocm_duration->bill_chunk_cnt = cocm_duration->bill_chunk_cnt + 1
;        set pos                           = cocm_duration->bill_chunk_cnt
;        set stat                          = alterlist(cocm_duration->bill_chunk, pos)
;        
;        set cocm_duration->bill_chunk[pos]->duration = leftover_bill
;        set cocm_duration->bill_chunk[pos]->activity_dt = cocm_duration->bill_forms[index].form_dt_txt
;        
;        set leftover_bill = 0
;    
;    endif
;endif


;declare leftover_desg = i4 with protect, noconstant(0)
;declare chunk         = i4 with protect, noconstant(0)
;
;set leftover_bill = cocm_duration->bill_tot_dur
;if(leftover_bill >= 20)
;    ;Initial minutes
;    if(leftover_bill >= 30) 
;        set chunk         = 30
;        set leftover_bill = leftover_bill - 30
;    else
;        set chunk         = leftover_bill
;        set leftover_bill = 0
;    endif
;    
;                
;    call add_cpt_rs( cocm_duration
;                   , '99491'
;                   , chunk
;                   , format(last_day_last_month, '@SHORTDATE')
;                   , '1'
;                   )
;    
;    ;Add on Minutes
;    if(leftover_bill > 0)
;        if(leftover_bill / 30 > 0)
;                
;            call add_cpt_rs( cocm_duration
;                           , '99437'
;                           , 30
;                           , format(last_day_last_month, '@SHORTDATE')
;                           , cnvtstring(leftover_bill / 30)
;                           )
;            
;            set leftover_bill = mod(leftover_bill, 30)
;            
;        endif
;        
;        if(leftover_bill > 0)
;                
;            call add_cpt_rs( cocm_duration
;                           , '99437'
;                           , leftover_bill
;                           , format(last_day_last_month, '@SHORTDATE')
;                           , '1'
;                           )
;                           
;        endif
;    
;    endif
;endif

set leftover_desg = cocm_duration->desg_tot_dur
if(leftover_desg >= 20)
    ;Initial minutes
    if(leftover_desg >= 20) 
        set chunk         = 20
        set leftover_desg = leftover_desg - 20
    else
        set chunk         = leftover_desg
        set leftover_desg = 0
    endif
    
            
    call add_cpt_rs( cocm_duration
                   , '99490'
                   , chunk
                   , format(last_day_last_month, '@SHORTDATE')
                   , '1'
                   )
            
    
    ;Add on Minutes
    if(leftover_desg > 0)
        if(leftover_desg > 40)
            
            call add_cpt_rs( cocm_duration
                           , '99439'
                           , 20
                           , format(last_day_last_month, '@SHORTDATE')
                           , '2'
                           )
            
            set leftover_desg = leftover_desg - 40
        
            ;call add_cpt_rs( cocm_duration
            ;               , ''
            ;               , leftover_desg
            ;               , format(last_day_last_month, '@SHORTDATE')
            ;               , '1'
            ;               , 'Unbillable Addl Staff Time'
            ;               )
            ;
            ;set leftover_desg = 0
            
        else
            if(leftover_desg > 20)
            
                call add_cpt_rs( cocm_duration
                               , '99439'
                               , 20
                               , format(last_day_last_month, '@SHORTDATE')
                               , cnvtstring(leftover_desg / 20)
                               )
                
                set leftover_desg = mod(leftover_desg, 20)
                
            endif
            
          ;  if(leftover_desg > 0)
          ;      
          ;      call add_cpt_rs( cocm_duration
          ;                     , '99439'
          ;                     , leftover_desg
          ;                     , format(last_day_last_month, '@SHORTDATE')
          ;                     , '1'
          ;                     )
          ;  endif
        endif
    
    endif
endif

;/***********************************************************************
;DESCRIPTION: Create Duration Logged as Table
;***********************************************************************/
if(cocm_duration->det_cnt > 0)
    set stat                  = alterlist(cells->cells, 4)

    set cells->cells[1]->size = 1000
    set cells->cells[2]->size = 2000
    set cells->cells[3]->size = 4250
    set cells->cells[4]->size = 5000

    set rtf_table_dur2 = build2(rh2b, set_row_dur2("DATE", "DURATION", "TYPE", "ROLE"))
    set rtf_table_dur2 = build2(rtf_table_dur2, wr)

    for (cnt = 1 to cocm_duration->det_cnt)
        set rtf_table_dur2 = notrim(build2( rtf_table_dur2
                                          , set_row_dur2( trim(cocm_duration->details[cnt].activity_dt  , 3)
                                                        , trim(cocm_duration->details[cnt].activity_durr, 3)
                                                        , trim(cocm_duration->details[cnt].type         , 3)
                                                        , trim(cocm_duration->details[cnt].role         , 3)
                                                        )
                                          )
                                   )
    endfor
    
    if(cocm_duration->det_cnt > 0)
        set rtf_table_dur2 = notrim(build2( rtf_table_dur2
                                          , set_row_dur2( 'Total'
                                                        , trim(cnvtstring(cocm_duration->tot_dur), 3)
                                                        , ' '
                                                        , ' '
                                                        )
                                          )
                                   )
        
    endif
endif

set stat = alterlist(cells->cells,2)

set cells->cells[1]->size = 1000
set cells->cells[2]->size = 6000

set rtf_table_ord = build2(rh2b, set_row_ord('Date','CCM Activity'))
set rtf_table_ord = build2(rtf_table_ord, wr)


if(cocm_duration->det_cnt > 0)
    for(looper = 1 to cocm_duration->det_cnt)
    
        if(cocm_duration->details[looper].act_cnt > 0)

            for(looper2 = 1 to cocm_duration->details[looper].act_cnt)
                
                set rtf_table_ord = notrim(build2( rtf_table_ord
                                                 , set_row_ord( cocm_duration->details[looper].activity_dt
                                                              , cocm_duration->details[looper].acts[looper2].activity
                                                              )
                                                 )
                                          )
                
            endfor
        endif
    
    endfor
else 
    set rtf_table_ord = ''
endif

if(cocm_duration->cpt_cnt > 0)
    set stat = alterlist(cells->cells, 5)

    set cells->cells[1]->size = 1000
    set cells->cells[2]->size = 1600
    set cells->cells[3]->size = 2600
    set cells->cells[4]->size = 3800
    set cells->cells[5]->size = 12000

    set rtf_table_dur         = build2(rh2b, set_row_dur("DATE", "CPT", "UNIT(S)", "DURATION", "DESCRIPTION"))
    set rtf_table_dur         = build2(rtf_table_dur, wr)

    for (cnt = 1 to cocm_duration->cpt_cnt)
        set rtf_table_dur = notrim(build2( rtf_table_dur
                                         , set_row_dur( trim(cocm_duration->cpt[cnt].date_time           ,3)
                                                      , trim(cocm_duration->cpt[cnt].cpt                 ,3)
                                                      , trim(cocm_duration->cpt[cnt].unit                ,3)
                                                      , trim(cnvtstring(cocm_duration->cpt[cnt].duration),3)
                                                      , trim(cocm_duration->cpt[cnt].description         ,3)
                                                      )
                                         )
                                  )
    endfor
else
    set rtf_table_dur = reol
endif





;/***********************************************************************
;DESCRIPTION: Presentation
;***********************************************************************/
if(textlen(trim(rtf_table_dur,3)) >0 )
    set output_rtf = (build2(output_rtf, trim(rtf_table_dur,3)))
endif

if(textlen(trim(rtf_table_dur2, 3)) > 0)
    set output_rtf =build2(output_rtf, "\plain \f1 \fs20 \b \ul \cb2 \pard\sl0 ", "Chronic Care Time Detail:", reol
                                     , trim(rtf_table_dur2, 3)
                                     )
else
    set output_rtf =build2(output_rtf, wr, "No Chronic Care time detail this period", reol)
endif

if(textlen(trim(rtf_table_ord,3)) >0 )
    set output_rtf = build2(output_rtf, "\plain \f1 \fs20 \b \ul \cb2 \pard\sl0 ", "Chronic Care Activities:", reol
                                      , trim(rtf_table_ord,3)
                           )
else
    set output_rtf = build2(output_rtf, wr, "No Chronic Care Activities this period", reol)
endif

set reply->text = build2(rhead,trim(output_rtf,3), rtfeof)


set drec->status_data->status  = "S"
set reply->status_data->status = "S"



subroutine set_row_dur(col1_txt, col2_txt, col3_txt, col4_txt,col5_txt)
    declare row_string = vc

    set row_str = concat(
        rtf_row(cells, 1),
            rtf_cell(col1_txt, 0),
            rtf_cell(col2_txt, 0),
            rtf_cell(col3_txt, 0),
            rtf_cell(col4_txt, 0),
            rtf_cell(col5_txt, 1)
    )

    ;call echo(row_str)
    return (row_str)
end

subroutine set_row_ord(col1_txt, col2_txt)
    declare row_string = vc

    set row_str = concat(
        rtf_row(cells, 1),
            rtf_cell(col1_txt, 0),
            rtf_cell(col2_txt, 1)
    )

    ;call echo(row_str)
    return (row_str)
end

subroutine set_row_dur2(col1_txt, col2_txt, col3_txt, col4_txt)
    declare row_string = vc
    set row_str = concat(
        rtf_row(cells, 1),
            rtf_cell(col1_txt, 0),
            rtf_cell(col2_txt, 0),
            rtf_cell(col3_txt, 0),
            rtf_cell(col4_txt, 1)
    )

    ;call echo(row_str)
    return (row_str)
end



subroutine add_cpt_rs(rs, cpt, dur, date_time, unit, opt_desc)
    
    declare rs_pos = i4 with protect, noconstant(0)
    declare desc   = vc with protect, noconstant('')
    
    
    if(opt_desc > ' ')
        set desc = opt_desc
    else
        case(cpt)
        of '99491': set desc = notrim(build2('Bill For Chronic Care Mgmt Svc Phys 1St 30 Min Cal Month - AMB 99491' ))
        of '99437': set desc = notrim(build2('Bill For Chronic Care Mgmt Svc Phys Ea Addl 30 Min Cal Mo - AMB 99437'))
        of '99490': set desc = notrim(build2('Bill For Chron Care Management Srvc 20 Min Per Month AMB - 99490'     ))
        of '99439': set desc = notrim(build2('Bill For Chronic Care Mgmt Svc Staf Ea Addl 20 Min Cal Mo - AMB 99439'))
        endcase
    endif
    
    
    set rs->cpt_cnt  = rs->cpt_cnt + 1
    set rs_pos       = rs->cpt_cnt
    set stat         = alterlist(rs->cpt, rs_pos)
    
    set rs->cpt[rs_pos]->cpt         = cpt
    set rs->cpt[rs_pos]->duration    = dur
    set rs->cpt[rs_pos]->date_time   = date_time
    set rs->cpt[rs_pos]->description = desc
    set rs->cpt[rs_pos]->unit        = unit
    
end


#exit_script

call echorecord(mesqual)
call echorecord(cocm_duration)

;call echo(reply->text)


end
go
