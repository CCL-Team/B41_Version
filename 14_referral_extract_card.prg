/*************************************************************************
 Program Title: 14_referral_extract_card
 
 Object name:   14_referral_extract_card
 Source file:   14_referral_extract_card.prg
 
 Purpose:       
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 07/17/2025 Michael Mayes        354281 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_referral_extract_card:dba go
create program 14_referral_extract_card:dba
 
prompt
      "Output to File/Printer/MINE" = "MINE"    ;* Enter or select the printer or file name to send this report to.
    , "Registration Start Date"     = "CURDATE"
    , "Registration End Date"       = "CURDATE"
    ;, "Report Type"                 = 1

with outdev, start_dt, end_dt;, type
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 per_id                    = f8
        2 enc_id                    = f8
    
        2 pat_info
            3 empi                  = vc
            3 last_name             = vc
            3 first_name            = vc
            3 email                 = vc
            3 phone                 = vc
            3 gend                  = vc
            3 sex_birth             = vc
            3 dob                   = vc
            3 mar_stat              = vc
            3 address            
                4 add               = vc
                4 add2              = vc
                4 city              = vc
                4 state             = vc
                4 zip               = vc
                
        2 ref_info  
            3 prov                  
                4 id                = f8
                4 name              = vc
                4 npi               = vc
                
            3 target                
                4 service           = vc
                4 prov_id           = f8
                4 prov              = vc
                4 npi               = vc
                4 phone             = vc
                4 address           = vc
                
            3 location              = vc
            3 dos                   = vc
            3 appt_type             = vc  ;Unused but needed by ingestion.
            3 med_service           = vc  ;Unused but needed by ingestion.
            3 spec_unit_cd          = f8
            3 spec_unit             = vc
            3 order                 
                4 id                = f8
                4 name              = vc
                4 dx
                    5 cd            = vc
                    5 source_string = vc
                    5 display       = vc
                    
        2 new_to_service            = i2
        2 dx_incl_ind               = i2
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
/* 
declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))
*/
/*
declare idx                = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)
*/


declare pos                = i4  with protect, noconstant(0)

declare start_dt_tm_n       = vc  with protect, noconstant('')
declare end_dt_tm_n         = vc  with protect, noconstant('')
declare dateRange           = vc  with protect, noconstant('')

declare output_file         = vc  with protect, noconstant(' ')
declare email_subject       = vc  with protect, noconstant(' ')
declare email_body          = vc  with protect, noconstant(' ')
declare email_body_noresult = vc  with protect, noconstant(' ')

declare dayofweek           = i4  with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
if(textlen(trim($start_dt, 3)) > 0 and textlen(trim($End_Dt, 3)) > 0)
    
    call echo("Date")
    
    set start_dt_tm_n = trim(format(cnvtdatetime($start_dt), 'DD-MMM-YYYY HH:MM:SS;;d'), 3)
    set end_dt_tm_n   = trim(format(cnvtdatetime($End_Dt  ), 'DD-MMM-YYYY HH:MM:SS;;d'), 3)
    
else
    
    call echo("Default date")
    
    set dayofweek = weekday(curdate)
    
    case(dayofweek)
    of 1:  ;Monday
        call echo('Monday Fri-Sat-Sun run.')
        set start_dt_tm_n = trim(format(cnvtdatetime((curdate - 3), 000000), "DD-MMM-YYYY HH:MM:SS;;d"), 3)
        set end_dt_tm_n   = trim(format(cnvtdatetime((curdate - 1), 235959), "DD-MMM-YYYY HH:MM:SS;;d"), 3)
        
    of 2:  ;Tuesday
    of 3:  ;Wednesday
    of 4:  ;Thursday
    of 5:  ;Friday
        call echo('Normal Previous Day run.')
        set start_dt_tm_n = trim(format(cnvtdatetime((curdate - 1), 000000), "DD-MMM-YYYY HH:MM:SS;;d"), 3)
        set end_dt_tm_n   = trim(format(cnvtdatetime((curdate - 1), 235959), "DD-MMM-YYYY HH:MM:SS;;d"), 3)
    
    of 6:  ;Saturday
    of 0:  ;Sunday
        ;We don't do anything these days, and wait for monday to grab them.
        call echo('Weekend no run.')
        go to exit_script
    endcase
    
    

endif




if($outdev = 'OPS')
    ;This is piggybacking GI for now... supposedly.
    set output_file = build2( "/cerner/d_p41/cust_output_2/referral_extract/gi/card_ref"
                            , format(cnvtdatetime(curdate,curtime3), "YYYYMMDD;;Q")
                            , ".csv"
                            )
    
elseif($outdev = 'OPSTEST')
    ;This is for testing... I'm going to change the output file... but have it drop one... going to change the date range... but 
    ;leave it... etc.
    
    call echo('30 day lookback file creation for testing.')
    set start_dt_tm_n = trim(format(cnvtdatetime((curdate - 30), 000000), "DD-MMM-YYYY HH:MM:SS;;d"), 3)
    set end_dt_tm_n   = trim(format(cnvtdatetime((curdate -  1), 235959), "DD-MMM-YYYY HH:MM:SS;;d"), 3)
    
    ;CCLUSERDIR
    set output_file = build2( "/cerner/d_p41/ccluserdir/card_ref"
                            , format(cnvtdatetime(curdate,curtime3), "YYYYMMDD;;Q")
                            , ".csv"
                            )
    
    
else
    set output_file = build2($outdev)
endif

;set send_to      = "Sofy@Medstar.net, Despina.Kiaoulias@Medstar.net, Justin.M.Hughes@medstar.net, Stephen.V.Manti@medstar.net"
set send_to       = "michael.m.mayes@medstar.net"

set email_subject = "Clinic Cardio Referral Extract Report"
set dateRange     = concat(start_dt_tm_n, " to ", end_dt_tm_n)

call echo(build('start_dt_tm_n:', start_dt_tm_n      ))
call echo(build('end_dt_tm_n  :', end_dt_tm_n        ))
call echo(build('dateRange    :', dateRange          ))
call echo(build('output_file  :', output_file        ))
call echo(build('email_subject:', email_subject      ))
call echo(build('send_to      :', send_to            ))

 
/**********************************************************************
DESCRIPTION:  Initial Referral Find
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from orders         o
     , encounter      e
     , person         p
     , person_patient pp
     , person_alias   pa
     , organization   org

 where o.orig_order_dt_tm between cnvtdatetime(start_dt_tm_n) 
                              and cnvtdatetime(end_dt_tm_n  )
   and o.product_id       =  0
   and o.activity_type_cd =  249925330.00  ;Internal Referral
   ;and o.catalog_cd       =  833712029.00  ;Referral to MedStar Cardiology
   
   and o.catalog_cd       in (  833710989.00  ;Referral to MedStar Cardiac Rehab
                             ,  833711693.00  ;Referral to MedStar Cardiac Surgery
                             ,  833712029.00  ;Referral to MedStar Cardiology
                             , 1346692061.00  ;Referral to Non-MedStar Cardiac Surgery
                             , 1346692049.00  ;Referral to Non-MedStar Cardiac Rehab
                             , 1346692085.00  ;Referral to Non-MedStar Cardiology
                             , 1691511245.00  ;Referral to Non-MedStar Pediatric Cardiology
                             , 1691496713.00  ;Referral to MedStar Pediatric Cardiology
                             , 1928439767.00  ;Referral to MedStar Cardio-Oncology
                             , 2955101233.00  ;Referral to MedStar Cardiac Genetic Counselor
                             , 3357274227.00  ;Referral to Medstar Cardiodiabetes Clinic at MUMH
                             )
   
   and o.order_status_cd  in ( 2543.00 ;Completed
                             , 2546.00 ;Future
                             , 2550.00 ;Ordered
                             , 2548.00 ;InProcess
                             )
   
   and e.encntr_id = o.encntr_id
   and (  ;------------------------------Urgent Care Locations -------------------------------------------------------------------
          (e.loc_facility_cd in (select cv1.code_value
                                   from code_value cv1
                                  where cv1.code_set    = 220 
                                    and cv1.active_ind  = 1
                                    and cv1.cdf_meaning = 'FACILITY'
                                    and (   cnvtlower(cv1.display) = 'medstar health uc*' 
                                         or cnvtlower(cv1.display) = 'medstar health urgent*' 
                                         or cnvtlower(cv1.display) = 'medstar hlth urgent*' 
                                         or cnvtlower(cv1.display) = '*medstar uc*' 
                                         or cnvtlower(cv1.display) = 'medstar urgent care*'
                                        )
                                )
          )
       
       ;-------------------------------Primary Care Location ------------------------------------------------------------------
       or (e.loc_facility_cd in (select cvg.child_code_value
                                  from code_value cv
                                     , code_value_group cvg
                                     , code_value cvc
                                 where cv.code_set           = 100705
                                   and cv.display_key        = 'PRIMARYCARELOCATIONS'
                                   and cvg.parent_code_value = cv.code_value
                                   and cvc.code_value        = cvg.child_code_value
                                )
          )
       
       or e.loc_facility_cd = 2348539959.00  ;One Medical
      ) 
     
    and p.person_id              =  e.person_id
    and not OPERATOR(p.name_last_key, "REGEXPLIKE", "[0-9]")
    and p.name_last_key          != "ZZ*"
    and p.name_last_key          != "CAREMOBILE"
    and p.name_last_key          != "REGRESSION"
    and p.name_last_key          != "TEST"
    and p.name_last_key          != "CERNERTEST"
    and p.name_last_key          != "*PATIENT*"
    and p.active_ind             =  1
    and p.end_effective_dt_tm    >  cnvtdatetime(curdate, curtime3)
    and p.birth_dt_tm            <  cnvtlookbehind("16,Y")
                                 
    and pp.person_id             =  outerjoin(p.person_id)
	and pp.active_ind            =  outerjoin(1)
	and pp.end_effective_dt_tm   >  outerjoin(cnvtdatetime(curdate, curtime3))
                                 
    and pa.person_id             =  outerjoin(p.person_id)
    and pa.active_ind            =  outerjoin(1)
    and pa.end_effective_dt_tm   >  outerjoin(cnvtdatetime(curdate, curtime3))
    and pa.person_alias_type_cd  =  outerjoin(2)
    
    and org.organization_id      =  e.organization_id

order by o.order_id

head o.order_id
    
    data->cnt = data->cnt + 1
    
    pos = data->cnt
    
    stat = alterlist(data->qual, pos)
    
    data->qual[pos]->per_id = e.person_id
    data->qual[pos]->enc_id = e.encntr_id
    
    data->qual[pos]->pat_info->last_name       = cnvtcap(cnvtlower(p.name_last ))
    data->qual[pos]->pat_info->first_name      = cnvtcap(cnvtlower(p.name_first))
    data->qual[pos]->pat_info->gend            = uar_get_code_display(p.sex_cd)
    data->qual[pos]->pat_info->dob             = datebirthformat(p.birth_dt_tm, p.birth_tz, 0, 'YYYY-MM-DD;;D')
    data->qual[pos]->pat_info->sex_birth       = uar_get_code_display(pp.birth_sex_cd)
    data->qual[pos]->pat_info->mar_stat        = uar_get_code_display(p.marital_type_cd)
    data->qual[pos]->pat_info->empi            = cnvtalias(pa.alias,pa.alias_pool_cd)
                                               
    data->qual[pos]->ref_info->dos             = format(e.reg_dt_tm, "YYYY-MM-DD HH:MM:SS;;D")
    data->qual[pos]->ref_info->location        = uar_get_code_display(e.loc_facility_cd)
    
    
    data->qual[pos]->ref_info->spec_unit_cd    = e.specialty_unit_cd
    data->qual[pos]->ref_info->spec_unit       = uar_get_code_display(e.specialty_unit_cd)
    
    data->qual[pos]->ref_info->med_service     = uar_get_code_display(e.med_service_cd)
    
    data->qual[pos]->ref_info->order->id       = o.order_id
    data->qual[pos]->ref_info->order->name     = o.ordered_as_mnemonic
    
    
    
    data->qual[pos]->ref_info->target->service = replace(replace( trim(substring(1, 255, o.ordered_as_mnemonic))
                                                                , "Referral to MedStar ", ""
                                                                )
                                                        , "Referral to Non-MedStar ", ""
                                                        )
    
    ;Defaulting these yes, will overwrite no below.
    data->qual[pos]->new_to_service            = 1


with nocounter


/**********************************************************************
DESCRIPTION:  Ref Order Diagnosis
      NOTES:  
***********************************************************************/
;select into 'nl:'
;  
;  from nomen_entity_reltn ner
;     , diagnosis          dx
;     , nomenclature       n
;     , (dummyt d with seq = data->cnt)
;  
;  plan d
;   where data->cnt                              >  0
;     and data->qual[d.seq]->ref_info->order->id >  0
;  
;  join ner
;   where ner.parent_entity_id    =  data->qual[d.seq]->ref_info->order->id
;     and ner.parent_entity_name  =  'ORDERS'
;     and ner.reltn_type_cd       =  639177.00   ;Diagnosis to Orders
;     and ner.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
;     and ner.active_ind          =  1
;     and ner.priority            =  1
;     and ner.child_entity_name   =  'DIAGNOSIS'
;  
;  join dx
;   where dx.diagnosis_id         =  ner.child_entity_id
;  
;  join n
;   where n.nomenclature_id       =  dx.nomenclature_id
;     and (   n.source_identifier_keycap = 'R07.9'
;          or n.source_identifier_keycap = 'R07.89'
;          or n.source_identifier_keycap = 'R00.0'
;          or n.source_identifier_keycap = 'R55'
;          or n.source_identifier_keycap = 'R06.02'
;         )
;     
;     
;
;order by ner.parent_entity_id
;
;head ner.parent_entity_id
;    
;    data->qual[d.seq]->dx_incl_ind                        = 1
;    
;    data->qual[d.seq]->ref_info->order->dx->cd            = trim(n.source_identifier , 3)
;    data->qual[d.seq]->ref_info->order->dx->source_string = trim(n.source_string     , 3)
;    data->qual[d.seq]->ref_info->order->dx->display       = trim(dx.diagnosis_display, 3)
;
;with nocounter 


/**********************************************************************
DESCRIPTION:  Encounter Diagnosis
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from diagnosis          dx
     , nomenclature       n
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->enc_id >  0
  
  join dx
   where dx.encntr_id           =  data->qual[d.seq]->enc_id
     and dx.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
  
  join n
   where n.nomenclature_id       =  dx.nomenclature_id
     and (   n.source_identifier_keycap = 'R07.9'
          or n.source_identifier_keycap = 'R07.89'
          or n.source_identifier_keycap = 'R00.0'
          or n.source_identifier_keycap = 'R55'
          or n.source_identifier_keycap = 'R06.02'
         )

order by dx.encntr_id, dx.diag_priority

head dx.encntr_id
    
    data->qual[d.seq]->dx_incl_ind                        = 1
    
    data->qual[d.seq]->ref_info->order->dx->cd            = trim(n.source_identifier , 3)
    data->qual[d.seq]->ref_info->order->dx->source_string = trim(n.source_string     , 3)
    data->qual[d.seq]->ref_info->order->dx->display       = trim(dx.diagnosis_display, 3)

with nocounter 





/**********************************************************************
DESCRIPTION:  Phone Numbers and emails
      NOTES:  
***********************************************************************/
select into "nl:"
  
  from phone ph
     , (dummyt d with seq = data->cnt)
   
  plan d
   where data->cnt                 > 0
     and data->qual[d.seq]->per_id > 0
  
  join ph    
   where ph.parent_entity_id    =  data->qual[d.seq]->per_id
     and ph.active_ind          =  1
     and ph.phone_type_cd       =  170   ;Home
     and ph.beg_effective_dt_tm <  cnvtdatetime(curdate,curtime)
     and ph.end_effective_dt_tm >  cnvtdatetime(curdate,curtime)
     ;and ph.parent_entity_name  =  "PERSON"  ;We can do this another way.
     and ph.contact_method_cd   in ( 4054479.00  ;Tel
                                   , 4054478.00  ;Email
                                   )

detail

    case(ph.contact_method_cd)
    of 4054479.00:  ;Tel
        if(findstring("(",ph.phone_num) > 0) data->qual[d.seq]->pat_info->phone = ph.phone_num
        else                                 data->qual[d.seq]->pat_info->phone = format(ph.phone_num_key, "(###)###-####")
        endif
    of 4054478.00:  ;Email
        data->qual[d.seq]->pat_info->email = ph.phone_num
    endcase


with nocounter


/**********************************************************************
DESCRIPTION:  Pat Address
      NOTES:  
***********************************************************************/
select into "nl:"
  from address a
     , (dummyt d with seq = data->cnt)

plan d
   where data->cnt                 > 0
     and data->qual[d.seq]->per_id > 0

join a
  where a.parent_entity_id    =  data->qual[d.seq]->per_id
    and a.address_type_cd     =  756.00;   Home
    and a.active_ind          =  1
    and a.end_effective_dt_tm >  cnvtdatetime(curdate, curtime3)

order by d.seq

detail

    data->qual[d.seq]->pat_info->address->add      = a.street_addr
    data->qual[d.seq]->pat_info->address->add2     = a.street_addr2
    data->qual[d.seq]->pat_info->address->city     = a.city
    data->qual[d.seq]->pat_info->address->state    = a.state
    data->qual[d.seq]->pat_info->address->zip      = a.zipcode

with nocounter


/**********************************************************************
DESCRIPTION:  Target provider info
      NOTES:  
***********************************************************************/
select into "nl:"
  
  from order_detail od
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                              > 0
     and data->qual[d.seq]->ref_info->order->id > 0
  
  join od
   where od.order_id            =  data->qual[d.seq]->ref_info->order->id
     and od.oe_field_id         in (  258409575.00  ;Referred To Provider
                                   , 1593931077.00  ;Find a Doc Phone and Fax
                                   ,  951929101.00  ;Referred to Location (Internal to MedStar)
                                   )
     and od.oe_field_meaning_id in ( 3581  ;Referred To Provider
                                   , 9000  ;User defined field
                                   )

order by d.seq, od.oe_field_id

head d.seq
  null

head od.oe_field_id
    case(od.oe_field_id)
    
    ;Referred To Provider
    of  258409575.0:  
        data->qual[d.seq]->ref_info->target->prov_id = od.oe_field_value
        data->qual[d.seq]->ref_info->target->prov    = od.oe_field_display_value
    
    ;Find a Doc Phone and Fax    
    of 1593931077.0:  
        data->qual[d.seq]->ref_info->target->phone = trim(replace(replace(od.oe_field_display_value,"P: ", ""), 'P:', ''),3)

        ;This should give us something like:
        ;703-852-8060 F: 877-743-0[...]
        ;or (443) 777-2475 F:(443) 77[...]
        ;
        ;they were prefixed by 'P: ' or 'P:'...
        ;I need to just grab the first number.  Looks like there is always an F: so I can pull that off.
        data->qual[d.seq]->ref_info->target->phone = substring(1, findstring( 'F:', data->qual[d.seq]->ref_info->target->phone) - 1
                                                                                  , data->qual[d.seq]->ref_info->target->phone)
    
    ;Referred to Location (Internal to MedStar)
    of  951929101.0:  
        data->qual[d.seq]->ref_info->target->address = trim(od.oe_field_display_value, 3)
    
    endcase
with nocounter


/**********************************************************************
DESCRIPTION:  Ordering Provider
      NOTES:  
***********************************************************************/
select into "nl:"
  from order_action oa
     , prsnl p
     , credential cred
     , prsnl_alias pa
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                              >  0
     and data->qual[d.seq]->ref_info->order->id >  0
  
  join oa
   where oa.order_id                            =  data->qual[d.seq]->ref_info->order->id
     and oa.action_type_cd                      =  2534  ;ORDER
                                                   
  join p                                           
   where p.person_id                            =  oa.order_provider_id
   
  join cred
   where cred.prsnl_id                          =  oa.order_provider_id
     and cred.active_ind                        =  1 
     and cred.end_effective_dt_tm               >  cnvtdatetime(curdate, curtime3)
     and cred.active_status_cd                  =  188.00  ;ACTIVE
                                                   
  join pa                                          
   where pa.person_id                           =  outerjoin(p.person_id)
     and pa.prsnl_alias_type_cd                 =  outerjoin(4038127.00)   ;NPI
     and pa.active_ind                          =  outerjoin(1)
     and pa.end_effective_dt_tm                 >  outerjoin(cnvtdatetime(curdate, curtime3))
    
order by d.seq
head d.seq
    data->qual[d.seq]->ref_info->prov->id         = oa.order_provider_id
    data->qual[d.seq]->ref_info->prov->name       = notrim(build2( trim(p.name_first, 3), ' '
                                                                 , trim(p.name_last , 3), ', '
                                                                 , trim(uar_get_code_display(cred.credential_cd), 3)
                                                                 )
                                                          )
    data->qual[d.seq]->ref_info->prov->npi        = pa.alias
with nocounter


/**********************************************************************
DESCRIPTION:  Ref Target Provider
      NOTES:  
***********************************************************************/
select into "nl:"
  from prsnl p
     , credential cred
     , prsnl_alias pa
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                                    >  0
     and data->qual[d.seq]->ref_info->target->prov_id >  0
                                                   
  join p                                           
   where p.person_id                            =  data->qual[d.seq]->ref_info->target->prov_id
   
  join cred
   where cred.prsnl_id                          =  p.person_id
     and cred.active_ind                        =  1 
     and cred.end_effective_dt_tm               >  cnvtdatetime(curdate, curtime3)
     and cred.active_status_cd                  =  188.00  ;ACTIVE
                                                   
  join pa                                          
   where pa.person_id                           =  outerjoin(p.person_id)
     and pa.prsnl_alias_type_cd                 =  outerjoin(4038127.00)   ;NPI
     and pa.active_ind                          =  outerjoin(1)
     and pa.end_effective_dt_tm                 >  outerjoin(cnvtdatetime(curdate, curtime3))
    
order by d.seq
head d.seq
    ;This is an overwrite.
    data->qual[d.seq]->ref_info->target->prov   =  notrim(build2( trim(p.name_first, 3), ' '
                                                                 , trim(p.name_last , 3), ', '
                                                                 , trim(uar_get_code_display(cred.credential_cd), 3)
                                                                 )
                                                          )
    data->qual[d.seq]->ref_info->target->npi    =  pa.alias
with nocounter


/**********************************************************************
DESCRIPTION:  New to service
      NOTES:  
***********************************************************************/
select into "nl:"

  from encounter e
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->per_id >  0
     and data->qual[d.seq]->enc_id >  0

  join e
   where e.person_id      =  data->qual[d.seq].per_id
                             ; 
     and e.med_service_cd IN ( 6133122293.00  ;ARCX CA CONNECTED CARDIOLOGY  
                             , 6133118635.00  ;ARCX CCA CONNECTED CARDIOLOGY 
                             , 6224226353.00  ;ARCX CONNECTED CARDIOLOGY MGUH
                             , 6224218259.00  ;ARCX CONNECTED CARDIOLOGY MWHC
                             ,    5041899.00  ;Cardiac Surgery               
                             ,    5048027.00  ;Cardiology                    
                             ,    5041903.00  ;Cardiology - Admini           
                             ,    5041907.00  ;Cardiology - Arhythmia        
                             ,  966220837.00  ;CARDIOLOGY ASSOCIATES OV      
                             ,  966221775.00  ;CARDIOLOGY FACULTY GUH OV-WHC 
                             ,    5041911.00  ;Cardiology - Invasive         
                             ,    8689532.00  ;Cardiology Non-Invasive       
                             ,  966223357.00  ;CARDIOLOGY OV - MHH           
                             ,    5041915.00  ;Cardiology - Rehab            
                             ,     313003.00  ;Cardiothoracic Surgery        
                             ,    5041919.00  ;Cardiovascular Disease        
                             ,     313007.00  ;Med-Cardiovascular            
                             ,  966288743.00  ;MMG CARDIOLOGY AT GOOD SAM OV 
                             ,  966289229.00  ;MMG CARDIOVASCULAR CARD ASSOC 
                             , 4766712467.00  ;MMG CONNECTED CARDIOLOGY
                             , 5789840711.00  ;MSH CARDOLOGY CENTER    
                             ,  966447503.00  ;WOMENS CARDIOLOGY OV-WHC
                             )
  and e.reg_dt_tm            >  cnvtlookbehind("3,Y")
  and e.encntr_id            != data->qual[d.seq].enc_id
  and e.reg_dt_tm            <  cnvtdatetime(curdate, curtime)
  
order by d.seq, e.reg_dt_tm desc

head d.seq
    data->qual[d.seq].new_to_service = 0

with nocounter






;Presentation time
if (data->cnt > 0)
    select
    if($outdev in ('OPS', 'OPSTEST')) into value(output_file)
                                      with nocounter, format, format=stream, separator=" ", pcformat('"', ',',1),compress, check
    else                              into $outdev
    endif
      ;  per_id              = data->qual[d.seq]->per_id
      ;, enc_id              = data->qual[d.seq]->enc_id
      ;, ref_prov_id         = data->qual[d.seq]->ref_info->prov->id
      ;, ref_targ_prov_id    = data->qual[d.seq]->ref_info->target->prov_id
      ;, ref_ord_id          = data->qual[d.seq]->ref_info->order->id
      ;
      ;, pat_last            = trim(substring(1, 50, data->qual[d.seq]->pat_info->last_name     ), 3)
      ;, pat_first           = trim(substring(1, 50, data->qual[d.seq]->pat_info->first_name    ), 3)
      ;, pat_empi            = trim(substring(1, 50, data->qual[d.seq]->pat_info->empi          ), 3)
      ;, pat_email           = trim(substring(1, 50, data->qual[d.seq]->pat_info->email         ), 3)
      ;, pat_phone           = trim(substring(1, 50, data->qual[d.seq]->pat_info->phone         ), 3)
      ;, pat_gend            = trim(substring(1, 50, data->qual[d.seq]->pat_info->gend          ), 3)
      ;, pat_birth_sex       = trim(substring(1, 50, data->qual[d.seq]->pat_info->sex_birth     ), 3)
      ;, pat_dob             = trim(substring(1, 50, data->qual[d.seq]->pat_info->dob           ), 3)
      ;, pat_mar_stat        = trim(substring(1, 50, data->qual[d.seq]->pat_info->mar_stat      ), 3)
      ;, pat_add_add         = trim(substring(1, 50, data->qual[d.seq]->pat_info->address->add  ), 3)
      ;, pat_add_add2        = trim(substring(1, 50, data->qual[d.seq]->pat_info->address->add2 ), 3)
      ;, pat_add_city        = trim(substring(1, 50, data->qual[d.seq]->pat_info->address->city ), 3)
      ;, pat_add_state       = trim(substring(1, 50, data->qual[d.seq]->pat_info->address->state), 3)
      ;, pat_add_zip         = trim(substring(1, 50, data->qual[d.seq]->pat_info->address->zip  ), 3)
      ;
      ;, ref_prov_name       = trim(substring(1, 50, data->qual[d.seq]->ref_info->prov->name       ), 3)
      ;, ref_prov_npi        = trim(substring(1, 50, data->qual[d.seq]->ref_info->prov->npi        ), 3)
      ;, ref_targ_serv       = trim(substring(1, 50, data->qual[d.seq]->ref_info->target->service  ), 3)
      ;, ref_targ_prov       = trim(substring(1, 50, data->qual[d.seq]->ref_info->target->prov     ), 3)
      ;, ref_targ_prov_npi   = trim(substring(1, 50, data->qual[d.seq]->ref_info->target->npi      ), 3)
      ;, ref_targ_phone      = trim(substring(1, 50, data->qual[d.seq]->ref_info->target->phone    ), 3)
      ;, ref_targ_address    = trim(substring(1, 50, data->qual[d.seq]->ref_info->target->address  ), 3)
      ;
      ;
      ;, ref_spec_cd         = data->qual[d.seq]->ref_info->ref_spec_cd
      ;, ref_spec            = trim(substring(1, 50, data->qual[d.seq]->ref_info->ref_spec                     ), 3)    
      ;
      ;, ref_loc             = trim(substring(1, 50, data->qual[d.seq]->ref_info->location                     ), 3)           
      ;, ref_dos             = trim(substring(1, 50, data->qual[d.seq]->ref_info->dos                          ), 3)          
      ;, ref_ord_name        = trim(substring(1, 50, data->qual[d.seq]->ref_info->order->name                  ), 3)          
      ;, ref_ord_dx_cd       =                       data->qual[d.seq]->ref_info->order->dx->cd
      ;, ref_ord_source_str  = trim(substring(1, 50, data->qual[d.seq]->ref_info->order->dx->source_string     ), 3)          
      ;, ref_ord_disp        = trim(substring(1, 50, data->qual[d.seq]->ref_info->order->dx->display           ), 3)
      ;
      ;, new_to_service      = data->qual[d.seq]->new_to_service
      
      ;This is the requested format
        LASTNAME                      = trim(substring(1,  200, data->qual[d.seq]->pat_info->last_name                    ), 3)
      , FIRSTNAME                     = trim(substring(1,  200, data->qual[d.seq]->pat_info->first_name                   ), 3)
      , EMAIL                         = trim(substring(1,  100, data->qual[d.seq]->pat_info->email                        ), 3)
      , PHONE                         = trim(substring(1,  100, data->qual[d.seq]->pat_info->phone                        ), 3)
      , GENDER                        = trim(substring(1,   40, data->qual[d.seq]->pat_info->gend                         ), 3)
      , SEX_AT_BIRTH                  = trim(substring(1,   40, data->qual[d.seq]->pat_info->sex_birth                    ), 3)
      , ADDRESS                       = trim(substring(1,  100, data->qual[d.seq]->pat_info->address->add                 ), 3)
      , ADDRESS_2                     = trim(substring(1,  100, data->qual[d.seq]->pat_info->address->add2                ), 3)
      , CITY                          = trim(substring(1,  100, data->qual[d.seq]->pat_info->address->city                ), 3)
      , STATE                         = trim(substring(1,  100, data->qual[d.seq]->pat_info->address->state               ), 3)
      , ZIPCODE                       = trim(substring(1,   25, data->qual[d.seq]->pat_info->address->zip                 ), 3)
      , REFERRAL_TARGET_SERVICE       = trim(substring(1, 1000, data->qual[d.seq]->ref_info->target->service              ), 3)
      , REFERRAL_TARGET_PROVIDER_NAME = trim(substring(1,  450, data->qual[d.seq]->ref_info->target->prov                 ), 3)
      , REFERRAL_TARGET_PROVIDER_NPI  = trim(substring(1,   40, data->qual[d.seq]->ref_info->target->npi                  ), 3)
      , REFERRAL_TARGET_PHONE         = trim(substring(1,  255, data->qual[d.seq]->ref_info->target->phone                ), 3)
      , ADDRESS_PROVIDER_FLAG         = trim(substring(1,  255, data->qual[d.seq]->ref_info->target->address              ), 3)
      , CMRN                          = trim(substring(1,   20, data->qual[d.seq]->pat_info->empi                         ), 3)
      , ORDER_NAME                    = trim(substring(1, 1000, data->qual[d.seq]->ref_info->order->name                  ), 3)
      , DATE_OF_SERVICE               = trim(substring(1,   25, data->qual[d.seq]->ref_info->dos                          ), 3)
      , LOCATION                      = trim(substring(1,   40, data->qual[d.seq]->ref_info->location                     ), 3)
      , PERSONID                      =                         data->qual[d.seq]->per_id
      , ORDERID                       =                         data->qual[d.seq]->ref_info->order->id
      , DOB                           = trim(substring(1,   20, data->qual[d.seq]->pat_info->dob                          ), 3)
      , DIAGNOSIS_CODE                = trim(substring(1,   50, data->qual[d.seq]->ref_info->order->dx->cd                ), 3)
      , SOURCE_STRING                 = trim(substring(1,  255, data->qual[d.seq]->ref_info->order->dx->source_string     ), 3)
      , DIAGNOSIS_DISPLAY             = trim(substring(1,  255, data->qual[d.seq]->ref_info->order->dx->display           ), 3)
      
      ; These three unused but needed by ingestion.
      , INCLUDE                       =                         data->qual[d.seq]->dx_incl_ind  ;Probably always 1.  Fine.
      , APPT_TYPE                     = trim(substring(1,   75, data->qual[d.seq]->ref_info->appt_type                    ), 3) 
      , MED_SERVICE                   = trim(substring(1,  100, data->qual[d.seq]->ref_info->med_service                  ), 3) 
      
      , NEW_TO_SERVICE                =                         data->qual[d.seq]->new_to_service 
      , MARITAL_STATUS                = trim(substring(1,   40, data->qual[d.seq]->pat_info->mar_stat                     ), 3)
      , REFERRING_PROVIDER            = trim(substring(1,  450, data->qual[d.seq]->ref_info->prov->name                   ), 3)
      , REFERRING_PROVIDER_NPI        = trim(substring(1,   20, data->qual[d.seq]->ref_info->prov->npi                    ), 3)
      
    from (dummyt d with SEQ = data->cnt)
    
    where data->qual[d.seq]->dx_incl_ind = 1
          ;From validation they want us to exclude some stuff... excluding cases that:
          ;   Have no email or phone.
          ;   referring NPI missing
          ;   They have to be new to service.
      and (   data->qual[d.seq]->pat_info->email > ' '
           or data->qual[d.seq]->pat_info->phone > ' '
          )
      and data->qual[d.seq]->ref_info->prov->npi  > ' '
      and data->qual[d.seq]->new_to_service       = 1
    with format, separator = " "

else
    
    if($outdev = 'OPS')
        set email_body_noresult = notrim(build2( "No qualifying Cardiology Referral Order found."               ,"<br>"
                                               , "Date Range: ", trim(dateRange, 3)                             ,"<br>"
                                               , "This report ran on date and time: "
                                               , format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q")  ,"<br>"
                                               , "CCL Object name: ",trim(cnvtlower(curprog))                   ,"<br>"
                                               )
                                        )
        
        call echo("sending blank email")
        set crlf         = concat(char(13), char(10))
        set xcontenttype = concat(crlf, "mime-version: 1.0", crlf, "content-type: text/html", crlf, crlf, char(0))
        set xsubject     = concat(email_subject, xcontenttype)
        set xfrom        = "reporting@medstar.net"
        set xto          = send_to
        set xclass       = "IPM.NOTE"
        set xpriority    = 5
        set xheader      = "<html><body>"
        set xfooter      = "</html>"
        set xbody        = concat(email_body_noresult, "<br><br>")
        set xsend        = concat(xheader, xbody, xfooter)
        call uar_send_mail(nullterm(xto), nullterm(xsubject), nullterm(xsend), nullterm(xfrom), xpriority, nullterm(xclass))
        
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
endif

 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script
;DEBUGGING
call echorecord(data)

end
go
 
 

