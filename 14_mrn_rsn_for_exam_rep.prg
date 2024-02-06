/*************************************************************************
 Program Title: MedStar Radiology Network - Reason for Exam Report
 
 Object name:   14_mrn_rsn_for_exam_rep
 Source file:   14_mrn_rsn_for_exam_rep.prg
 
 Purpose:       Collect various information about completed exams.
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 12/08/2023 Michael Mayes        240477 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_mrn_rsn_for_exam_rep:dba go
create program 14_mrn_rsn_for_exam_rep:dba
 
prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Completion Date Begin"     = "SYSDATE"
	, "Completion Date End"       = "SYSDATE"
	, "Modality"                  = VALUE(0.0)
	, "Facility"                  = VALUE(0.0)
	, "Type"                      = 0

with OUTDEV, BEG_DT, END_DT, MOD_CD, FAC_CD, TYPE_FLAG
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt                   = i4
    1 qual[*]
        2 per_id            = f8
        2 enc_id            = f8
        2 ord_id            = f8
        2 loc_name          = vc
        2 modality          = vc
        2 exam_desc         = vc
        2 cpt_code          = vc
        2 reason_indication = vc
        2 accession         = vc
        2 pat_name          = vc
        2 mrn               = vc
        2 fin               = vc
        2 dob               = dq8
        2 dob_txt           = vc
        2 com_date          = dq8
        2 com_date_txt      = vc
        2 com_time_txt      = vc
)


record facs(
    1 cnt          = i4
    1 qual[*]
        2 fac_cd   = f8
        2 fac_name = vc
)

 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare mrn_cd = f8  with protect,   constant(uar_get_code_by(   'MEANING',   319, 'MRN'))
declare fin_cd = f8  with protect,   constant(uar_get_code_by(   'MEANING',   319, 'FIN NBR'))

declare pos                = i4  with protect, noconstant(0)
declare idx                = i4  with protect, noconstant(0)

 
/*************************************************************
; DVDev Start Coding
**************************************************************/

/**********************************************************************
DESCRIPTION:  Gather our locations, in case we are going to search for any
      NOTES:  
***********************************************************************/
SELECT DISTINCT
  into 'nl:'
       FAC_CD   = l.location_cd                                                  
     , FAC_NAME = cv.display    
  
  FROM org_set       os                                                         
     , org_set_org_r osor                                                       
     , organization  o                                                          
     , location      l                                                          
     , code_value    cv                                                         
  
  plan os                                                                       
   where os.org_set_id        = 12319578.00   ;Medstar Radiology Network                                       
     and os.active_ind        = 1                                               
  
  join osor                                                                     
   where osor.org_set_id      = os.org_set_id                                   
     and osor.active_ind      = 1                                               
  
  join o                                                                         
   where o.organization_id     =  osor.organization_id                           
     and o.active_ind          =  1                                              
     and o.organization_id not in ( 807425.00  ; GUHLABCORP
                                  , 807419.00  ; GUH Quest Diagnostics Nichols Institute
                                  , 807427.00  ; WHCLABCORP
                                  , 2650023.00 ; WHCLABCORPSTATS
                                  )     
  
  join l                                                                         
   where l.organization_id     =  o.organization_id                              
     and l.location_type_cd    =  (select cv.code_value                          
                                     from code_value cv                          
                                    where cv.code_set = 222                      
                                      and CDF_MEANING = 'FACILITY'               
                                  )                                              
     and l.beg_effective_dt_tm <  cnvtdatetime(curdate, curtime3)                
     and l.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)                
     and l.active_ind          =  1                                              
  
  join cv                                                                        
   where cv.code_value          =  l.location_cd                                 
     and cv.active_ind          =  1                                             
detail
    facs->cnt = facs->cnt + 1
    
    stat = alterlist(facs->qual, facs->cnt)
    
    facs->qual[facs->cnt].fac_cd   = FAC_CD
    facs->qual[facs->cnt].fac_name = FAC_NAME
    
with nocounter, expand=1


;Jeremy's email declaration
if($TYPE_FLAG = 1);EMAILING OF REPORT
    declare email_subject     = vc with protect, noconstant('MRN Reason For Exam Results')
    declare email_addresses   = vc with protect, noconstant('')
    declare email_body        = vc with protect, noconstant('')
    declare unicode           = vc with protect, noconstant('')
    declare aix_command       = vc with protect, noconstant('')
    declare aix_cmdlen        = i4 with protect, noconstant(0)
    declare aix_cmdstatus     = i4 with protect, noconstant(0)
    declare production_domain = vc with protect,   constant('P41')
    declare email_address     = vc with protect, noconstant($outdev)
 
    set email_body = concat('14_mrn_rsn_for_exam_rep_', format(cnvtdatetime(curdate, curtime3),'YYYYMMDDhhmmss;;q'), ".dat")
 
    declare filename = vc
            with  noconstant(concat('14_mrn_rsn_for_exam_rep_',
                                  format(cnvtdatetime(curdate, curtime3), 'YYYYMMDDhhmmss;;Q'),
                                  trim(substring(3,3,cnvtstring(rand(0)))),     ;<<<< These 3 digits are random #s
                                  '.csv'))
 
    if (curdomain = production_domain)
        select into (value(email_body))
            build2('The MRN REASON FOR EXAM REPORT is attached to this email.'  , char(13), char(10), char(13), char(10),
                   'Date Range: ', $beg_dt , ' to ', $end_dt                   , char(13), char(10), char(13), char(10),
                   'Run date and time: ',
                   format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10))
 
        from dummyt
        with format, noheading
    endif
endif
 
 
/**********************************************************************
DESCRIPTION:  Gather population information.
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from encounter       e
     , orders          o
     , order_catalog   oc
     , order_radiology orad
     , person          p
     , encntr_alias    mrn
     , encntr_alias    fin
     
 where (   0                 in ($fac_cd)
        or e.loc_facility_cd in ($fac_cd)
       )
   and expand(idx, 1, facs->cnt, e.loc_facility_cd, facs->qual[idx].fac_cd)  ;Handles the all case.
       
   and e.active_ind               =  1
                                  
   and p.person_id                =  e.person_id
                                  
   and o.encntr_id                =  e.encntr_id
   and o.catalog_type_cd          =  2517.00  ;Radiology
   and o.order_status_cd          =  2543.00  ;Completed
   and o.active_ind               =  1
                                  
   and oc.catalog_cd              =  o.catalog_cd
   and (   0                      in ($mod_cd)
        or oc.activity_subtype_cd in ($mod_cd)
       )
   
   and orad.order_id              =  o.order_id
   and orad.complete_dt_tm        between cnvtdatetime($beg_dt) and cnvtdatetime($end_dt)
                                  
   and fin.encntr_id              =  outerjoin(e.encntr_id)
   and fin.encntr_alias_type_cd   =  outerjoin(fin_cd)
   and fin.active_ind             =  outerjoin(1)
   and fin.beg_effective_dt_tm    <= outerjoin(cnvtdatetime(curdate, curtime3))
   and fin.end_effective_dt_tm    >= outerjoin(cnvtdatetime(curdate, curtime3))
                                  
   and mrn.encntr_id              =  outerjoin(e.encntr_id)
   and mrn.encntr_alias_type_cd   =  outerjoin(mrn_cd)
   and mrn.active_ind             =  outerjoin(1)
   and mrn.beg_effective_dt_tm    <= outerjoin(cnvtdatetime(curdate, curtime3))
   and mrn.end_effective_dt_tm    >= outerjoin(cnvtdatetime(curdate, curtime3))

order by p.name_full_formatted

detail
    pos = data->cnt + 1
    data->cnt = pos
    
    stat = alterlist(data->qual, pos)
    
    data->qual[pos]->per_id            = e.person_id
    data->qual[pos]->enc_id            = e.encntr_id
                                       
    data->qual[pos]->loc_name          = trim(uar_get_code_display(e.loc_facility_cd), 3)
                                       
    data->qual[pos]->ord_id            = o.order_id
    data->qual[pos]->exam_desc         = trim(o.order_mnemonic, 3)
    
    data->qual[pos]->modality          = trim(uar_get_code_meaning(oc.activity_subtype_cd), 3)
    
    data->qual[pos]->accession         = trim(orad.accession, 3)
    data->qual[pos]->reason_indication = trim(orad.reason_for_exam, 3)
    data->qual[pos]->com_date          = orad.complete_dt_tm
    data->qual[pos]->com_date_txt      = format(orad.complete_dt_tm, '@SHORTDATE')
    data->qual[pos]->com_time_txt      = format(orad.complete_dt_tm, 'HH:MM')
                                       
    data->qual[pos]->pat_name          = trim(p.name_full_formatted, 3)
    data->qual[pos]->dob               = p.birth_dt_tm
    data->qual[pos]->dob_txt           = format(p.birth_dt_tm, '@SHORTDATE')
                                       
    data->qual[pos]->mrn               = trim(mrn.alias, 3)
    data->qual[pos]->fin               = trim(fin.alias, 3)
with nocounter


/**********************************************************************
DESCRIPTION:  Gather CPT Info
      NOTES:  Doing this in a side query, due to the subselect,
              and the fact that I can't really outerjoin above comfortably.
***********************************************************************/
select into 'nl:'
  from order_detail od
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                 >  0
     and data->qual[d.seq]->ord_id >  0
  
  join od
   where od.order_id               =  data->qual[d.seq]->ord_id
     and od.oe_field_id            =  3644439611.00  ;CPT
     and od.action_sequence        =  (select max(od2.action_sequence)
                                         from order_detail od2
                                        where od2.order_id    = od.order_id
                                          and od2.oe_field_id = 3644439611.00  ;CPT
                                      )
detail
    data->qual[d.seq]->cpt_code = trim(od.oe_field_display_value, 3)

with nocounter


;Presentation time
if($TYPE_FLAG = 0)
    if (data->cnt > 0)
        
        select into $outdev
               ;Debugging
             ;  PER_ID = data->qual[d.seq].per_id,
             ;  ENC_ID = data->qual[d.seq].enc_id,
             ;  ORD_ID = data->qual[d.seq].ord_id,
             ;  FIN    = trim(substring(1,   15, data->qual[d.seq].fin              )),


               LOCATION          = trim(substring(1,   80, data->qual[d.seq].loc_name         ))
             , MODALITY          = trim(substring(1,   20, data->qual[d.seq].modality         ))
             , EXAM              = trim(substring(1,   80, data->qual[d.seq].exam_desc        ))
             , CPT               = trim(substring(1,   10, data->qual[d.seq].cpt_code         ))
             , REASON_INDICATION = trim(substring(1, 1000, data->qual[d.seq].reason_indication))
             , ACCESSION         = trim(substring(1,   20, data->qual[d.seq].accession        ))
             , PATIENT           = trim(substring(1,   80, data->qual[d.seq].pat_name         ))
             , MRN               = trim(substring(1,   15, data->qual[d.seq].mrn              ))
             , FIN               = trim(substring(1,   15, data->qual[d.seq].fin              ))
             , DOB               = trim(substring(1,   10, data->qual[d.seq].dob_txt          ))
             , COMPLETE_DT       = trim(substring(1,   20, data->qual[d.seq].com_date_txt     ))
             , COMPLETE_TM       = trim(substring(1,   20, data->qual[d.seq].com_time_txt     ))
             

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

elseif($TYPE_FLAG = 1);EMAILING OF REPORT
    if (data->cnt > 0)
        select into value(FILENAME)
               LOCATION          = trim(substring(1,   80, data->qual[d.seq].loc_name         ))
             , MODALITY          = trim(substring(1,   20, data->qual[d.seq].modality         ))
             , EXAM              = trim(substring(1,   80, data->qual[d.seq].exam_desc        ))
             , CPT               = trim(substring(1,   10, data->qual[d.seq].cpt_code         ))
             , REASON_INDICATION = trim(substring(1, 1000, data->qual[d.seq].reason_indication))
             , ACCESSION         = trim(substring(1,   20, data->qual[d.seq].accession        ))
             , PATIENT           = trim(substring(1,   80, data->qual[d.seq].pat_name         ))
             , MRN               = trim(substring(1,   15, data->qual[d.seq].mrn              ))
             , FIN               = trim(substring(1,   15, data->qual[d.seq].fin              ))
             , DOB               = trim(substring(1,   10, data->qual[d.seq].dob_txt          ))
             , COMPLETE_DT       = trim(substring(1,   20, data->qual[d.seq].com_date_txt     ))
             , COMPLETE_TM       = trim(substring(1,   20, data->qual[d.seq].com_time_txt     ))
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
    if(curdomain = production_domain);only email out of p41
 
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

end
go
 
 

