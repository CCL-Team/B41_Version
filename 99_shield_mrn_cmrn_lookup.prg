/*************************************************************************
 Program Title: Shield MRN to CMRN Lookup Table File Creation

 Object name:   99_shield_mrn_cmrn_lookup
 Source file:   99_shield_mrn_cmrn_lookup.prg

 Purpose:       Retrieve information on previous MRNs gathered, and gathering
                new CMRN to use for previous data updates.

 Tables read:   
 Executed from: Manual

 Special Notes:

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
002 04/15/2021 Micahel Mayes        227001 Initial
*************END OF ALL MODCONTROL BLOCKS* *******************************/
drop   program 99_shield_mrn_cmrn_lookup:dba go
create program 99_shield_mrn_cmrn_lookup:dba

prompt
      'Output to File/Printer/MINE'     = 'MINE'   ;* Enter or select the printer or file name to send this report to.
    , 'Enter start date (DD-MMM-YYYY):' = 'SYSDATE'
    , 'Enter end date (DD-MMM-YYYY):'   = 'SYSDATE'

with OUTDEV, BEG_DATE, END_DATE


/*************************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************************/
declare CSV_comma_esc(csv_str = vc) = vc


/*************************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************************/

free record extract_data
record extract_data(
    1 cnt                = i4
    1 qual[*]
        2 rx_id          = f8
        2 person_id      = f8
)

free record mrn_data
record mrn_data(
    1 cnt                = i4
    1 qual[*]
        2 person_id      = f8
        2 cmrn           = vc
        2 mrn            = vc
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
declare default_beg_dt   = dq8
declare default_end_dt   = dq8

declare patient_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING', 14250, 'PATIENT'                   ))
declare per_cmrn_cd      = f8  with protect,   constant(uar_get_code_by(   'MEANING',     4, 'CMRN'                      ))
declare per_mrn_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',     4, 'MRN'                       ))

declare ord_act_ord_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  6003, 'ORDER'                     ))
declare dischg_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',    17, 'DISCHARGE'                 ))
declare final_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',    17, 'FINAL'                     ))

declare pos              = i4  with protect, noconstant(0)
declare pos2             = i4  with protect, noconstant(0)
declare idx              = i4  with protect, noconstant(0)
declare looper           = i4  with protect, noconstant(0)

declare shield_appt_file = vc  with protect, noconstant('MINE')

declare mrn_max          = i4  with protect, noconstant(0)
declare cmrn_max         = i4  with protect, noconstant(0)

declare temp_cmrn        = vc  with protect, noconstant('')

declare out_str          = vc  with protect, noconstant('')
declare cr_char          = vc  with protect,   constant(char(13))
declare lf_char          = vc  with protect,   constant(char(10))
declare delim_char       = vc  with protect,   constant('|')

declare run_beg_dt_tm    = dq8 with protect,   constant(cnvtdatetime(curdate, curtime3))
declare run_end_dt_tm    = dq8 with protect, noconstant(cnvtdatetime(curdate, curtime3))

/*************************************************************************
; DVDev Start Coding
**************************************************************************/

;If we are running in an extract, we'll pass in 0 dates, and we should find our own extract time frame based on when the extract is
;run
if($beg_date = '0' and $end_date = '0')

    set default_beg_dt = cnvtdatetime('01-DEC-2018')     ;Dec 2018
    set default_end_dt = cnvtdatetime(curdate, curtime3) ;Today

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

if($OUTDEV = 'EXTRACTTEST')
    set shield_appt_file = concat('cust_output:shield/historical/shield_medstar_mrn_cmrn_',
                                  trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'),3),
                                  '.dat')
elseif($OUTDEV = 'EXTRACT')
    set shield_appt_file = concat('cust_output:shield/shield_medstar_mrn_cmrn_',
                                  trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'), 3),
                                  '.dat')
else
    set shield_appt_file = $OUTDEV
endif

call echo(concat('File Location: ', shield_appt_file))



/*************************************************************************
DESCRIPTION:  Find main prescription data
**************************************************************************/
select into 'nl:'
  from orders                o
     , order_catalog_synonym ocs
     , order_action          oa
 where o.active_ind           =  1
   and o.orig_order_dt_tm             >= cnvtdatetime(beg_dt_tm)
   and o.orig_order_dt_tm             <= cnvtdatetime(end_dt_tm)
   and o.orig_ord_as_flag     =  1              ;from uCern:
                                                ; 0: InPatient Order
                                                ; 1: Prescription/Discharge Order
                                                ; 2: Recorded / Home Meds
                                                ; 3: Patient Owns Meds
                                                ; 4: Pharmacy Charge Only
                                                ; 5: Satellite (Super Bill) Meds.
   and ocs.synonym_id         =  o.synonym_id
   and ocs.active_ind         =  1
   ;TODO not sure about this, I've stolen it from saa126_14_mp.prg (referral management mpage)
   and oa.order_id            =  o.order_id
   and oa.action_type_cd      =  ord_act_ord_cd
order by o.orig_order_dt_tm
detail

    pos = locateval(idx, 1, extract_data->cnt, o.person_id,  extract_data->qual[idx]->person_id)

    if(pos = 0)
        extract_data->cnt = extract_data->cnt + 1

        ;For cleaner code below
        pos = extract_data->cnt

        if(extract_data->cnt > size(extract_data->qual, 5))
            stat = alterlist(extract_data->qual, extract_data->cnt + 9)
        endif

        extract_data->qual[pos]->rx_id             = o.order_id
        extract_data->qual[pos]->person_id         = o.person_id
    endif

foot report
    stat = alterlist(extract_data->qual, extract_data->cnt)

;Deliberately leaving nocounter off here so I can see the counts rise on the query as I'm waiting
with counter
;troubleshooting with maxqual, if you need it, comment the order by
;with orahintcbo('GATHER_PLAN_STATISTICS MONITOR mmm1741'), maxqual(o, 1000)


;Now we need to get the MRN/CMRN info
/*************************************************************************
DESCRIPTION:  Find person_alias info
**************************************************************************/
select into 'nl:'
    sortcol = if(pa.person_alias_type_cd = per_cmrn_cd) 0
              else                                      1
              endif
  from person_alias pa
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->person_id != 0
  join pa
   where pa.person_id                         =  extract_data->qual[d.seq]->person_id
     and pa.person_alias_type_cd              in (per_cmrn_cd, per_mrn_cd)
     and pa.alias                             >  ' '
     and pa.active_ind                        =  1
     and pa.beg_effective_dt_tm               <= cnvtdatetime(curdate, curtime3)
     and pa.end_effective_dt_tm               >= cnvtdatetime(curdate, curtime3)
order by pa.person_id, sortcol
head pa.person_id
    if(pa.person_alias_type_cd = per_cmrn_cd)
        temp_cmrn = trim(pa.alias, 3)
    else
        temp_cmrn = '-999' ;this shouldn't happen but I don't trust myself and want to see
    endif
detail
    if(pa.person_alias_type_cd = per_mrn_cd)
        mrn_data->cnt = mrn_data->cnt + 1
        
        ;For cleaner code below
        pos = mrn_data->cnt
        
        if(mrn_data->cnt > size(mrn_data->qual, 5))
            stat = alterlist(mrn_data->qual, mrn_data->cnt + 9)
        endif
        
        mrn_data->qual[pos].person_id = pa.person_id
        mrn_data->qual[pos].cmrn      = temp_cmrn
        mrn_data->qual[pos].mrn       = trim(pa.alias, 3)
    endif
    
foot report
        stat = alterlist(mrn_data->qual, mrn_data->cnt)
with nocounter



;Lets find the maxlengths of the columns
for(looper = 1 to mrn_data->cnt)
    if(mrn_max < size(mrn_data->qual[looper]->cmrn, 3))
        set mrn_max = size(mrn_data->qual[looper]->cmrn, 3)
    endif

    if(cmrn_max < size(mrn_data->qual[looper]->mrn, 3))
        set cmrn_max = size(mrn_data->qual[looper]->mrn, 3)
    endif
endfor


set run_end_dt_tm    = cnvtdatetime(curdate, curtime3)




;Draw out the file.  I tried doing this in dummyts but due to the with clauses we had to use, we were
;getting different operation from the opsjob vs the manual runs.
set frec->file_name = shield_appt_file ;set the file name/location
set frec->file_buf  = "w"
set stat = cclio("OPEN",frec) ;open the file and prepare for writing

set out_str = notrim(check(build2(
    'CMRN'    ,delim_char,
    'MRN'
)))


set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
set stat = cclio("WRITE",frec)


for(looper = 1 to mrn_data->cnt)
    ;I don't really need all the dumb max vars anymore since we are not in a query...
    ;however I'm just going to keep it for now.
    set out_str = notrim(build2(
        trim(substring(1, value(cmrn_max), mrn_data->qual[looper]->cmrn),3), delim_char,
        trim(substring(1, value(mrn_max ), mrn_data->qual[looper]->mrn ),3)
        
    ))

    set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
    set stat = cclio("WRITE",frec)
endfor

set stat = cclio("CLOSE",frec)

call echorecord(mrn_data)

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
call echo(concat('Script run time: ',
                  format(datetimediff(run_end_dt_tm, run_beg_dt_tm), "DD Days HH:MM:SS:CC;;Z")))

end
go
