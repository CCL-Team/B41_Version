/*************************************************************************
 Program Title:   CC Medication Inotrope Vasopressor Contin

 Object name:     5_st_cc_ino_vaso
 Source file:     5_st_cc_ino_vaso.prg

 Purpose:         This ST is supposed to be a subset of the 5_st_cc_inpat_meds, pulling only
                  the currently specific inotrope active IV meds from it.
                  
                  This will be used in autotext (.medicationInotropeVasopressorContinCritCare)
                  supposedly as a ST too...
                  Also in the note Consultation Note – Shock Team Activation (Cardiogenic Shock)
                  
                  In the ST they don't want the header... and no nodata message.
                  
                  and in the Autotext they want a header if we have data.
                  
                  To facilitate this, I'm wrapping this ST with another script,
                  and adding the header if we need it.
                  
                  Wrapper is 5_st_cc_cont_inf_all_auto.

 Tables read:

 Executed from:

 Special Notes:

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-06-05 Michael Mayes        241764 Initial (This was copied from 5_st_cc_inpat_meds at this time, then adjusted.)
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 5_st_cc_ino_vaso:dba go
create program 5_st_cc_ino_vaso:dba

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

free record catalog_codes
record catalog_codes(
    1 cnt          = i4
    1 qual[*]
        2 cat_cd   = f8
        2 cat_name = vc
)


free record iv_meds
record iv_meds (
    1 cnt                    = i4
    1 list [* ]
        2 order_id           = f8
        2 generic            = vc
        2 name               = vc
        2 strength_dose      = vc
        2 strength_dose_unit = vc
        2 volume_dose        = vc
        2 volume_dose_unit   = vc
        2 route              = vc
        2 rate               = vc
        2 rate_units         = vc
        2 free_txt_rate      = vc
        2 rate_chg_ind       = i2
        2 beg_bag_ind        = i2
        2 display_line       = vc
)

free record pt
record pt (
    1 line_cnt = i4
    1 lns[*]
        2 line = vc
)

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare floatToStringTrimZeros(float_val   = f8)                 = vc with protect


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare mf8_orderedCd     = f8 with          noconstant(uar_get_code_by("DISPLAY_KEY",  6004, "ORDERED"    ))

declare mf8_pharmacyCd    = f8 with          noconstant(uar_get_code_by("DISPLAY_KEY",  6000, "PHARMACY"   ))

declare mf8_orderCd       = f8 with          noconstant(uar_get_code_by("DISPLAY_KEY",  6003, "ORDER"      ))
declare mf8_modifyCd      = f8 with          noconstant(uar_get_code_by("DISPLAY_KEY",  6003, "MODIFY"     ))
declare mf8_renewCd       = f8 with          noconstant(uar_get_code_by("DISPLAY_KEY",  6003, "RENEW"      ))

declare mf8_ivOrderCd     = f8 with          noconstant(uar_get_code_by("DISPLAY_KEY", 18309, "IV"         ))

declare modifiedCd        = f8 with  public,   constant(uar_get_code_by(    "MEANING",     8, "MODIFIED"   ))
declare authverifyCd      = f8 with  public,   constant(uar_get_code_by(    "MEANING",     8, "AUTH"       ))

declare placeholderCd     = f8 with  public,   constant(uar_get_code_by(    "MEANING",    53, "PLACEHOLDER"))

declare ratechangeCd      = f8 with  public,   constant(uar_get_code_by("DISPLAY_KEY",   180, "RATECHANGE" ))
declare beginbagCd        = f8 with  public,   constant(uar_get_code_by("DISPLAY_KEY",   180, "BEGINBAG"   ))

declare orderName         = vc
declare resultVal         = vc
declare administeredVal   = vc

declare primary_cd        = f8 with protect,   constant(uar_get_code_by(    "MEANING",  6011, "PRIMARY"    ))
declare line_length       = i4 with protect,   constant(80)

declare mother_milk_cd    = f8 with protect,   constant( 38253550.00)
declare donor_milk_cd     = f8 with protect,   constant(384502275.00)
declare zerohour_cd       = f8 with protect,   constant(uar_get_code_by("DISPLAY_KEY",   200, "ZEROHOUR"))

declare dose_temp         = vc with protect, noconstant('')
declare name_temp         = vc with protect, noconstant('')


declare pos               = i4 with protect, noconstant(0)
declare idx               = i4 with protect, noconstant(0)

/**************************************************************
; DVDev Start Coding
**************************************************************/

/***********************************************************************
DESCRIPTION: Gather Categories
      NOTES: Inotropic Agents, and Vasopressors
***********************************************************************/
select into 'nl:'
      oc_catalog_disp = uar_get_code_display(oc.catalog_cd)

 from mltm_drug_categories    mdc
    , mltm_category_drug_xref m
    , order_catalog           oc

where mdc.multum_category_id in (50, 54)

  and m.multum_category_id   =  mdc.multum_category_id

  and oc.cki                 =  concat("MUL.ORD!", m.drug_identifier)
  and oc.active_ind          =  1

order by oc.catalog_cd

head oc.catalog_cd

    pos = catalog_codes->cnt + 1

    catalog_codes->cnt = pos

    stat = alterlist(catalog_codes->qual, pos)

    catalog_codes->qual[pos]->cat_cd   = oc.catalog_cd
    catalog_codes->qual[pos]->cat_name = oc.description

with nocounter


/***********************************************************************
DESCRIPTION: Gather Vasopressin
      NOTES: Not sure why this isn't a vasopressor, but they call it out
             in specs as being seporate too.
***********************************************************************/
select into 'nl:'

  from order_catalog           oc

 where cnvtupper(description) = '*VASOPRESSIN*'
   and active_ind = 1
   and catalog_type_cd = 2516.0 ;Pharm

detail

    pos = catalog_codes->cnt + 1

    catalog_codes->cnt = pos

    stat = alterlist(catalog_codes->qual, pos)

    catalog_codes->qual[pos]->cat_cd   = oc.catalog_cd
    catalog_codes->qual[pos]->cat_name = oc.description

with nocounter


call echorecord(catalog_codes)



/***********************************************************************
DESCRIPTION: Obtain IV Meds
***********************************************************************/
select into 'nl:'
    order_mnemonic = trim(cnvtupper(o.hna_order_mnemonic))
  from orders                   o
     , order_ingredient         oi
     , order_detail            od
     , order_action            oa
     , encounter                e
plan o
 where o.encntr_id             =  request->visit[1].encntr_id
   and o.order_status_cd       =  mf8_orderedCd
   and o.active_ind            =  1
   and o.template_order_flag   in (0,1,2)
   and o.catalog_type_cd       =  mf8_pharmacyCd
   and o.catalog_cd            not in (zerohour_cd, mother_milk_cd, donor_milk_cd)
   and o.order_mnemonic        != '*patch*removal*'
   and o.med_order_type_cd     =  mf8_ivOrderCd
   and not (o.orig_ord_as_flag in (1,2))
   and o.iv_ind                =  1
   and o.prn_ind               =  0
   and o.suspend_ind           =  0
   and o.discontinue_ind       =  0
join oi
 where oi.order_id = o.order_id
   and expand(idx, 1, catalog_codes->cnt, oi.catalog_cd, catalog_codes->qual[idx]->cat_cd)
join e
 where e.encntr_id             =  o.encntr_id
   and e.active_ind            =  1
   and e.beg_effective_dt_tm   <= cnvtdatetime(curdate,curtime3)
   and e.end_effective_dt_tm   >  cnvtdatetime(curdate,curtime3)
join oa
 where oa.order_id             =  o.order_id
   and oa.action_type_cd       in (mf8_orderCd,mf8_modifyCd,mf8_renewCd)
join od
 where od.order_id             =  oa.order_id
   and od.action_sequence      >  0
   and od.detail_sequence      >  0
order by
      order_mnemonic
    , o.order_id
    , oa.action_sequence desc
    , od.oe_field_meaning
    , od.action_sequence desc
head report
    ivCnt = 0

head o.order_id
    if(mod(ivCnt,10) = 0)
        stat = alterlist(iv_meds->list,(ivCnt + 10))
    endif

    ivCnt = ivCnt + 1
    iv_meds->list[ivCnt].order_id = o.order_id

    iv_meds->list[ivCnt].name = trim(o.hna_order_mnemonic)

head od.oe_field_meaning
    case(od.oe_field_meaning)
    of "FREETXTDOSE"     : iv_meds->list[ivCnt].strength_dose      = trim(od.oe_field_display_value,3)
    of "STRENGTHDOSE"    : iv_meds->list[ivCnt].strength_dose      = trim(od.oe_field_display_value,3)
    of "STRENGTHDOSEUNIT": iv_meds->list[ivCnt].strength_dose_unit = trim(od.oe_field_display_value,3)
    of "VOLUMEDOSE"      : iv_meds->list[ivCnt].volume_dose        = trim(od.oe_field_display_value,3)
    of "VOLUMEDOSEUNIT"  : iv_meds->list[ivCnt].volume_dose_unit   = trim(od.oe_field_display_value,3)
    of "RXROUTE"         : iv_meds->list[ivCnt].route              = trim(od.oe_field_display_value,3)
    of "RATE"            : iv_meds->list[ivCnt].rate               = trim(od.oe_field_display_value,3)
    of "RATEUNIT"        : iv_meds->list[ivCnt].rate_units         = trim(od.oe_field_display_value,3)
    of "FREETEXTRATE"    : iv_meds->list[ivCnt].free_txt_rate      = trim(od.oe_field_display_value,3)
    endcase


foot report
    iv_meds->cnt = ivCnt
    stat = alterlist(iv_meds->list, ivCnt)

with nocounter


if(iv_meds->cnt > 0)

    /***********************************************************************
    DESCRIPTION: Check IV for current dose
          NOTES: tons of debugging because this thing is nasty.
    ***********************************************************************/
    select into 'nl:'
      from (dummyt d with seq = iv_meds->cnt)
         , clinical_event  ce
         , orders           o
         , ce_med_result  cmr
      plan d
      join ce
       where ce.order_id           =  iv_meds->list[d.seq].order_id
         and ce.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
         and ce.result_status_cd   in (modifiedCd, authverifyCd)
         and ce.event_class_cd     != placeholderCd
         and ce.event_end_dt_tm    =  (select max(ce2.event_end_dt_tm)
                                         from clinical_event ce2
                                            , ce_med_result  cmr2
                                        where ce2.order_id = ce.order_id
                                          and ce2.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
                                          and ce2.result_status_cd   in (modifiedCd,authverifyCd)
                                          and ce2.event_class_cd     != placeholderCd
                                          and cmr2.event_id          =  ce2.event_id
                                          and cmr2.iv_event_cd       in (ratechangeCd, beginbagCd)
                                          and cmr2.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
                                      )
      join o
       where o.order_id            =  ce.order_id
      join cmr
       where cmr.event_id          =  ce.event_id
         and cmr.iv_event_cd       in (ratechangeCd, beginbagCd)
         and cmr.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
    order by
         d.seq
       , ce.parent_event_id
       , ce.event_end_dt_tm desc
       , ce.collating_seq
       , cmr.diluent_type_cd
    head d.seq
        iv_meds->list[d.seq].rate_chg_ind = 1
        orderInfoCnt                      = 0
        orderName                         = ''
        resultVal                         = ''
        administeredVal                   = ''

    detail
        call echo(uar_get_code_display(cmr.iv_event_cd))
        call echo(build('Detail for:', iv_meds->list[d.seq].order_id))
        if(cmr.iv_event_cd = ratechangeCd)
            if(ce.event_cd != 679984.00)
                call echo('ce.event_cd != 679984.00')

                if(ce.event_tag != '*NOT VALUED*' and textlen(trim(ce.event_tag,3)) > 0)
                    if(findstring(trim(ce.event_tag,3), trim(uar_get_code_display(ce.event_cd),3)) = 0);The name isn't the same
                        call echo("ce.event_tag != '*NOT VALUED*' and textlen(trim(ce.event_tag,3)) > 0")
                        call echo('name diff')
                        call echo(ce.event_tag)
                        call echo(build('event_id:', ce.event_id))

                        if(cmr.infusion_rate > 0)
                            resultVal = build2('[',trim(ce.event_tag,3),']')
                        endif
                    else
                        call echo('name same')
                        resultVal = ''
                    endif

                else
                    call echo('failed not valued check')
                    resultVal = ''
                endif

                if(orderInfoCnt = 0)
                    call echo('orderInfoCnt = 0')
                    orderName = build2(trim(uar_get_code_display(ce.event_cd),3),' '
                                      ,trim(cnvtstring(format(cmr.initial_dosage,'###############.##')),3),' '
                                      ,trim(uar_get_code_display(cmr.dosage_unit_cd),3), ' '
                                      ,trim(resultVal,3)
                                      )
                    call echo(orderName)
                else
                    call echo('orderInfoCnt != 0')
                    orderName = build2(orderName,' + ',trim(uar_get_code_display(ce.event_cd),3),' '
                                                      ,trim(cnvtstring(format(cmr.initial_dosage,'###############.##')),3),' '
                                                      ,trim(uar_get_code_display(cmr.dosage_unit_cd),3)
                                                      ;,trim(resultVal,3)
                                                      )
                    call echo(orderName)
                endif
                orderInfoCnt = orderInfoCnt + 1 ;additive so need the '+'
            else
                call echo('ce.event_cd = 679984.00')
                administeredVal = trim(ce.event_tag,3)
                call echo(administeredVal)
            endif

        elseif(cmr.iv_event_cd = beginbagCd)
            if(ce.event_cd != 679984.00)
                call echo('ce.event_cd != 679984.00')
                ;I have no idea if this is possible with begin bags... but it doesn't hurt to add it.
                if(ce.event_tag != '*NOT VALUED*' and textlen(trim(ce.event_tag,3)) > 0)
                    if(findstring(trim(ce.event_tag,3), trim(uar_get_code_display(ce.event_cd),3)) = 0);The name isn't the same
                        call echo("ce.event_tag != '*NOT VALUED*' and textlen(trim(ce.event_tag,3)) > 0")
                        call echo('name diff')
                        call echo(ce.event_tag)

                        ;apparently... we can get a 9 documented on infusion rate here... I'm going to try a last ditch effort of
                        ; using the ordered rate.  And if we don't even find that... don't show a rate.

                        if(cmr.infusion_rate > 0)
                            resultVal = build2( '['
                                              , floatToStringTrimZeros(cmr.infusion_rate)
                                              ,' '
                                              , trim(uar_get_code_display(cmr.infusion_unit_cd),3)
                                              ,']')
                        elseif(iv_meds->list[d.seq].rate > ' ')
                            resultVal = ''
                            administeredVal = build2(iv_meds->list[d.seq].rate
                                                    , ' '
                                                    , iv_meds->list[d.seq].rate_units)
                        elseif(iv_meds->list[d.seq].free_txt_rate > ' ')
                            ;PCA will dup on us in route and freetext rate.
                            call echo('Free text route')
                            call echo(build('iv_meds->list[d.seq].free_txt_rate:', iv_meds->list[d.seq].free_txt_rate))
                            call echo(build('iv_meds->list[d.seq].route:', iv_meds->list[d.seq].route))
                            if(iv_meds->list[d.seq].free_txt_rate != iv_meds->list[d.seq].route)
                                resultVal = ''
                                administeredVal = iv_meds->list[d.seq].free_txt_rate
                            endif
                        else
                            resultVal = ''
                        endif
                    else
                        call echo('name same')
                        resultVal = ''
                    endif
                else
                    call echo('failed not valued check')
                    call echo(ce.event_tag)
                    resultVal = ''
                endif

                if(orderInfoCnt = 0)
                    call echo('orderInfoCnt = 0')
                    orderName = build2(trim(uar_get_code_display(ce.event_cd),3),' '
                                      ,trim(cnvtstring(format(cmr.initial_dosage,'###############.##')),3),' '
                                      ,trim(uar_get_code_display(cmr.dosage_unit_cd),3), ' '
                                      ,trim(resultVal,3)
                                      )
                    call echo(orderName)
                else
                    call echo('orderInfoCnt != 0')
                    orderName = build2(orderName,' + ',trim(uar_get_code_display(ce.event_cd),3),' '
                                                      ,trim(cnvtstring(format(cmr.initial_dosage,'###############.##')),3),' '
                                                      ,trim(uar_get_code_display(cmr.dosage_unit_cd),3)
                                                      ;,trim(resultVal,3)
                                                      )
                    call echo(orderName)
                endif
                orderInfoCnt = orderInfoCnt + 1 ;additive so need the '+'
            ;else
            ;    call echo('ce.event_cd = 679984.00')
            ;    administeredVal = trim(ce.event_tag,3)
            ;    call echo(administeredVal)
            endif
        endif

    foot d.seq
        ;if(orderInfoCnt > 1)
            call echo('FINAL')
            call echo(build('o.order_id:', o.order_id))
            call echo(build('ce.event_id:', ce.event_id))
            call echo(trim(orderName,3))
            call echo(trim(administeredVal,3))
            call echo('---')
        ;endif

        iv_meds->list[d.seq].name = build2(trim(orderName,3)
                                          ;,', ',trim(administeredVal,3)
                                          ,', ',iv_meds->list[d.seq].route
                                          )

        call echo('foot')
        call echo(iv_meds->list[d.seq].name)
        ;This is probably a dumb way to do this, but going to try...
        ;  Conversations during this work say that if we don't have a normalized dosing rate ie [.24 mcg/kg/min]
        ;  We should list out the mL/Hr rate.  I think this is what I was hiding in the administered value.  So I'm going
        ;  to do a dumb check for the rate using a find string on [
        if(findstring('[', iv_meds->list[d.seq].name) = 0)
            call echo('foot if')
            call echo(administeredVal)
            if(administeredVal > '')
                iv_meds->list[d.seq].name = build2(iv_meds->list[d.seq].name
                                                  ,', ',trim(administeredVal,3)
                                               ;,', ',iv_meds->list[d.seq].route  This is almost certainly going to dup everyt time.
                                                  )
            endif
            call echo(iv_meds->list[d.seq].name)
        endif

    with nocounter


    /***********************************************************************
    DESCRIPTION: Check IV for begin bag
          NOTES: We want to drop the rate if we don't have a begin bag.
    ***********************************************************************/
    select into 'nl:'
      from (dummyt d with seq = iv_meds->cnt)
         , clinical_event  ce
         , orders           o
         , ce_med_result  cmr
      plan d
      join ce
       where ce.order_id           =  iv_meds->list[d.seq].order_id
         and ce.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
         and ce.result_status_cd   in (modifiedCd, authverifyCd)
         and ce.event_class_cd     != placeholderCd
      join o
       where o.order_id            =  ce.order_id
      join cmr
       where cmr.event_id          =  ce.event_id
         and cmr.iv_event_cd       in (beginbagCd)
         and cmr.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
    detail
        iv_meds->list[d.seq].beg_bag_ind = 1
    with nocounter
endif



;display smart template output
if(iv_meds->cnt    = 0)

    set reply->text = build2(rhead, reol)

else
    set totalMedCnt = iv_meds->cnt
    set reply->text = build2(rhead)

    declare dosevar = vc
    declare disp_var = vc

    ;display continuous meds
    if(iv_meds->cnt != 0)
        for(ivMedIdx = 1 to iv_meds->cnt)

            set dosevar = " "

            set stat = initrec(pt)

            if(iv_meds->list[ivMedIdx].rate_chg_ind = 1);only display updated name when rate change occured
                set iv_meds->list[ivMedIdx].display_line = iv_meds->list[ivMedIdx].name

                execute dcp_parse_text value(iv_meds->list[ivMedIdx].display_line), value(line_length)
            else

                if(iv_meds->list[ivMedIdx].strength_dose > " ")
                    set dosevar = build2(iv_meds->list[ivMedIdx].strength_dose," ",iv_meds->list[ivMedIdx].strength_dose_unit)
                elseif(iv_meds->list[ivMedIdx].volume_dose > " ")
                    set dosevar = build2(iv_meds->list[ivMedIdx].volume_dose," ",iv_meds->list[ivMedIdx].volume_dose_unit)
                endif

                set iv_meds->list[ivMedIdx].display_line = iv_meds->list[ivMedIdx].name

                set dose_temp = replace(cnvtupper(dosevar)                     , ',', '')
                set name_temp = replace(cnvtupper(iv_meds->list[ivMedIdx].name), ',', '')

                if( findstring(dose_temp, name_temp) = 0)
                    set iv_meds->list[ivMedIdx].display_line = build2(iv_meds->list[ivMedIdx].name, " ",dosevar)
                endif

                if(iv_meds->list[ivMedIdx].route > " ")
                    set iv_meds->list[ivMedIdx].display_line = build2(iv_meds->list[ivMedIdx].display_line,", ",
                                                                      iv_meds->list[ivMedIdx].route)
                endif

                if(iv_meds->list[ivMedIdx].beg_bag_ind = 1)
                    if(iv_meds->list[ivMedIdx].rate > ' ')
                        set iv_meds->list[ivMedIdx].display_line = build2(iv_meds->list[ivMedIdx].display_line,", ",
                                                                          iv_meds->list[ivMedIdx].rate, ' ',
                                                                          iv_meds->list[ivMedIdx].rate_units)
                    elseif(iv_meds->list[ivMedIdx].free_txt_rate > ' ')
                        set iv_meds->list[ivMedIdx].display_line = build2(iv_meds->list[ivMedIdx].display_line,", ",
                                                                          iv_meds->list[ivMedIdx].free_txt_rate)
                    endif
                else
                    ;If we didn't have a begin bag... we want to rip the rate off the order name.  This is nasty.

                    declare start_pos    = i4
                    declare end_pos      = i4
                    declare string_start = vc
                    declare string_end   = vc

                    set start_pos = findstring('[', iv_meds->list[ivMedIdx].display_line) - 1

                    if(start_pos > 0)
                        set end_pos   = findstring(']', iv_meds->list[ivMedIdx].display_line) + 1

                        if(end_pos > 0)
                           ; call echo('!!!')

                            set string_start = substring(1, start_pos, iv_meds->list[ivMedIdx].display_line)

                           ; call echo(string_start)

                            set string_end = substring( end_pos, size(iv_meds->list[ivMedIdx].display_line, 3) + 1 - end_pos
                                                      , iv_meds->list[ivMedIdx].display_line)

                           ; call echo(string_end)

                           ; call echo(iv_meds->list[ivMedIdx].display_line)
                           ; call echo(build2(string_start, string_end))

                           set iv_meds->list[ivMedIdx].display_line = build2(string_start, string_end)
                        endif
                    endif
                endif

            endif

            execute dcp_parse_text value(iv_meds->list[ivMedIdx].display_line), value(line_length)

            for(lineIdx = 1 to pt->line_cnt)
                if(lineIdx = 1)
                    set reply->text = build2(reply->text,wr,pt->lns[lineIdx].line)
                else
                    set reply->text = build2(reply->text,reol,wr,pt->lns[lineIdx].line)
                endif
            endfor


            set reply->text = build2(reply->text ,reol)
        endfor

        set reply->text = build2(reply->text ,reol);add space b/w each med category
    endif



endif


/***********************************************************************
NAME:                  floatToStringTrimZeros

DESCRIPITON:           CCL doesn't have a great way to trim trailing zeros from floats, this should do that.

PARAMETER DESCRIPTION: float_val (f8): float value to be converted.

RETURN:                ret_str (vc):   Float converted to string with no trailing zeros,
                                       no "xxx.0" if whole
                                       and 0.xxxx if < 1 (still with no trailing zeros)

NOTES:                 I stole this from 6_st_crit_io_result_7days, and modified it but uCern had the same steps.
                       I can't believe that CCL doesn't have this functionality, it has to be common.  But I
                       couldn't find anything that would work between cnvtstring and format.
************************************************************************/
subroutine floatToStringTrimZeros(float_val)

    declare ret_str = vc with protect, noconstant(trim(cnvtstring(float_val, 30, 6), 3))

    declare pos1 = I4 with protect, noconstant(findstring('.', ret_str))
    declare pos2 = I4 with protect, noconstant(0)

    if (pos1 = 0)
        return (ret_str)
    endif

    if (pos1 = 1)
        set ret_str = concat('0', ret_str)
        set pos1 = pos1 + 1
    endif

    set pos2 = size(ret_str)
    while ((pos2 >= pos1) and ((substring(pos2, 1, ret_str) = '0') or (substring(pos2, 1, ret_str) = '.'))
        and (movestring(' ', 1, ret_str, pos2, 1) != 0))
        set pos2 = pos2 - 1
    endwhile

    set ret_str = trim(ret_str, 3)

    return (ret_str)

end ;RemoveTrailingZeros


#exit_script


call echojson(iv_meds)

;call echorecord(reply)

set reply->status_data->status = "S"
set reply->text = build2(reply->text, rtfeof)



end
go
