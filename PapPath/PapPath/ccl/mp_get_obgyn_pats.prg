/**************************************************************************
 Program Title:   mPage get obgyn specimen order pats

 Object name:     mp_get_obgyn_pats
 Source file:     mp_get_obgyn_pats.prg

 Purpose:         Gets a list of patients, qualifying with the drop down filters
                  and the corresponding information needed by the page

 Tables read:

 Executed from:   MPage

 Special Notes:

***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 02/27/2018 Michael Mayes        210739    Initial release
002 12/14/2018 Michael Mayes                  Removing cancelled orders
003 08/27/2024 Michael Mayes        239854    Adding filter for provider
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mp_get_obgyn_pats:dba go
create program mp_get_obgyn_pats:dba


prompt
    "Output to File/Printer/MINE" = "MINE",   ;* Enter or select the printer or file name to send this report to.
    "Organization"   = 0.0,  ;003
    "Start Date"     = "",
    "End Date"       = "",  
    "Providers"      = ""   ;003

with OUTDEV, orgs, beg_range, end_range
   , providers       ;003



/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record obgyn_pats
record obgyn_pats(
    1 cnt                 = i4
    1 pat[*]
        2 enc_id          = f8
        2 per_id          = f8
        2 name            = vc
        2 fin             = vc
        2 order
            3 order_id    = f8
            3 prsnl_id    = f8
            3 prsnl_name  = vc
            3 date        = vc
            3 dq_date     = dq8
            3 name        = vc
            3 status      = vc
        2 result
            3 event_id    = f8
            3 turn_tm     = vc
            3 receive_ind = i2
            3 date        = vc
        2 endorse
            3 prsnl_name  = vc
            3 date        = vc
    1 overdue_cnt         = i4
    1 overdue_per         = i4
    1 average_turn        = i4
%i cust_script:mmm_mp_status.inc
)

free record orders
record orders(
    1 cnt            = i4
    1 qual[*]
        2 ord_cd   = f8
)

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare start_dt_tm = dq8 with protect, constant(cnvtdatetime($beg_range))
declare end_dt_tm   = dq8 with protect, constant(cnvtdatetime($end_range))

declare FIN_NBR     = f8 with protect, constant(uar_get_code_by('MEANING'   ,  319, 'FIN NBR'))
declare PAP_DX      = f8 with protect, constant(uar_get_code_by('DISPLAYKEY',   72, 'APCLINICIANPROVIDEDICD10'))

declare auth_cd     = f8 with protect, constant(uar_get_code_by('DISPLAYKEY',    8, 'AUTHVERIFIED'))
declare modified_cd = f8 with protect, constant(uar_get_code_by('MEANING'   ,    8, 'MODIFIED'))
declare altered_cd  = f8 with protect, constant(uar_get_code_by('MEANING'   ,    8, 'ALTERED'))

declare cancel_cd   = f8 with protect, constant(uar_get_code_by('MEANING'   , 6004, 'CANCELED'))
declare delete_cd   = f8 with protect, constant(uar_get_code_by('MEANING'   , 6004, 'DELETED'))

declare endorse_cd  = f8 with protect, constant(uar_get_code_by('MEANING'   ,   21, 'ENDORSE'))

declare day_num     = i4 with protect, noconstant(0)

declare tot_day     = i4 with protect, noconstant(0)
declare res_cnt     = i4 with protect, noconstant(0)

declare idx         = i4 with protect, noconstant(0)
declare looper      = i4 with protect, noconstant(0)


/**************************************************************
; DVDev Start Coding
**************************************************************/


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/



/***********************************************************************
DESCRIPTION:  Gather orders, pulling their names and ids
***********************************************************************/
;TODO I don't think I'm gathering orders right at this point... maybe I should just hit synoymn somehow
select into 'nl:'
  from order_catalog oc
 where (oc.primary_mnemonic = 'AptmPap*'
        or (oc.primary_mnemonic = 'Pap*' and oc.primary_mnemonic != 'Pap Stain*')
        or oc.primary_mnemonic = 'PAP *'
        or oc.primary_mnemonic = 'Herpes Simples Virus 1/2 DNA*'
        or oc.primary_mnemonic = 'Aptm CT/NG NAA (LabCorp Only)'
        or oc.primary_mnemonic = 'Aptm CT/NG/TV NAA (LabCorp Only)'
        or oc.primary_mnemonic = 'Chlamydia/Gonorrhoeae nucleic acid amplification'
        or oc.primary_mnemonic = 'Vaginitis (BV, Candida, Trich) PCR'
        or oc.primary_mnemonic = 'Vaginitis Plus (BV, Candida, Trich, CT/NG) PCR'
        or oc.primary_mnemonic = 'Culture, Bact, Genital'
        or oc.primary_mnemonic = 'Culture, Viral, HSV Reflex to Typing'
        or oc.primary_mnemonic = 'Vaginitis Plus (BV, Candida, Trich, CT/NG) PCR'
        or oc.primary_mnemonic = 'HPV HR (Cobas) w/HPV 16/18, Rectal'
        or oc.primary_mnemonic = 'Herpes Simples Virus 1/2 DNA, Real-Time PCR, Pap Vial (Quest Only)'
       )
detail
    orders->cnt = orders->cnt + 1

    stat = alterlist(orders->qual, orders->cnt)

    orders->qual[orders->cnt]->ord_cd = oc.catalog_cd

with format, separator = " "

call echorecord(orders)

if(size(orders->qual, 5) > 0)
    /***********************************************************************
    DESCRIPTION:  Find Patients at a location
    ***********************************************************************/
    select into 'nl:'
      
      from person       p
         , encounter    e
         , encntr_alias ea
         , orders       o
         , prsnl        pr
         , order_action oa
         
     where e.organization_id          in ($ORGS)  ;003
       and e.reg_dt_tm                >= cnvtdatetime(start_dt_tm)
       and e.reg_dt_tm                <= cnvtdatetime(end_dt_tm)
      
       and expand(idx, 1, size(orders->qual, 5), o.catalog_cd, orders->qual[idx]->ord_cd)
       and o.orig_order_dt_tm         >= cnvtdatetime(start_dt_tm)
       and o.orig_order_dt_tm         <= cnvtdatetime(end_dt_tm)
       and (   o.encntr_id            =  e.encntr_id
            or o.encntr_id            =  0.0)                        ;Maybe we should join to order_detail to get the encounter ID?
       and o.person_id                =  e.person_id
       and o.last_update_provider_id  =  pr.person_id
       and o.order_status_cd          not in (cancel_cd, delete_cd) ;002
       
       and oa.order_id                =  o.order_id      ;003
       and oa.action_type_cd          =  2534.0 ; order  ;003
       and (   0                    in ($providers)      ;003
            or oa.order_provider_id in ($providers)      ;003
           )
           
       and e.person_id                =  p.person_id     
      
       and ea.encntr_id               =  e.encntr_id
       and ea.encntr_alias_type_cd    =  FIN_NBR
    order by p.name_full_formatted, o.orig_order_dt_tm desc
    head report
        obgyn_pats->cnt = 0

    head o.order_id

        obgyn_pats->cnt = obgyn_pats->cnt + 1

        if (mod(obgyn_pats->cnt, 100) = 1)
            stat = alterlist(obgyn_pats->pat, obgyn_pats->cnt + 100)
        endif

        obgyn_pats->pat[obgyn_pats->cnt].enc_id = e.encntr_id
        obgyn_pats->pat[obgyn_pats->cnt].per_id = p.person_id
        obgyn_pats->pat[obgyn_pats->cnt].name   = trim(p.name_full_formatted, 3)
        obgyn_pats->pat[obgyn_pats->cnt].fin    = trim(ea.alias, 3)

        obgyn_pats->pat[obgyn_pats->cnt].order->order_id   = o.order_id
        obgyn_pats->pat[obgyn_pats->cnt].order->prsnl_id   = oa.order_provider_id
        obgyn_pats->pat[obgyn_pats->cnt].order->prsnl_name = trim(pr.name_full_formatted, 3)
        obgyn_pats->pat[obgyn_pats->cnt].order->date       = format(o.orig_order_dt_tm, "MM-DD-YYYY HH:MM:SS")
        obgyn_pats->pat[obgyn_pats->cnt].order->dq_date    = o.orig_order_dt_tm
        obgyn_pats->pat[obgyn_pats->cnt].order->name       = trim(uar_get_code_description(o.catalog_cd), 3)
        obgyn_pats->pat[obgyn_pats->cnt].order->status     = trim(uar_get_code_display(o.order_status_cd), 3)

        ;If this order is >= 7 days old, initialize the result flag to 0 (for sorting) otherwise 1.
        ;This will show a normal x (1) if we are under
        ;And show a critical icon (0) if we are over
        if(o.orig_order_dt_tm < cnvtlookbehind("7 D"))
            obgyn_pats->pat[obgyn_pats->cnt]->result->receive_ind = 0
        else
            obgyn_pats->pat[obgyn_pats->cnt]->result->receive_ind = 1
        endif

    foot report

        stat = alterlist(obgyn_pats->pat, obgyn_pats->cnt)
    with nocounter
endif


if(size(obgyn_pats->pat, 5) > 0)

    /***********************************************************************
    DESCRIPTION:  Find Result tied to the orders already found
    ***********************************************************************/
    select into 'nl:'
      from clinical_event ce,
           (dummyt d with seq = value(size(obgyn_pats->pat, 5)))
     plan d
      where obgyn_pats->pat[d.seq]->enc_id > 0
     join ce
      where ce.encntr_id         = obgyn_pats->pat[d.seq]->enc_id
        and ce.order_id          = obgyn_pats->pat[d.seq]->order->order_id
        and ce.parent_event_id   = ce.event_id
        and ce.result_status_cd  in (auth_cd, modified_cd, altered_cd)
        and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
    order by ce.encntr_id, ce.valid_from_dt_tm
    detail

        obgyn_pats->pat[d.seq]->result->event_id = ce.event_id

        obgyn_pats->pat[d.seq]->result->receive_ind = 2

        ;I don't know if it is better to do this on the frontend or backend, I guess it doesn't matter
        day_num = datetimediff(ce.valid_from_dt_tm, obgyn_pats->pat[d.seq].order->dq_date)

        if(day_num = 1)
            obgyn_pats->pat[d.seq]->result->turn_tm = concat(trim(cnvtstring(day_num), 3), " day")
        else
            obgyn_pats->pat[d.seq]->result->turn_tm = concat(trim(cnvtstring(day_num), 3), " days")
        endif

        res_cnt = res_cnt + 1
        tot_day = tot_day + day_num

        obgyn_pats->pat[d.seq]->result->date        = format(ce.valid_from_dt_tm, "MM-DD-YYYY HH:MM:SS")
    with nocounter


    ;Compute average turn around
    set obgyn_pats->average_turn = tot_day / res_cnt

    ;Find total of over due (couldn't do this above, since it relied on two queries to finalize)
    for(looper = 1 to size(obgyn_pats->pat, 5))
        if(obgyn_pats->pat[looper]->result->receive_ind = 0)
            set obgyn_pats->overdue_cnt = obgyn_pats->overdue_cnt + 1
        endif
    endfor


    ;Compute overdue percent
    set obgyn_pats->overdue_per = cnvtint(round(cnvtreal(obgyn_pats->overdue_cnt) / cnvtreal(size(obgyn_pats->pat, 5)), 2) * 100)


    /***********************************************************************
    DESCRIPTION:  Find Endorsement tied to the result if already found
    ***********************************************************************/
    select into 'nl:'
      from ce_event_prsnl cep,
           clinical_event ce,
           prsnl p,
           (dummyt d with seq =value(size(obgyn_pats->pat, 5)))
     plan d
      where obgyn_pats->pat[d.seq]->enc_id > 0
        and obgyn_pats->pat[d.seq]->result->event_id > 0
     join ce
      where ce.encntr_id         = obgyn_pats->pat[d.seq]->enc_id
        and ce.order_id          = obgyn_pats->pat[d.seq]->order->order_id
        and ce.result_status_cd  in (auth_cd, modified_cd, altered_cd)
        and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
     join cep
      where cep.event_id          = ce.event_id
        and cep.action_type_cd    = endorse_cd
        and cep.valid_until_dt_tm > sysdate
     join p
      where p.person_id = cep.action_prsnl_id
    order by cep.action_dt_tm
    detail

        obgyn_pats->pat[d.seq]->endorse->prsnl_name = trim(p.name_full_formatted, 3)
        obgyn_pats->pat[d.seq]->endorse->date       = format(cep.action_dt_tm, "MM-DD-YYYY HH:MM:SS")

    with nocounter

endif

#exit_script

call echorecord(obgyn_pats)

if(size(obgyn_pats->pat,5) > 0)
    set obgyn_pats->status_data->status = "S"
else
    set obgyn_pats->status_data->status = "Z"
endif


call putRSToFile($outdev, obgyn_pats)


end
go

