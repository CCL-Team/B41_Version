/*************************************************************************
 Program Title: PAWQ - Monthly Performance Summary

 Object name:   6_pawq_performance_sum_rpt
 Source file:   6_pawq_performance_sum_rpt.prg

 Purpose:       Gather information of activities performed in the PAWQ -
                Prior Authorization Work Queue Mpage

 Tables read:

 Executed from:

 Special Notes:



******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 11/19/2024 Michael Mayes        Pend   Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 6_pawq_performance_sum_rpt:dba go
create program 6_pawq_performance_sum_rpt:dba

prompt 
	  "Output to File/Printer/MINE" = "MINE"
	, "Start Date"                  = "SYSDATE"
	, "End Date"                    = "SYSDATE"
	, "Type"                        = "1"    ;1 is going to be report.  2 is going to be ops emailing with date determination below.

with OUTDEV, START_DT, END_DT, TYPE_FLAG




/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/


record data(
    1 cnt = i4
    1 qual[*]
        2 per_id              = f8
        2 enc_id              = f8
        2 ord_id              = f8
        2 source              = vc
        2 event_id            = f8
        2 sch_event_id        = f8
        2 serv_dt             = dq8
        2 serv_dt_txt         = vc

        2 per_name            = vc
        2 per_dob             = vc
        2 per_mrn             = vc

        2 order_name          = vc
        2 order_dt_tm         = dq8
        2 order_dt_txt        = vc
        2 order_loc           = vc

        2 perf_prov_id        = f8
        2 perf_prov           = vc
        2 perf_loc            = vc

        2 post_dt_tm          = dq8
        2 post_dt_txt         = vc

        2 auth_status         = vc
        2 auth_status_dt_tm   = dq8
        2 auth_status_dt_txt  = vc

        2 auth_comment        = vc
        2 auth_comment_dt_tm  = dq8
        2 auth_comment_dt_txt = vc

)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare beg_dt_tm  = dq8 with protect
declare end_dt_tm  = dq8 with protect

declare comment_cd = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    72, 'AMBSURGPROCPRIAUTHCOMMENTMP' ))
declare status_cd  = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    72, 'AMBSURGPROCPRIAUTHSTATUSMP'))

declare act_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd    = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd    = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))

declare pos        = i4  with protect, noconstant(0)
declare idx        = i4  with protect, noconstant(0)
/*
declare looper             = i4  with protect, noconstant(0)
*/

/*************************************************************
; DVDev Start Coding
**************************************************************/


if($type_flag = 2)  ;EMAILING OF REPORT
    set beg_dt_tm = datetimefind(cnvtdatetime(curdate, curtime3), 'M', 'B', 'B')  ; Find beginning of the month.
    set beg_dt_tm = datetimeadd( beg_dt_tm, -1)                                   ; Go back a day.
    set beg_dt_tm = datetimefind(beg_dt_tm, 'M', 'B', 'B')                        ; Find beginning of last month.
    
    set end_dt_tm = datetimefind(beg_dt_tm, 'M', 'E', 'E')                        ; End of that month we found.
    
    call echo(build('beg_dt_tm:', format(beg_dt_tm, '@SHORTDATETIME')))
    call echo(build('end_dt_tm:', format(end_dt_tm, '@SHORTDATETIME')))
    
    declare email_subject     = vc with protect, noconstant('PAWQ Monthly Report')
    declare email_body        = vc with protect, noconstant('')
    declare aix_command       = vc with protect, noconstant('')
    declare aix_cmdlen        = i4 with protect, noconstant(0)
    declare aix_cmdstatus     = i4 with protect, noconstant(0)
    declare production_domain = vc with protect,   constant('P41')
    declare email_address     = vc with protect, noconstant($outdev)
 
    set email_body = concat('6_pawq_performance_sum_rpt_', format(cnvtdatetime(curdate, curtime3),'YYYYMMDDhhmmss;;q'), ".dat")
 
    declare filename = vc
            with  noconstant(concat('6_pawq_performance_sum_rpt_',
                                  format(cnvtdatetime(curdate, curtime3), 'YYYYMMDDhhmmss;;Q'),
                                  trim(substring(3,3,cnvtstring(rand(0)))),     ;<<<< These 3 digits are random #s
                                  '.csv'))
 
    if ($type_flag = 2 and curdomain = production_domain)
        select into (value(email_body))
            build2( 'The PAWQ MONTHLY REPORT is attached to this email.'         , char(13), char(10), char(13), char(10)
                  , 'Date Range: ', format(beg_dt_tm, '@SHORTDATETIME') 
                  ,        ' to ' , format(end_dt_tm, '@SHORTDATETIME')          , char(13), char(10), char(13), char(10)
                  , 'Run date and time: '
                  , format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10)
                  )
 
        from dummyt
        with format, noheading
    endif
else

    set beg_dt_tm = cnvtdatetime($START_DT)
    set end_dt_tm = cnvtdatetime($END_DT)
    
    call echo(build('beg_dt_tm:', format(beg_dt_tm, '@SHORTDATETIME')))
    call echo(build('end_dt_tm:', format(end_dt_tm, '@SHORTDATETIME')))
endif


declare serv_loc_str = vc with protect, noconstant('')
select into 'nl:'
  from code_value cv1

 where cv1.code_set    =  220
   and cv1.cdf_meaning =  'ANCILSURG'
   and (   cv1.display = 'EN*'
        or cv1.display = 'OR*'
        or cv1.display = 'Cath*'
        or cv1.display = 'EP*'
        or cv1.display = 'TEE/Echo*'
        or cv1.display = 'Anes Remote - WHC'
       )
    
detail

    if(serv_loc_str = '') serv_loc_str = cnvtstring(cv1.code_value, 17, 1)
    else                  serv_loc_str = concat(serv_loc_str, ',', cnvtstring(cv1.code_value, 17, 1))
    endif
with nocounter



select into 'nl:'
  from sch_appt         sa
     , sch_event_attach sea
     , orders           o
     , encounter        e

 where sa.beg_dt_tm   between cnvtdatetime(beg_dt_tm)
                          and cnvtdatetime(end_dt_tm)
   and sa.schedule_seq = (select max(sa2.schedule_seq)
                           from sch_appt sa2
                          where sa2.sch_event_id = sa.sch_event_id
                         )
   and sa.sch_role_cd = 4572.00  ;Patient
   and parser(build('sa.appt_location_cd in (', serv_loc_str ,')'))

   and sea.sch_event_id        =  sa.sch_event_id
   and sea.attach_type_meaning =  'ORDER'

   and o.order_id              =  sea.order_id
   ;We got some logic now.  This used to just exclude the cancelled voided and discontinued.
   ;Now we want to let the canceled through if they have a sch_event Booking out there (not just a procedure).
   ;and o.order_status_cd    not in (2542.00, 2544.00, 2545.00)  ;Canceled, Voided, Discontinued.

   and (   (o.order_status_cd    not in (2542.00, 2544.00, 2545.00))  ;Canceled, Voided, Discontinued.
        or (o.order_status_cd  = 2542.00  ;Canceled
            and exists(select 'X'
                         from sch_event_action act
                        where act.sch_event_id        =  sea.sch_event_id
                          and act.sch_action_cd       =  4517.00  ;BOOK
                          and act.active_ind          =  1
                          and act.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
                      )
           )
       )

   and (   (o.originating_encntr_id > 0 and e.encntr_id = o.originating_encntr_id)
        or (o.originating_encntr_id = 0 and e.encntr_id = o.encntr_id)
       )

detail
    pos       = data->cnt + 1
    data->cnt = pos

    stat = alterlist(data->qual, pos)

    data->qual[pos]->per_id       = o.person_id
    data->qual[pos]->enc_id       = e.encntr_id
    data->qual[pos]->ord_id       = o.order_id
    
    ; Note to future me... this is a departure from the work queue.  I think it might be doing it, in a different way.
    if(sa.encntr_id >= 0.0)
        data->qual[pos]->enc_id = sa.encntr_id
    endif
    
    data->qual[pos]->serv_dt      = sa.beg_dt_tm
    data->qual[pos]->serv_dt_txt  = format(sa.beg_dt_tm, '@SHORTDATETIME')
    
    data->qual[pos]->source       = 'Initial Pop'

with nocounter


free record noApptEvents
record noApptEvents(
    1 cnt = i4
    1 qual[*]
        2 sch_event_id = f8
        2 order_id     = f8
)

/**********************************************************************
DESCRIPTION:  Gather events without an appointment.
***********************************************************************/
select into 'nl:'
  from sch_object       so
     , sch_entry        se
     , sch_event_attach sea
 where so.OBJECT_SUB_CD  = 625795.00  ;QUEUE
   and so.sch_object_id in ( 1273463.00  ;Unknown Request Queue
                           , 1113463.00  ;Surgery Request List - SMHC
                           , 2507529.00  ;Endoscopy Request List - FSH & HH
                           ,  907465.00  ;Endoscopy Request List - GSH & UMH
                           , 2507529.00  ;Endoscopy Request List - FSH & HH
                           , 1113463.00  ;Surgery Request List - SMHC
                           ,  907465.00  ;Endoscopy Request List - GSH & UMH
                           ,  907471.00  ;Endoscopy Request List - WHC
                           , 1057439.00  ;EP Request List - WHC
                           , 2509493.00  ;Surgery Request List - FSH & HH
                           ,  907493.00  ;Surgery Request List - GSH & UMH
                           ,  907495.00  ;Surgery Request List - GUH
                           , 2509493.00  ;Surgery Request List - FSH & HH
                           , 1111451.00  ;Surgery Request List - MMC
                           , 1113463.00  ;Surgery Request List - SMHC
                           ,  907493.00  ;Surgery Request List - GSH & UMH
                           ,  907499.00  ;Surgery Request List - WHC
                           , 2397495.00  ;Cardiology TEE Request List - WHC
                           )
   
   
   

   and se.queue_id       = so.sch_object_id
   and se.entry_state_cd = 653550.00  ;PENDING

   and se.earliest_dt_tm   between cnvtdatetime(beg_dt_tm)
                               and cnvtdatetime(end_dt_tm)

   and sea.sch_event_id = se.sch_event_id
detail
    noApptEvents->cnt = noApptEvents->cnt + 1

    stat = alterlist(noApptEvents->qual, noApptEvents->cnt)

    noApptEvents->qual[noApptEvents->cnt]->sch_event_id = se.sch_event_id
    noApptEvents->qual[noApptEvents->cnt]->order_id     = sea.order_id


with nocounter


select into 'nl:'
  from orders              o
     , order_detail        sdate
     , encounter           e
     , (dummyt d with seq = noApptEvents->cnt)

  plan d
   where noApptEvents->qual[d.seq]->order_id     > 0

  join o
   where o.order_id = noApptEvents->qual[d.seq]->order_id
     and o.activity_type_cd       =  720.00  ;SURGERY
     ;If an order is cancelled... we _DO_ want to see it if it got a SCH booking event (not just a procedure on surginet tables)
     and (   o.order_status_cd not in (2542.00, 2544.00, 2545.00)  ;Canceled, Voided, Discontinued.
          or (    o.order_status_cd = 2542.00  ;Canceled
              and exists(select 'X'
                           from sch_event_attach sea
                              , sch_event_action act
                          where sea.order_id            =  o.order_id
                            and sea.attach_type_meaning =  'ORDER'
                            and act.sch_event_id        =  sea.sch_event_id
                            and act.sch_action_cd       =  4517.00  ;BOOK
                            and act.active_ind          =  1
                            and act.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
                        )
             )
         )
     ; There is a chance that both encounter and originating encounter are not filled...
     ; not sure what to do about this.
     ;and (o.originating_encntr_id != 0 or o.encntr_id != 0)

   ;I have a strategy for the above now.  We'll let it join to zero... fill zero below, and try and correct this when seeing
   ;if it is tied to an appointment tied to an encounter.

  join sdate
   where sdate.order_id             =  o.order_id                                  
     and sdate.oe_field_id          =  12620.00                        ;REQSTARTDT
     and sdate.action_sequence      =  ( select max(odx2.action_sequence)          
                                         from order_detail odx2                    
                                        where odx2.order_id    =  sdate.order_id   
                                          and odx2.oe_field_id =  sdate.oe_field_id
                                       )                                           
     and sdate.oe_field_dt_tm_value between cnvtdatetime(beg_dt_tm)
                                        and cnvtdatetime(end_dt_tm)
    
    
  join e
   ;Trying to use originating encounter if I have it.  Otherwise just encounter
   where (   (o.originating_encntr_id > 0 and e.encntr_id = o.originating_encntr_id)
          or (o.originating_encntr_id = 0 and e.encntr_id = o.encntr_id)
         )

detail
    pos = locateval(idx, 1, data->cnt, o.order_id, data->qual[idx]->ord_id)

    if(pos = 0)
        call echo("We addin'")
        call echo(o.order_id)
        data->cnt = data->cnt + 1

        stat = alterlist(data->qual, data->cnt)

        data->qual[data->cnt]->ord_id  = o.order_id
        data->qual[data->cnt]->per_id  = o.person_id
        data->qual[data->cnt]->enc_id  = e.encntr_id
            
        data->qual[data->cnt]->serv_dt      = sdate.oe_field_dt_tm_value
        data->qual[data->cnt]->serv_dt_txt  = format(sdate.oe_field_dt_tm_value, '@SHORTDATETIME')
    
        data->qual[pos]->source       = 'No Appts'

    endif

with nocounter, expand = 1



/**********************************************************************
DESCRIPTION:  Find initial population
      NOTES:
***********************************************************************/
select into 'nl:'

  from clinical_event ce
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->ord_id >  0
     
  join ce
   where ce.order_id              =  data->qual[d.seq]->ord_id
     and ce.event_cd              in (status_cd)
     and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd      in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.event_end_dt_tm       in ( select max(ce2.event_end_dt_tm)
                                      from clinical_event ce2
                                     where ce2.encntr_id = ce.encntr_id
                                       and ce2.person_id = ce.person_id
                                       and ce2.order_id  = ce.order_id
                                       and ce2.event_cd  = ce.event_cd
                                  )

detail
    data->qual[d.seq]->event_id    = ce.event_id

    data->qual[d.seq]->auth_status        = trim(ce.result_val, 3)
    data->qual[d.seq]->auth_status_dt_tm  = ce.event_end_dt_tm
    data->qual[d.seq]->auth_status_dt_txt = format(ce.event_end_dt_tm, 'MM-DD-YYYY')

with nocounter




/**********************************************************************
DESCRIPTION:  Find Patient identifiers
      NOTES:
***********************************************************************/
select into 'nl:'

  from person p
     , encounter e
     , encntr_alias mrn
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->per_id >  0
     and data->qual[d.seq]->enc_id >  0

  join p
   where p.person_id               =  data->qual[d.seq]->per_id
     and p.active_ind              =  1
  
  join e
   where e.encntr_id = data->qual[d.seq]->enc_id

  join mrn
   where mrn.encntr_id              =  outerjoin(e.encntr_id)
     and mrn.encntr_alias_type_cd   =  outerjoin(1079.00)  ;MRN
     and mrn.active_ind             =  outerjoin(1)
     and mrn.beg_effective_dt_tm    <= outerjoin(cnvtdatetime(curdate, curtime3))
     and mrn.end_effective_dt_tm    >= outerjoin(cnvtdatetime(curdate, curtime3))

detail
    data->qual[d.seq]->per_name    =  trim(p.name_full_formatted, 3)
    data->qual[d.seq]->per_dob     =  format(p.birth_dt_tm, 'MM-DD-YYYY')
    data->qual[d.seq]->per_mrn     =  trim(mrn.alias, 3)

with nocounter


/**********************************************************************
DESCRIPTION:  Find Order Information
      NOTES:
***********************************************************************/
select into 'nl:'

  from orders o
     , encounter e
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->ord_id >  0

  join o
   where o.order_id                  =  data->qual[d.seq]->ord_id
   
  join e
   where (   (o.originating_encntr_id > 0 and e.encntr_id = o.originating_encntr_id)
          or (o.originating_encntr_id = 0 and e.encntr_id = o.encntr_id)
         )


detail
    data->qual[d.seq]->order_name    =  trim(o.order_mnemonic, 3)
    data->qual[d.seq]->order_dt_tm   =  o.orig_order_dt_tm
    data->qual[d.seq]->order_dt_txt  =  format(o.orig_order_dt_tm, 'MM/DD/YYYY')
    
    data->qual[d.seq]->order_loc     =  trim(uar_get_code_display(e.loc_facility_cd), 3)
    
with nocounter


/**********************************************************************
DESCRIPTION:  Find Posting Date
      NOTES:
***********************************************************************/
select into 'nl:'

  from sch_event_attach sea
     , sch_event_action act
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->ord_id >  0

  join sea
   where sea.order_id                =  data->qual[d.seq]->ord_id
     and sea.attach_type_meaning     =  'ORDER'

  join act
   where act.sch_event_id          =  outerjoin(sea.sch_event_id)
     and act.sch_action_cd         =  outerjoin(4517.00)  ;BOOK
     and act.active_ind            =  outerjoin(1)
     and act.end_effective_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))

order by act.sch_event_id, act.action_dt_tm desc

head act.sch_event_id

    data->qual[d.seq]->sch_event_id     = sea.sch_event_id
    data->qual[d.seq]->post_dt_tm       = act.action_dt_tm
    data->qual[d.seq]->post_dt_txt      = format(act.action_dt_tm, 'MM/DD/YYYY')

with nocounter


/**********************************************************************
DESCRIPTION:  Find Service Date
      NOTES:
***********************************************************************/
select into 'nl:'
  from order_detail loc
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->ord_id >  0

  join loc
   where loc.order_id            = data->qual[d.seq]->ord_id

     and loc.oe_field_id         =  3542632.00 ;SURGAREA
     ;and loc.oe_field_id         =  830792277.00 ;Surgical Area UDF
     and loc.action_sequence      =  ( select max(odx2.action_sequence)
                                         from order_detail odx2
                                        where odx2.order_id    =  loc.order_id
                                          and odx2.oe_field_id =  loc.oe_field_id
                                     )

detail
    data->qual[d.seq]->perf_loc = uar_get_code_display(loc.oe_field_value)

with nocounter


/**********************************************************************
DESCRIPTION:  Find Comment
      NOTES:
***********************************************************************/
select into 'nl:'

  from clinical_event   ce
     , ce_string_result csr
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->per_id >  0
     and data->qual[d.seq]->enc_id >  0
     and data->qual[d.seq]->ord_id >  0

  join ce
   where ce.person_id             =  data->qual[d.seq]->per_id
     and ce.encntr_id             =  data->qual[d.seq]->enc_id
     and ce.order_id              =  data->qual[d.seq]->ord_id
     and ce.event_cd              in (comment_cd)
     and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd      in (act_cd, mod_cd, auth_cd, altr_cd)

  join csr
   where csr.event_id            =  outerjoin(ce.event_id)
     and csr.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))

order by ce.order_id, ce.event_end_dt_tm desc

head ce.order_id

    data->qual[d.seq]->auth_comment        = replace(replace(trim(csr.string_result_text, 3), char(13), ''), char(10), '')
    data->qual[d.seq]->auth_comment_dt_tm  = ce.event_end_dt_tm
    data->qual[d.seq]->auth_comment_dt_txt = format(ce.event_end_dt_tm, 'MM-DD-YYYY')

with nocounter


/**********************************************************************
DESCRIPTION:  Find procedure provider
      NOTES:
***********************************************************************/
select into 'nl:'

  from surg_case_procedure scp
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->ord_id >  0

  join scp
   where scp.order_id = data->qual[d.seq]->ord_id
     and (   scp.primary_surgeon_id       > 0
          or scp.sched_primary_surgeon_id > 0
         )

detail

    if(scp.primary_surgeon_id > 0) data->qual[d.seq]->perf_prov_id = scp.primary_surgeon_id
    else                           data->qual[d.seq]->perf_prov_id = scp.sched_primary_surgeon_id
    endif

with nocounter


/**********************************************************************
DESCRIPTION:  Find procedure provider from order
      NOTES:
***********************************************************************/
select into 'nl:'

  from sch_appt prov
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                       >  0
     and data->qual[d.seq]->sch_event_id >  0
     and data->qual[d.seq]->perf_prov_id =  0  ;Only if we didn't find above.

  join prov
   where prov.sch_event_id = data->qual[d.seq]->sch_event_id
     and prov.sch_role_cd  = 667043.00  ;SURGEON1
     and prov.schedule_seq = (select max(sa2.schedule_seq)
                                from sch_appt sa2
                               where sa2.sch_event_id = prov.sch_event_id
                                 and sa2.sch_role_cd  = prov.sch_role_cd
                             )

detail

    data->qual[d.seq]->perf_prov_id = prov.person_id

with nocounter


/**********************************************************************
DESCRIPTION:  Lastly try and yank the order detail.
      NOTES:  There is a chance we don't have a procedure or appt yet to 
              fill this in.  PAWQ checks all these locs... in a bit 
              different manner, but the important part is that:
                proc is most important,
                followed by appt
                followed by OEF.
              I think I'm honoring that here.
***********************************************************************/
select into 'nl:'

  from orders o
     , order_detail prov
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                       >  0
     and data->qual[d.seq]->ord_id       >  0
     and data->qual[d.seq]->perf_prov_id =  0  ;Only if we didn't find above.
    
  join o
   where o.order_id = data->qual[d.seq]->ord_id

  join prov
   where prov.order_id            =  o.order_id
     and prov.oe_field_meaning_id =  3303.00
     and prov.action_sequence     =  ( select max(odx.action_sequence)
                                         from order_detail odx
                                        where odx.order_id            =  o.order_id
                                          and odx.oe_field_meaning_id =  prov.oe_field_meaning_id
                                          and odx.oe_field_meaning    =  prov.oe_field_meaning
                                      )


detail

    data->qual[d.seq]->perf_prov_id = prov.oe_field_value

with nocounter


/**********************************************************************
DESCRIPTION:  Find perf provider names
      NOTES:
***********************************************************************/
select into 'nl:'

  from prsnl p
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                       >  0
     and data->qual[d.seq]->perf_prov_id >  0  ;Only if we didn't find above.

  join p
   where p.person_id  = data->qual[d.seq]->perf_prov_id
     and p.active_ind = 1

detail

    data->qual[d.seq]->perf_prov = trim(p.name_full_formatted, 3)

with nocounter




;Presentation time
if($type_flag = 1)  ;REPORT
    if (data->cnt > 0)

        select into $outdev
               PAT_NAME          = trim(substring(1,  140, data->qual[d.seq].per_name           ))
             , DATE_OF_BIRTH     = trim(substring(1,   15, data->qual[d.seq].per_dob            ))
             , MRN               = trim(substring(1,   40, data->qual[d.seq].per_mrn            ))

             , ORD               = trim(substring(1,   40, data->qual[d.seq].order_name         ))
             , ORD_loc           = trim(substring(1,  100, data->qual[d.seq].order_loc          ))
             , ORD_DATE          = trim(substring(1,   40, data->qual[d.seq].order_dt_txt       ))

             , PERF_LOC          = trim(substring(1,  140, data->qual[d.seq].perf_loc           ))
             , SERV_DATE         = trim(substring(1,   20, data->qual[d.seq].serv_dt_txt        ))
             , PERF_PROV         = trim(substring(1,  140, data->qual[d.seq].perf_prov          ))

             , POST_DATE         = trim(substring(1,   40, data->qual[d.seq].post_dt_txt        ))

             , AUTH_STATUS_DATE  = trim(substring(1,  140, data->qual[d.seq].auth_status_dt_txt ))
             , AUTH_STATUS       = trim(substring(1,   40, data->qual[d.seq].auth_status        ))

             , AUTH_COMMENT_DATE = trim(substring(1,  140, data->qual[d.seq].auth_comment_dt_txt))
             , AUTH_COMMENT      = trim(substring(1,   40, data->qual[d.seq].auth_comment       ))

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
else  ;OPS
    if (data->cnt > 0)
        select into value(FILENAME)
                   PAT_NAME          = trim(substring(1,  140, data->qual[d.seq].per_name           ))
                 , DATE_OF_BIRTH     = trim(substring(1,   15, data->qual[d.seq].per_dob            ))
                 , MRN               = trim(substring(1,   40, data->qual[d.seq].per_mrn            ))

                 , ORD               = trim(substring(1,   40, data->qual[d.seq].order_name         ))
                 , ORD_loc           = trim(substring(1,  100, data->qual[d.seq].order_loc          ))
                 , ORD_DATE          = trim(substring(1,   40, data->qual[d.seq].order_dt_txt       ))

                 , PERF_LOC          = trim(substring(1,  140, data->qual[d.seq].perf_loc           ))
                 , SERV_DATE         = trim(substring(1,   20, data->qual[d.seq].serv_dt_txt        ))
                 , PERF_PROV         = trim(substring(1,  140, data->qual[d.seq].perf_prov          ))

                 , POST_DATE         = trim(substring(1,   40, data->qual[d.seq].post_dt_txt        ))

                 , AUTH_STATUS_DATE  = trim(substring(1,  140, data->qual[d.seq].auth_status_dt_txt ))
                 , AUTH_STATUS       = trim(substring(1,   40, data->qual[d.seq].auth_status        ))

                 , AUTH_COMMENT_DATE = trim(substring(1,  140, data->qual[d.seq].auth_comment_dt_txt))
                 , AUTH_COMMENT      = trim(substring(1,   40, data->qual[d.seq].auth_comment       ))
          
          from (dummyt d with SEQ = data->cnt)
        with heading, pcformat('"', ',', 1), format=stream, format,  nocounter , compress

    else
       select into value(FILENAME)
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
 
 
    ;***********EMAIL THE ACTUAL ZIPPED FILE****************************
    if(curdomain = production_domain)  ;only email out of p41
 
        set aix_command  =
            build2('cat ', email_body ,' | tr -d \\r',
                   " | mailx  -S from='report@medstar.net' -s '" , email_subject, "' -a ", filename, " ", email_address)
 
        set aix_cmdlen = size(trim(aix_command))
        set aix_cmdstatus = 0
        call echo(aix_command)
        call dcl(aix_command,aix_cmdlen, aix_cmdstatus)
 
        call pause(2);LETS SLOW THINGS DOWN
 
        set  aix_command  =
            concat('rm -f ', filename,  ' | rm -f ', email_body)
 
        set aix_cmdlen = size(trim(aix_command))
        set aix_cmdstatus = 0
 
        call echo(aix_command)
        call dcl(aix_command,aix_cmdlen, aix_cmdstatus)
    endif



endif



/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;DEBUGGING
;call echorecord(data)
declare looper = i4

for(looper = 1 to data->cnt)
    if(data->qual[looper].per_name = '')
        call echorecord(data->qual[looper])
    endif
endfor


end
go




