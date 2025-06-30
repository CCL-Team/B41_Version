/*************************************************************************
 Program Title: Request by Queue Oncology

 Object name:   14_onc_sch_req_queue_rep
 Source file:   14_onc_sch_req_queue_rep.prg

 Purpose:       Gather choice data from a scheduling report run from sch_app_book
                in order to be able to print off the report.

                "Request List Inquiry/Schedule Inquiry Request by Queue-Oncology
                 in the MedConnect Scheduling App."
 Tables read:

 Executed from:

 Special Notes: This sucker in the app looks like it is built out by CCL.  But it
                is weird custom.  Maybe.  Had to translate it at least, so that
                is annoying.  That object is kb_schq_wcomments_v2.prg


******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 08/19/2022 Michael Mayes        234018 Initial release
002 12/15/2022 German Perez			236038 ADD fields Order DateTime bw order and earliest dates
003 08/30/2023 Michael Mayes		231394 Add new order detail for additional spec inst
004 06/25/2025 MIchael Mayes        PEND   Trying a correction here...
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_onc_sch_req_queue_rep:dba go
create program 14_onc_sch_req_queue_rep:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Begin Date"                = "SYSDATE"
	, "End Date"                  = "SYSDATE"
	, "Request Queue"             = 0
	, "Enter Provider Last Name"  = ""
	;<<hidden>>"Search"           = ""
	, "Provider"                  = VALUE(-1) 

with OUTDEV, BEG_DT, END_DT, REQ_QUEUE, PRSNL_SEARCH, PROV_ID


/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        ;debugging
        2 pat_id         = f8
        
        ;for joins
        2 sch_event_id   = f8
        2 schedule_seq   = i4
        2 sch_id         = f8
        2 prot_flag      = i4
        2 parent_id      = f8
        2 ord_id         = f8
        2 ord_prov_id    = f8
        
        2 ord_cnt        = i4
        2 ords[*]
            3 ord_id     = f8
            3 desc       = vc
            3 seq        = i4
        
        ;data
        2 pat_name       = vc
        2 req_action     = vc
        2 appt_type      = vc
        2 earliest_dt    = vc
        2 sch_dt_tm      = vc
        2 pp_ref         = vc
        2 pp_sch_phase   = vc
        2 ord_prov       = vc
        2 orders         = vc
        2 spec_inst      = vc
        2 add_spec_inst  = vc  ;003
        2 pp_activity    = vc
        2 order_date     = vc
        2 earliest_dt_tm = dq8
        2 time_bw_ord_dt_earliest_dt = vc

    ;more debugging?
    1 max_ord      = i4
)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare pend_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING', 23018, 'PENDING'       ))
declare ord_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING', 16110, 'ORDER'         ))

declare ord_ord_cd      = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'ORDER'         ))
declare ord_mod_cd      = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'MODIFY'        ))
declare ord_coll_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'COLLECTION'    ))
declare ord_renew_cd    = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'RENEW'         ))
declare ord_act_cd      = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'ACTIVATE'      ))
declare ord_fut_dc_cd   = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'FUTUREDC'      ))
declare ord_res_ren_cd  = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6003, 'RESUME/RENEW'  ))

/*
declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))
*/

/*
declare pos                = i4  with protect, noconstant(0)
declare idx                = i4  with protect, noconstant(0)

*/
declare looper  = i4  with protect, noconstant(0)
declare looper2 = i4  with protect, noconstant(0)

/*************************************************************
; DVDev Start Coding
**************************************************************/

/**********************************************************************
DESCRIPTION: Gather pending patients from schedule queue
      NOTES: 
***********************************************************************/
select into 'nl:'
  from sch_entry        a
     , sch_event_action sea  ;004
     , sch_event        e
     , person           p
 where a.queue_id        in ($req_queue)
   and a.entry_state_cd  =  pend_cd
   and a.earliest_dt_tm  between cnvtdatetime($beg_dt) and cnvtdatetime($end_dt)
   
   and sea.sch_action_id =  a.sch_action_id
   and sea.version_dt_tm =  cnvtdatetime("31-DEC-2100 00:00:00.00")
  
   and e.sch_event_id    =  a.sch_event_id
   and e.version_dt_tm   =  cnvtdatetime("31-DEC-2100 00:00:00.00")
   
   and p.person_id       =  a.person_id
order by a.sch_action_id  ;004

head a.sch_action_id      ;004
    data->cnt = data->cnt + 1
    
    if(mod(data->cnt, 20) = 1)
        stat = alterlist(data->qual, data->cnt + 19)
    endif
    
    ;debugging
    data->qual[data->cnt]->pat_id        = a.person_id
    
    ;for later queries
    data->qual[data->cnt]->sch_event_id  = a.sch_event_id
    data->qual[data->cnt]->schedule_seq  = e.schedule_seq  ;For the record... this looks like 1 most the time.
    data->qual[data->cnt]->sch_id        = a.schedule_id
    
    data->qual[data->cnt]->prot_flag     = e.protocol_type_flag
    if(e.protocol_type_flag = 1)
        data->qual[data->cnt]->parent_id = e.sch_event_id
    endif
    
    ;data
    data->qual[data->cnt]->pat_name    = trim(p.name_full_formatted, 3)
    data->qual[data->cnt]->earliest_dt = format(a.earliest_dt_tm, '@SHORTDATE')
    data->qual[data->cnt]->earliest_dt_tm = a.earliest_dt_tm 
    data->qual[data->cnt]->req_action  = uar_get_code_display(a.req_action_cd),
    data->qual[data->cnt]->appt_type   = uar_get_code_display(e.appt_synonym_cd)
    
foot report
    stat = alterlist(data->qual, data->cnt)

with nocounter


/*  This... I'm trying to piece together a bit.  It looks like
    the example script does a double hit, depending on if the 
    protocol type flag above was set or not.  Looks like it 
    mostly is set... but I have no idea if that is the norm
    or not so still doing it like the parent script is.
*/
/**********************************************************************
DESCRIPTION: Gather order data for protocol_parent_id > 0
      NOTES: TODO I have no idea if this works yet.  Looks like we don't
             have parents on my current list
***********************************************************************/
select into 'nl:'
  from sch_event e
     , sch_event_attach a
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->parent_id >  0
  
  join e
   where e.protocol_parent_id         =  data->qual[d.seq]->parent_id
     and e.sch_meaning            not in ("CANCELED", "NOSHOW")
     and e.version_dt_tm              =  cnvtdatetime("31-DEC-2100 00:00:00.00")
  
  join a
   where a.sch_event_id               =  e.sch_event_id
     and a.attach_type_cd             =  ord_cd
     and a.beg_schedule_seq           <= data->qual[d.seq]->schedule_seq
     and a.end_schedule_seq           >= data->qual[d.seq]->schedule_seq
     and a.order_status_meaning   not in ("CANCELED", "COMPLETED", "DISCONTINUED")
     and a.state_meaning              != "REMOVED"
     and a.version_dt_tm              =  cnvtdatetime("31-DEC-2100 00:00:00.00")
     and a.active_ind                 =  1

order by d.seq
       , e.protocol_seq_nbr
       , a.order_seq_nbr

head d.seq
   data->qual[d.seq]->ord_cnt = 0
   
detail
    data->qual[d.seq]->ord_cnt = data->qual[d.seq]->ord_cnt + 1
    
    if(mod(data->qual[d.seq]->ord_cnt, 10) = 1)
        stat = alterlist(data->qual[d.seq]->ords, data->qual[d.seq]->ord_cnt + 9)
    endif
    
    data->qual[d.seq]->ords[data->qual[d.seq]->ord_cnt]->ord_id = a.order_id
    data->qual[d.seq]->ords[data->qual[d.seq]->ord_cnt]->desc   = a.description
    data->qual[d.seq]->ords[data->qual[d.seq]->ord_cnt]->seq    = a.order_seq_nbr

foot d.seq
    stat = alterlist(data->qual[d.seq]->ords, data->qual[d.seq]->ord_cnt)
    
    if(data->max_ord < data->qual[d.seq]->ord_cnt)
        data->max_ord = data->qual[d.seq]->ord_cnt
    endif

with nocounter


/**********************************************************************
DESCRIPTION: Gather order data for protocol_parent_id <= 0
      NOTES: 
***********************************************************************/
select into 'nl:'
  from sch_event_attach a
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                       >  0
     and data->qual[d.seq]->sch_event_id >  0
  
  join a
   where a.sch_event_id                  =  data->qual[d.seq]->sch_event_id
     and a.attach_type_cd                =  ord_cd
     and a.beg_schedule_seq              <= data->qual[d.seq]->schedule_seq
     and a.end_schedule_seq              >= data->qual[d.seq]->schedule_seq
     and a.order_status_meaning      not in ("CANCELED", "COMPLETED", "DISCONTINUED")
     and a.state_meaning                 != "REMOVED"
     and a.version_dt_tm                 =  cnvtdatetime("31-DEC-2100 00:00:00.00")
     and a.active_ind                    =  1

order by d.seq
       , a.order_seq_nbr

head d.seq
   data->qual[d.seq]->ord_cnt = 0
   
detail
    data->qual[d.seq]->ord_cnt = data->qual[d.seq]->ord_cnt + 1
    
    if(mod(data->qual[d.seq]->ord_cnt, 10) = 1)
        stat = alterlist(data->qual[d.seq]->ords, data->qual[d.seq]->ord_cnt + 9)
    endif
    
    data->qual[d.seq]->ords[data->qual[d.seq]->ord_cnt]->ord_id = a.order_id
    data->qual[d.seq]->ords[data->qual[d.seq]->ord_cnt]->desc   = a.description
    data->qual[d.seq]->ords[data->qual[d.seq]->ord_cnt]->seq    = a.order_seq_nbr

foot d.seq
    stat = alterlist(data->qual[d.seq]->ords, data->qual[d.seq]->ord_cnt)
    
    if(data->max_ord < data->qual[d.seq]->ord_cnt)
        data->max_ord = data->qual[d.seq]->ord_cnt
    endif

with nocounter


/**********************************************************************
DESCRIPTION: Gather scheduled_date if it exists.
      NOTES: 
***********************************************************************/
select into 'nl:'
  t_sort = evaluate(a.role_meaning, "PATIENT", 2, a.primary_role_ind)
  
  from sch_appt a
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                       >  0
     and data->qual[d.seq]->sch_event_id >  0
     and data->qual[d.seq]->sch_id       >  0
  
  join a
   where a.sch_event_id  = data->qual[d.seq]->sch_event_id
     and a.schedule_id   = data->qual[d.seq]->sch_id
     and a.version_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")

order by d.seq, t_sort

detail
    data->qual[d.seq]->sch_dt_tm = format(a.beg_dt_tm, '@SHORTDATETIME')
    
with nocounter


/*  They did this in a million dummyts.  I also am a dummyt, so 
    I'm going to do it in a more... dummy way.
*/

for(looper = 1 to data->cnt)
    for(looper2 = 1 to data->qual[looper]->ord_cnt)

        /**********************************************************************
        DESCRIPTION: Gather order information based on above.
              NOTES: TODO I feel like I might be doing something off here... 
                     If there are multiple orders... what the heck are we supposed
                     to do.  I think that the overwrites?
                     
                     They act like they might get a OD action_seq not equal to the
                     oa action_seq.  Not sure how that is possible either.
                     
                     I'm thinking now that sometimes the orders don't fully qualify
                     below... which filters them there... we reset some stuff
                     in the example script... so I'm going to pull them out
                     for the report in a similar manner.
        ***********************************************************************/
        select into 'nl:'
          from orders       o
             , order_action oa
             , order_detail od
         
         where o.order_id             =  data->qual[looper]->ords[looper2]->ord_id
         
           and oa.order_id            =  o.order_id
           and oa.action_type_cd      in ( ord_ord_cd    , ord_mod_cd, ord_coll_cd
                                         , ord_renew_cd  , ord_act_cd, ord_fut_dc_cd
                                         , ord_res_ren_cd
                                         )
           and oa.action_rejected_ind =  0
        
           and od.order_id            =  oa.order_id
           and od.action_sequence     =  oa.action_sequence
           and od.oe_field_meaning_id in ( 3521  ; PowerPlan Reference
                                         , 3523  ; PowerPlan Scheduled Phase
                                         , 3519  ; PowerPlan Activity
                                         
                                         ; Maybe don't need these
                                         ;, 127   ; Priority
                                         ;, 3520  ; PowerPlan Phase Activity
                                         ;, 3522  ; PowerPlan Phase Reference
                                         ;, 12    ; Isolation Code
                                         )
        order by o.order_id
               , od.oe_field_id
               , od.action_sequence DESC
        
        head o.order_id
            data->qual[looper]->ord_id = data->qual[looper]->ords[looper2]->ord_id
            data->qual[looper]->orders = data->qual[looper]->ords[looper2]->desc
            data->qual[looper]->order_date = format(o.orig_order_dt_tm, ";;d")
        
        detail
            case(od.oe_field_meaning_id)
            of 3521: data->qual[looper]->pp_ref       = trim(od.oe_field_display_value, 3)
            of 3523: data->qual[looper]->pp_sch_phase = trim(od.oe_field_display_value, 3)
            of 3519: data->qual[looper]->pp_activity  = trim(od.oe_field_display_value, 3)
            endcase
        foot o.order_id
        	data->qual[looper]->time_bw_ord_dt_earliest_dt = 
        		format(DATETIMEDIFF(data->qual[looper].earliest_dt_tm, o.orig_order_dt_tm), "DD days HH hours MM min;;Z")
        with nocounter
    
        /**********************************************************************
        DESCRIPTION: Gather order special instructions
              NOTES: 
        ***********************************************************************/
        select into "nl:"
          from order_detail od
                       
         
         where od.order_id        =  data->qual[looper]->ords[looper2]->ord_id
           and od.oe_field_id     in ( 258409528.00    ; Special Instructions
                                     , 4534419959.00 ) ; Add Special Instructions ;TODO might need prod translate.  ;003
           and od.action_sequence =  (select max(action_sequence)
                                        from order_detail x
                                       where x.order_id    = od.order_id
                                         and x.oe_field_id = od.oe_field_id
                                     )
           
        detail
            ;003 reworking all this a bit.
            case(od.oe_field_id)
            of 258409528:
                data->qual[looper]->spec_inst = trim(od.oe_field_display_value, 3)
            of 4534419959:
                if(data->qual[looper]->add_spec_inst = '')
                    data->qual[looper]->add_spec_inst = trim(od.oe_field_display_value, 3)
                else
                    data->qual[looper]->add_spec_inst = build2( data->qual[looper]->add_spec_inst, '; '
                                                              , trim(od.oe_field_display_value, 3))
                endif
            endcase
            
            
        with nocounter


        /**********************************************************************
        DESCRIPTION: Gather order provider
              NOTES: Should be safe to start being dumb... I hope.
        ***********************************************************************/
        select into "nl:"
          from order_action oa
             , prsnl p
             
         where oa.order_id          =  data->qual[looper]->ords[looper2]->ord_id
           and oa.order_provider_id >  0
           
           and p.person_id          =  oa.order_provider_id
        
        order by oa.action_sequence desc
        head report
            data->qual[looper]->ord_prov    = trim(p.name_full_formatted, 3)
            data->qual[looper]->ord_prov_id = p.person_id

        with nocounter
          
    endfor
endfor


;Presentation time
if (data->cnt > 0)
   select into $OUTDEV
          PATIENT_NAME                             = trim(substring(1,  50, data->qual[d.seq].pat_name                      ))
        , ACTION                                   = trim(substring(1,  50, data->qual[d.seq].req_action                    ))
        , APPT_TYPE                                = trim(substring(1, 100, data->qual[d.seq].appt_type                     ))
        , EARLIEST_DATE                            = trim(substring(1,  20, data->qual[d.seq].earliest_dt                   ))
        , SCHEDULED_DATE                           = trim(substring(1,  20, data->qual[d.seq].sch_dt_tm                     ))
        , POWERPLAN_REF                            = trim(substring(1, 100, data->qual[d.seq].pp_ref                        ))
        , POWERPLAN_SCH_PHASE                      = trim(substring(1,  50, data->qual[d.seq].pp_sch_phase                  ))
        , ORDERING_PROV                            = trim(substring(1,  50, data->qual[d.seq].ord_prov                      ))
        , ORDER_DATE	                           = trim(substring(1,  50, data->qual[d.seq].order_date                    ))
        , TIME_BW_ORDERDATE_AND_EARLIESTDATE       = trim(substring(1,  50, data->qual[d.seq].time_bw_ord_dt_earliest_dt    ))
        , ORDERS                                   = trim(substring(1, 100, data->qual[d.seq].orders                        ))
        , SPEC_INSTRUCT                            = trim(substring(1, 255, data->qual[d.seq].spec_inst                     ))
        , ADD_SPEC_INSTRUCT                        = trim(substring(1, 255, data->qual[d.seq].add_spec_inst                 ))
        , POWERPLAN_ACTIVITY                       = trim(substring(1, 100, data->qual[d.seq].pp_activity                   ))
        , sch_event_id        = data->qual[d.seq].sch_event_id
      from (dummyt d with SEQ = data->cnt)
      plan d
       where (   -1 in ($prov_id)
              or data->qual[d.seq].ord_prov_id in ($prov_id)
             )
    order by EARLIEST_DATE, PATIENT_NAME
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
call echorecord(data)

for(looper = 1 to data->cnt)
    if(data->qual[looper]->sch_id > 0)
        call echorecord(data->qual[looper])
    endif
endfor

;select into 'nl:'
;  from (dummyt d with seq = data->cnt)
;  plan d
;   ;where data->qual[d.seq]->parent_id != data->qual[d.seq]->sch_event_id
;   where data->qual[d.seq]->schedule_seq != 1
;detail
;    call echorecord(data->qual[d.seq])
;with nocounter

end
go



