/*************************************************************************
 Program Title: CCM Billing Report
 
 Object name:   14_st_ccm_bill_rpt
 Source file:   14_st_ccm_bill_rpt.prg
 
 Purpose:       Gathers CCM activity data for a time range and facility.
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 12/18/2024 Michael Mayes        351109 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_ccm_bill_rpt:dba go
create program 14_ccm_bill_rpt:dba
 
prompt 
	  "Output to File/Printer/MINE" = "MINE"
	, "Billing Month"               = ""
	, "Billing Year"                = ""
	, "Facility Name Search:"       = ""
	;<<hidden>>"Search"             = ""
	, "Facilities:"                 = VALUE(0.0) 

with OUTDEV, MONTH, YEAR, FAC_SEARCH, FAC_CD
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 per_id                       = f8
                                       
        2 pat_name                     = vc
        2 pat_dob                      = vc
        2 cmrn                         = vc
                                       
        2 form_cnt                     = i4
        2 forms[*]                     
            3 enc_id                   = f8
            3 loc_cd                   = f8
            3 stop_dt                  = dq8
            3 stop_dt_txt              = vc
            3 event_id                 = f8
            3 type_mins                = vc
            3 mins                     = i4
                                       
        2 stop_dt_list                 = vc  ;(This is going to be the form dates, or encounter dates they asked for.)
        2 bill_role_list               = vc  ; These are going to be the care man.
        2 desg_role_list               = vc  ; These are going to be the care man.
        
        2 ref_loc_list                 = vc  ;coming from... the encounters on the forms.
        
        2 bill_date                    = vc 
        
        2 month_bill_min               = i4
        2 month_desg_min               = i4
        
        2 bill_init_cpt                = vc
        2 bill_init_cpt_desc           = vc
        2 bill_init_cpt_min_per_unit   = i4
        2 bill_init_cpt_units          = i4
        
        2 bill_add_on_cpt              = vc
        2 bill_add_on_cpt_desc         = vc
        2 bill_add_on_cpt_min_per_unit = i4
        2 bill_add_on_cpt_units        = i4
        
        2 bill_leftover                = i4
        
        2 desg_init_cpt                = vc
        2 desg_init_cpt_desc           = vc
        2 desg_init_cpt_min_per_unit   = i4
        2 desg_init_cpt_units          = i4
        
        2 desg_add_on_cpt              = vc
        2 desg_add_on_cpt_desc         = vc
        2 desg_add_on_cpt_min_per_unit = i4
        2 desg_add_on_cpt_units        = i4
        
        2 desg_leftover                = i4
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
/*
declare idx                = i4  with protect, noconstant(0)
*/

declare cmrn_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     4, 'CMRN'))

declare pos                = i4  with protect, noconstant(0)
declare pos2               = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)

declare rep_beg_dt_tm = dq8 with protect
declare rep_end_dt_tm = dq8 with protect


;BUILD
;declare ccm_stop_cd = f8 with protect,   constant(4568455577.00)
;declare ccm_role_cd = f8 with protect,   constant(4568455649.00)
;declare ccm_durr_cd = f8 with protect,   constant(4568455597.00)

;PROD
declare ccm_stop_cd = f8 with protect,   constant(5734861407.00)
declare ccm_role_cd = f8 with protect,   constant(5734895299.00)
declare ccm_durr_cd = f8 with protect,   constant(5734894793.00)


declare leftover_bill = i4 with protect, noconstant(0)
declare leftover_desg = i4 with protect, noconstant(0)



 
/*************************************************************
; DVDev Start Coding
**************************************************************/

; First let's settle the date stuff coming in...

set rep_beg_dt_tm = cnvtdatetime(cnvtdate2(concat('01', $MONTH, $YEAR), 'DDMMYYYY'), 0)
set rep_end_dt_tm = datetimefind(rep_beg_dt_tm, 'M', 'E', 'E')


call echo(build('rep_beg_dt_tm:', format(rep_beg_dt_tm, ';;q')))
call echo(build('rep_end_dt_tm:', format(rep_end_dt_tm, ';;q')))

 
/**********************************************************************
DESCRIPTION:  Lets attempt to find our initial population

      NOTES:  We kind of have a crappy hand here, but CoCM survives it
              too... The dates we are filtering on are actually
              from documentation on the stop time on the forms.
              So I guess I have to tell the query to go gather those
              values... all of them... then filter down.  Indexes 
              won't really help us here.
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce

     , ce_date_result stop

     , clinical_event sect
      
     , clinical_event role
     , clinical_event durr
      
      ,clinical_event form

     , person         p
     , encounter      e
 
 where ce.valid_until_dt_tm       >= cnvtdatetime(curdate,curtime3)
   and ce.event_tag               != 'In Error'
   and ce.event_cd                =  ccm_stop_cd  ;CCM Stop Time 
   ; I need to think of something here for the loc filter...
   
   
   and sect.event_id              =  ce.parent_event_id
   and sect.valid_until_dt_tm     >  cnvtdatetime(curdate, curtime3)
   
   and role.parent_event_id       =  outerjoin(sect.event_id)
   and role.valid_until_dt_tm     >= outerjoin(cnvtdatetime(curdate,curtime3))
   and role.event_tag             != outerjoin('In Error')
   and role.event_cd              =  outerjoin(ccm_role_cd)  ;Role Providing Services 
   
   and durr.parent_event_id       =  outerjoin(sect.event_id)
   and durr.valid_until_dt_tm     >= outerjoin(cnvtdatetime(curdate,curtime3))
   and durr.event_tag             != outerjoin('In Error')
   and durr.event_cd              =  outerjoin(ccm_durr_cd)   ;CCM Duration
   
   and form.event_id              =  sect.parent_event_id
   and form.valid_until_dt_tm     >  cnvtdatetime(curdate, curtime3)
   
   and stop.event_id              =  ce.event_id
   and stop.valid_until_dt_tm     >  cnvtdatetime(curdate, curtime3)
   and stop.result_dt_tm          between cnvtdatetime(rep_beg_dt_tm) and cnvtdatetime(rep_end_dt_tm)
   
   ; Trying for the location filter here.  If they have a stop time on that loc... they are in.  
   ; Even if not all stop times are there.
   and exists(select 'x'
                from clinical_event ce2
                   , ce_date_result stop2
                   , encounter      e2
               where ce2.valid_until_dt_tm       >= cnvtdatetime(curdate,curtime3)
                 and ce2.event_tag               != 'In Error'
                 and ce2.event_cd                =  ccm_stop_cd  ;CCM Stop Time 
                 
                 and stop2.event_id              =  ce2.event_id
                 and stop2.valid_until_dt_tm     >  cnvtdatetime(curdate, curtime3)
                 and stop2.result_dt_tm          between cnvtdatetime(rep_beg_dt_tm) and cnvtdatetime(rep_end_dt_tm)
               
                 and e2.encntr_id                 = ce2.encntr_id
                 and (   0.0 in ($FAC_CD)
                      or e2.loc_facility_cd in ($FAC_CD)
                     )
   
             )
   
   and p.person_id                =  ce.person_id
   
   and e.encntr_id                =  ce.encntr_id

order by ce.person_id

head ce.person_id
    pos       = data->cnt + 1
    data->cnt = pos
    stat      = alterlist(data->qual, pos)
    
    data->qual[pos]->per_id = p.person_id
    
    ;This is always the same... the last day of the month we are running.
    data->qual[pos]->bill_date = format(rep_end_dt_tm, '@SHORTDATE')
    
    

detail
    pos2                      = data->qual[pos]->form_cnt + 1
    data->qual[pos]->form_cnt = pos2
    stat                      = alterlist(data->qual[pos]->forms, pos2)
    
    
    data->qual[pos]->forms[pos2]->enc_id       = e.encntr_id
    data->qual[pos]->forms[pos2]->event_id     = form.event_id
    data->qual[pos]->forms[pos2]->stop_dt      = stop.result_dt_tm
    data->qual[pos]->forms[pos2]->stop_dt_txt  = format(stop.result_dt_tm, '@SHORTDATE')
    
    
    if(data->qual[pos]->stop_dt_list = '') data->qual[pos]->stop_dt_list = format(stop.result_dt_tm, '@SHORTDATE')
    else                                   data->qual[pos]->stop_dt_list = notrim(build2( data->qual[pos]->stop_dt_list
                                                                                        , ', '
                                                                                        , format(stop.result_dt_tm, '@SHORTDATE')
                                                                                        )
                                                                                 )
    endif
    
    
    if(data->qual[pos]->ref_loc_list = '') data->qual[pos]->ref_loc_list = trim(uar_get_code_display(e.loc_facility_cd), 3)
    else
        if(findstring(trim(trim(uar_get_code_display(e.loc_facility_cd), 3), 3), data->qual[pos]->ref_loc_list) = 0)
            data->qual[pos]->ref_loc_list = notrim(build2( data->qual[pos]->ref_loc_list
                                                         , ', '
                                                         , trim(uar_get_code_display(e.loc_facility_cd), 3)
                                                         )
                                                  )
        endif
    endif
    
    data->qual[pos]->forms[pos2]->loc_cd = e.loc_facility_cd
    
    
    if(trim(role.result_val, 3) in ('MD', 'Nurse Practitioner'))
        data->qual[pos]->forms[pos2]->type_mins = 'BillingProv'
        
        if(data->qual[pos]->bill_role_list = '') data->qual[pos]->bill_role_list = trim(role.result_val, 3)
        else
            if(findstring(trim(role.result_val, 3), data->qual[pos]->bill_role_list) = 0)
                data->qual[pos]->bill_role_list = notrim(build2(data->qual[pos]->bill_role_list, ', ', trim(role.result_val, 3)))
            endif
        endif
        
        data->qual[pos]->month_bill_min = data->qual[pos]->month_bill_min + cnvtint(durr.result_val)
        
    else
        
        data->qual[pos]->forms[pos2]->type_mins = 'DesignatedProv'
        
        if(data->qual[pos]->desg_role_list = '') data->qual[pos]->desg_role_list = trim(role.result_val, 3)
        else
            if(findstring(trim(role.result_val, 3), data->qual[pos]->desg_role_list) = 0)
                data->qual[pos]->desg_role_list = notrim(build2(data->qual[pos]->desg_role_list, ', ', trim(role.result_val, 3)))
            endif
        endif
        
        data->qual[pos]->month_desg_min =data->qual[pos]->month_desg_min + cnvtint(durr.result_val)
        
    endif
    
    data->qual[pos]->forms[pos2]->mins = cnvtint(durr.result_val)
    
with nocounter


/**********************************************************************
DESCRIPTION:  General Pat Data
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from person       p
     , person_alias pa
     , (dummyt d with seq = data->cnt)
     
  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->per_id >  0
  
  join p
   where p.person_id               =  data->qual[d.seq]->per_id
     and p.active_ind              =  1 
  
  join pa
   where pa.person_id              =  outerjoin(p.person_id)
     and pa.person_alias_type_cd   =  outerjoin(cmrn_cd)
     and pa.active_ind             =  outerjoin(1)
     and pa.beg_effective_dt_tm    <= outerjoin(cnvtdatetime(curdate, curtime3))
     and pa.end_effective_dt_tm    >= outerjoin(cnvtdatetime(curdate, curtime3))

detail
    
    data->qual[d.seq]->pat_name = trim(p.name_full_formatted, 3)
    data->qual[d.seq]->pat_dob  = format(p.birth_dt_tm, '@SHORTDATE')
    data->qual[d.seq]->cmrn     = trim(cnvtalias(pa.alias, pa.alias_pool_cd), 3)
     
with nocounter


; Adjustments from chunking logic in the ST 14_st_ccm_ord_dur.prg  if something changes here... it needs to change there too.
for(looper = 1 to data->cnt)
    set leftover_desg = data->qual[looper]->month_desg_min
    
    if(leftover_desg >= 20)
    
        ;Initial minutes
        set leftover_desg = leftover_desg - 20
        
        set data->qual[looper]->desg_init_cpt               = '99490'
        set data->qual[looper]->desg_init_cpt_desc          = 'Bill For Chron Care Management Srvc 20 Min Per Month AMB - 99490'
        set data->qual[looper]->desg_init_cpt_min_per_unit  = 20
        set data->qual[looper]->desg_init_cpt_units         = 1
    endif
    
    
    if(leftover_desg > 0)
        if(leftover_desg > 40)
            set data->qual[looper]->desg_add_on_cpt               = '99439'
            set data->qual[looper]->desg_add_on_cpt_desc          = concat( 'Bill For Chronic Care Mgmt Svc Staf Ea Addl 20 '
                                                                          , 'Min Cal Mo - AMB 99439')
            set data->qual[looper]->desg_add_on_cpt_min_per_unit  = 20
            set data->qual[looper]->desg_add_on_cpt_units         = 2
            
            set leftover_desg = leftover_desg - 40
        else
            if(leftover_desg > 20)
                set data->qual[looper]->desg_add_on_cpt               = '99439'
                set data->qual[looper]->desg_add_on_cpt_desc          = concat( 'Bill For Chronic Care Mgmt Svc Staf Ea Addl 20 '
                                                                              , 'Min Cal Mo - AMB 99439')
                set data->qual[looper]->desg_add_on_cpt_min_per_unit  = 20
                set data->qual[looper]->desg_add_on_cpt_units         = leftover_desg / 20
                
                set leftover_desg = mod(leftover_desg, 20)
            
            endif
        endif
    
    endif
    
    set data->qual[looper]->desg_leftover = leftover_desg
    
    
    set leftover_bill = data->qual[looper]->month_bill_min
    
    if(leftover_bill >= 30)
        ;Initial minutes
        set leftover_bill = leftover_bill - 30
        
        set data->qual[looper]->bill_init_cpt               = '99491'
        set data->qual[looper]->bill_init_cpt_desc          = 'Bill For Chronic Care Mgmt Svc Phys 1St 30 Min Cal Month - AMB 99491'
        set data->qual[looper]->bill_init_cpt_min_per_unit  = 30
        set data->qual[looper]->bill_init_cpt_units         = 1
    
        ;Add on Minutes
        if(leftover_bill > 0)
            if(leftover_bill / 30 > 0)
        
                set data->qual[looper]->bill_add_on_cpt               = '99437'
                set data->qual[looper]->bill_add_on_cpt_desc          = concat( 'Bill For Chronic Care Mgmt Svc Phys Ea Addl '
                                                                            , '30 Min Cal Mo - AMB 99437')
                set data->qual[looper]->bill_add_on_cpt_min_per_unit  = 30
                set data->qual[looper]->bill_add_on_cpt_units         = leftover_bill / 30
                
                set leftover_bill = mod(leftover_bill, 30)
            
            endif
        endif
    endif
    
    set data->qual[looper]->bill_leftover = leftover_bill


endfor
   

 
;Presentation time
if (data->cnt > 0)
    
    select into $outdev
        PATIENT                       = trim(substring(1, 100, data->qual[d.seq].pat_name                                        ))
      , DOB                           = trim(substring(1,  10, data->qual[d.seq].pat_dob                                         ))
      , CMRN                          = trim(substring(1,  15, data->qual[d.seq].cmrn                                            ))
      , FORM_DATES                    = trim(substring(1, 100, data->qual[d.seq].stop_dt_list                                    ))
      
      , LOCATION_LIST                 = trim(substring(1, 200, data->qual[d.seq].ref_loc_list                                    ))
      
      , BILLING_DATE                  = trim(substring(1,  15, data->qual[d.seq].bill_date                                       ))
      
      , BILL_STAFF_LIST               = trim(substring(1, 200, data->qual[d.seq].bill_role_list                                  ))
      
      , BILL_PROV_MONTH_MIN           = trim(substring(1,  10, cnvtstring(data->qual[d.seq].month_bill_min              , 17, 0) ))
      
      , BILL_PROV_INIT_CPT            = trim(substring(1,  10,            data->qual[d.seq].bill_init_cpt                        ))
      , BILL_PROV_INIT_DESC           = trim(substring(1, 100,            data->qual[d.seq].bill_init_cpt_desc                   ))
      , BILL_PROV_INIT_MIN_PER_UNIT   = trim(substring(1,  10, cnvtstring(data->qual[d.seq].bill_init_cpt_min_per_unit  , 17, 0) ))
      , BILL_PROV_INIT_UNITS          = trim(substring(1,  10, cnvtstring(data->qual[d.seq].bill_init_cpt_units         , 17, 0) ))
      
      , BILL_PROV_ADDON_CPT           = trim(substring(1,  10,            data->qual[d.seq].bill_add_on_cpt                      ))
      , BILL_PROV_ADDON_DESC          = trim(substring(1, 100,            data->qual[d.seq].bill_add_on_cpt_desc                 ))
      , BILL_PROV_ADDON_MIN_PER_UNIT  = trim(substring(1,  10, cnvtstring(data->qual[d.seq].bill_add_on_cpt_min_per_unit, 17, 0) ))
      , BILL_PROV_ADDON_UNITS         = trim(substring(1,  10, cnvtstring(data->qual[d.seq].bill_add_on_cpt_units       , 17, 0) ))
      
      , BILL_PROV_LEFTOVER_MIN        = trim(substring(1,  10, cnvtstring(data->qual[d.seq].bill_leftover               , 17, 0) ))
      
      , DESG_STAFF_LIST               = trim(substring(1, 200, data->qual[d.seq].desg_role_list                                  ))
      
      , DESG_STAFF_MONTH_MIN          = trim(substring(1,  10, cnvtstring(data->qual[d.seq].month_desg_min              , 17, 0) ))
      
      , DESG_STAFF_INIT_CPT           = trim(substring(1,  10,            data->qual[d.seq].desg_init_cpt                        ))
      , DESG_STAFF_INIT_DESC          = trim(substring(1, 100,            data->qual[d.seq].desg_init_cpt_desc                   ))
      , DESG_STAFF_INIT_MIN_PER_UNIT  = trim(substring(1,  10, cnvtstring(data->qual[d.seq].desg_init_cpt_min_per_unit  , 17, 0) ))
      , DESG_STAFF_INIT_UNITS         = trim(substring(1,  10, cnvtstring(data->qual[d.seq].desg_init_cpt_units         , 17, 0) ))
      
      , DESG_STAFF_ADDON_CPT          = trim(substring(1,  10,            data->qual[d.seq].desg_add_on_cpt                      ))
      , DESG_STAFF_ADDON_DESC         = trim(substring(1, 100,            data->qual[d.seq].desg_add_on_cpt_desc                 ))
      , DESG_STAFF_ADDON_MIN_PER_UNIT = trim(substring(1,  10, cnvtstring(data->qual[d.seq].desg_add_on_cpt_min_per_unit, 17, 0) ))
      , DESG_STAFF_ADDON_UNITS        = trim(substring(1,  10, cnvtstring(data->qual[d.seq].desg_add_on_cpt_units       , 17, 0) ))
      
      , DESG_STAFF_LEFTOVER_MIN       = trim(substring(1,  10, cnvtstring(data->qual[d.seq].desg_leftover               , 17, 0) ))
           
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
call echorecord(data)

end
go
 
 



