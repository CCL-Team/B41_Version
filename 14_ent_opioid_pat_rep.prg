/*************************************************************************
 Program Title: ENT Opioid Patterns

 Object name:   14_ent_opioid_pat_rep
 Source file:   14_ent_opioid_pat_rep.prg

 Purpose:       Gather prescribing patterns and complications related to
                ENT and Opioid

 Tables read:

 Executed from:

 Special Notes:



******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 01/31/2023 Michael Mayes        235786 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_ent_opioid_pat_rep:dba go
create program 14_ent_opioid_pat_rep:dba

prompt
      "Output to File/Printer/MINE" = "MINE"
    , "Start Date"                  = "SYSDATE"
    , "End Date"                    = "SYSDATE"
    , "Location"                    = 0.0

with OUTDEV, beg_dt_tm, end_dt_tm, locs




/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
%i cust_script:cust_timers_debug.inc


declare floatToStringTrimZeros(float_val = f8)  = vc with protect


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record opioid_codes(
    1 cnt = i4
    1 code[*]
        2 catalog_cd        = f8
        2 catalog_disp      = vc
        2 drug_ident        = vc
        2 csa_schedule      = vc
        2 multm_category_id = f8
        2 multm_category    = vc
)



record data(
    1 cnt = i4
    1 qual[*]
        2 per_id            = f8
        2 enc_id            = f8
        2 ord_id            = f8
        2 ord_enc_id        = f8
                            
        2 name              = vc
        2 mrn               = vc
        2 fin               = vc
        2 dob_dt            = dq8
        2 dob               = vc
                            
        2 proc_ind          = i2
        2 proc_txt          = vc
        2 proc_loc_cd       = f8
        2 proc_enc_loc_cd   = f8
        2 proc_loc          = vc
        2 proc_dt           = dq8
        2 proc_dt_txt       = vc
        2 surgeon_id        = f8
        2 surgeon_name      = vc
        ;ICD10/CPT          
                            
        2 narc_cnt          = i4
        2 narc[*]           
            3 order_id      = f8
            3 ord_enc_id    = f8
            3 ord_mrn       = vc
            3 ord_fin       = vc
            3 name          = vc
            3 cur_ord_stat  = vc
            3 ord_dt        = dq8
            3 ord_dt_txt    = vc
            3 ord_loc       = vc
            3 ord_loc_cd    = f8
            3 ord_appt_type = vc
)

record flat_data(
    1 cnt = i4
    1 qual[*]
        2 per_id                 = f8
        2 enc_id                 = f8
        2 ord_id                 = f8
        2 ord_enc_id             = f8

        2 name                   = vc
        2 dob_dt                 = dq8
        2 dob                    = vc

        2 proc_ind               = i2
        2 proc_txt               = vc
        2 proc_loc_cd            = f8
        2 proc_enc_loc_cd        = f8
        2 proc_loc               = vc
        2 proc_dt                = dq8
        2 proc_dt_txt            = vc
        2 surgeon_id             = f8
        2 surgeon_name           = vc
        ;ICD10/CPT      
                        
        2 ord_loc                = vc
        2 ord_loc_cd             = f8
        2 ord_appt_type          = vc
        2 ord_mrn                = vc
        2 ord_fin                = vc

        2 narc_order_id          = f8
        2 narc_dt                = dq8
        2 narc_dt_txt            = vc
        2 narc_name              = vc
        2 narc_status            = vc
        2 narc_dose              = vc
        2 narc_dose_unit         = vc
        2 narc_freetxt_dose_unit = vc
        2 narc_vol               = vc
        2 narc_vol_unit          = vc
        2 narc_refills           = vc
        2 narc_route             = vc
        2 narc_freq              = vc
        2 narc_prn_flag          = i2

        2 pain_med_string        = vc

        2 steroid_med_string     = vc

        2 phone_msg_cnt          = i4

        2 ed_visit_ind           = i4
        2 debug_ed_visits_cnt    = i4
        2 debug_ed_visits[*]
            3 encntr_id          = f8
            3 reg_dt_tm          = dq8
        
        2 inpt_visit_ind         = i4
        2 debug_inpt_visits_cnt  = i4
        2 debug_inpt_visits[*]
            3 encntr_id          = f8
            3 reg_dt_tm          = dq8
        
        2 return_or_ind          = i4
        2 debug_or_visits_cnt    = i4
        2 debug_or_visits[*]
            3 encntr_id          = f8
            3 reg_dt_tm          = dq8

)


free record steroids
record steroids(
    1 cnt          = i4
    1 qual[*]
        2 cat_cd   = f8
        2 ord_name = vc
)



record locs(
    1 cnt          = i4
    1 qual[*]
        2 loc_name = vc
        2 loc_cd   = f8
)



/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare prog_timer       = i4  with protect,   constant(ctd_add_timer_seq('14_ENT_OPIOID_PAT_REP', 100))


declare act_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))


declare discon_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'DISCONTINUED'    ))
declare cancel_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'CANCELED'        ))
declare voided_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'DELETED'         ))
declare comp_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'COMPLETED'       ))


declare phone_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'PHONEMESSAGECALL'))


declare idx           = i4  with protect, noconstant(0)
declare pos           = i4  with protect, noconstant(0)
declare looper        = i4  with protect, noconstant(0)
declare looper2       = i4  with protect, noconstant(0)

declare temp_dose     = vc with protect, noconstant('')


/*************************************************************
; DVDev Start Coding
**************************************************************/

;Org work first
if (0 in ($locs))
    call ctd_add_timer('Locations')
    select into 'nl:'

      from location   l
         , code_value cv

     where l.location_type_cd = (select cv.code_value 
                                   from code_value cv 
                                  where cv.code_set = 222 
                                    and CDF_MEANING = "AMBULATORY"
                                )
       and l.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
       and l.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
       and l.active_ind = 1
       
       and cv.code_value  = l.location_cd
       and cv.display_key = '*OTOLARYN*' 
    detail 

            locs->cnt = locs->cnt + 1

            stat = alterlist(locs->qual, locs->cnt)

            locs->qual[locs->cnt]->loc_name = cv.display
            locs->qual[locs->cnt]->loc_cd   = l.location_cd
    with nocounter
    call ctd_end_timer(0)
    

else
    call ctd_add_timer('Locations')
    select into 'nl:'

      from location   l
         , code_value cv
    
     where l.location_cd in ($locs)
       
       and cv.code_value = l.location_cd
    
    detail 
            locs->cnt = locs->cnt + 1

            stat = alterlist(locs->qual, locs->cnt)

            locs->qual[locs->cnt]->loc_name = cv.display
            locs->qual[locs->cnt]->loc_cd   = l.location_cd
    with nocounter
    call ctd_end_timer(0)
    

endif


/***********************************************************************
DESCRIPTION:  Retrieve Steroids
      NOTES:  This is coming from a script called 7_diabetes_care_cont.
              No idea if it is a full list of steroids to check for.
***********************************************************************/
call ctd_add_timer('Retrieve Steroids')
select distinct
  into "nl:"
       oc.primary_mnemonic
     , oc.catalog_cd

  from order_catalog        oc
     , alt_sel_cat          ac
     , alt_sel_list         al
     , order_catalog_item_r oi

  plan ac

   where ac.alt_sel_category_id in ( 3366153.00 ;glucocorticoids
                                   , 3366154.00 ;mineralcorticoids
                                   )

  join al
    where al.alt_sel_category_id = ac.alt_sel_category_id

  join oi
   where oi.synonym_id = al.synonym_id

  join oc
   where oc.catalog_cd = oi.catalog_cd

order by oc.description
       , oi.catalog_cd

head report
    medcnt = 0

detail
    steroids->cnt = steroids->cnt + 1

    stat = alterlist (steroids->qual, steroids->cnt)

    steroids ->qual[steroids->cnt].cat_cd   = oi.catalog_cd
    steroids ->qual[steroids->cnt].ord_name = oc.description

with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Retrieve catalog_cds we are interested in
      NOTES:  Specs say this is multm category 60, 63, and 190
              CSA schedule 2, 3, and 4.
***********************************************************************/
call ctd_add_timer('Catalog_cds')
select into 'nl:'
       oc_catalog_disp = uar_get_code_display(oc.catalog_cd)

  from mltm_drug_categories    mdc
     , mltm_category_drug_xref m
     , order_catalog           oc
     , mltm_ndc_main_drug_code mmdc

 where mdc.multum_category_id in (60, 63, 190, 191)

   and m.multum_category_id   =  mdc.multum_category_id

   and oc.cki                 =  concat("MUL.ORD!", m.drug_identifier)
   and oc.active_ind          =  1

   and mmdc.drug_identifier   =  m.drug_identifier
   and mmdc.csa_schedule      in ('2', '3', '4')

order by mdc.multum_category_id, mmdc.csa_schedule, oc_catalog_disp

head oc.catalog_cd

    opioid_codes->cnt = opioid_codes->cnt + 1

    if(mod(opioid_codes->cnt, 10) = 1)
        stat = alterlist(opioid_codes->code, opioid_codes->cnt + 9)
    endif


    opioid_codes->code[opioid_codes->cnt]->catalog_cd        = oc.catalog_cd
    opioid_codes->code[opioid_codes->cnt]->catalog_disp      = oc_catalog_disp
    opioid_codes->code[opioid_codes->cnt]->drug_ident        = m.drug_identifier
    opioid_codes->code[opioid_codes->cnt]->csa_schedule      = mmdc.csa_schedule
    opioid_codes->code[opioid_codes->cnt]->multm_category_id = mdc.multum_category_id
    opioid_codes->code[opioid_codes->cnt]->multm_category    = mdc.category_name

foot report
    stat = alterlist(opioid_codes->code, opioid_codes->cnt)

with nocounter
call ctd_end_timer(0)



/**********************************************************************
DESCRIPTION:  Start finding appointments
      NOTES:  Third time is a charm
***********************************************************************/
call ctd_add_timer('finding appointments')
select into 'nl:'
  
  from encounter        e
    
     , sch_appt         sa
     , sch_event        se
  
     , orders           o 
     
     , person           p
 
 where expand(idx, 1, locs->cnt, e.loc_nurse_unit_cd, locs->qual[idx].loc_cd)
   and e.reg_dt_tm        between cnvtdatetime($beg_dt_tm) and cnvtdatetime($end_dt_tm)
   and e.active_ind             = 1
                                
   and sa.encntr_id             =  e.encntr_id
   and sa.schedule_seq          =  (select max(sa2.schedule_seq)
                                      from sch_appt sa2
                                     where sa2.sch_event_id = sa.sch_event_id
                                   )
                                
   and se.sch_event_id          =  sa.sch_event_id
   
   and (   (o.originating_encntr_id > 0 and e.encntr_id = o.originating_encntr_id)
        or (o.originating_encntr_id = 0 and e.encntr_id = o.encntr_id)
       )
   and o.person_id              =  e.person_id
   and o.activity_type_cd       =  720.00  ;SURGERY
   and o.order_status_cd not in (2542.00, 2544.00, 2545.00)  ;Canceled, Voided, Discontinued.

   and p.person_id              =  e.person_id
   and p.active_ind             =  1

order by e.loc_facility_cd, p.name_full_formatted, e.encntr_id, o.order_id

head o.order_id

    data->cnt = data->cnt + 1

    stat = alterlist(data->qual, data->cnt)

    data->qual[data->cnt]->per_id        = e.person_id
    data->qual[data->cnt]->enc_id        = e.encntr_id
    data->qual[data->cnt]->ord_id        = o.order_id
    data->qual[data->cnt]->ord_enc_id    = o.encntr_id

    data->qual[data->cnt]->name          = p.name_full_formatted
    data->qual[data->cnt]->dob_dt        = p.birth_dt_tm
    data->qual[data->cnt]->dob           = format(p.birth_dt_tm, "@SHORTDATE")

    data->qual[data->cnt]->proc_txt       = trim(uar_get_code_display(o.catalog_cd), 3)

with nocounter, orahintcbo('LEADING(E SA O)')
call ctd_end_timer(0)



/***********************************************************************
DESCRIPTION:  Retrieve the procedure information
       NOTE:  
***********************************************************************/
call ctd_add_timer('procedure information')
select into 'nl:'
  from surg_case_procedure scp
     , surgical_case       sc
     , encounter           e
     , prsnl               name1
     , prsnl               name2
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt > 0
     and data->qual[d.seq]->ord_id > 0
  
  join scp
   where scp.order_id    =  data->qual[d.seq]->ord_id
  
  join sc
   where sc.surg_case_id =  scp.surg_case_id
   
  join e
   where sc.encntr_id    =  e.encntr_id
   
  join name1
   where name1.person_id =  outerjoin(scp.primary_surgeon_id)
     and name1.person_id != 0
  
  join name2
   where name2.person_id =  outerjoin(scp.sched_primary_surgeon_id)
     and name2.person_id != 0

detail
    
    data->qual[d.seq]->proc_ind         = 1
    data->qual[d.seq]->proc_dt          = sc.surg_start_dt_tm
    data->qual[d.seq]->proc_dt_txt      = format(sc.surg_start_dt_tm, "mm/dd/yyyy HH:MM:SS;;d")
    
    if(scp.primary_surgeon_id > 0) 
        data->qual[d.seq]->surgeon_id   = scp.primary_surgeon_id
        data->qual[d.seq]->surgeon_name = trim(name1.name_full_formatted, 3)
    else                           
        data->qual[d.seq]->surgeon_id   = scp.sched_primary_surgeon_id
        data->qual[d.seq]->surgeon_name = trim(name2.name_full_formatted, 3)
    endif
    
    data->qual[d.seq]->proc_loc_cd      = sc.dept_cd
    data->qual[d.seq]->proc_enc_loc_cd  = e.loc_facility_cd
    data->qual[d.seq]->proc_loc         = trim(uar_get_code_display(sc.dept_cd), 3)
    
with nocounter
call ctd_end_timer(0)



/***********************************************************************
DESCRIPTION:  Retrieve qualifying orders
       NOTE:  For this they want prescription opioids
***********************************************************************/
call ctd_add_timer('qualifying orders')
select into 'nl:'

  from orders           o
     , encounter        e
     , sch_appt         sa
     , sch_event        se
     , encntr_alias     mrn
     , encntr_alias     fin
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt > 0
     ;and (   data->qual[d.seq]->enc_id > 0
     ;     or data->qual[d.seq]->ord_enc_id > 0
     ;    )
     and data->qual[d.seq]->per_id   > 0
     and data->qual[d.seq]->proc_ind = 1
  
  join o
   ;where (   o.encntr_id       =  data->qual[d.seq]->enc_id
   ;       or o.encntr_id       =  data->qual[d.seq]->ord_enc_id
   ;      )
   where o.person_id           =  data->qual[d.seq]->per_id
     and o.encntr_id           != 0
     and o.orig_order_dt_tm    >= cnvtdatetime(data->qual[d.seq]->proc_dt)
     and o.orig_order_dt_tm    <= cnvtlookahead('30,D', cnvtdatetime(data->qual[d.seq]->proc_dt))
     ;and o.order_status_cd     not in (discon_cd, cancel_cd, voided_cd, comp_cd)
     ;and o.discontinue_ind     != 1
     and o.orig_ord_as_flag    in (1, 2, 3)  ;from uCern:
                                             ; 0: InPatient Order
                                             ; 1: Prescription/Discharge Order
                                             ; 2: Recorded / Home Meds
                                             ; 3: Patient Owns Meds
                                             ; 4: Pharmacy Charge Only
                                             ; 5: Satellite (Super Bill) Meds.
     
     and o.catalog_type_cd     =  2516.00  ;Pharmacy

     ;I don't think I need a with expand here, it is 60ish meds I think.
     and expand(idx, 1, opioid_codes->cnt, o.catalog_cd, opioid_codes->code[idx]->catalog_cd)
  
  join e
   where e.encntr_id              =  o.encntr_id
   
  join sa
   where sa.encntr_id             =  outerjoin(o.encntr_id)
   
  join se
   where se.sch_event_id          =  outerjoin(sa.sch_event_id)
  
  join mrn
   where mrn.encntr_id            =  o.encntr_id
     and mrn.encntr_alias_type_cd =  1079.00   ;MRN
     and mrn.active_ind           =  1
     and mrn.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)
  
  join fin
   where fin.encntr_id            =  o.encntr_id
     and fin.encntr_alias_type_cd =  1077.00  ;FIN
     and fin.active_ind           =  1
     and fin.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)

order by o.encntr_id, o.order_id

head o.order_id

    pos = data->qual[d.seq]->narc_cnt + 1

    data->qual[d.seq]->narc_cnt = pos

    stat = alterlist(data->qual[d.seq]->narc, pos)


    data->qual[d.seq]->narc[pos]->order_id      = o.order_id
    data->qual[d.seq]->narc[pos]->name          = trim(o.ordered_as_mnemonic, 3)
    data->qual[d.seq]->narc[pos]->ord_dt        = o.orig_order_dt_tm
    data->qual[d.seq]->narc[pos]->ord_dt_txt    = format(o.orig_order_dt_tm, '@SHORTDATETIME')
    data->qual[d.seq]->narc[pos]->cur_ord_stat  = uar_get_code_display(o.order_status_cd)
                                                
    data->qual[d.seq]->narc[pos]->ord_enc_id    = o.encntr_id
    data->qual[d.seq]->narc[pos]->ord_mrn       = cnvtalias(mrn.alias, mrn.alias_pool_cd)
    data->qual[d.seq]->narc[pos]->ord_fin       = cnvtalias(fin.alias, fin.alias_pool_cd)
    data->qual[d.seq]->narc[pos]->ord_loc       = uar_get_code_display(e.loc_facility_cd)
    data->qual[d.seq]->narc[pos]->ord_loc_cd    = e.loc_facility_cd
    
    data->qual[d.seq]->narc[pos]->ord_appt_type = uar_get_code_display(se.appt_type_cd)
    
with nocounter, orahintcbo('INDEX(O XIE7ORDERS)')
call ctd_end_timer(0)


;We are going to flatten this RS early for now.  Maybe _forever_
for(looper = 1 to data->cnt)

    if(data->qual[looper]->narc_cnt > 0)

        for(looper2 = 1 to data->qual[looper]->narc_cnt)
            set flat_data->cnt = flat_data->cnt + 1

            set stat = alterlist(flat_data->qual, flat_data->cnt)

            set flat_data->qual[flat_data->cnt]->per_id            = data->qual[looper]->per_id
            set flat_data->qual[flat_data->cnt]->enc_id            = data->qual[looper]->enc_id
            set flat_data->qual[flat_data->cnt]->ord_id            = data->qual[looper]->ord_id
            set flat_data->qual[flat_data->cnt]->ord_enc_id        = data->qual[looper]->ord_enc_id
                                                                   
                                                                   
                                                                   
            set flat_data->qual[flat_data->cnt]->name              = data->qual[looper]->name
            set flat_data->qual[flat_data->cnt]->dob_dt            = data->qual[looper]->dob_dt
            set flat_data->qual[flat_data->cnt]->dob               = data->qual[looper]->dob
                                                                   
            set flat_data->qual[flat_data->cnt]->proc_txt          = data->qual[looper]->proc_txt
            set flat_data->qual[flat_data->cnt]->proc_enc_loc_cd   = data->qual[looper]->proc_enc_loc_cd
            set flat_data->qual[flat_data->cnt]->proc_loc_cd       = data->qual[looper]->proc_loc_cd
            set flat_data->qual[flat_data->cnt]->proc_loc          = data->qual[looper]->proc_loc
            set flat_data->qual[flat_data->cnt]->proc_dt           = data->qual[looper]->proc_dt
            set flat_data->qual[flat_data->cnt]->proc_dt_txt       = data->qual[looper]->proc_dt_txt
            set flat_data->qual[flat_data->cnt]->surgeon_id        = data->qual[looper]->surgeon_id
            set flat_data->qual[flat_data->cnt]->surgeon_name      = data->qual[looper]->surgeon_name
                                                                   
            set flat_data->qual[flat_data->cnt]->ord_mrn           = data->qual[looper]->narc[looper2]->ord_mrn
            set flat_data->qual[flat_data->cnt]->ord_fin           = data->qual[looper]->narc[looper2]->ord_fin
            set flat_data->qual[flat_data->cnt]->ord_loc           = data->qual[looper]->narc[looper2]->ord_loc
            set flat_data->qual[flat_data->cnt]->ord_loc_cd        = data->qual[looper]->narc[looper2]->ord_loc_cd
            set flat_data->qual[flat_data->cnt]->ord_appt_type     = data->qual[looper]->narc[looper2]->ord_appt_type
                                                                   
            set flat_data->qual[flat_data->cnt]->narc_order_id     = data->qual[looper]->narc[looper2]->order_id
            set flat_data->qual[flat_data->cnt]->narc_name         = data->qual[looper]->narc[looper2]->name
            set flat_data->qual[flat_data->cnt]->narc_status       = data->qual[looper]->narc[looper2]->cur_ord_stat
            set flat_data->qual[flat_data->cnt]->narc_dt           = data->qual[looper]->narc[looper2]->ord_dt
            set flat_data->qual[flat_data->cnt]->narc_dt_txt       = data->qual[looper]->narc[looper2]->ord_dt_txt

        endfor
    endif
endfor


/***********************************************************************
DESCRIPTION:  Now we want some order details
***********************************************************************/
call ctd_add_timer('order details')
select into 'nl:'

  from order_detail od
     , (dummyt d with seq = flat_data->cnt)

  plan d
   where flat_data->cnt                        > 0
     and flat_data->qual[d.seq]->narc_order_id > 0

  join od
   where od.order_id = flat_data->qual[d.seq]->narc_order_id
     and od.oe_field_meaning in ( 'STRENGTHDOSE'
                                , 'STRENGTHDOSEUNIT'
                                , 'FREETXTDOSE'
                                , 'VOLUMEDOSE'
                                , 'VOLUMEDOSEUNIT'
                                , 'RXROUTE'
                                , 'FREQ'
                                , 'SCH/PRN'
                                , 'NBRREFILLS'
                                )
detail

    case(od.oe_field_meaning)
    of 'STRENGTHDOSE'    :
        temp_dose              = ''
        temp_dose              = replace(trim(od.oe_field_display_value, 3), ',','')
        temp_dose              = floatToStringTrimZeros(cnvtreal(temp_dose))

        flat_data->qual[d.seq]->narc_dose = temp_dose

    of 'STRENGTHDOSEUNIT': flat_data->qual[d.seq]->narc_dose_unit = trim(od.oe_field_display_value, 3)

    of 'FREETXTDOSE'     : flat_data->qual[d.seq]->narc_dose_unit = trim(od.oe_field_display_value, 3)

    of 'VOLUMEDOSE'      :
        temp_dose              = ''
        temp_dose              = replace(trim(od.oe_field_display_value, 3), ',','')
        temp_dose              = floatToStringTrimZeros(cnvtreal(temp_dose))

        flat_data->qual[d.seq]->narc_vol = temp_dose
    of 'VOLUMEDOSEUNIT'  : flat_data->qual[d.seq]->narc_vol_unit  = trim(od.oe_field_display_value, 3)
    of 'RXROUTE'         : flat_data->qual[d.seq]->narc_route     = trim(od.oe_field_display_value, 3)
    of 'FREQ'            : flat_data->qual[d.seq]->narc_freq      = trim(od.oe_field_display_value, 3)
    of 'SCH/PRN'         :
        if(trim(od.oe_field_display_value, 3) in ('Yes*', 'Y'))
           flat_data->qual[d.seq]->narc_prn_flag = 1
        endif
    of 'NBRREFILLS':
        flat_data->qual[d.seq]->narc_refills  = trim(od.oe_field_display_value, 3)
    endcase
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Now we want to see if there are other pain meds prescribed
      NOTES:  Borrowing a lot of this from 7_pain_score_med_180822, some
              pain report I found.
***********************************************************************/
call ctd_add_timer('other pain meds')
select into 'nl:'

  from orders o
     , order_catalog_item_r  ocir
     , order_catalog         oc
     , order_catalog_synonym ocs
     , alt_sel_list          al
     , alt_sel_cat           ac
     , (dummyt d with seq = flat_data->cnt)

  plan d
   where flat_data->cnt                 > 0
     and flat_data->qual[d.seq]->per_id > 0

  join o
   where o.person_id           =  flat_data->qual[d.seq]->per_id
     and o.order_id            != flat_data->qual[d.seq]->narc_order_id
     and o.activity_type_cd    =  705.00    ;  Pharmacy
     and o.med_order_type_cd   =  10915.00  ;  Med
     and o.order_status_cd not in (discon_cd, cancel_cd, voided_cd, comp_cd)
     and o.orig_ord_as_flag    in (1, 2, 3)  ;from uCern:
                                       ; 0: InPatient Order
                                       ; 1: Prescription/Discharge Order
                                       ; 2: Recorded / Home Meds
                                       ; 3: Patient Owns Meds
                                       ; 4: Pharmacy Charge Only
                                       ; 5: Satellite (Super Bill) Meds.
  join ocir
   where ocir.catalog_cd = o.catalog_cd
     and ocir.item_id    = (select max(sub.item_id)
                              from order_catalog_item_r sub
                             where sub.catalog_cd = ocir.catalog_cd
                              with maxrec = 1, nocounter)

  join oc
   where oc.catalog_cd  =  o.catalog_cd
     and oc.description != 'pain pump*'
     and oc.description != 'STUDY*'
     and oc.description != '*STUDY'

  join ocs
   where ocir.synonym_id = ocs.synonym_id

  join al
   where ocs.synonym_id = al.synonym_id

  join ac
   where al.alt_sel_category_id = ac.alt_sel_category_id
     and (   ac.long_description_key_cap in ( "ANALGESICS"
                                            , "MISCELLANEOUS ANALGESICS"
                                            , "ANALGESIC COMBINATIONS"
                                            , "NARCOTIC ANALGESICS"
                                            , "NARCOTIC ANALGESIC COMBINATIONS"
                                            , "COX-2 INHIBITORS"
                                            , "NONSTEROIDAL ANTI-INFLAMMATORY AGENTS"
                                            )
          or (    ac.long_description_key_cap =  "BENZODIAZEPINES"
              and o.catalog_cd = 2755701.00)
          or (    ac.long_description_key_cap =  "SALICYLATES"
              and o.catalog_cd = 2750066.00)
          or (    ac.long_description_key_cap =  "ANTITUSSIVES"
              and o.catalog_cd = 2754362.00)
          or (    ac.long_description_key_cap =  "CALCIUM CHANNEL BLOCKING AGENTS"
              and o.catalog_cd = 2765101.00)
          or (    ac.long_description_key_cap =  "ANTIANGINAL AGENTS"
              and o.catalog_cd = 2765191.00)
         )
detail
    if(flat_data->qual[d.seq]->pain_med_string = '')
        flat_data->qual[d.seq]->pain_med_string = trim(oc.description, 3)
    else
        flat_data->qual[d.seq]->pain_med_string = notrim(build2( flat_data->qual[d.seq]->pain_med_string, ';'
                                                               , trim(oc.description, 3)
                                                               )
                                                        )
    endif


with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Now we want to see if there are steroids prescribed
      NOTES:  I don't really know what I am doing.
***********************************************************************/
call ctd_add_timer('steroids')
select into 'nl:'

  from orders o
     , (dummyt d with seq = flat_data->cnt)

  plan d
   where flat_data->cnt                 > 0
     and flat_data->qual[d.seq]->per_id > 0

  join o
   where o.person_id           =  flat_data->qual[d.seq]->per_id
     and o.order_id            != flat_data->qual[d.seq]->narc_order_id
     and o.activity_type_cd    =  705.00    ;  Pharmacy
     and o.med_order_type_cd   =  10915.00  ;  Med
     and o.order_status_cd not in (discon_cd, cancel_cd, voided_cd, comp_cd)
     and o.orig_ord_as_flag    in (1, 2, 3)  ;from uCern:
                                       ; 0: InPatient Order
                                       ; 1: Prescription/Discharge Order
                                       ; 2: Recorded / Home Meds
                                       ; 3: Patient Owns Meds
                                       ; 4: Pharmacy Charge Only
                                       ; 5: Satellite (Super Bill) Meds.
     and EXPAND(idx, 1, steroids->cnt, o.catalog_cd, steroids->QUAL[idx].cat_cd)
detail
    if(flat_data->qual[d.seq]->steroid_med_string = '')
        flat_data->qual[d.seq]->steroid_med_string = trim(uar_get_code_display(o.catalog_cd), 3)
    else
        flat_data->qual[d.seq]->steroid_med_string = notrim(build2( flat_data->qual[d.seq]->steroid_med_string, ';'
                                                                  , trim(uar_get_code_display(o.catalog_cd), 3)
                                                                  )
                                                           )
    endif
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Attempt to find phone messages after the procedure
      NOTES:  I don't really know what I am doing.  This time 30 days.
***********************************************************************/
call ctd_add_timer('phone messages')
select into 'nl:'
  from clinical_event ce
     , (dummyt d with seq = flat_data->cnt)

  plan d
   where flat_data->cnt                 > 0
     and flat_data->qual[d.seq]->per_id > 0

  join ce
   where ce.person_id         =  flat_data->qual[d.seq]->per_id
     and ce.event_cd          =  phone_cd
     and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
     and ce.event_end_dt_tm   between cnvtdatetime(flat_data->qual[d.seq]->proc_dt)
                                  and cnvtlookahead('30,D', cnvtdatetime(flat_data->qual[d.seq]->proc_dt))

detail
    flat_data->qual[d.seq]->phone_msg_cnt = flat_data->qual[d.seq]->phone_msg_cnt + 1
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Finally... attempt to find visits that we are interested in
      NOTES:  These would be... returns to the OR... ED visits...
              Or any admit.
***********************************************************************/
call ctd_add_timer('Visits')
select into 'nl:'
  from encounter e
     , (dummyt d with seq = flat_data->cnt)

  plan d
   where flat_data->cnt                 > 0
     and flat_data->qual[d.seq]->per_id > 0

  join e
   where e.person_id  =  flat_data->qual[d.seq]->per_id
     and e.active_ind =  1
     ;Beginning of the next day.  Sucks... couldn't use nicer functions.
     and e.reg_dt_tm  >  cnvtdate(cnvtdatetime(flat_data->qual[d.seq]->proc_dt)) + 1
     and e.reg_dt_tm  <  cnvtlookahead('30,D', cnvtdatetime(flat_data->qual[d.seq]->proc_dt))

detail
    case(e.encntr_type_cd)
    ;Emergency
    of 309310.00:  
        flat_data->qual[d.seq]->ed_visit_ind   = 1
        
        pos = flat_data->qual[d.seq]->debug_ed_visits_cnt + 1
        
        flat_data->qual[d.seq]->debug_ed_visits_cnt = pos
        stat = alterlist(flat_data->qual[d.seq]->debug_ed_visits, pos)
        
        flat_data->qual[d.seq]->debug_ed_visits[pos]->encntr_id = e.encntr_id
        flat_data->qual[d.seq]->debug_ed_visits[pos]->reg_dt_tm = e.reg_dt_tm
        
    ;Inpatient
    of 309308.00:  
        flat_data->qual[d.seq]->inpt_visit_ind = 1
        
        pos = flat_data->qual[d.seq]->debug_inpt_visits_cnt + 1
        
        flat_data->qual[d.seq]->debug_inpt_visits_cnt = pos
        stat = alterlist(flat_data->qual[d.seq]->debug_inpt_visits, pos)
        
        flat_data->qual[d.seq]->debug_inpt_visits[pos]->encntr_id = e.encntr_id
        flat_data->qual[d.seq]->debug_inpt_visits[pos]->reg_dt_tm = e.reg_dt_tm

    endcase

    if(e.loc_facility_cd = flat_data->qual[d.seq]->proc_enc_loc_cd)
        flat_data->qual[d.seq]->return_or_ind = 1
        
        pos = flat_data->qual[d.seq]->debug_or_visits_cnt + 1
        
        flat_data->qual[d.seq]->debug_or_visits_cnt = pos
        stat = alterlist(flat_data->qual[d.seq]->debug_or_visits, pos)
        
        flat_data->qual[d.seq]->debug_or_visits[pos]->encntr_id = e.encntr_id
        flat_data->qual[d.seq]->debug_or_visits[pos]->reg_dt_tm = e.reg_dt_tm
    endif

with nocounter
call ctd_end_timer(0)


;Presentation time
call ctd_end_timer(prog_timer)


call ctd_print_timers(null)

if (flat_data->cnt > 0)

    select into $outdev
          ;DEBUG COLUMNS
          per_id     = flat_data->qual[d.seq].per_id    ,
          enc_id     = flat_data->qual[d.seq].enc_id    ,
          ord_id     = flat_data->qual[d.seq].ord_id    ,
          ord_enc_id = flat_data->qual[d.seq].ord_enc_id,

          NAME                 = trim(substring(1, 150, flat_data->qual[d.seq].name                   ))
        , DOB                  = trim(substring(1,  15, flat_data->qual[d.seq].dob                    ))
        
        , MRN                  = trim(substring(1,  25, flat_data->qual[d.seq].ord_mrn                ))
        , FIN                  = trim(substring(1,  25, flat_data->qual[d.seq].ord_fin                ))
        , ORD_LOC              = trim(substring(1,  50, flat_data->qual[d.seq].ord_loc                ))
        , ORD_APPT_TYPE        = trim(substring(1,  50, flat_data->qual[d.seq].ord_appt_type          ))

        , PROC                 = trim(substring(1, 100, flat_data->qual[d.seq].proc_txt               ))
        , PROC_LOC             = trim(substring(1,  50, flat_data->qual[d.seq].proc_loc               ))
        , PROC_DATE            = trim(substring(1,  30, flat_data->qual[d.seq].proc_dt_txt            ))
        , SURGEON              = trim(substring(1, 150, flat_data->qual[d.seq].surgeon_name           ))

        , OPI_ORD_DT           = trim(substring(1,  30, flat_data->qual[d.seq].narc_dt_txt            ))
        , OPI_NAME             = trim(substring(1, 150, flat_data->qual[d.seq].narc_name              ))
        , OPI_CURRENT_STATUS   = trim(substring(1, 150, flat_data->qual[d.seq].narc_status            ))
        , OPI_DOSE             = trim(substring(1,  30, flat_data->qual[d.seq].narc_dose              ))
        , OPI_UNIT             = trim(substring(1, 300, flat_data->qual[d.seq].narc_dose_unit         ))
        , OPI_FREETEXT_DOSE    = trim(substring(1, 100, flat_data->qual[d.seq].narc_freetxt_dose_unit ))
        , OPI_VOL              = trim(substring(1,  30, flat_data->qual[d.seq].narc_vol               ))
        , OPI_VOL_UNIT         = trim(substring(1,  30, flat_data->qual[d.seq].narc_vol_unit          ))
        , OPI_ROUTE            = trim(substring(1,  30, flat_data->qual[d.seq].narc_route             ))
        , OPI_FREQ             = trim(substring(1,  30, flat_data->qual[d.seq].narc_freq              ))
        , OPI_REFILLS          = trim(substring(1,  30, flat_data->qual[d.seq].narc_refills           ))
        , OPI_PRN              = evaluate(flat_data->qual[d.seq].narc_prn_flag  , 1, 'Yes', 0, 'No')

        , OTHER_PAIN_MEDS      = trim(substring(1, 100, flat_data->qual[d.seq].pain_med_string        ))

        , OTHER_STEROIDS       = trim(substring(1, 100, flat_data->qual[d.seq].steroid_med_string     ))

        , PHONE_MSG_CNT        = flat_data->qual[d.seq].phone_msg_cnt

        , ED_VISIT_AFTER_PROC  = evaluate(flat_data->qual[d.seq].ed_visit_ind  , 1, 'Yes', 0, 'No')
        , ADMIT_AFTER_PROC     = evaluate(flat_data->qual[d.seq].inpt_visit_ind, 1, 'Yes', 0, 'No')
        , OR_RETURN_AFTER_PROC = evaluate(flat_data->qual[d.seq].return_or_ind , 1, 'Yes', 0, 'No')

      from (dummyt d with SEQ = flat_data->cnt)
      
    order by MRN, OPI_ORD_DT
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

                       Borrowing all of this from an old script.
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
;DEBUGGING
call echorecord(flat_data)

for(looper = 1 to flat_data->cnt)
    
    if(   flat_data->qual[looper].ed_visit_ind   = 1
       or flat_data->qual[looper].inpt_visit_ind = 1
       or flat_data->qual[looper].return_or_ind  = 1
      )
        call echorecord(flat_data->qual[looper])
    endif
endfor


end
go



