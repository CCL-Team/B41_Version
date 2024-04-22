/*************************************************************************
 Program Title: Shield Prescription Data Extract

 Object name:   99_shield_extract_rx
 Source file:   99_shield_extract_rx.prg

 Purpose:       Retrieve information for the SHIELD data extract involving
                prescription data and requested data around prescriptions.

                For use in a scheduled job.  At the moment this is a weekly
                job scheduled to run on Fridays.

 Tables read:   diagnosis
                encounter
                nomenclature
                person
                person_alias
                prsnl
                prsnl_alias
                prsnl_group
                prsnl_group_reltn
                sch_appt

 Executed from: OpsJob (Olympus)

 Special Notes:

**********************************************************************************************************
                  MODIFICATION CONTROL LOG
**********************************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 12/26/2019 Michael Mayes               Initial
002 04/15/2021 Micahel Mayes        227001 MRN to CMRN   
003 04/28/2021 Michael Mayes        227003 Adding new columns
004 10/20/2021 Michael Mayes               TASK4698502 New 6 week lookback... to run joinly with current.
005 09/22/2022 Michael Mayes               TASK Pending They did build work on synonyms and inactivated some.
                                           We were checking active-ness, and need to correct that.  Probably
                                           defaulting with orders ordered as synonym, then repopulating
                                           in the order_catalog_syn query.  Also... dup orders... not sure how...
                                           but it can only be one place... so trying a better approach there.
006 12/14/2023 Michael Mayes               [TASK PENDING] Moving the weekly extract to Sats, looking back to Sat - Friday.
*****************************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 99_shield_extract_rx:dba go
create program 99_shield_extract_rx:dba

prompt
      'Output to File/Printer/MINE'     = 'MINE'   ;* Enter or select the printer or file name to send this report to.
    , 'Enter start date (DD-MMM-YYYY):' = 'SYSDATE'
    , 'Enter end date (DD-MMM-YYYY):'   = 'SYSDATE'

with OUTDEV, BEG_DATE, END_DATE


/*************************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************************/
declare CSV_comma_esc(csv_str = vc) = vc


%i cust_script:cust_timers_debug.inc

/*************************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************************/
;004->
free record candidate_ord
record candidate_ord(
    1 cnt        = i4
    1 qual[*]
        2 ord_id            = f8
        2 catalog_cd        = f8
        2 rx_date           = vc
        2 rx_id_txt         = vc  ;I guess we need this to strip the .0s.
        2 rx_drug           = vc  ;005
        2 med_status        = vc
        2 med_time          = vc
        2 med_directions    = vc
        2 encntr_id         = f8
        2 person_id         = f8
        2 discontinue_date  = vc
        2 orig_ord_as_flag  = i4
        2 synonym_id        = f8
)
;004<-


free record extract_data
record extract_data(
    1 cnt                   = i4
    1 qual[*]
        2 rx_id             = f8
        2 catalog_cd        = f8
        2 rx_id_txt         = vc  ;I guess we need this to strip the .0s.
        2 synonym_id        = f8  ;004 We need this for the multm stuff.
        2 encntr_id         = f8
        2 person_id         = f8
        2 mrn               = vc
        2 name_first        = vc
        2 name_middle       = vc
        2 name_last         = vc
        2 name_suffix       = vc
        2 dob               = vc
        2 last_4_ssn        = vc
        2 add_street_1      = vc
        2 add_street_2      = vc
        2 add_city          = vc
        2 add_state         = vc
        2 add_zip           = vc
        2 primary_phone     = vc
        2 sex               = vc
        2 ord_prov_id       = f8
        2 ord_prov          = vc
        2 prov_prsnl_id     = f8
        2 prov_name_first   = vc
        2 prov_name_middle  = vc
        2 prov_name_last    = vc
        2 prov_name_suffix  = vc
        2 prescriber_npi    = vc
        2 prov_add_street_1 = vc
        2 prov_add_street_2 = vc
        2 prov_add_city     = vc
        2 prov_add_state    = vc
        2 prov_add_zip      = vc
        2 prov_phone        = vc
        2 prov_fax          = vc
        2 prov_spec         = vc
        2 clinic_name       = vc
        2 prov_affiliation  = vc
        2 prov_cred         = vc
        2 rx_date           = vc
        2 rx_drug           = vc
        2 rx_ndc_nbr        = vc
        2 dv_med_id         = vc
        2 rx_refills        = vc
        2 rx_strength       = vc
        2 rx_freq           = vc
        2 rx_quantity       = vc
        2 rx_supply_days    = vc
        2 rx_brandname      = vc
        2 med_status        = vc
        2 med_time          = vc
        2 med_directions    = vc
        2 prior_auth        = vc
        2 reorder           = vc  ;003
        2 hx                = vc  ;003
        2 pharm_name        = vc
        2 pharm_id          = vc
        2 pharm_address     = vc
        2 prindx            = vc
        2 plan_name         = vc
        2 pri_insure        = vc
        2 pri_plan_type     = vc
        2 pri_group         = vc
        2 pri_sponsor       = vc
        2 pri_sponsor_type  = vc
        2 pri_member_id     = vc
        2 discontinue_date  = vc
)


record 3202501_request (
  1 active_status_flag = i2
  1 transmit_capability_flag = i2
  1 id_cnt = i4 ;004 This is me... not from the normal request.
  1 ids [*]
    2 id = vc
)


record 3202501_reply (
  1 pharmacies [*]
    2 id = vc
    2 version_dt_tm = dq8
    2 pharmacy_name = vc
    2 pharmacy_number = vc
    2 active_begin_dt_tm = dq8
    2 active_end_dt_tm = dq8
    2 pharmacy_contributions [*]
      3 contributor_system_cd = f8
      3 version_dt_tm = dq8
      3 contribution_id = vc
      3 pharmacy_name = vc
      3 pharmacy_number = vc
      3 active_begin_dt_tm = dq8
      3 active_end_dt_tm = dq8
      3 addresses [*]
        4 type_cd = f8
        4 type_seq = i2
        4 street_address_lines [*]
          5 street_address_line = vc
        4 city = vc
        4 state = vc
        4 postal_code = vc
        4 country = vc
        4 cross_street = vc
      3 telecom_addresses [*]
        4 type_cd = f8
        4 type_seq = i2
        4 contact_method_cd = f8
        4 value = vc
        4 extension = vc
      3 service_level = vc
      3 partner_account = vc
      3 service_levels
        4 new_rx_ind = i2
        4 ref_req_ind = i2
        4 epcs_ind = i2
      3 specialties
        4 mail_order_ind = i2
        4 retail_ind = i2
        4 specialty_ind = i2
        4 twenty_four_hour_ind = i2
        4 long_term_ind = i2
    2 primary_business_address
      3 type_cd = f8
      3 type_seq = i2
      3 street_address_lines [*]
        4 street_address_line = vc
      3 city = vc
      3 state = vc
      3 postal_code = vc
      3 country = vc
      3 cross_street = vc
    2 primary_business_telephone
      3 type_cd = f8
      3 type_seq = i2
      3 contact_method_cd = f8
      3 value = vc
      3 extension = vc
    2 primary_business_fax
      3 type_cd = f8
      3 type_seq = i2
      3 contact_method_cd = f8
      3 value = vc
      3 extension = vc
    2 primary_business_email
      3 type_cd = f8
      3 type_seq = i2
      3 contact_method_cd = f8
      3 value = vc
      3 extension = vc
  1 status_data
    2 status = c1
    2 subeventstatus [*]
      3 operationname = c25
      3 operationstatus = c1
      3 targetobjectname = c25
      3 targetobjectvalue = vc
)


free set frec ;record used in the CCLIO process to create the ouput file
record frec(
    1 file_desc = i4
    1 file_name = vc
    1 file_buf = vc
    1 file_dir = i4
    1 file_offset = i4
)



/*************************************************************************
; DVDev DECLARED VARIABLES
**************************************************************************/
declare default_beg_dt        = dq8
declare default_end_dt        = dq8

declare per_mrn_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     4, 'CMRN'                      ));002
declare ssn_cd                = f8  with protect,   constant(uar_get_code_by(   'MEANING',     4, 'SSN'                       ))
declare npi_cd                = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   320, 'NATIONALPROVIDERIDENTIFIER'))
declare cur_per_name_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',   213, 'CURRENT'                   ))
declare prsnl_per_name_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',   213, 'PRSNL'                     ))
declare home_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',   212, 'HOME'                      ))
declare mail_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',   212, 'MAILING'                   ))
declare business_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',   212, 'BUSINESS'                  ))
declare home_phone_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',    43, 'HOME'                      ))
declare business_phone_cd     = f8  with protect,   constant(uar_get_code_by(   'MEANING',    43, 'BUSINESS'                  ))
declare business_fax_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',    43, 'FAX BUS'                   ))
declare ord_act_ord_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  6003, 'ORDER'                     ))
declare dischg_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',    17, 'DISCHARGE'                 ))
declare final_cd              = f8  with protect,   constant(uar_get_code_by(   'MEANING',    17, 'FINAL'                     ))
declare spec_cd               = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 19189, 'SPECIALTYGROUP'            ))
declare ndc_cd                = f8  with protect,   constant(uar_get_code_by(   'MEANING', 11000, 'NDC'                       ))
declare med_prod_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',  4063, 'MEDPRODUCT'                ))

declare male_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',    57, 'MALE'                      ))
declare female_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',    57, 'FEMALE'                    ))

declare id_max                = i4  with protect, noconstant(0)
declare mrn_max               = i4  with protect, noconstant(0)
declare name_first_max        = i4  with protect, noconstant(0)
declare name_middle_max       = i4  with protect, noconstant(0)
declare name_last_max         = i4  with protect, noconstant(0)
declare name_suffix_max       = i4  with protect, noconstant(0)
declare dob_max               = i4  with protect, noconstant(0)
declare add_street_1_max      = i4  with protect, noconstant(0)
declare add_street_2_max      = i4  with protect, noconstant(0)
declare add_city_max          = i4  with protect, noconstant(0)
declare add_state_max         = i4  with protect, noconstant(0)
declare add_zip_max           = i4  with protect, noconstant(0)
declare pri_phone_max         = i4  with protect, noconstant(0)
declare sex_max               = i4  with protect, noconstant(0)
declare ord_prov_max          = i4  with protect, noconstant(0)
declare prov_name_first_max   = i4  with protect, noconstant(0)
declare prov_name_middle_max  = i4  with protect, noconstant(0)
declare prov_name_last_max    = i4  with protect, noconstant(0)
declare prov_name_suffix_max  = i4  with protect, noconstant(0)
declare prescribe_npi_max     = i4  with protect, noconstant(0)
declare prov_add_street_1_max = i4  with protect, noconstant(0)
declare prov_add_street_2_max = i4  with protect, noconstant(0)
declare prov_add_city_max     = i4  with protect, noconstant(0)
declare prov_add_state_max    = i4  with protect, noconstant(0)
declare prov_add_zip_max      = i4  with protect, noconstant(0)
declare prov_phone_max        = i4  with protect, noconstant(0)
declare prov_fax_max          = i4  with protect, noconstant(0)
declare prov_spec_max         = i4  with protect, noconstant(0)
declare clinic_name_max       = i4  with protect, noconstant(0)
declare prov_affil_max        = i4  with protect, noconstant(0)
declare prov_cred_max         = i4  with protect, noconstant(0)
declare rx_date_max           = i4  with protect, noconstant(0)
declare rx_drug_max           = i4  with protect, noconstant(0)
declare rx_ndc_nbr_max        = i4  with protect, noconstant(0)
declare dv_med_id_max         = i4  with protect, noconstant(0)
declare rx_refill_max         = i4  with protect, noconstant(0)
declare rx_strength_max       = i4  with protect, noconstant(0)
declare rx_freq_max           = i4  with protect, noconstant(0)
declare rx_quant_max          = i4  with protect, noconstant(0)
declare daysupp_max           = i4  with protect, noconstant(0)
declare brandname_max         = i4  with protect, noconstant(0)
declare med_status_max        = i4  with protect, noconstant(0)
declare med_time_max          = i4  with protect, noconstant(0)
declare med_direct_max        = i4  with protect, noconstant(0)
declare prior_auth_max        = i4  with protect, noconstant(0)
declare reorder_max           = i4  with protect, noconstant(0)
declare pharm_name_max        = i4  with protect, noconstant(0)
declare pharm_add_max         = i4  with protect, noconstant(0)
declare prindx_max            = i4  with protect, noconstant(0)
declare plan_name_max         = i4  with protect, noconstant(0)
declare pri_insure_max        = i4  with protect, noconstant(0)
declare pri_plan_type_max     = i4  with protect, noconstant(0)
declare pri_group_max         = i4  with protect, noconstant(0)
declare pri_sponsor_max       = i4  with protect, noconstant(0)
declare pri_sponsor_max       = i4  with protect, noconstant(0)
declare pri_member_id_max     = i4  with protect, noconstant(0)
declare dc_date_max           = i4  with protect, noconstant(0)

declare out_str               = vc  with protect, noconstant('')
declare cr_char               = vc  with protect,   constant(char(13))
declare lf_char               = vc  with protect,   constant(char(10))
declare delim_char            = vc  with protect,   constant('|')

declare pos                   = i4  with protect, noconstant(0)
declare idx                   = i4  with protect, noconstant(0)
declare looper                = i4  with protect, noconstant(0)
declare looper2               = i4  with protect, noconstant(0)

declare ssn_temp              = vc  with protect, noconstant('')

declare shield_rx_file        = vc  with protect, noconstant('MINE')

declare run_beg_dt_tm         = dq8 with protect,   constant(cnvtdatetime(curdate, curtime3))
declare run_end_dt_tm         = dq8 with protect, noconstant(cnvtdatetime(curdate, curtime3))

/*************************************************************************
; DVDev Start Coding
**************************************************************************/
declare prog_timer = i4
set prog_timer = ctd_add_timer('99_SHIELD_EXTRACT_RX')


;If we are running in an extract, we'll pass in 0 dates, and we should find our own extract time frame based on when the extract is
;run
if($beg_date = '0' and $end_date = '0')
    ;004 Mods here...  changing the current code to only run if we are using extract and extracttest.  New stuff below.
    if($OUTDEV in ('EXTRACTTEST', 'EXTRACT'))
        ;Weekly previous 7 day on fridays.

        /*
        So if today is Friday the 13th, we want this to be the 7th-13th
        */
        set default_beg_dt = datetimefind(cnvtlookbehind('1,D'), 'D', 'E', 'E')  ;End of the current Friday.
        set default_end_dt = default_beg_dt                                                ;Storing that into the end.

        set default_beg_dt = datetimefind(datetimeadd(default_beg_dt, - 6), 'D', 'B', 'B') ;End of the Sat before this week.
    ;004->
    ;This is a 6 week lookback currently... run on the first of the month.  So we can lookback using that assumption.
    ;Comments below based on week 1 and 2 being last week, and the week before.  3 and 4 being the two weeks behind that. etc.
    elseif($OUTDEV in ('EXTRACTWK1'))  ;This is week 1 and 2
        
        set default_end_dt = datetimefind(datetimeadd(cnvtdatetime(curdate, curtime3), - 1), 'D', 'E', 'E') ;End of yesterday
        set default_beg_dt = datetimefind(datetimeadd(default_end_dt, - 13), 'D', 'B', 'B') ;2 weeks before that, start of day
    
    elseif($OUTDEV in ('EXTRACTWK2'))  ;This is week 3 and 4
        ;This is a 6 week lookback currently... so... I think I use the day before as the end date time.
        set default_end_dt = datetimefind(datetimeadd(cnvtdatetime(curdate, curtime3), - 15), 'D', 'E', 'E') ;End of 3 weeks ago
        set default_beg_dt = datetimefind(datetimeadd(default_end_dt, - 13), 'D', 'B', 'B') ;2 weeks before that, start of day
    
    elseif($OUTDEV in ('EXTRACTWK3'))  ;This is week 5 and 6
        ;This is a 6 week lookback currently... so... I think I use the day before as the end date time.
        set default_end_dt = datetimefind(datetimeadd(cnvtdatetime(curdate, curtime3), - 29), 'D', 'E', 'E') ;end of 5 weeks ago
        set default_beg_dt = datetimefind(datetimeadd(default_end_dt, - 13), 'D', 'B', 'B') ;2 weeks before that, start of day
    endif
    ;004<-
    

    declare beg_dt_tm  = dq8 with protect, constant(default_beg_dt)
    declare end_dt_tm  = dq8 with protect, constant(default_end_dt)

    call echo('Defaulted dates:')

else
    declare beg_dt_tm  = dq8 with protect, constant(cnvtdatetime($beg_date))
    declare end_dt_tm  = dq8 with protect, constant(cnvtdatetime($end_date))

    call echo('Adhoc dates:')
endif


call echo(concat('BEG_DT_TM:', format(beg_dt_tm, '@SHORTDATETIME')))
call echo(concat('END_DT_TM:', format(end_dt_tm, '@SHORTDATETIME')))



;Historical is for tests, and backfills, however it is pulled as well from the automated interface
if($OUTDEV = 'EXTRACTTEST')
    set shield_rx_file = concat( 'cust_output:shield/historical/medstar_prescription_'
                               , trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'),3)
                               , '.dat')
                               
elseif($OUTDEV = 'EXTRACT')
    set shield_rx_file = concat( 'cust_output:shield/medstar_prescription_'                         
                               , trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'), 3)
                               , '.dat')
                               
;004->  They want a new format for the lookback guy
elseif($OUTDEV = 'EXTRACTWK1')
    set shield_rx_file = concat( 'cust_output:shield/medstar_prescription_m_'
                               , trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'), 3)
                               , '_1.dat')
elseif($OUTDEV = 'EXTRACTWK2')
    set shield_rx_file = concat( 'cust_output:shield/medstar_prescription_m_'
                               , trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'), 3)
                               , '_2.dat')
elseif($OUTDEV = 'EXTRACTWK3')
    set shield_rx_file = concat( 'cust_output:shield/medstar_prescription_m_'
                               , trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'), 3)
                               , '_3.dat')
;004<-
else
    set shield_rx_file = $OUTDEV
endif

call echo(concat('File Location: ', shield_rx_file))


;004->
/*************************************************************************
DESCRIPTION:  Find Main Ord Candidate Data
      NOTES:  I was doing most the work in the same query here, but that 
              hosed performance.  Now I'm just going to use the index to 
              gather the candidates (Norm and DC) and filter them both out
              in the same query.
              
              I guess this also helps because I can do all the oa person 
              person_name stuff in the same query, rather than twice.
**************************************************************************/
call ctd_add_timer('Main Ord Candidate')
select into 'nl:'
  from orders o
 where o.active_ind       =  1
   and o.orig_order_dt_tm >= cnvtdatetime(beg_dt_tm)
   and o.orig_order_dt_tm <= cnvtdatetime(end_dt_tm)
   and o.orig_ord_as_flag in (1, 2, 3) ;from uCern:     ;003 Adding 2 and 3 here.
                                          ; 0: InPatient Order
                                          ; 1: Prescription/Discharge Order
                                          ; 2: Recorded / Home Meds
                                          ; 3: Patient Owns Meds
                                          ; 4: Pharmacy Charge Only
                                          ; 5: Satellite (Super Bill) Meds.
   ;004-> Trying to better hit this index
   and o.product_id       =  0
   and o.order_status_cd  in (2543.00, 2548.00, 2550.00, 2545.00)  ;Completed, Inprocess, Ordered, DCed
   and o.activity_type_cd =  705.00  ;PHARM
   ;004<-
order by o.orig_order_dt_tm
detail
    candidate_ord->cnt = candidate_ord->cnt + 1
    
    if(mod(candidate_ord->cnt, 100) = 1)
        stat = alterlist(candidate_ord->qual, candidate_ord->cnt + 100)
    endif
    
    candidate_ord->qual[candidate_ord->cnt]->ord_id            = o.order_id
    candidate_ord->qual[candidate_ord->cnt]->catalog_cd        = o.catalog_cd

    candidate_ord->qual[candidate_ord->cnt]->rx_date           = format(o.orig_order_dt_tm, 'YYYYMMDD;;d')

    candidate_ord->qual[candidate_ord->cnt]->med_status        = trim(uar_get_code_display(o.order_status_cd) , 3)
    candidate_ord->qual[candidate_ord->cnt]->med_time          = trim(format(o.status_dt_tm, 'YYYYMMDD HH:MM'), 3)
    candidate_ord->qual[candidate_ord->cnt]->med_directions    = trim(o.clinical_display_line, 3)

    ;TODO it seems like I can get orders with no encounter id and the order doesn't have it on order details
    ;     like a future order
    candidate_ord->qual[candidate_ord->cnt]->encntr_id         = o.encntr_id
    candidate_ord->qual[candidate_ord->cnt]->person_id         = o.person_id

    candidate_ord->qual[candidate_ord->cnt]->discontinue_date  = format(o.discontinue_effective_dt_tm, 'YYYYMMDD;;d')

    candidate_ord->qual[candidate_ord->cnt]->synonym_id        = o.synonym_id
    
    candidate_ord->qual[candidate_ord->cnt]->rx_drug           = o.ordered_as_mnemonic  ;005
with nocounter   
;troubleshooting with maxqual, if you need it, comment the order by
;with orahintcbo('GATHER_PLAN_STATISTICS MONITOR mmm1741'), maxqual(o, 1000)
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find DCed Ord Candidate Data
       NOTE:  This is sort of goofy.  They want to pick up the DCed for the
              week, and the above won't necessarily do it.  The
              discontinue_effective_dt_tm doesn't have an index at all...

              So I'm going to look for RXes that have updated this week,
              check to see if they are DCed, and send them if they are.

              This means I basically have to redo the query above and add
              it to the results above.
**************************************************************************/
call ctd_add_timer('DCed Ord Candidate')
select into 'nl:'
  from orders o
 where o.active_ind                   =  1
   and o.updt_dt_tm                   >= cnvtdatetime(beg_dt_tm)
   and o.updt_dt_tm                   <= cnvtdatetime(end_dt_tm)
   and o.discontinue_ind              =  1
   and o.discontinue_effective_dt_tm  >= cnvtdatetime(beg_dt_tm)
   and o.discontinue_effective_dt_tm  <= cnvtdatetime(end_dt_tm)
   and o.orig_order_dt_tm             >= cnvtdatetime('01-JAN-2018')  ;004 Trying to limit the size here... we pull ancient stuff 
   and o.orig_ord_as_flag             in (1, 2, 3) ;from uCern:     ;003 Adding 2 and 3 here.
                                                   ; 0: InPatient Order
                                                   ; 1: Prescription/Discharge Order
                                                   ; 2: Recorded / Home Meds
                                                   ; 3: Patient Owns Meds
                                                   ; 4: Pharmacy Charge Only
                                                   ; 5: Satellite (Super Bill) Meds.
order by o.orig_order_dt_tm
detail
    candidate_ord->cnt = candidate_ord->cnt + 1
    
    if(mod(candidate_ord->cnt, 100) = 1)
        stat = alterlist(candidate_ord->qual, candidate_ord->cnt + 99)
    endif
    
    candidate_ord->qual[candidate_ord->cnt]->ord_id            = o.order_id
    candidate_ord->qual[candidate_ord->cnt]->catalog_cd        = o.catalog_cd

    candidate_ord->qual[candidate_ord->cnt]->rx_date           = format(o.orig_order_dt_tm, 'YYYYMMDD;;d')

    candidate_ord->qual[candidate_ord->cnt]->med_status        = trim(uar_get_code_display(o.order_status_cd) , 3)
    candidate_ord->qual[candidate_ord->cnt]->med_time          = trim(format(o.status_dt_tm, 'YYYYMMDD HH:MM'), 3)
    candidate_ord->qual[candidate_ord->cnt]->med_directions    = trim(o.clinical_display_line, 3)

    ;TODO it seems like I can get orders with no encounter id and the order doesn't have it on order details
    ;     like a future order
    candidate_ord->qual[candidate_ord->cnt]->encntr_id         = o.encntr_id
    candidate_ord->qual[candidate_ord->cnt]->person_id         = o.person_id

    candidate_ord->qual[candidate_ord->cnt]->discontinue_date  = format(o.discontinue_effective_dt_tm, 'YYYYMMDD;;d')

    candidate_ord->qual[candidate_ord->cnt]->synonym_id        = o.synonym_id
    
    candidate_ord->qual[candidate_ord->cnt]->rx_drug           = o.ordered_as_mnemonic  ;005
    
with nocounter
;troubleshooting with maxqual, if you need it, comment the order by
;with orahintcbo('GATHER_PLAN_STATISTICS MONITOR mmm1742'), maxqual(o, 1000)
call ctd_end_timer(0)


set stat = alterlist(candidate_ord->qual, candidate_ord->cnt)


/*************************************************************************
DESCRIPTION:  Find Final Population Info
       
       NOTE:  Okay... we have our candidate Ords and DCed... now we can 
              perform the final filters, and data gathering.
**************************************************************************/
call ctd_add_timer('Final Population')
select into 'nl:'
  from order_action          oa
     , (dummyt d with seq = candidate_ord->cnt)
  
  plan d
   where candidate_ord->cnt                 >  0
     and candidate_ord->qual[d.seq]->ord_id >  0
  
  join oa
  ;TODO not sure about this, I've stolen it from saa126_14_mp.prg (referral management mpage)
   where oa.order_id                        =  candidate_ord->qual[d.seq]->ord_id
     and oa.action_type_cd                  =  ord_act_ord_cd
order by oa.order_id, oa.action_sequence desc ;005
head oa.order_id
    pos = locateval(idx, 1, extract_data->cnt, candidate_ord->qual[d.seq]->ord_id,  extract_data->qual[idx]->rx_id)

    ;Seems as if you can have multiple current names.  So I need to make sure we haven't added already.
    if(pos = 0)
        extract_data->cnt = extract_data->cnt + 1

        ;For cleaner code below
        pos = extract_data->cnt

        if(mod(pos, 100) = 1)
            stat = alterlist(extract_data->qual, extract_data->cnt + 99)
        endif
        
        extract_data->qual[pos]->rx_id            = candidate_ord->qual[d.seq]->ord_id
        extract_data->qual[pos]->catalog_cd       = candidate_ord->qual[d.seq]->catalog_cd      
        extract_data->qual[pos]->rx_date          = candidate_ord->qual[d.seq]->rx_date  
        extract_data->qual[pos]->rx_id_txt        = candidate_ord->qual[d.seq]->rx_id_txt       
        extract_data->qual[pos]->med_status       = candidate_ord->qual[d.seq]->med_status      
        extract_data->qual[pos]->med_time         = candidate_ord->qual[d.seq]->med_time        
        extract_data->qual[pos]->med_directions   = candidate_ord->qual[d.seq]->med_directions  
        extract_data->qual[pos]->encntr_id        = candidate_ord->qual[d.seq]->encntr_id       
        extract_data->qual[pos]->person_id        = candidate_ord->qual[d.seq]->person_id       
        extract_data->qual[pos]->discontinue_date = candidate_ord->qual[d.seq]->discontinue_date
        extract_data->qual[pos]->synonym_id       = candidate_ord->qual[d.seq]->synonym_id      
        extract_data->qual[pos]->rx_drug          = candidate_ord->qual[d.seq]->rx_drug      
        
        extract_data->qual[pos]->prov_prsnl_id     = oa.order_provider_id    
        extract_data->qual[pos]->reorder           = 'No' ;003 defaulting
        
        if(candidate_ord->qual[d.seq]->orig_ord_as_flag in (2, 3))
            extract_data->qual[pos]->hx = 'Yes'
        else
            extract_data->qual[pos]->hx = 'No'
        endif
        
    endif

foot report
    stat = alterlist(extract_data->qual, extract_data->cnt)
with nocounter;, orahintcbo('GATHER_PLAN_STATISTICS MONITOR MMMFINAL008')
call ctd_end_timer(0)


;unneeded now and huge
free record candidate_ord

/*************************************************************************
DESCRIPTION:  Find Synonym Info
       NOTE:  
**************************************************************************/
call ctd_add_timer('Find Synonym Info')
select into 'nl:'
  from order_catalog_synonym ocs
     , (dummyt d with seq = extract_data->cnt)
  
  plan d
   where extract_data->cnt                     >  0
     and extract_data->qual[d.seq]->synonym_id >  0
  
  join ocs
   where ocs.synonym_id                        =  extract_data->qual[d.seq]->synonym_id
     and ocs.active_ind                        =  1
detail
    extract_data->qual[d.seq]->rx_drug         = trim(ocs.mnemonic, 3)
    extract_data->qual[d.seq]->synonym_id      = ocs.synonym_id  ;004

with nocounter;, orahintcbo('GATHER_PLAN_STATISTICS MONITOR MMMSYN003')
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find Patient Info
**************************************************************************/
call ctd_add_timer('Patient Info')
select into 'nl:'
  from person                p
     , person_name           pn
     , (dummyt d with seq = extract_data->cnt)
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->person_id >  0
  
  join p
   where p.person_id                          =  extract_data->qual[d.seq]->person_id
     and p.active_ind                         =  1 
  
  join pn
   where pn.person_id                         =  p.person_id 
     and pn.beg_effective_dt_tm               <= cnvtdatetime(curdate, curtime3)
     and pn.end_effective_dt_tm               >= cnvtdatetime(curdate, curtime3)
     and pn.active_ind                        =  1
     and pn.name_type_cd                      =  cur_per_name_cd
     ;if we want to do this now that this is out of the population query... 
     ;we'll have to flag the row or catch the names in the file gen.
     ;and pn.name_last_key                     not in ('ZZ*TEST*', 'ZZ*CERNER*')
  
detail
    
    extract_data->qual[d.seq]->name_first        = p.name_first
    extract_data->qual[d.seq]->name_middle       = p.name_middle
    extract_data->qual[d.seq]->name_last         = p.name_last
    extract_data->qual[d.seq]->dob               = format(p.birth_dt_tm, 'YYYYMMDD;;d')

    extract_data->qual[d.seq]->name_suffix       = pn.name_suffix

    case(p.sex_cd)
    of male_cd  : extract_data->qual[d.seq]->sex = '1'
    of female_cd: extract_data->qual[d.seq]->sex = '2'
    else          extract_data->qual[d.seq]->sex = '0'
    endcase
    
with nocounter;, orahintcbo('GATHER_PLAN_STATISTICS MONITOR MMMPERSON005')
call ctd_end_timer(0)


;004<-

;003 ->
/*************************************************************************
DESCRIPTION:  Find reorder info
       
       NOTE:  I don't really know what I am doing here... the ask is to 
              try and find if a prescription was reordered or new.  I'm 
              going to try and use order_recon to catch cases where we 
              know that the med is reordered... but this isn't really what
              is documented on that table, and I don't know a good way to 
              determine what they are after.
**************************************************************************/
call ctd_add_timer('Reorder Info')
select into 'nl:'
  from order_recon orr
     , order_recon_detail ord
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->qual[d.seq]->rx_id != 0
  join ord
   where ord.order_nbr = extract_data->qual[d.seq]->rx_id
  join orr
   where ord.order_recon_id = orr.order_recon_id
order by orr.order_recon_id
detail
    ;there can be multiple rows... might want to watch out for that.
    if(orr.recon_type_flag = 3) ;DC/Outpat
        
        case(ord.recon_order_action_mean)
        of 'RENEW_RX':
        ;of 'RECON_CONTINUE':
        ;of 'RECON_ACKNOWLEDGE':
        ;of 'CONVERT_HX':
        ;of 'CONVERT_RX':
        ;of 'REPEAT':
        ;of 'CONVERT_INPAT':
        ;of 'CANCEL REORD':
            extract_data->qual[d.seq]->reorder           = 'Yes' 
        endcase
        
        ;Possible statuses
        /*
        ORDER
            MODIFY
            ORDER
            ACCEPT

        RENEW_RX
            CONVERT_RX
            CONVERT_HX
            RECON_ACKNOWLEDGE
            RECON_CONTINUE
            RENEW_RX
            REPEAT
            CANCEL REORD
            CONVERT_INPAT
            
        OTHER
            CANCEL DC
            DELETE
            CANCEL
            COMPLETE
            WITHDRAW
            RECON_DO_NOT_COPY
            RECON_DO_NOT_CNVT
            DISCONTINUE
            RECON_DO_NOT_CONT 
        */
    endif
    
with nocounter
;003<-
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find person_alias info
**************************************************************************/
call ctd_add_timer('Person_alias Info')
select into 'nl:'
  from person_alias pa
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->person_id != 0
  join pa
   where pa.person_id                         =  extract_data->qual[d.seq]->person_id
     and pa.person_alias_type_cd              in (ssn_cd, per_mrn_cd)
     and pa.alias                             >  ' '
     and pa.active_ind                        =  1
     and pa.beg_effective_dt_tm               <= cnvtdatetime(curdate, curtime3)
     and pa.end_effective_dt_tm               >= cnvtdatetime(curdate, curtime3)
detail
    case(pa.person_alias_type_cd)
    of ssn_cd:
        ;Seeing weird non-nine lengths
        if(textlen(pa.alias)  = 9)
            ;this assign is just in case we have to do some replacing later to remove non numerics.
            ssn_temp = trim(pa.alias, 3)

            ;we only want last 4
            extract_data->qual[d.seq]->last_4_ssn = substring(6, 4, ssn_temp)
        endif

    of per_mrn_cd:
        if(extract_data->qual[d.seq]->mrn = '')

            extract_data->qual[d.seq]->mrn = trim(pa.alias, 3)
        endif
    endcase

with nocounter
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find order proposal
**************************************************************************/
call ctd_add_timer('Order Proposal')
select into 'nl:'
  from order_proposal op
     , prsnl          p
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->rx_id     != 0
  join op
   where op.order_id                          =  extract_data->qual[d.seq]->rx_id
     and op.proposed_action_type_cd           =  ord_act_ord_cd
  join p
   where p.person_id                          =  op.entered_by_prsnl_id
detail
    extract_data->qual[d.seq]->ord_prov_id = p.person_id
    extract_data->qual[d.seq]->ord_prov    = trim(p.name_full_formatted, 3)
with nocounter
call ctd_end_timer(0)



/**********************************************************************
DESCRIPTION:  Find Patient Addresses
***********************************************************************/
call ctd_add_timer('Patient Addresses')
select into 'nl:'
  from address a
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->person_id != 0
  join a
   where a.parent_entity_name                 =  "PERSON"
     and a.parent_entity_id                   =  extract_data->qual[d.seq]->person_id
     and a.active_ind                         =  1
     and a.address_type_cd                    =  home_cd
detail
    extract_data->qual[d.seq]->add_street_1 = trim(a.street_addr, 3)
    extract_data->qual[d.seq]->add_street_2 = trim(a.street_addr2, 3)
    extract_data->qual[d.seq]->add_city     = trim(a.city, 3)
    extract_data->qual[d.seq]->add_state    = trim(a.state, 3)
    extract_data->qual[d.seq]->add_zip      = substring(1, 5, a.zipcode) ;They don't want extentions here

with nocounter
call ctd_end_timer(0)


/**********************************************************************
DESCRIPTION:  Find phone numbers
***********************************************************************/
call ctd_add_timer('Phone Numbers')
select into 'nl:'
  from phone p
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->person_id != 0
  join p
   where p.parent_entity_name                 =  "PERSON"
     and p.parent_entity_id                   =  extract_data->qual[d.seq]->person_id
     and p.active_ind                         =  1
     and p.phone_num                          >  ' '
     and p.phone_type_cd                      =  home_phone_cd
detail

    extract_data->qual[d.seq]->primary_phone  =
            ;Remove any chars if present
            replace(replace(replace(replace(trim(p.phone_num, 3), '(', ''), ')', ''), '-', ''),'x', '')
with nocounter
call ctd_end_timer(0)


/**********************************************************************
DESCRIPTION:  Find provider info
***********************************************************************/
call ctd_add_timer('Provider Info')
select into 'nl:'
  from person_name pn
     , phone       ph
     , credential  c
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                        >  0
     and extract_data->qual[d.seq]->prov_prsnl_id != 0
  join pn
   where pn.person_id                             =  extract_data->qual[d.seq]->prov_prsnl_id
     ;This is probably not a concern, but we might have to worry about name as present during the week...
     and pn.beg_effective_dt_tm                   <= cnvtdatetime(curdate, curtime3)
     and pn.end_effective_dt_tm                   >= cnvtdatetime(curdate, curtime3)
     and pn.active_ind                            =  1
     and pn.name_type_cd                          =  prsnl_per_name_cd
  join ph
   ;TODO I don't know if I should be pulling the clinic phone/fax, or the phys phone fax.  Pulling Phys for now.
   where ph.parent_entity_name                    =  outerjoin('PERSON' )
     and ph.parent_entity_id                      =  outerjoin(pn.person_id)
     and ph.active_ind                            =  outerjoin(1)
     and ph.phone_num                             >  outerjoin(' ')
     and (
             ph.phone_type_cd                     =  outerjoin(business_phone_cd)
          or ph.phone_type_cd                     =  outerjoin(business_fax_cd)
         )
   join c
    where c.prsnl_id                              =  outerjoin(pn.person_id)
      ;I'm guessing this is how we find the most significant cred.
      and c.display_seq                           =  outerjoin(1)
      and c.beg_effective_dt_tm                   <= outerjoin(cnvtdatetime(curdate, curtime3))
      and c.end_effective_dt_tm                   >= outerjoin(cnvtdatetime(curdate, curtime3))
      and c.active_ind                            =  outerjoin(1)
detail
    ;Is the ordering provider the authorizor or the ordering... if ordering, where do I get the authorizor?
    extract_data->qual[d.seq]->prov_name_first     = pn.name_first
    extract_data->qual[d.seq]->prov_name_middle    = pn.name_middle
    extract_data->qual[d.seq]->prov_name_last      = pn.name_last
    extract_data->qual[d.seq]->prov_name_suffix    = pn.name_suffix

    if(ph.phone_num is not null)
        case(ph.phone_type_cd)
        of business_phone_cd:
            extract_data->qual[d.seq]->prov_phone  =
                ;Remove any chars if present
                replace(replace(replace(replace(trim(ph.phone_num, 3), '(', ''), ')', ''), '-', ''),'x', '')
        of   business_fax_cd:
            extract_data->qual[d.seq]->prov_fax    =
                ;Remove any chars if present
                replace(replace(replace(replace(trim(ph.phone_num, 3), '(', ''), ')', ''), '-', ''),'x', '')
        endcase
    endif

    if(c.credential_cd is not null)
        extract_data->qual[d.seq]->prov_cred       = trim(uar_get_code_display(c.credential_cd), 3)
    endif
with nocounter
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find provider specialty
**************************************************************************/
call ctd_add_timer('Provider Specialty')
select into 'nl:'
  from prsnl_group_reltn pgr
     , prsnl_group pg
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                        >  0
     and extract_data->qual[d.seq]->prov_prsnl_id != 0
  join pgr
   where pgr.person_id                            =  extract_data->qual[d.seq]->prov_prsnl_id
     and pgr.active_ind                           =  1
     and pgr.beg_effective_dt_tm                  <= cnvtdatetime(curdate, curtime3)
     and pgr.end_effective_dt_tm                  >= cnvtdatetime(curdate, curtime3)
  join pg
   where pg.prsnl_group_id = pgr.prsnl_group_id
     and pg.active_ind                            =  1
     and pg.beg_effective_dt_tm                   <= cnvtdatetime(curdate, curtime3)
     and pg.end_effective_dt_tm                   >= cnvtdatetime(curdate, curtime3)
     and pg.prsnl_group_class_cd                  =  spec_cd
detail
    extract_data->qual[d.seq]->prov_spec = trim(uar_get_code_display(pg.prsnl_group_type_cd), 3)
with nocounter
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find provider NPI
**************************************************************************/
call ctd_add_timer('Provider NPI')
select into 'nl:'
  from prsnl_alias pa
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                        >  0
     and extract_data->qual[d.seq]->prov_prsnl_id != 0
  join pa
   where pa.person_id                             =  extract_data->qual[d.seq]->prov_prsnl_id
     and pa.active_ind                            =  1
     and pa.beg_effective_dt_tm                   <= cnvtdatetime(curdate, curtime3)
     and pa.end_effective_dt_tm                   >= cnvtdatetime(curdate, curtime3)
     and pa.prsnl_alias_type_cd                   =  npi_cd
detail
    extract_data->qual[d.seq]->prescriber_npi  = trim(pa.alias, 3)

with nocounter
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find provider/clinic address
**************************************************************************/
call ctd_add_timer('Provider/Clinic Address')
select into 'nl:'
  from encounter    e
     , address      a
     , organization o
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->encntr_id != 0
  join e
   where e.encntr_id                          =  extract_data->qual[d.seq]->encntr_id
     and e.active_ind                         =  1
  join a
   where a.parent_entity_name                 =  'LOCATION'
     ;I don't know if there should be some kind of heirarchy here, for now I'm just going to grab whatever I can find
     and a.parent_entity_id                   in (e.loc_building_cd, e.loc_facility_cd, e.location_cd)
     and a.active_ind                         =  1
     ;mailing seems right here, but it looks like business is pulling more results.
     and a.address_type_cd                    in (mail_cd, business_cd)
   join o
    where o.organization_id                   =  outerjoin(e.organization_id)
      and o.active_ind                        =  outerjoin(1)
detail

    extract_data->qual[d.seq]->clinic_name       = trim(uar_get_code_display(e.loc_nurse_unit_cd), 3)

    extract_data->qual[d.seq]->prov_affiliation  = trim(o.org_name, 3)

    extract_data->qual[d.seq]->prov_add_street_1 = trim(a.street_addr, 3)
    extract_data->qual[d.seq]->prov_add_street_2 = trim(a.street_addr2, 3)
    extract_data->qual[d.seq]->prov_add_city     = trim(a.city, 3)

    if(a.state_cd > 0)
        extract_data->qual[d.seq]->prov_add_state = trim(uar_get_code_display(a.state_cd), 3)
    elseif(trim(a.state, 3) = 'District of Columbia')
        extract_data->qual[d.seq]->prov_add_state   = 'DC'
    else
        extract_data->qual[d.seq]->prov_add_state = trim(a.state, 3)
    endif

    extract_data->qual[d.seq]->prov_add_zip      = substring(1, 5, a.zipcode) ;They don't want extentions here

with nocounter
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find order details

       NOTE:  For some reason if I added this to the order query above,
              performance dived no matter what index I hit OD with.  Maybe
              seporating it out will help?
**************************************************************************/
call ctd_add_timer('Order Details')
select into 'nl:'
  from order_detail od
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                >  0
     and extract_data->qual[d.seq]->rx_id != 0
  join od
   where od.order_id                      =  extract_data->qual[d.seq]->rx_id
         ;this goofiness is for the better index I hope.
     and od.oe_field_meaning_id in(
        select oe.oe_field_meaning_id
          from oe_field_meaning oe
         where oe.oe_field_meaning in ('NBRREFILLS'
                                      ,'FREQ'
                                      ,'DISPENSEQTY'
                                      ,'DISPENSEQTYUNIT'
                                      ,'ROUTINGPHARMACYNAME'
                                      ,'ROUTINGPHARMACYID'
                                      )
        )
order by od.order_id, od.detail_sequence
detail
    ;TODO right now I'm counting on ordering of the units being after the values.  this might not be the case and will need work.
    case(od.oe_field_meaning)
    of 'NBRREFILLS'         : extract_data->qual[d.seq]->rx_refills  = trim(od.oe_field_display_value, 3)
    of 'FREQ'               : extract_data->qual[d.seq]->rx_freq     = trim(od.oe_field_display_value, 3)
    of 'DISPENSEQTY'        : extract_data->qual[d.seq]->rx_quantity = trim(od.oe_field_display_value, 3)
    of 'DISPENSEQTYUNIT'    :
        extract_data->qual[d.seq]->rx_quantity = concat(extract_data->qual[d.seq]->rx_quantity, ' ',
                                                        trim(od.oe_field_display_value, 3))
    of 'ROUTINGPHARMACYNAME': extract_data->qual[d.seq]->pharm_name  = trim(od.oe_field_display_value, 3)
    of 'ROUTINGPHARMACYID'  : extract_data->qual[d.seq]->pharm_id    = trim(od.oe_field_display_value, 3)
    endcase
with nocounter
call ctd_end_timer(0)

;004->  Trying something new.

;Now we want to see if we can find some addresses for those pharms
call echo('Calling Pharm Script: Processing')
call ctd_add_timer('Pharm Script')

set 3202501_request->active_status_flag = 1
for(looper = 1 to extract_data->cnt)
    ;Try two... doing it pharm by pharm was horrible.  Let's see if we batch it if it is better.
    
    if(extract_data->qual[looper]->pharm_id != '')
        set pos = locateval(idx, 1                                   , size(3202501_request->ids, 5)
                               , extract_data->qual[looper]->pharm_id, 3202501_request->ids[idx]->id)
        
        if(pos = 0)
            set 3202501_request->id_cnt = 3202501_request->id_cnt + 1
            
            if(mod(3202501_request->id_cnt, 10) = 1)
                set stat = alterlist(3202501_request->ids, 3202501_request->id_cnt + 9)
            endif
            
            set 3202501_request->ids[3202501_request->id_cnt]->id = extract_data->qual[looper]->pharm_id
        endif
    endif
endfor


set appnum  = 3202004
set tasknum = 3202004
set reqnum  = 3202501


set stat = tdbexecute(appnum, tasknum, reqnum,
                      'REC', 3202501_request,
                      'REC', 3202501_reply)  

for(looper = 1 to extract_data->cnt)
    if(mod(looper, 100) = 0)
        call echo(concat(trim(cnvtstring(looper), 3), ' of ', trim(cnvtstring(extract_data->cnt),3)))
    endif
    
    set pos = locateval(idx, 1                                   , size(3202501_REPLY->pharmacies, 5)
                           , extract_data->qual[looper]->pharm_id, 3202501_REPLY->pharmacies[idx]->id                       )
    
    if(pos > 0)
        ;Oh... manual building of addresses.  This won't go wrong I'm sure.
        for(looper2 = 1 to
            size(3202501_REPLY->pharmacies[pos]->
                               primary_business_address->street_address_lines, 5))  ;could this size get any longer?

            if(extract_data->qual[looper]->pharm_address = '')
                set extract_data->qual[looper]->pharm_address =
                    3202501_REPLY->pharmacies[pos]->
                        primary_business_address->street_address_lines[looper2]->street_address_line
            else
                set extract_data->qual[looper]->pharm_address =  concat(extract_data->qual[looper]->pharm_address, ' ',
                    3202501_REPLY->pharmacies[pos]->
                        primary_business_address->street_address_lines[looper2]->street_address_line
                )
            endif
            
        endfor
        
        set extract_data->qual[looper]->pharm_address =  concat(extract_data->qual[looper]->pharm_address, ' ',
            3202501_REPLY->pharmacies[pos]->primary_business_address->city
            )

        set extract_data->qual[looper]->pharm_address =  concat(extract_data->qual[looper]->pharm_address, ', ',
            3202501_REPLY->pharmacies[pos]->primary_business_address->state
            )

        set extract_data->qual[looper]->pharm_address =  concat(extract_data->qual[looper]->pharm_address, ', ',
            substring(1, 5, 3202501_REPLY->pharmacies[pos]->primary_business_address->postal_code)
            )

    endif
    
endfor
;004<-
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find a NDC
      NOTES:  Phew here we go.  I have no idea if this is correct.  I'm
              borrowing this logic from the invision extract:
              invistics_orders_extract_hist

              Brand was added later and there are all kinds of duplicates
              on this, and I don't think I'm gathering this right... I think
              we might pick the brand or the generic.

              I tried fixing this based on what Jennifer is doing on
              9_mum_admin_file.  But I don't have a reliable link through
              order_product...

              TODO just moving on for now.
**************************************************************************/
;select into 'nl:'
;  from order_catalog_item_r ocir
;     , med_identifier       mi
;     , med_flex_object_idx  mfoi
;     , (dummyt d with seq = value(extract_data->cnt))
;   plan d
;    where extract_data->cnt                     >  0
;      and extract_data->qual[d.seq]->catalog_cd != 0
;   join ocir
;    where extract_data->qual[d.seq]->catalog_cd = ocir.catalog_cd
;   join mi
;    where mi.item_id                            =  ocir.item_id
;      and mi.med_identifier_type_cd             in (ndc_cd)
;      and mi.active_ind                         =  1
;      and mi.primary_ind                        =  1
;      and mi.med_type_flag                      =  0
;      and mi.med_product_id                     >  0
;   join mfoi ;trying to filter to parent mi
;    where mfoi.parent_entity_id                 =  mi.med_product_id
;      and mfoi.med_def_flex_id                  =  mi.med_def_flex_id
;      and mfoi.parent_entity_name               =  "MED_PRODUCT"
;      and mfoi.sequence                         =  1
;      and mfoi.active_ind                       =  1
;      and mfoi.flex_object_type_cd              =  med_prod_cd
;detail ;There is a bunch here, not sure if that matters?
;    case(mi.med_identifier_type_cd)
;    of ndc_cd:
;        if(textlen(mi.value_key) = 11)
;            extract_data->qual[d.seq]->rx_ndc_nbr   = trim(mi.value_key, 3)
;        endif
;    endcase
;with nocounter



/*************************************************************************
DESCRIPTION:  Find an RxNorm and NDC
      NOTES:  Phew here we go again.  I have no idea if this is correct.
              I'm in a rush, and interpreting information I found here:
                https://wiki.cerner.com/pages/
                releaseview.action?spaceKey=reference&title=Understand%20Multum%20to%20RxNorm%20Cross%20Mapping%20Content
              I'm crossing my fingers that this works.
**************************************************************************/
;select into 'nl:'
;  from order_catalog           oc
;     , mltm_order_catalog_load moc
;     , cmt_cross_map           ccm
;     , cmt_concept             cc
;     , (dummyt d with seq = value(extract_data->cnt))
;   plan d
;    where extract_data->cnt                     >  0
;      and extract_data->qual[d.seq]->catalog_cd != 0
;   join oc
;    where oc.catalog_cd = extract_data->qual[d.seq]->catalog_cd
;   join moc
;    where moc.mnemonic_type = "Primary"
;      and moc.catalog_cki = oc.cki
;   join ccm
;    where moc.synonym_concept_cki = ccm.concept_cki
;   join cc
;    where ccm.target_concept_cki = cc.concept_cki
;detail
;    extract_data->qual[d.seq]->dv_med_id = trim(cc.concept_identifier, 3)
;with nocounter

;select into 'nl:'
;  from orders                  o
;     , order_catalog_synonym   ocs
;     , mltm_order_catalog_load moc
;     , cmt_cross_map           ccm
;     , cmt_concept             cc
;     , (dummyt d with seq = value(extract_data->cnt))
;   plan d
;    where extract_data->cnt                     >  0
;      and extract_data->qual[d.seq]->rx_id      != 0
;   join o
;    where o.order_id                             = extract_data->qual[d.seq]->rx_id
;   join ocs
;    where ocs.synonym_id                         = o.synonym_id
;   join moc
;    where moc.synonym_cki                        = ocs.cki
;   join ccm
;    where moc.synonym_concept_cki                = ccm.concept_cki
;   join cc
;    where ccm.target_concept_cki                 = cc.concept_cki
;detail
;    extract_data->qual[d.seq]->dv_med_id = trim(cc.concept_identifier, 3)
;with nocounter

;select into 'nl:'
;from  orders o
;    , order_catalog ocat
;    , order_catalog_synonym   ocs
;    , cmt_cross_map   cc
;    , (dummyt d with seq = value(extract_data->cnt))
;plan d
; where extract_data->cnt                     >  0
;   and extract_data->qual[d.seq]->rx_id      != 0
;join o
;   where o.order_id = extract_data->qual[d.seq]->rx_id
;join ocat
; where ocat.catalog_cd = o.catalog_cd
;join ocs
; where ocs.catalog_cd = ocat.catalog_cd
;  and cnvtupper(ocs.mnemonic) = cnvtupper(o.ordered_as_mnemonic)
;join cc where cc.concept_cki = ocs.concept_cki
;detail
;    extract_data->qual[d.seq]->dv_med_id = trim(cc.source_identifier, 3)
;with nocounter



/* Performance here was garbo.  Indexes look fine though.  Trying to limit how much we hit here, by only dummyting against
   the synonyms once for each synonym rather than row by row
*/

declare mltm_parent_timer = i4 with protect, constant(ctd_add_timer('MLTM Data Total'))

free record mltm_data
record mltm_data(
    1 cnt = i4
    1 qual[*]
        2 synonym_id       = f8
        2 drug_synonym_id  = f8
        2 data
            3 dv_med_id    = vc
            3 rx_ndc_nbr   = vc
            3 rx_strength  = vc
            3 rx_brandname = vc
)

/*************************************************************************
DESCRIPTION:  Find an MLTM Order Synonyms.
      NOTES:  After a long fight above in the commented out stuff, we found
              a better way finally.
              
              This was adjusted though to be multiple queries due to 
              performance
              
              TODO I can do this above in the data pop queries.  Avoid the
              first RS all together.  Leaving for now, because that is work.
**************************************************************************/
call ctd_add_timer('MLTM Order Synonyms')
select into 'nl:'
  from order_catalog_synonym     ocs
     , (dummyt d with seq = extract_data->cnt)
plan d
 where extract_data->cnt                >  0
   and extract_data->qual[d.seq]->rx_id != 0
join ocs
 where ocs.synonym_id                     =  extract_data->qual[d.seq]->synonym_id
order by ocs.synonym_id
head ocs.synonym_id
    mltm_data->cnt = mltm_data->cnt + 1

    stat = alterlist(mltm_data->qual, mltm_data->cnt)
    
    mltm_data->qual[mltm_data->cnt]->synonym_id      = ocs.synonym_id
    mltm_data->qual[mltm_data->cnt]->drug_synonym_id = cnvtreal(substring(13, 50, ocs.cki))
with nocounter
call ctd_end_timer(0)


/*************************************************************************
DESCRIPTION:  Find an mltm data.
      NOTES:  After a long fight above in the commented out stuff, we found
              a better way finally.
              
              This was adjusted though to be multiple queries due to 
              performance
**************************************************************************/
call ctd_add_timer('MLTM Data Orders')
select into 'nl:'
from  mltm_rxn_map              mrm
    , mltm_ndc_core_description ncd
    , mltm_ndc_main_drug_code   nmdc
    , mltm_product_strength     ps
    , (dummyt d with seq = mltm_data->cnt)
plan d
 where mltm_data->cnt                          >  0
   and mltm_data->qual[d.seq]->drug_synonym_id != 0
join mrm
 where mrm.drug_synonym_id              =  mltm_data->qual[d.seq]->drug_synonym_id
   and mrm.term_type_meaning            in ('BPCK', 'SCD', 'SBD', 'GPCK')
join ncd
 where mrm.main_multum_drug_code        =  ncd.main_multum_drug_code
join nmdc
 where ncd.main_multum_drug_code        =  nmdc.main_multum_drug_code
join ps
 where nmdc.product_strength_code       =  ps.product_strength_code
detail
    mltm_data->qual[d.seq]->data->dv_med_id    = trim(mrm.rxcui                      , 3)
    mltm_data->qual[d.seq]->data->rx_ndc_nbr   = trim(ncd.ndc_code                   , 3)
    mltm_data->qual[d.seq]->data->rx_strength  = trim(ps.product_strength_description, 3)
    mltm_data->qual[d.seq]->data->rx_brandname = trim(mrm.rxn_description            , 3) ;This isn't a brand name, but Nevin likes
with nocounter
call ctd_end_timer(0)


call ctd_add_timer('MLTM RS Join')

for(looper = 1 to extract_data->cnt)
    set pos = locateval(idx, 1, mltm_data->cnt
                           , extract_data->qual[looper]->synonym_id, mltm_data->qual[idx]->synonym_id)
                           
    if(pos > 0)
        set extract_data->qual[looper]->dv_med_id    = mltm_data->qual[pos]->data->dv_med_id
        set extract_data->qual[looper]->rx_ndc_nbr   = mltm_data->qual[pos]->data->rx_ndc_nbr
        set extract_data->qual[looper]->rx_strength  = mltm_data->qual[pos]->data->rx_strength
        set extract_data->qual[looper]->rx_brandname = mltm_data->qual[pos]->data->rx_brandname
    endif
    
endfor

call ctd_end_timer(0)

call ctd_end_timer(mltm_parent_timer)





/*************************************************************************
DESCRIPTION:  Find PRINDX for visits
**************************************************************************/
call ctd_add_timer('PRINDX')
select into 'nl:'
  from diagnosis    dx
     , nomenclature n
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->encntr_id != 0
  join dx
   where dx.encntr_id                         =  extract_data->qual[d.seq]->encntr_id
     and dx.diag_type_cd                      in (dischg_cd, final_cd)
     and dx.active_ind                        =  1
     and dx.diag_priority                     =  1
     and dx.beg_effective_dt_tm               <= cnvtdatetime(curdate,curtime3)
     and dx.end_effective_dt_tm               >= cnvtdatetime(curdate,curtime3)
  join n
   where dx.nomenclature_id                   = n.nomenclature_id
     and n.active_ind                         =  1
     and n.beg_effective_dt_tm                <= cnvtdatetime(curdate , curtime3)
     and n.end_effective_dt_tm                >= cnvtdatetime(curdate , curtime3)
detail
    extract_data->qual[d.seq]->prindx  = trim(n.source_identifier, 3)

with nocounter
call ctd_end_timer(0)


/**********************************************************************
DESCRIPTION:  Find insurance information

       NOTE: I removed a bunch of active/effective checks from o1, o2, hp,
             and por.  It seems sometimes this is unfilled and we want to
             rely on the zero row to avoid outerjoins.

             The zero row looks like it could be marked as inactive.
***********************************************************************/
call ctd_add_timer('Insurance Info')
select into 'nl:'
  from encntr_plan_reltn epr
     , organization      o1
     , health_plan       hp
     , person_org_reltn  por
     , organization      o2
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                     >  0
     and extract_data->qual[d.seq]->encntr_id !=  0
  join epr
   where epr.encntr_id                         =  extract_data->qual[d.seq]->encntr_id
     and epr.active_ind                        =  1
     ;TODO looks like you can have multiple primary.  Not sure what to do about that. (per_id 27598662.00)
     and epr.priority_seq                      =  1
     and epr.beg_effective_dt_tm               <= cnvtdatetime(curdate , curtime3)
     and epr.end_effective_dt_tm               >= cnvtdatetime(curdate , curtime3)
  join o1
   where epr.organization_id                   =  o1.organization_id
  join hp
   where hp.health_plan_id                     =  epr.health_plan_id
  join por
   where por.person_org_reltn_id               =  epr.sponsor_person_org_reltn_id
  join o2
   where por.organization_id                   =  o2.organization_id
order by epr.encntr_id, epr.priority_seq
detail
    extract_data->qual[d.seq]->plan_name        = trim(hp.plan_name, 3)
    extract_data->qual[d.seq]->pri_insure       = trim(o1.org_name, 3)                         ;TODO is this correct?
    extract_data->qual[d.seq]->pri_plan_type    = trim(uar_get_code_display(hp.plan_type_cd), 3)         ;TODO is this correct?
    extract_data->qual[d.seq]->pri_group        = trim(epr.group_nbr, 3)                                 ;TODO is this correct?
    extract_data->qual[d.seq]->pri_sponsor      = trim(o2.org_name, 3)                                    ;TODO is this correct?
    extract_data->qual[d.seq]->pri_sponsor_type = trim(uar_get_code_display(por.person_org_reltn_cd), 3) ;TODO is this correct?
    extract_data->qual[d.seq]->pri_member_id    = trim(epr.member_nbr, 3)                                ;TODO is this correct?
with nocounter
call ctd_end_timer(0)


call ctd_add_timer('File Buildout')
;Lets find the maxlengths of the columns
for(looper = 1 to extract_data->cnt)
    set extract_data->qual[looper]->rx_id_txt         = cnvtstring(extract_data->qual[looper]->rx_id, 11, 0)

    ;Finding the evil chars causing new lines and such in the file
    set extract_data->qual[looper]->rx_id_txt         = CSV_comma_esc(extract_data->qual[looper]->rx_id_txt        )
    set extract_data->qual[looper]->mrn               = CSV_comma_esc(extract_data->qual[looper]->mrn              )
    set extract_data->qual[looper]->name_first        = CSV_comma_esc(extract_data->qual[looper]->name_first       )
    set extract_data->qual[looper]->name_middle       = CSV_comma_esc(extract_data->qual[looper]->name_middle      )
    set extract_data->qual[looper]->name_last         = CSV_comma_esc(extract_data->qual[looper]->name_last        )
    set extract_data->qual[looper]->name_suffix       = CSV_comma_esc(extract_data->qual[looper]->name_suffix      )
    set extract_data->qual[looper]->dob               = CSV_comma_esc(extract_data->qual[looper]->dob              )
    set extract_data->qual[looper]->add_street_1      = CSV_comma_esc(extract_data->qual[looper]->add_street_1     )
    set extract_data->qual[looper]->add_street_2      = CSV_comma_esc(extract_data->qual[looper]->add_street_2     )
    set extract_data->qual[looper]->add_city          = CSV_comma_esc(extract_data->qual[looper]->add_city         )
    set extract_data->qual[looper]->add_state         = CSV_comma_esc(extract_data->qual[looper]->add_state        )
    set extract_data->qual[looper]->add_zip           = CSV_comma_esc(extract_data->qual[looper]->add_zip          )
    set extract_data->qual[looper]->primary_phone     = CSV_comma_esc(extract_data->qual[looper]->primary_phone    )
    set extract_data->qual[looper]->sex               = CSV_comma_esc(extract_data->qual[looper]->sex              )
    set extract_data->qual[looper]->ord_prov          = CSV_comma_esc(extract_data->qual[looper]->ord_prov         )
    set extract_data->qual[looper]->prov_name_first   = CSV_comma_esc(extract_data->qual[looper]->prov_name_first  )
    set extract_data->qual[looper]->prov_name_middle  = CSV_comma_esc(extract_data->qual[looper]->prov_name_middle )
    set extract_data->qual[looper]->prov_name_last    = CSV_comma_esc(extract_data->qual[looper]->prov_name_last   )
    set extract_data->qual[looper]->prov_name_suffix  = CSV_comma_esc(extract_data->qual[looper]->prov_name_suffix )
    set extract_data->qual[looper]->prescriber_npi    = CSV_comma_esc(extract_data->qual[looper]->prescriber_npi   )
    set extract_data->qual[looper]->prov_add_street_1 = CSV_comma_esc(extract_data->qual[looper]->prov_add_street_1)
    set extract_data->qual[looper]->prov_add_street_2 = CSV_comma_esc(extract_data->qual[looper]->prov_add_street_2)
    set extract_data->qual[looper]->prov_add_city     = CSV_comma_esc(extract_data->qual[looper]->prov_add_city    )
    set extract_data->qual[looper]->prov_add_state    = CSV_comma_esc(extract_data->qual[looper]->prov_add_state   )
    set extract_data->qual[looper]->prov_add_zip      = CSV_comma_esc(extract_data->qual[looper]->prov_add_zip     )
    set extract_data->qual[looper]->prov_phone        = CSV_comma_esc(extract_data->qual[looper]->prov_phone       )
    set extract_data->qual[looper]->prov_fax          = CSV_comma_esc(extract_data->qual[looper]->prov_fax         )
    set extract_data->qual[looper]->prov_spec         = CSV_comma_esc(extract_data->qual[looper]->prov_spec        )
    set extract_data->qual[looper]->clinic_name       = CSV_comma_esc(extract_data->qual[looper]->clinic_name      )
    set extract_data->qual[looper]->prov_affiliation  = CSV_comma_esc(extract_data->qual[looper]->prov_affiliation )
    set extract_data->qual[looper]->prov_cred         = CSV_comma_esc(extract_data->qual[looper]->prov_cred        )
    set extract_data->qual[looper]->rx_date           = CSV_comma_esc(extract_data->qual[looper]->rx_date          )
    set extract_data->qual[looper]->rx_drug           = CSV_comma_esc(extract_data->qual[looper]->rx_drug          )
    set extract_data->qual[looper]->rx_ndc_nbr        = CSV_comma_esc(extract_data->qual[looper]->rx_ndc_nbr       )
    set extract_data->qual[looper]->dv_med_id         = CSV_comma_esc(extract_data->qual[looper]->dv_med_id        )
    set extract_data->qual[looper]->rx_refills        = CSV_comma_esc(extract_data->qual[looper]->rx_refills       )
    set extract_data->qual[looper]->rx_strength       = CSV_comma_esc(extract_data->qual[looper]->rx_strength      )
    set extract_data->qual[looper]->rx_freq           = CSV_comma_esc(extract_data->qual[looper]->rx_freq          )
    set extract_data->qual[looper]->rx_quantity       = CSV_comma_esc(extract_data->qual[looper]->rx_quantity      )
    set extract_data->qual[looper]->rx_supply_days    = CSV_comma_esc(extract_data->qual[looper]->rx_supply_days   )
    set extract_data->qual[looper]->rx_brandname      = CSV_comma_esc(extract_data->qual[looper]->rx_brandname     )
    set extract_data->qual[looper]->med_status        = CSV_comma_esc(extract_data->qual[looper]->med_status       )
    set extract_data->qual[looper]->med_time          = CSV_comma_esc(extract_data->qual[looper]->med_time         )
    set extract_data->qual[looper]->med_directions    = CSV_comma_esc(extract_data->qual[looper]->med_directions   )
    set extract_data->qual[looper]->prior_auth        = CSV_comma_esc(extract_data->qual[looper]->prior_auth       )
    set extract_data->qual[looper]->reorder           = CSV_comma_esc(extract_data->qual[looper]->reorder          )
    set extract_data->qual[looper]->pharm_name        = CSV_comma_esc(extract_data->qual[looper]->pharm_name       )
    set extract_data->qual[looper]->pharm_address     = CSV_comma_esc(extract_data->qual[looper]->pharm_address    )
    set extract_data->qual[looper]->prindx            = CSV_comma_esc(extract_data->qual[looper]->prindx           )
    set extract_data->qual[looper]->plan_name         = CSV_comma_esc(extract_data->qual[looper]->plan_name        )
    set extract_data->qual[looper]->pri_insure        = CSV_comma_esc(extract_data->qual[looper]->pri_insure       )
    set extract_data->qual[looper]->pri_plan_type     = CSV_comma_esc(extract_data->qual[looper]->pri_plan_type    )
    set extract_data->qual[looper]->pri_group         = CSV_comma_esc(extract_data->qual[looper]->pri_group        )
    set extract_data->qual[looper]->pri_sponsor       = CSV_comma_esc(extract_data->qual[looper]->pri_sponsor      )
    set extract_data->qual[looper]->pri_sponsor_type  = CSV_comma_esc(extract_data->qual[looper]->pri_sponsor_type )
    set extract_data->qual[looper]->pri_member_id     = CSV_comma_esc(extract_data->qual[looper]->pri_member_id    )
    set extract_data->qual[looper]->discontinue_date  = CSV_comma_esc(extract_data->qual[looper]->discontinue_date )


    if(id_max < size(extract_data->qual[looper]->rx_id_txt, 3))
        set id_max = size(extract_data->qual[looper]->rx_id_txt, 3)
    endif

    if(mrn_max < size(extract_data->qual[looper]->mrn, 3))
        set mrn_max = size(extract_data->qual[looper]->mrn, 3)
    endif

    if(name_first_max < size(extract_data->qual[looper]->name_first, 3))
        set name_first_max = size(extract_data->qual[looper]->name_first, 3)
    endif

    if(name_middle_max < size(extract_data->qual[looper]->name_middle, 3))
        set name_middle_max = size(extract_data->qual[looper]->name_middle, 3)
    endif

    if(name_last_max < size(extract_data->qual[looper]->name_last, 3))
        set name_last_max = size(extract_data->qual[looper]->name_last, 3)
    endif

    if(name_suffix_max < size(extract_data->qual[looper]->name_suffix, 3))
        set name_suffix_max = size(extract_data->qual[looper]->name_suffix, 3)
    endif

    if(dob_max < size(extract_data->qual[looper]->dob, 3))
        set dob_max = size(extract_data->qual[looper]->dob, 3)
    endif

    if(add_street_1_max < size(extract_data->qual[looper]->add_street_1, 3))
        set add_street_1_max = size(extract_data->qual[looper]->add_street_1, 3)
    endif

    if(add_street_2_max < size(extract_data->qual[looper]->add_street_2, 3))
        set add_street_2_max = size(extract_data->qual[looper]->add_street_2, 3)
    endif

    if(add_city_max < size(extract_data->qual[looper]->add_city, 3))
        set add_city_max = size(extract_data->qual[looper]->add_city, 3)
    endif

    if(add_state_max < size(extract_data->qual[looper]->add_state, 3))
        set add_state_max = size(extract_data->qual[looper]->add_state, 3)
    endif

    if(add_zip_max < size(extract_data->qual[looper]->add_zip, 3))
        set add_zip_max = size(extract_data->qual[looper]->add_zip, 3)
    endif

    if(pri_phone_max < size(extract_data->qual[looper]->primary_phone, 3))
        set pri_phone_max = size(extract_data->qual[looper]->primary_phone, 3)
    endif

    if(sex_max < size(extract_data->qual[looper]->sex, 3))
        set sex_max = size(extract_data->qual[looper]->sex, 3)
    endif

    if(ord_prov_max < size(extract_data->qual[looper]->ord_prov, 3))
        set ord_prov_max = size(extract_data->qual[looper]->ord_prov, 3)
    endif

    if(prov_name_first_max < size(extract_data->qual[looper]->prov_name_first, 3))
        set prov_name_first_max = size(extract_data->qual[looper]->prov_name_first, 3)
    endif

    if(prov_name_middle_max < size(extract_data->qual[looper]->prov_name_middle, 3))
        set prov_name_middle_max = size(extract_data->qual[looper]->prov_name_middle, 3)
    endif

    if(prov_name_last_max < size(extract_data->qual[looper]->prov_name_last, 3))
        set prov_name_last_max = size(extract_data->qual[looper]->prov_name_last, 3)
    endif

    if(prov_name_suffix_max < size(extract_data->qual[looper]->prov_name_suffix, 3))
        set prov_name_suffix_max = size(extract_data->qual[looper]->prov_name_suffix, 3)
    endif

    if(prescribe_npi_max < size(extract_data->qual[looper]->prescriber_npi, 3))
        set prescribe_npi_max = size(extract_data->qual[looper]->prescriber_npi, 3)
    endif

    if(prov_add_street_1_max < size(extract_data->qual[looper]->prov_add_street_1, 3))
        set prov_add_street_1_max = size(extract_data->qual[looper]->prov_add_street_1, 3)
    endif

    if(prov_add_street_2_max < size(extract_data->qual[looper]->prov_add_street_2, 3))
        set prov_add_street_2_max = size(extract_data->qual[looper]->prov_add_street_2, 3)
    endif

    if(prov_add_city_max < size(extract_data->qual[looper]->prov_add_city, 3))
        set prov_add_city_max = size(extract_data->qual[looper]->prov_add_city, 3)
    endif

    if(prov_add_state_max < size(extract_data->qual[looper]->prov_add_state, 3))
        set prov_add_state_max = size(extract_data->qual[looper]->prov_add_state, 3)
    endif

    if(prov_add_zip_max < size(extract_data->qual[looper]->prov_add_zip, 3))
        set prov_add_zip_max = size(extract_data->qual[looper]->prov_add_zip, 3)
    endif

    if(prov_phone_max < size(extract_data->qual[looper]->prov_phone, 3))
        set prov_phone_max = size(extract_data->qual[looper]->prov_phone, 3)
    endif

    if(prov_spec_max < size(extract_data->qual[looper]->prov_spec, 3))
        set prov_spec_max = size(extract_data->qual[looper]->prov_spec, 3)
    endif

    if(prov_fax_max < size(extract_data->qual[looper]->prov_fax, 3))
        set prov_fax_max = size(extract_data->qual[looper]->prov_fax, 3)
    endif

    if(clinic_name_max < size(extract_data->qual[looper]->clinic_name, 3))
        set clinic_name_max = size(extract_data->qual[looper]->clinic_name, 3)
    endif

    if(prov_affil_max < size(extract_data->qual[looper]->prov_affiliation, 3))
        set prov_affil_max = size(extract_data->qual[looper]->prov_affiliation, 3)
    endif

    if(prov_cred_max < size(extract_data->qual[looper]->prov_cred, 3))
        set prov_cred_max = size(extract_data->qual[looper]->prov_cred, 3)
    endif

    if(rx_date_max < size(extract_data->qual[looper]->rx_date, 3))
        set rx_date_max = size(extract_data->qual[looper]->rx_date, 3)
    endif

    if(rx_drug_max < size(extract_data->qual[looper]->rx_drug, 3))
        set rx_drug_max = size(extract_data->qual[looper]->rx_drug, 3)
    endif

    if(rx_ndc_nbr_max < size(extract_data->qual[looper]->rx_ndc_nbr, 3))
        set rx_ndc_nbr_max = size(extract_data->qual[looper]->rx_ndc_nbr, 3)
    endif

    if(dv_med_id_max < size(extract_data->qual[looper]->dv_med_id, 3))
        set dv_med_id_max = size(extract_data->qual[looper]->dv_med_id, 3)
    endif

    if(rx_refill_max < size(extract_data->qual[looper]->rx_refills, 3))
        set rx_refill_max = size(extract_data->qual[looper]->rx_refills, 3)
    endif

    if(rx_strength_max < size(extract_data->qual[looper]->rx_strength, 3))
        set rx_strength_max = size(extract_data->qual[looper]->rx_strength, 3)
    endif

    if(rx_freq_max < size(extract_data->qual[looper]->rx_freq, 3))
        set rx_freq_max = size(extract_data->qual[looper]->rx_freq, 3)
    endif

    if(rx_quant_max < size(extract_data->qual[looper]->rx_quantity, 3))
        set rx_quant_max = size(extract_data->qual[looper]->rx_quantity, 3)
    endif

    if(daysupp_max < size(extract_data->qual[looper]->rx_supply_days, 3))
        set daysupp_max = size(extract_data->qual[looper]->rx_supply_days, 3)
    endif

    if(brandname_max < size(extract_data->qual[looper]->rx_brandname, 3))
        set brandname_max = size(extract_data->qual[looper]->rx_brandname, 3)
    endif

    if(med_status_max < size(extract_data->qual[looper]->med_status, 3))
        set med_status_max = size(extract_data->qual[looper]->med_status, 3)
    endif

    if(med_time_max < size(extract_data->qual[looper]->med_time, 3))
        set med_time_max = size(extract_data->qual[looper]->med_time, 3)
    endif

    if(med_direct_max < size(extract_data->qual[looper]->med_directions, 3))
        set med_direct_max = size(extract_data->qual[looper]->med_directions, 3)
    endif

    if(prior_auth_max < size(extract_data->qual[looper]->prior_auth, 3))
        set prior_auth_max = size(extract_data->qual[looper]->prior_auth, 3)
    endif

    if(reorder_max < size(extract_data->qual[looper]->reorder, 3))
        set reorder_max = size(extract_data->qual[looper]->reorder, 3)
    endif

    if(pharm_name_max < size(extract_data->qual[looper]->pharm_name, 3))
        set pharm_name_max = size(extract_data->qual[looper]->pharm_name, 3)
    endif

    if(pharm_add_max < size(extract_data->qual[looper]->pharm_address, 3))
        set pharm_add_max = size(extract_data->qual[looper]->pharm_address, 3)
    endif

    if(prindx_max < size(extract_data->qual[looper]->prindx, 3))
        set prindx_max = size(extract_data->qual[looper]->prindx, 3)
    endif

    if(plan_name_max < size(extract_data->qual[looper]->plan_name, 3))
        set plan_name_max = size(extract_data->qual[looper]->plan_name, 3)
    endif

    if(pri_insure_max < size(extract_data->qual[looper]->pri_insure, 3))
        set pri_insure_max = size(extract_data->qual[looper]->pri_insure, 3)
    endif

    if(pri_plan_type_max < size(extract_data->qual[looper]->pri_plan_type, 3))
        set pri_plan_type_max = size(extract_data->qual[looper]->pri_plan_type, 3)
    endif

    if(pri_group_max < size(extract_data->qual[looper]->pri_group, 3))
        set pri_group_max = size(extract_data->qual[looper]->pri_group, 3)
    endif

    if(pri_sponsor_max < size(extract_data->qual[looper]->pri_sponsor, 3))
        set pri_sponsor_max = size(extract_data->qual[looper]->pri_sponsor, 3)
    endif

    if(pri_sponsor_max < size(extract_data->qual[looper]->pri_sponsor_type, 3))
        set pri_sponsor_max = size(extract_data->qual[looper]->pri_sponsor_type, 3)
    endif

    if(pri_member_id_max < size(extract_data->qual[looper]->pri_member_id, 3))
        set pri_member_id_max = size(extract_data->qual[looper]->pri_member_id, 3)
    endif

    if(dc_date_max < size(extract_data->qual[looper]->discontinue_date, 3))
        set dc_date_max = size(extract_data->qual[looper]->discontinue_date, 3)
    endif
endfor


set run_end_dt_tm    = cnvtdatetime(curdate, curtime3)

call ctd_end_timer(0)

call ctd_end_timer(prog_timer)

;Draw out the file.  I tried doing this in dummyts but due to the with clauses we had to use, we were
;getting different operation from the opsjob vs the manual runs (missing headers and such).
set frec->file_name = shield_rx_file ;set the file name/location
set frec->file_buf  = "w"
set stat = cclio("OPEN",frec) ;open the file and prepare for writing


set out_str = notrim(check(build2(
    'UNIQUE_RECORD_ID'       ,delim_char,
    'MRN_PATIENT'            ,delim_char,
    'NAMEFIRST_PATIENT'      ,delim_char,
    'NAMEMIDDLE_PATIENT'     ,delim_char,
    'NAMELAST_PATIENT'       ,delim_char,
    'NAMESUFFIX_PATIENT'     ,delim_char,
    'DOB_PATIENT'            ,delim_char,
    'LAST4SSN_PATIENT'       ,delim_char,
    'ADRSADD1_PATIENT'       ,delim_char,
    'ADRSADD2_PATIENT'       ,delim_char,
    'ADRSCITY_PATIENT'       ,delim_char,
    'ADRSSTATE_PATIENT'      ,delim_char,
    'ADRSZIP_PATIENT'        ,delim_char,
    'ADRSPHONENUMBER_PATIENT',delim_char,
    'SEX_PATIENT'            ,delim_char,
    'ORDERING_PROVIDER'      ,delim_char,
    'NAMEFIRST_DOC'          ,delim_char,
    'NAMEMIDDLE_DOC'         ,delim_char,
    'NAMELAST_DOC'           ,delim_char,
    'NAMESUFFIX_DOC'         ,delim_char,
    'PRESCRIBER_NPI'         ,delim_char,
    'ADRSADD1_DOC'           ,delim_char,
    'ADRSADD2_DOC'           ,delim_char,
    'ADRSCITY_DOC'           ,delim_char,
    'ADRSSTATE_DOC'          ,delim_char,
    'ADRSZIP_DOC'            ,delim_char,
    'ADRSPHONENUMBER_DOC'    ,delim_char,
    'ADRSFAXNUMBER_DOC'      ,delim_char,
    'SPECIALTY_DOC'          ,delim_char,
    'CLINIC_NAME'            ,delim_char,
    'PROVIDER_AFFILIATION'   ,delim_char,
    'CLINICIAN_CREDENTIALS'  ,delim_char,
    'DATE_RX'                ,delim_char,
    'NAME_DRUG'              ,delim_char,
    'DRUGNDCNBR_DRUG'        ,delim_char,
    'DV_MEDID'               ,delim_char,
    'REFILLS_RX'             ,delim_char,
    'DRUG_STRENGTH'          ,delim_char,
    'DRUG_FREQUENCY'         ,delim_char,
    'RXQTY_RX'               ,delim_char,
    'DAYSUPP_RX'             ,delim_char,
    'BRANDNAME_DRUG'         ,delim_char,
    'MED_STATUS'             ,delim_char,
    'MED_STATUS_TIME'        ,delim_char,
    'MED_DIRECTIONS'         ,delim_char,
    'PRIOR_AUTHORIZATION'    ,delim_char,
    'RX_REORDER_YN'          ,delim_char,  ;003 Renamed this as part of validation.
    'PAT_HX_YN'              ,delim_char,  ;003 Renamed this as part of validation.
    'PHARMACY_NAME'          ,delim_char,
    'PHARMACY_ADDRESS'       ,delim_char,
    'ICD1_RX'                ,delim_char,
    'BENEFIT_PLAN_NAME'      ,delim_char,
    'PRIMARY_INSURANCE'      ,delim_char,
    'PRIMARY_PLAN_TYPE'      ,delim_char,
    'PRIMARY_GROUP'          ,delim_char,
    'PRIMARY_SPONSOR'        ,delim_char,
    'PRIMARY_SPONSOR_TYPE'   ,delim_char,
    'PRIMARY_MEMBER_ID'      ,delim_char,
    'DISCONTINUED_DATE'                    ;003 Renamed this as part of validation.
)))


set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
set stat = cclio("WRITE",frec)


for(looper = 1 to extract_data->cnt)
    if(cnvtupper(extract_data->qual[looper]->name_last) not in ('ZZ*TEST*', 'ZZ*CERNER*'))  ;004
        ;I don't really need all the dumb max vars anymore since we are not in a query...
        ;however I'm just going to keep it for now.
        set out_str = notrim(build2(
            trim(substring(1, value(id_max               ), extract_data->qual[looper]->rx_id_txt        ),3), delim_char,
            trim(substring(1, value(mrn_max              ), extract_data->qual[looper]->mrn              ),3), delim_char,
            trim(substring(1, value(name_first_max       ), extract_data->qual[looper]->name_first       ),3), delim_char,
            trim(substring(1, value(name_middle_max      ), extract_data->qual[looper]->name_middle      ),3), delim_char,
            trim(substring(1, value(name_last_max        ), extract_data->qual[looper]->name_last        ),3), delim_char,
            trim(substring(1, value(name_suffix_max      ), extract_data->qual[looper]->name_suffix      ),3), delim_char,
            trim(substring(1, value(dob_max              ), extract_data->qual[looper]->dob              ),3), delim_char,
            trim(substring(1,                            4, extract_data->qual[looper]->last_4_ssn       ),3), delim_char,
            trim(substring(1, value(add_street_1_max     ), extract_data->qual[looper]->add_street_1     ),3), delim_char,
            trim(substring(1, value(add_street_2_max     ), extract_data->qual[looper]->add_street_2     ),3), delim_char,
            trim(substring(1, value(add_city_max         ), extract_data->qual[looper]->add_city         ),3), delim_char,
            trim(substring(1, value(add_state_max        ), extract_data->qual[looper]->add_state        ),3), delim_char,
            trim(substring(1, value(add_zip_max          ), extract_data->qual[looper]->add_zip          ),3), delim_char,
            trim(substring(1, value(pri_phone_max        ), extract_data->qual[looper]->primary_phone    ),3), delim_char,
            trim(substring(1, value(sex_max              ), extract_data->qual[looper]->sex              ),3), delim_char,
            trim(substring(1, value(ord_prov_max         ), extract_data->qual[looper]->ord_prov         ),3), delim_char,
            trim(substring(1, value(prov_name_first_max  ), extract_data->qual[looper]->prov_name_first  ),3), delim_char,
            trim(substring(1, value(prov_name_middle_max ), extract_data->qual[looper]->prov_name_middle ),3), delim_char,
            trim(substring(1, value(prov_name_last_max   ), extract_data->qual[looper]->prov_name_last   ),3), delim_char,
            trim(substring(1, value(prov_name_suffix_max ), extract_data->qual[looper]->prov_name_suffix ),3), delim_char,
            trim(substring(1, value(prescribe_npi_max    ), extract_data->qual[looper]->prescriber_npi   ),3), delim_char,
            trim(substring(1, value(prov_add_street_1_max), extract_data->qual[looper]->prov_add_street_1),3), delim_char,
            trim(substring(1, value(prov_add_street_2_max), extract_data->qual[looper]->prov_add_street_2),3), delim_char,
            trim(substring(1, value(prov_add_city_max    ), extract_data->qual[looper]->prov_add_city    ),3), delim_char,
            trim(substring(1, value(prov_add_state_max   ), extract_data->qual[looper]->prov_add_state   ),3), delim_char,
            trim(substring(1, value(prov_add_zip_max     ), extract_data->qual[looper]->prov_add_zip     ),3), delim_char,
            trim(substring(1, value(prov_phone_max       ), extract_data->qual[looper]->prov_phone       ),3), delim_char,
            trim(substring(1, value(prov_fax_max         ), extract_data->qual[looper]->prov_fax         ),3), delim_char,
            trim(substring(1, value(prov_spec_max        ), extract_data->qual[looper]->prov_spec        ),3), delim_char,
            trim(substring(1, value(clinic_name_max      ), extract_data->qual[looper]->clinic_name      ),3), delim_char,
            trim(substring(1, value(prov_affil_max       ), extract_data->qual[looper]->prov_affiliation ),3), delim_char,
            trim(substring(1, value(prov_cred_max        ), extract_data->qual[looper]->prov_cred        ),3), delim_char,
            trim(substring(1, value(rx_date_max          ), extract_data->qual[looper]->rx_date          ),3), delim_char,
            trim(substring(1, value(rx_drug_max          ), extract_data->qual[looper]->rx_drug          ),3), delim_char,
            trim(substring(1, value(rx_ndc_nbr_max       ), extract_data->qual[looper]->rx_ndc_nbr       ),3), delim_char,
            trim(substring(1, value(dv_med_id_max        ), extract_data->qual[looper]->dv_med_id        ),3), delim_char,
            trim(substring(1, value(rx_refill_max        ), extract_data->qual[looper]->rx_refills       ),3), delim_char,
            trim(substring(1, value(rx_strength_max      ), extract_data->qual[looper]->rx_strength      ),3), delim_char,
            trim(substring(1, value(rx_freq_max          ), extract_data->qual[looper]->rx_freq          ),3), delim_char,
            trim(substring(1, value(rx_quant_max         ), extract_data->qual[looper]->rx_quantity      ),3), delim_char,
            trim(substring(1, value(daysupp_max          ), extract_data->qual[looper]->rx_supply_days   ),3), delim_char,
            trim(substring(1, value(brandname_max        ), extract_data->qual[looper]->rx_brandname     ),3), delim_char,
            trim(substring(1, value(med_status_max       ), extract_data->qual[looper]->med_status       ),3), delim_char,
            trim(substring(1, value(med_time_max         ), extract_data->qual[looper]->med_time         ),3), delim_char,
            trim(substring(1, value(med_direct_max       ), extract_data->qual[looper]->med_directions   ),3), delim_char,
            trim(substring(1, value(prior_auth_max       ), extract_data->qual[looper]->prior_auth       ),3), delim_char,
            trim(substring(1, value(reorder_max          ), extract_data->qual[looper]->reorder          ),3), delim_char,
            trim(substring(1,                           10, extract_data->qual[looper]->hx               ),3), delim_char,
            trim(substring(1, value(pharm_name_max       ), extract_data->qual[looper]->pharm_name       ),3), delim_char,
            trim(substring(1, value(pharm_add_max        ), extract_data->qual[looper]->pharm_address    ),3), delim_char,
            trim(substring(1, value(prindx_max           ), extract_data->qual[looper]->prindx           ),3), delim_char,
            trim(substring(1, value(plan_name_max        ), extract_data->qual[looper]->plan_name        ),3), delim_char,
            trim(substring(1, value(pri_insure_max       ), extract_data->qual[looper]->pri_insure       ),3), delim_char,
            trim(substring(1, value(pri_plan_type_max    ), extract_data->qual[looper]->pri_plan_type    ),3), delim_char,
            trim(substring(1, value(pri_group_max        ), extract_data->qual[looper]->pri_group        ),3), delim_char,
            trim(substring(1, value(pri_sponsor_max      ), extract_data->qual[looper]->pri_sponsor      ),3), delim_char,
            trim(substring(1, value(pri_sponsor_max      ), extract_data->qual[looper]->pri_sponsor_type ),3), delim_char,
            trim(substring(1, value(pri_member_id_max    ), extract_data->qual[looper]->pri_member_id    ),3), delim_char,
            trim(substring(1, value(dc_date_max          ), extract_data->qual[looper]->discontinue_date ),3)
        ))
        
        set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
        set stat = cclio("WRITE",frec)
    endif  ;004

    ;005 I think this is duping rows out here man... jeze.  Moving up.
    ;set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
    ;set stat = cclio("WRITE",frec)
endfor

set stat = cclio("CLOSE",frec)


/*************************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************************/
/* CSV_comma_esc
   This subroutine should check a string, looking for a delim within it.
   If found, remove it.  We also remove other chars that are problems.

   Input:
        csv_str (vc): The string to check

   Output:
        ret_str (vc): The string wrapped in quotes if a comma is found, or
                      as is if not.

   NOTES:
        It might be worthwhile to have it check to see if we have quotes already too?

*/
subroutine CSV_comma_esc(csv_str)
    declare ret_str = vc with protect, noconstant(csv_str)

    ;replace bad chars now
    set ret_str = replace(ret_str, char(10), '')
    set ret_str = replace(ret_str, char(13), '')
    set ret_str = replace(ret_str, char(0), '')
    set ret_str = replace(ret_str, '|', '')

    ;if(findstring('|', ret_str) > 0)
    ;    set ret_str = concat('"', ret_str ,'"')
    ;endif

    return(ret_str)
end


#exit_script
;DEBUGGING
;call echorecord(extract_data)
call ctd_print_timers(null)

end
go
