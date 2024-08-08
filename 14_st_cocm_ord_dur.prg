/*************************************************************************
 Program Title:   CoCM Duration Activities

 Object name:     14_st_cocm_ord_dur
 Source file:     14_st_cocm_ord_dur.prg

 Purpose:         The template will pull the Collaborative care orders and duration for the Person.

 Tables read:

 Executed from:

 Special Notes:   This was stolen from 14_st_cocm_v2 (mod 003 @ 2024-06-27).  Orders have changed, and that is
                  necessary to update for the activities side of the ST.

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-06-27 Michael Mayes        346995 Initial release (Taken a base from 14_st_cocm_v2)
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_cocm_ord_dur go
create program 14_st_cocm_ord_dur


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

free record displayqual
     record displayqual (
  1 line_cnt     = i4
  1 display_line = vc
  1 line_qual [*]
    2 disp_line  = vc
)

free record cocm_orders
     record cocm_orders (
  1 qual[*]
    2 order_date    = vc
    2 billable_cocm = vc
)

free record cocm_duration
     record cocm_duration (
  1 dur_cnt = i4
  1 qual[*]
    2 cpt = vc
    2 duration = i4
    2 date_time = vc
    2 description = vc
    2 unit = vc
    2 unit_num = i4
  1 details[*]
    2 activity_dt = vc
    2 activity_durr = vc
)

record cells(
    1 cells[*]
        2 size = i4
)
record cells2(
    1 cells[*]
        2 size = i4
)
record cells3(
    1 cells[*]
        2 size = i4
)

record cellorders(
    1 cellorders[*]
        2 size = i4
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare set_row_dur (col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc, col5_txt = vc) = vc
declare set_row_ord (col1_txt = vc, col2_txt = vc                                             ) = vc
declare set_row_dur2(col1_txt = vc, col2_txt = vc                                             ) = vc


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare first_day_cur_month   = dq8
declare last_day_cur_month    = dq8
declare first_day_last_month  = dq8
declare last_day_last_month   = dq8
declare vfirst_day_last_month = vc
declare vlast_day_last_month  = vc
declare yearmonth             = vc

declare beh_stnmd  = f8 with protect,   constant(2725835181.00)
declare beh_st     = f8 with protect,   constant(2725840843.00)

declare auth_cd    = f8 with protect,   constant(uar_get_code_by(   'MEANING', 8, 'AUTH'                                ))
declare mod_cd     = f8 with protect,   constant(uar_get_code_by(   'MEANING', 8, 'MODIFIED'                            ))
declare alter_cd   = f8 with protect,   constant(uar_get_code_by(   'MEANING', 8, 'ALTERED'                             ))

declare 72_tspt    = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'TIMESPENTINPSYCHOTHERAPY'           ))

declare 200_cocmbi = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMBRIEFINTERVENTIONS'           ))
declare 200_cocmcr = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMCASELOADREVIEW'               ))
declare 200_cocmeo = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMENGAGEMENTOUTREACH'           ))
declare 200_cocmia = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMINITIALASSESSMENT'            ))
declare 200_cocmoc = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMONGOINGCOORDINATION'          ))
declare 200_cocmpc = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMPSYCHIATRICCONSULTATION'      ))
declare 200_cocmrs = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMRATINGSCALES'                 ))
declare 200_cocmrt = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMREGISTRYTRACKING'             ))
declare 200_cocmrp = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMRELAPSEPREVENTION'            ))
declare 200_cocmfm = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMFIRSTMONTH'                   ))
declare 200_cocmsm = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMSUBSEQUENTMONTH'              ))
declare 200_cocmrc = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'REFERRALTOMEDSTARCOLLABORATIVEBEHAVI'))


declare 200_new_cocm_init  = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMINITIALASSESSMENTTXPLAN'  ))
declare 200_new_cocm_ebts  = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMEBTSSCALES'               ))
declare 200_new_cocm_psych = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMPSYCHCONSULT'             ))
declare 200_new_cocm_care  = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMCARETEAMREVIEW'           ))
declare 200_new_cocm_case  = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMSYSTEMATICCASELOADREVIEW' ))
declare 200_new_cocm_cont  = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMCONTACTWITHPT'            ))
declare 200_new_cocm_docu  = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMDOCUMENTATION'            ))
declare 200_new_cocm_chart = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMCHARTREVIEW'              ))
declare 200_new_cocm_coord = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMCOORDINATINGCARE'         ))
declare 200_new_cocm_crisi = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMCRISISRESPONSE'           ))
declare 200_new_cocm_disch = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMRPDISCHARGEPLANNING'      ))
declare 200_new_cocm_other = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'AMBCOCMOTHERCAREMANAGERTASK'     ))



declare 4_CMRN     = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY',   4, 'COMMUNITYMEDICALRECORDNUMBER'      ))
declare 331_PCP    = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 331, 'PRIMARYCAREPHYSICIAN'              ))


declare rtf_table_ord   = vc with protect, noconstant('')
declare rtf_table_dur   = vc with protect, noconstant('')
declare rtf_table_dur2  = vc with protect, noconstant('')

declare output_rtf      = vc with protect

declare is_initial_assm = c1 with protect, noconstant('n')

declare firstpasshr     = i4 with protect, noconstant(60)
declare firstpasshalfhr = i4 with protect, noconstant(31)

declare firstpasscpt    = vc with protect, noconstant('99493')
declare firstpassdesc   = vc with protect, noconstant('Subsequent psych care mgmt, 60 min/month - CoCM ')
declare firstpassfilled = c1 with protect, noconstant('n')

declare personid        = f8 with protect,   constant(request->person[1]->person_id)
declare num             = i4 with public, noconstant (0)
declare start           = i4 with public, noconstant (0)
declare cumsum          = i4

declare durationbalance = i4
declare totaldur        = i4
declare duration_desc   = vc

declare index           = i4 with public, noconstant(0)
declare index2          = i4 with public, noconstant(0)


/**************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('200_cocmbi:', 200_cocmbi))
call echo(build('200_cocmcr:', 200_cocmcr))
call echo(build('200_cocmeo:', 200_cocmeo))
call echo(build('200_cocmia:', 200_cocmia))
call echo(build('200_cocmoc:', 200_cocmoc))
call echo(build('200_cocmpc:', 200_cocmpc))
call echo(build('200_cocmrs:', 200_cocmrs))
call echo(build('200_cocmrt:', 200_cocmrt))
call echo(build('200_cocmrp:', 200_cocmrp))
call echo(build('200_cocmfm:', 200_cocmfm))
call echo(build('200_cocmsm:', 200_cocmsm))
call echo(build('200_cocmrc:', 200_cocmrc))

call echo(build('200_new_cocm_init :', 200_new_cocm_init ))
call echo(build('200_new_cocm_ebts :', 200_new_cocm_ebts ))
call echo(build('200_new_cocm_psych:', 200_new_cocm_psych))
call echo(build('200_new_cocm_care :', 200_new_cocm_care ))
call echo(build('200_new_cocm_case :', 200_new_cocm_case ))
call echo(build('200_new_cocm_cont :', 200_new_cocm_cont ))
call echo(build('200_new_cocm_docu :', 200_new_cocm_docu ))
call echo(build('200_new_cocm_chart:', 200_new_cocm_chart))
call echo(build('200_new_cocm_coord:', 200_new_cocm_coord))
call echo(build('200_new_cocm_crisi:', 200_new_cocm_crisi))
call echo(build('200_new_cocm_disch:', 200_new_cocm_disch))
call echo(build('200_new_cocm_other:', 200_new_cocm_other))

call echo(build('4_CMRN    :', 4_CMRN    ))
call echo(build('331_PCP   :', 331_PCP   ))


set drec->line_count          = 0
set drec->status_data->status = "f"



select into "nl:"
       ROW_NUM            = 1
     , FIRST_DAY          = datetimefind(cnvtdatetime(curdate, 0), 'M', 'B', 'B')                     'DD-MMM-YYYY HH:MM:SS;;D'
     , LAST_DAY           = datetimefind(cnvtdatetime(curdate, 0), 'M', 'E', 'E')                     'DD-MMM-YYYY HH:MM:SS;;D'
     , LAST_DAY_LAST_MTH  =  datetimeadd(datetimefind(cnvtdatetime(curdate,2359), 'M', 'B', 'E'), -1) 'DD-MMM-YYYY HH:MM:SS;;D'
     , FIRST_DAY_LAST_MTH = datetimefind(cnvtlookbehind('1,M'), 'M', 'B', 'B')                          'DD-MMM-YYYY HH:MM:SS;;D'
     , Year_Month         = build2( year(cnvtlookbehind('1,M')),' ',
                                    evaluate( month(cnvtlookbehind('1,M'))
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
  from dummyt

head row_num
    first_day_cur_month   = first_day
    last_day_cur_month    = last_day
    last_day_last_month   = last_day_last_mth
    first_day_last_month  = first_day_last_mth

    vfirst_day_last_month = format(first_day_last_mth,  'DD-MMM-YYYY HH:MM;;D')
    vlast_day_last_month  = format(last_day_last_mth,   'DD-MMM-YYYY HH:MM;;D')

    yearmonth             = year_month

    output_rtf            = build2(output_rtf, wr, 'Monthly summary for: ', trim(yearmonth, 3))
WITH NOCOUNTER

/***********************************************************************
DESCRIPTION: GET PCP
***********************************************************************/
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
   where p.person_id              = personid

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


/***********************************************************************
DESCRIPTION: Get Billable CoCM Orders This Month
***********************************************************************/
select into 'nl:'
       order_date                      = format(o.orig_order_dt_tm,  '@SHORTDATE')
     , billable_cocm_orders_this_month = replace(o.order_mnemonic,'Amb CoCM ', '')
     , month_year                      = build2( datetimepart(cnvtdatetime(o.orig_order_dt_tm), 1), ' '
                                               , evaluate( month(o.orig_order_dt_tm)
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
  from orders       o
     , order_detail od

  plan o
   where o.person_id = personId
     ;and o.catalog_cd in( 200_cocmbi, 200_cocmcr, 200_cocmeo
     ;                   , 200_cocmia, 200_cocmoc, 200_cocmpc
     ;                   , 200_cocmrs, 200_cocmrt, 200_cocmrp
     ;                   , 200_cocmfm, 200_cocmsm, 200_cocmrc
     ;                   )
     and o.catalog_cd in( 200_new_cocm_init , 200_new_cocm_ebts , 200_new_cocm_psych
                        , 200_new_cocm_care , 200_new_cocm_case , 200_new_cocm_cont 
                        , 200_new_cocm_docu , 200_new_cocm_chart, 200_new_cocm_coord
                        , 200_new_cocm_crisi, 200_new_cocm_disch, 200_new_cocm_other
                        )

  join od
   where od.order_id = o.order_id
     and od.oe_field_id = 12620
     and ;(   o.orig_order_dt_tm      between cnvtdatetime(vfirst_day_last_month ) and cnvtdatetime(vlast_day_last_month)
         ; or 
            od.oe_field_dt_tm_value between cnvtdatetime(vfirst_day_last_month ) and cnvtdatetime(vlast_day_last_month)
         ;)

order by od.oe_field_dt_tm_value

head report
    index                 = 0
    stat                  = alterlist(cells->cells,2)
    cells->cells[1]->size = 1600
    cells->cells[2]->size = 6000

    ;-Create Table header
    rtf_table_ord = build2(rh2b, set_row_ord('Date','CoCM Activity'))
    rtf_table_ord = build2(rtf_table_ord, wr)

detail
    index = index + 1
    call echo(build(o.catalog_cd, ':', uar_get_code_display(o.catalog_cd)))
    case(o.catalog_cd)
    of 200_new_cocm_init:
        call echo('we hit initial')
        is_initial_assm = 'y'
        firstPassHr     = 70
        firstPasshalfHr = 36
        firstPassCPT    = '99492'
        firstPassDesc   = 'Initial psych care mgmt, 70 min/month - CoCM'
    endcase
    stat                                   = alterlist(cocm_orders->qual,index)
    cocm_orders->qual[index].order_date    = format(od.oe_field_dt_tm_value,'@SHORTDATE')
    cocm_orders->qual[index].billable_cocm = replace(o.order_mnemonic, 'Amb CoCM ', '')

    rtf_table_ord = notrim(build2( rtf_table_ord
                                 , set_row_ord(cocm_orders->qual[index].order_date, cocm_orders->qual[index].billable_cocm)
                                 )
                          )
with nocounter

/***********************************************************************
DESCRIPTION: Get Duration Logged
***********************************************************************/
call echo('mmmtest duration')
select into 'nl:'
       duration         = substring(1, 255, trim(ce4.result_val,3))
     , all_sum          = sum(cnvtint(ce4.result_val)) over( )
     , dat.result_dt_tm 'DD-MMM-YYYY HH:MM:SS;;D'
     , ce3.event_cd
     , uar_get_code_display(ce3.event_cd)

  from dcp_forms_activity      d
     , dcp_forms_activity_comp dfc
     , clinical_event          ce1
     , clinical_event          ce2
     , clinical_event          ce3
     , clinical_event          ce4
     , clinical_event          ce5
     , ce_date_result          dat

  plan d
   where d.person_id               =  personId
     and d.active_ind              =  1
     ;PROD
     and d.dcp_forms_ref_id        in ( 25562326477.0    ; CoCM Initial Visit
                                      , 17187876873.0    ; COCM Stop Time
                                      , 25562361699.0    ; CoCM Follow Up Visit
                                      , 27852023149.0    ; CoCM Non-Appointment Activity
                                     )
     ;BUILD
     ;and d.dcp_forms_ref_id        in ( 24202552913.0    ; CoCM Initial Visit
     ;                                 , 17187876873.0    ; COCM Stop Time
     ;                                 , 24202571835.0    ; CoCM Follow Up Visit
     ;                                 , 24216264555.0)   ; CoCM Non-Appointment Activity
     and d.form_status_cd          in (25.00, 34.00, 35.00)

  join dfc
   where dfc.dcp_forms_activity_id =  d.dcp_forms_activity_id; ( 6560997569.00,6560490443.00)
     and dfc.parent_entity_name    =  'CLINICAL_EVENT'

  join ce1
   where ce1.parent_event_id       =  dfc.parent_entity_id
     and ce1.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')

  join ce2
   where ce2.parent_event_id       =  ce1.event_id
     and ce2.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')
     and ce2.event_end_dt_tm between  cnvtdatetime('01-JAN-1970 0000') and cnvtdatetime(curdate,curtime3)
     and ce2.result_status_cd      in (25.00, 33.00, 35.00)

  join ce3
   where ce3.parent_event_id       =  ce2.event_id
     and ce3.view_level            =  1
     and ce3.valid_until_dt_tm     >=  cnvtdatetime(curdate,curtime3)
     And ce3.event_tag             != 'In Error'
     and ce3.event_cd              =  3181294825.00
     and ce3.task_assay_cd         in (3203364711, 3203352463)

  join ce4
   where ce4.parent_event_id       = ce2.event_id
     and ce4.task_assay_cd         = 3203364711.00
     and ce4.valid_until_dt_tm     = cnvtdatetime('31-DEC-2100 00:00:00.00')

  join ce5
   where ce5.parent_event_id       = ce2.event_id
     and ce5.task_assay_cd         =  3203364689.00 ;002 use stop time because it's on the same form segment of the new forms
     and ce5.valid_until_dt_tm     = cnvtdatetime('31-DEC-2100 00:00:00.00')

  join dat
   where dat.event_id              = ce5.event_id
     and dat.valid_until_dt_tm     = cnvtdatetime('31-DEC-2100 00:00:00.00');003
     and dat.result_dt_tm between cnvtdatetime(vFIRST_DAY_LAST_MONTH ) AND cnvtdatetime(vLAST_DAY_LAST_MONTH)

order by d.person_id, dat.result_dt_tm

head report
    index        = 1
    index2       = 1
    firstPassMet = 0

    stat = alterlist(COCM_DURATION->qual,index2)

    macro(save_userdefs)
        call echo('in macro')
        call echo(index2)
        call echo(build('d.dcp_forms_ref_id:', d.dcp_forms_ref_id))
        case (index2)
            of 1:
                call echo(build('totalDur:', totalDur))
                call echo(build('firstPassHr:', firstPassHr))
                if(totalDur >= firstPassHr)
                    call echo('>= firstPassHr')
                    COCM_DURATION->qual[index2].duration    = firstPassHr
                    COCM_DURATION->qual[index2].description = firstPassDesc
                    COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
                    COCM_DURATION->qual[index2].unit        = '1'
                    COCM_DURATION->qual[index2].cpt         = firstPassCPT

                    totalDur     = totalDur - firstPassHr
                    index2       = index2 + 1

                    firstPassMet = 1

                    stat = alterlist(COCM_DURATION->qual, index2)
                    
                    call echo(build('totalDur:', totalDur))

                    if(totalDur >= 30)
                        call echo('In firstpasshr, total dur greater than 30 after initial work.')
                        durationBalance = mod(totalDur, 30)

                        COCM_DURATION->qual[index2].duration    = totalDur - durationBalance
                        COCM_DURATION->qual[index2].description = 'initial/subsequent psych care mgmt, additional 30 min CoCM '
                        COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
                        COCM_DURATION->qual[index2].unit        = cnvtstring((totalDur - durationBalance)/30)
                        COCM_DURATION->qual[index2].cpt         = '99494'

                        totalDur = durationBalance
                        index2 = index2 + 1

                        stat = alterlist(COCM_DURATION->qual, index2)
                    endif
                else
                    call echo('In else of firstpasshour')
                    COCM_DURATION->qual[index2].duration    = totalDur
                    COCM_DURATION->qual[index2].description = 'Additional collaborative care '
                    COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
                    COCM_DURATION->qual[index2].unit        = '0'
                endif
            else
                call echo('in else of index2.')
                if(totalDur >= 30)
                    call echo('and we were greater than 30.')
                    durationBalance = mod(totalDur, 30)

                    COCM_DURATION->qual[index2].duration    = totalDur - durationBalance
                    COCM_DURATION->qual[index2].description = 'initial/subsequent psych care mgmt, additional 30 min CoCM '
                    COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
                    COCM_DURATION->qual[index2].unit        = cnvtstring((totalDur - durationBalance)/30)
                    COCM_DURATION->qual[index2].cpt         = '99494'

                    totalDur = durationBalance
                    index2 = index2 + 1

                    stat = alterlist(COCM_DURATION->qual, index2)
                endif
            endcase
            
        call echo('out macro')
    endmacro

head d.person_id
    index = 0
    totalDur = 0

detail
    index = index + 1
    stat = alterlist(COCM_DURATION->details, index)
    COCM_DURATION->details[index].activity_dt   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
    COCM_DURATION->details[index].activity_durr = ce4.result_val
    totalDur                                    = totalDur + cnvtint(ce4.result_val)
    save_userdefs

foot d.person_id
    call echo(build('firstPassMet:', firstPassMet))
    call echo(build('totalDur:', totalDur))
    call echo(build('firstPasshalfHr:', firstPasshalfHr))
    call echo(build('totalDur:', totalDur))
    call echo(build('firstPassHr:', firstPassHr))
    
    if(firstPassMet = 0 and totalDur >= firstPasshalfHr and totalDur < firstPassHr)
        call echo('in first foot if')
        COCM_DURATION->qual[index2].duration    = totalDur
        COCM_DURATION->qual[index2].description = firstPassDesc
        COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
        COCM_DURATION->qual[index2].unit        = '1'
        COCM_DURATION->qual[index2].cpt         = firstPassCPT

        totalDur = 0
    endif

    if(firstPassMet = 1 and totalDur >= 16 and totalDur < 30)
        call echo('in second foot if')
    
        ;check if the last record contains data
        if(textlen(COCM_DURATION->qual[index2].description)>0)
            index2 = index2 + 1
            stat = alterlist(COCM_DURATION->qual, index2)
        endif

        COCM_DURATION->qual[index2].duration    = totalDur
        COCM_DURATION->qual[index2].description = 'initial/subsequent psych care mgmt, additional 30 min CoCM '
        COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
        COCM_DURATION->qual[index2].unit        = '1'
        COCM_DURATION->qual[index2].cpt         = '99494'

        totalDur = 0
    endif

    if(firstPassMet = 0 and totalDur >= 16 and totalDur < firstPasshalfHr)
        call echo('in third foot if')
        
        COCM_DURATION->qual[index2].duration    = totalDur
        COCM_DURATION->qual[index2].description = 'Init/sub psych care m 1st 30'
        COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
        COCM_DURATION->qual[index2].unit        = '1'
        COCM_DURATION->qual[index2].cpt         = 'G2214'

        totalDur = 0
    endif

    index = index + 1
    stat = alterlist(COCM_DURATION->details, index)

    COCM_DURATION->details[index].activity_dt = 'Total'
    COCM_DURATION->details[index].activity_durr = cnvtstring(ALL_SUM)

    if(index2 > 0 and COCM_DURATION->qual[index2].cpt = '99494' and totalDur > 0 and mod(totalDur,30) <16)
        call echo('in fourth foot if')
        
        COCM_DURATION->qual[index2].duration = COCM_DURATION->qual[index2].duration - mod(totalDur,30)

        index2 = index2 + 1
        stat = alterlist(COCM_DURATION->qual, index2)

        COCM_DURATION->qual[index2].duration    = mod(totalDur,30)
        COCM_DURATION->qual[index2].description = 'Additional collaborative care -'
        COCM_DURATION->qual[index2].Date_time   = FORMAT(dat.result_dt_tm,  '@SHORTDATE')
        COCM_DURATION->qual[index2].unit        = '0'
    endif


    index2 = index2 + 1
    stat = alterlist(COCM_DURATION->qual, index2)

    COCM_DURATION->qual[index2].description = 'Total'
    COCM_DURATION->qual[index2].cpt         = ''
    COCM_DURATION->qual[index2].Date_time   = ''
    COCM_DURATION->qual[index2].unit        = ''
    COCM_DURATION->qual[index2].duration    = ALL_SUM
with  nocounter


/***********************************************************************
DESCRIPTION: Create Duration Logged as Table
***********************************************************************/
if(size(COCM_DURATION->details,5) >0)
    set stat                  = alterlist(cells->cells, 2)

    set cells->cells[1]->size = 1600
    set cells->cells[2]->size = 3000

    set rtf_table_dur2 = build2(rh2b, set_row_dur2("DATE", "DURATION"))
    set rtf_table_dur2 = build2(rtf_table_dur2, wr)

    for (cnt = 1 to size(cocm_duration->details, 5))
        set rtf_table_dur2 = notrim(build2( rtf_table_dur2
                                          , set_row_dur2( trim(cocm_duration->details[cnt].activity_dt  , 3)
                                                        , trim(cocm_duration->details[cnt].activity_durr, 3)
                                                        )
                                          )
                                   )
    endfor
endif

if(size(COCM_DURATION->qual,5) >0)
    set stat = alterlist(cells->cells, 5)

    set cells->cells[1]->size = 1000
    set cells->cells[2]->size = 1600
    set cells->cells[3]->size = 2600
    set cells->cells[4]->size = 8800
    set cells->cells[5]->size = 10000

    set rtf_table_dur         = build2(rh2b, set_row_dur("DATE", "CPT", "UNIT(S)", "DESCRIPTION", "DURATION"))
    set rtf_table_dur         = build2(rtf_table_dur, wr)

    for (cnt = 1 to size(cocm_duration->qual,5))
        set rtf_table_dur = notrim(build2( rtf_table_dur
                                         , set_row_dur( trim(cocm_duration->qual[cnt].date_time           ,3)
                                                      , trim(cocm_duration->qual[cnt].cpt                 ,3)
                                                      , trim(cocm_duration->qual[cnt].unit                ,3)
                                                      , trim(cocm_duration->qual[cnt].description         ,3)
                                                      , trim(cnvtstring(cocm_duration->qual[cnt].duration),3)
                                                      )
                                         )
                                   )
    endfor
endif


/***********************************************************************
DESCRIPTION: Presentation
***********************************************************************/
if(textlen(trim(rtf_table_dur,3)) >0 )
    set output_rtf = (build2(output_rtf, trim(rtf_table_dur,3)))
endif

if(textlen(trim(rtf_table_dur2,3)) >0 )
    set output_rtf =build2(output_rtf, "\plain \f1 \fs20 \b \ul \cb2 \pard\sl0 ", "Collaborative Care Time Detail:", reol
                                     , trim(rtf_table_dur2, 3)
                                     )
else
    set output_rtf =build2(output_rtf, wr, "No Collaborative Care time detail this period", reol)
endif

if(textlen(trim(rtf_table_ord,3)) >0 )
    set output_rtf = build2(output_rtf, "\plain \f1 \fs20 \b \ul \cb2 \pard\sl0 ", "Collaborative Care Activities:", reol
                                      , trim(rtf_table_ord,3)
                           )
else
    set output_rtf = build2(output_rtf, wr, "No Collaborative Care Activities this period", reol)
endif


set reply->text = build2(rhead,trim(output_rtf,3), rtfeof)

call echo(build2(rhead,trim(output_rtf,3), rtfeof))

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

subroutine set_row_dur2(col1_txt, col2_txt)
    declare row_string = vc
    set row_str = concat(
        rtf_row(cells, 1),
            rtf_cell(col1_txt, 0),
            rtf_cell(col2_txt, 1)
    )

    ;call echo(row_str)
    return (row_str)
end


call echorecord(mesqual)
call echorecord(cocm_orders)
call echorecord(cocm_duration)

end
go
