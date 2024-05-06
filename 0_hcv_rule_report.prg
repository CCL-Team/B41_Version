/*************************************************************************
 Program Title: HCV High Risk Hep C Rule Report
 
 Object name:   0_hcv_rule_report.prg
 Source file:   0_hcv_rule_report.prg
 
 Purpose:       Display data about the fires of the HCV rule used to drop
                results that health maint sees to trigger a high risk follow
                up for Hep C patients.
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: Rule is called... PC_HEP_HCV_RISK.
 
                CE is:
CODE_VALUE     CODE_SET    CDF_MEANING  DISPLAY                                  DISPLAY_KEY
 4563449671.00          72              HCV screen                               HCVSCREEN  
                
                Although that will change in prod.
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 01/18/2024 Michael Mayes        241407 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_hcv_rule_report:dba go
create program 0_hcv_rule_report:dba
 
prompt 
	  "Output to File/Printer/MINE" = "MINE"
	, "Start Date"                  = "SYSDATE"
	, "End Date"                    = "SYSDATE"
    , "Most Recent Result?"         = "N"
    , "Needs Screen Only?"          = "N"

with OUTDEV, BEG_DT, END_DT, REC_FLAG, SCRN_FLAG 
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt               = i4
    1 qual[*]
        2 per_id        = f8
        2 enc_id        = f8
        2 event_id      = f8
        2 pat_name      = vc
        2 mrn           = vc
        2 fin           = vc
        
        2 score         = vc
        2 result_dt_tm  = dq8
        2 result_dt_txt = vc
        2 diag_string   = vc
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))

declare hcv_screen_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HCVSCREEN'))

/*

declare idx                = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)
*/

declare blob_holder        = vc  with protect, noconstant('')
declare pos                = i4  with protect, noconstant(0)

/*************************************************************
; DVDev Start Coding
**************************************************************/

 
 
/**********************************************************************
DESCRIPTION:  Find results that the rule has dropped within our timeframe
      NOTES:  
***********************************************************************/
select into 'nl:'

  from clinical_event ce
     , person         p
     , encounter      e
     , encntr_alias   mrn
     , encntr_alias   fin
  
 where ce.event_cd              =  hcv_screen_cd
   and ce.event_end_dt_tm       >= cnvtdatetime($BEG_DT)
   and ce.event_end_dt_tm       <= cnvtdatetime($END_DT)
   and ce.result_status_cd      in (act_cd, mod_cd, auth_cd, altr_cd)
   and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
   and (   'N' in ($REC_FLAG)
        or ce.event_end_dt_tm = ( select max(ce2.event_end_dt_tm)
                                    from clinical_event ce2
                                   where ce2.person_id         =  ce.person_id
                                     and ce2.event_cd          =  hcv_screen_cd
                                     and ce2.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
                                     and ce2.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
                                )
   
       )
                                
   and p.person_id              =  ce.person_id
   
   and e.encntr_id              =  ce.encntr_id
   
   and mrn.encntr_id            =  outerjoin(e.encntr_id)
   and mrn.encntr_alias_type_cd =  outerjoin(1079.00)  ; mrn
   and mrn.active_ind           =  outerjoin(1)
   and mrn.beg_effective_dt_tm  <  outerjoin(cnvtdatetime(curdate,curtime))
   and mrn.end_effective_dt_tm  >  outerjoin(cnvtdatetime(curdate,curtime))
                                
   and fin.encntr_id            =  outerjoin(e.encntr_id)
   and fin.encntr_alias_type_cd =  outerjoin(1077.00)  ; fin
   and fin.active_ind           =  outerjoin(1)
   and fin.beg_effective_dt_tm  <  outerjoin(cnvtdatetime(curdate,curtime))
   and fin.end_effective_dt_tm  >  outerjoin(cnvtdatetime(curdate,curtime))
order by ce.event_end_dt_tm desc
detail
    data->cnt = data->cnt + 1
    
    stat = alterlist(data->qual, data->cnt)
    
    data->qual[data->cnt]->per_id        = ce.person_id
    data->qual[data->cnt]->enc_id        = ce.encntr_id
    data->qual[data->cnt]->event_id      = ce.event_id
    data->qual[data->cnt]->pat_name      = trim(p.name_full_formatted, 3)
    data->qual[data->cnt]->mrn           = mrn.alias  ; cnvtalias(mrn.alias, mrn.alias_pool_cd)
    data->qual[data->cnt]->fin           = fin.alias  ; cnvtalias(fin.alias, fin.alias_pool_cd)
    
    data->qual[data->cnt]->score         = ce.result_val
    data->qual[data->cnt]->result_dt_tm  = ce.event_end_dt_tm
    data->qual[data->cnt]->result_dt_txt = format(ce.event_end_dt_tm, '@SHORTDATETIME')       

with nocounter




declare good_blob  = vc
declare outbuf     = c32768
declare blobout    = vc

declare retlen     = i4
declare offset     = i4
declare newsize    = i4
declare finlen     = i4
declare xlen       = i4
/**********************************************************************
DESCRIPTION:  Find results that the rule has dropped within our timeframe
      NOTES:  
***********************************************************************/
select into 'nl:'

  from ce_event_note cen
     , long_blob     lb
     , (dummyt d with seq = data->cnt)
     
  plan d
   where data->cnt                   >  0
     and data->qual[d.seq]->event_id >  0
     
  join cen
   where cen.event_id                =  data->qual[d.seq]->event_id
   
  join lb
   where lb.parent_entity_id         =  cen.ce_event_note_id
     and lb.parent_entity_name       =  'CE_EVENT_NOTE'

order by cen.event_id  ;since blobget() is used sorting must be done at the RDBMS level

head cen.event_id
        
        if(cen.compression_cd = 728)
            blobout   = " "
            outbuf    = " "
            good_blob = " "
            
            for (x = 1 to (lb.blob_length / 32768))
                blobout = notrim(concat(notrim(blobout),notrim(fillstring(32768, " "))))
            endfor
            
            finlen  = mod(lb.blob_length, 32768)
            blobout = notrim(concat(notrim(blobout), notrim(substring(1, finlen, fillstring(32768, " ")))))
        
        else
            outbuf    = " "
            good_blob = " "
        endif

detail
    if(cen.compression_cd = 728)
        retlen = 1
        offset = 0

        while (retlen > 0)
            retlen = blobget(outbuf, offset, lb.long_blob)
            offset = offset + retlen
            if(retlen!=0)
                xlen = findstring("ocf_blob", outbuf, 1) - 1

                if(xlen<1)
                   xlen = retlen
                endif

                good_blob = notrim(concat(notrim(good_blob), notrim(substring(1, xlen, outbuf))))

            endif
         endwhile
    
    else
        outbuf = lb.long_blob
        xlen = findstring("ocf_blob", outbuf, 1) - 1
        
        good_blob = notrim(concat(notrim(good_blob), notrim(substring(1, xlen, outbuf))))
    endif

    blob_holder = good_blob
    
    ;We also want to pull off the score... just leaving the diagnosis list

    
    pos = findstring('|', blob_holder, 1, 0) + 1  ;Char after the |
    
    
    
    if(pos > 0)  ;I suppose there is a chance we don't find the pipe.
        blob_holder = substring(pos, size(blob_holder, 3) - pos + 1, blob_holder)
    endif
    
    data->qual[d.seq]->diag_string = blob_holder
    
    
with nocounter


 
;Presentation time
if (data->cnt > 0)
    
    if($SCRN_FLAG = 'N')
        select into $outdev
               PER_ID      =                        data->qual[d.seq].per_id  
             , ENC_ID      =                        data->qual[d.seq].enc_id  
             , EVENT_ID    =                        data->qual[d.seq].event_id
             , PAT_NAME    = trim(substring(1,  50, data->qual[d.seq].pat_name     ))
             , MRN         = trim(substring(1,  20, data->qual[d.seq].mrn          ))
             , FIN         = trim(substring(1,  20, data->qual[d.seq].fin          ))
             , SCORE       = trim(substring(1,  10, data->qual[d.seq].score        ))
             , RESULT_DATE = trim(substring(1,  20, data->qual[d.seq].result_dt_txt))
             , DXS         = trim(substring(1, 100, data->qual[d.seq].diag_string  ))

          from (dummyt d with SEQ = data->cnt)
        order by PER_ID, RESULT_DATE
        with format, separator = " ", time = 300
    else
        select into $outdev
               PER_ID      =                        data->qual[d.seq].per_id  
             , ENC_ID      =                        data->qual[d.seq].enc_id  
             , EVENT_ID    =                        data->qual[d.seq].event_id
             , PAT_NAME    = trim(substring(1,  50, data->qual[d.seq].pat_name     ))
             , MRN         = trim(substring(1,  20, data->qual[d.seq].mrn          ))
             , FIN         = trim(substring(1,  20, data->qual[d.seq].fin          ))
             , SCORE       = trim(substring(1,  10, data->qual[d.seq].score        ))
             , RESULT_DATE = trim(substring(1,  20, data->qual[d.seq].result_dt_txt))
             , DXS         = trim(substring(1, 100, data->qual[d.seq].diag_string  ))

          from (dummyt d with SEQ = data->cnt)
         
         ;This coming from Health Maint Rules for Periodic HCV Screening for Adults at High Risk
         where cnvtreal(data->qual[d.seq]->score) > 0.7  
        order by PER_ID, RESULT_DATE
        with format, separator = " ", time = 300
        
    endif

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
;call echorecord(data)

end
go
 
 

