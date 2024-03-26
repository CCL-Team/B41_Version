/*************************************************************************
 Program Title: Breast Health Coordination Report
 
 Object name:   14_brst_hlth_coord_rep
 Source file:   14_brst_hlth_coord_rep.prg
 
 Purpose:       
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 06/05/2023 Michael Mayes        238459 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_brst_hlth_coord_rep:dba go
create program 14_brst_hlth_coord_rep:dba
 
prompt "Output to File/Printer/MINE"  = "MINE"
	 , "Start Date:"                  = "CURDATE"
	 , "Stop Date:"                   = "CURDATE"
	 , "Provider Search - Last Name:" = ""
	 ; <<hidden>>"Search"             = ""
	 , "Select Ordering Physician:"   = VALUE(0)
	 , "Enter Facility Name:"         = ""
	 ; <<hidden>>"Search"             = ""
	 , "Select Facilities:"           = VALUE(0) 

with OUTDEV, BEGIN_DATE, END_DATE, PRSNL_SEARCH, PRSNL_LIST, FAC_SEARCH, FAC_LIST
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 per_id             = f8
        2 enc_id             = f8
        2 pat_last_name      = vc
        2 pat_first_name     = vc
        2 pat_dob            = vc
        2 pat_age            = vc
        2 pat_mrn            = vc
        2 pat_fin            = vc
          
        2 ord_id             = f8
        2 ord_prov_id        = f8
        2 ord_prov           = vc
        2 ord_rad_serv       = vc
        2 ord_name           = vc
        2 ord_status         = vc
        2 ord_dt             = dq8
        2 ord_dt_txt         = vc
        2 ord_comp_dt        = dq8
        2 ord_comp_dt_txt    = vc
        
        2 res_endorse_dt     = dq8
        2 res_endorse_dt_txt = vc
)


free record ords
record ords(
    1 cnt = i4
    1 qual[*]
        2 cat_desc = vc
        2 cat_cd   = f8
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))

/*
declare pos                = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)
*/


declare mrn_cd      = f8   with protect,   constant(uar_get_code_by('MEANING',  319, 'MRN'     ))
declare fin_cd      = f8   with protect,   constant(uar_get_code_by('MEANING',  319, 'FIN NBR' ))

declare idx                = i4  with protect, noconstant(0)

declare prsnl_parser = vc with protect, noconstant('1 = 1')
declare prsnl_str    = vc with protect, noconstant('')
declare loc_parser   = vc with protect, noconstant('1 = 1')
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
;Find specific orders with our ordering provider
if(0 not in ($PRSNL_LIST))
    select into 'nl:'
      from prsnl pr
     where pr.person_id in ($PRSNL_LIST)
    detail
        if(prsnl_str = '')  prsnl_str =                        trim(cnvtstring(pr.person_id),3)
        else                prsnl_str = concat(prsnl_str, ',', trim(cnvtstring(pr.person_id),3))
        endif
    with nocounter
    
    set prsnl_parser = concat( ^exists (select 'x'                                      ^
                             , ^          from order_action oa                          ^
                             , ^         where oa.order_id          =  o.order_id       ^
                             , ^           and oa.action_type_cd    =  2534.00          ^  ;ORDER
                             , ^           and oa.order_provider_id in (^, prsnl_str, ^)^
                             , ^       )                                                ^
                             )
    
    call echo(prsnl_str)
    call echo(prsnl_parser)
    
endif


/**********************************************************************
DESCRIPTION:  Gather Orders catalog entries we want
      NOTES:  
***********************************************************************/
select into 'nl:'
  from order_catalog oc
 where oc.active_ind = 1
   and (   cnvtupper(oc.description) = '*SCREEN*MAM*'
        or cnvtupper(oc.description) = '*DIAG*MAM*'
        or cnvtupper(oc.description) = '*BREAST*ULT*'
        or cnvtupper(oc.description) = '*BREAST*MRI*'
        or cnvtupper(oc.description) = '*BREAST*BIO*'
       )
detail
    ords->cnt = ords->cnt + 1
    stat = alterlist(ords->qual, ords->cnt)
    
    ords->qual[ords->cnt]->cat_desc = oc.description
    ords->qual[ords->cnt]->cat_cd   = oc.catalog_cd
with nocounter

call echorecord(ords)

 
/**********************************************************************
DESCRIPTION:  Gather Orders we are interested in.
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from orders       o
     , encounter    e
     , person       p 
     , encntr_alias mrn
     , encntr_alias fin
     , order_action ordact
     , prsnl        pr
     , order_action oa
     , order_detail od
       
 where o.activity_type_cd = 711.00  ;RAD
   and expand(idx, 1, ords->cnt, o.catalog_cd, ords->qual[idx]->cat_cd)
   and o.orig_order_dt_tm between cnvtdatetime($begin_date) and cnvtdatetime($end_date)
   and parser(prsnl_parser)
   
   and (   e.encntr_id        = o.encntr_id
        or e.encntr_id        = o.originating_encntr_id
       )
   and e.active_ind       = 1
   and (   0 in ($FAC_LIST)
        or e.loc_facility_cd in ($FAC_LIST)
       )
   
   and p.person_id        = o.person_id
    
   and mrn.encntr_id             =  outerjoin(e.encntr_id                   )
   and mrn.encntr_alias_type_cd  =  outerjoin(mrn_cd                        )
   and mrn.beg_effective_dt_tm   <= outerjoin(cnvtdatetime(curdate,curtime3))
   and mrn.end_effective_dt_tm   >  outerjoin(cnvtdatetime(curdate,curtime3))
   and mrn.active_ind            =  outerjoin(1                             )
    
   and fin.encntr_id             =  outerjoin(e.encntr_id                   )
   and fin.encntr_alias_type_cd  =  outerjoin(fin_cd                        )
   and fin.beg_effective_dt_tm   <= outerjoin(cnvtdatetime(curdate,curtime3))
   and fin.end_effective_dt_tm   >  outerjoin(cnvtdatetime(curdate,curtime3))
   and fin.active_ind            =  outerjoin(1                             )
   
   and ordact.order_id           =  outerjoin(o.order_id)
   and ordact.action_type_cd     =  outerjoin(2534.00)  ;ORDER
   
   and pr.person_id              =  outerjoin(ordact.order_provider_id)
   
   and oa.order_id               =  outerjoin(o.order_id)
   and oa.action_type_cd         =  outerjoin(2529.00)  ;COMP
   
   and od.order_id               =  outerjoin(o.order_id)
   and od.oe_field_id            =  outerjoin(831982505.00)  ;Performing Location Radiology
   
order by o.orig_order_dt_tm, o.order_id

head o.order_id
    data->cnt = data->cnt + 1
    stat = alterlist(data->qual, data->cnt)
    
    data->qual[data->cnt]->per_id              = p.person_id
    data->qual[data->cnt]->enc_id              = e.encntr_id
                                               
    data->qual[data->cnt]->pat_last_name       = trim(p.name_last, 3)
    data->qual[data->cnt]->pat_first_name      = trim(p.name_first, 3)
    data->qual[data->cnt]->pat_dob             = format(p.birth_dt_tm, '@SHORTDATE')
    data->qual[data->cnt]->pat_age             = trim(cnvtage(p.birth_dt_tm), 3)
    data->qual[data->cnt]->pat_mrn             = trim(  cnvtalias(mrn.alias, mrn.alias_pool_cd), 3)
    data->qual[data->cnt]->pat_fin             = trim(  cnvtalias(fin.alias, fin.alias_pool_cd), 3)
                                               
    data->qual[data->cnt]->ord_id              = o.order_id
    data->qual[data->cnt]->ord_prov_id         = ordact.order_provider_id
    data->qual[data->cnt]->ord_prov            = trim(pr.name_full_formatted, 3)
    data->qual[data->cnt]->ord_rad_serv        = trim(od.oe_field_display_value, 3)
    data->qual[data->cnt]->ord_name            = trim(o.order_mnemonic, 3)
    data->qual[data->cnt]->ord_status          = trim(uar_get_code_display(o.order_status_cd), 3)
    data->qual[data->cnt]->ord_dt              = o.orig_order_dt_tm
    data->qual[data->cnt]->ord_dt_txt          = format(o.orig_order_dt_tm, '@SHORTDATETIME')
    
    if(oa.action_type_cd = 2529.00)
        data->qual[data->cnt]->ord_comp_dt     = oa.action_dt_tm
        data->qual[data->cnt]->ord_comp_dt_txt = format(oa.action_dt_tm, '@SHORTDATETIME')
    endif
    
with nocounter

/**********************************************************************
DESCRIPTION:  Find results tied to orders and gather endorse date
      NOTES:  
***********************************************************************/
select into 'nl:'
  from clinical_event ce
     , ce_event_prsnl cep
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->qual[d.seq]->ord_id >  0
     and data->cnt                 >  0
  
  join ce
   where ce.order_id               =  data->qual[d.seq]->ord_id
     and ce.view_level             =  1
     and ce.valid_until_dt_tm      >= cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd       in (act_cd, mod_cd, auth_cd, altr_cd)
  
  join cep
   where cep.event_id              =  ce.event_id
     and cep.valid_until_dt_tm     >= cnvtdatetime(curdate, curtime3)
     and cep.action_type_cd        =  678654.00  ;Endorse

detail
    
    data->qual[d.seq]->res_endorse_dt     = cep.action_dt_tm
    data->qual[d.seq]->res_endorse_dt_txt = format(cep.action_dt_tm, '@SHORTDATETIME')

with nocounter

   
;Presentation time
if (data->cnt > 0)
    
    select into $outdev
          ;Debugging
          ;ORDER_ID          = data->qual[d.seq]->ord_id,
          
          LAST_NAME         = substring(1,  75, data->qual[d.seq]->pat_last_name     )
        , FIRST_NAME        = substring(1,  75, data->qual[d.seq]->pat_first_name    )
        , DOB               = substring(1,  15, data->qual[d.seq]->pat_dob           )
        , AGE               = substring(1,  15, data->qual[d.seq]->pat_age           )
        , MRN               = substring(1,  20, data->qual[d.seq]->pat_mrn           )
        , FIN               = substring(1,  20, data->qual[d.seq]->pat_fin           )
        , PROVIDER          = substring(1,  75, data->qual[d.seq]->ord_prov          )
        , RADIOLOGY_SERVICE = substring(1, 100, data->qual[d.seq]->ord_rad_serv      )
        , RAD_ORD_NAME      = substring(1, 100, data->qual[d.seq]->ord_name          )
        , RAD_ORD_NAME      = substring(1, 100, data->qual[d.seq]->ord_status        )
        , ORD_DATE          = substring(1,  25, data->qual[d.seq]->ord_dt_txt        )
        , ORD_COMP_DATE     = substring(1,  25, data->qual[d.seq]->ord_comp_dt_txt   )
        , ENDORSE_DATE      = substring(1,  25, data->qual[d.seq]->res_endorse_dt_txt)

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
 
 

