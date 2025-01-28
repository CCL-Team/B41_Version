/*************************************************************************
 Program Title: Discharge Summary - NICU/Newborn Note Token

 Object name:   0x_nicu_note_token
 Source file:   0x_nicu_note_token.prg

 Purpose:       Scan office clinic notes for LCV of note and pull
                forward as a smart template.

 Tables read:

 Executed from:

 Special Notes: Most of this was stolen/adapted from st_dyndoc_parser_script_hpi or
                st_dyndoc_parser_script_cc

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 2021-08-25 Michael Mayes        227598 Initial
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0x_nicu_note_token:dba go
create program 0x_nicu_note_token:dba

prompt
    "Output to File/Printer/MINE" = "MINE"
with outdev

%i cust_script:0_cust_ce_blob_func.inc



/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/


record blob_events(
    1 cnt = i4
    1 qual[*]
        2 event_id = f8
        2 event_dt = vc
)

/*
record request(
    1 encntr_id   = f8
    1 person_id   = f8
    1 tracking_id = f8
)
*/

/*
free record reply
record reply(
    1 text = vc
    1 format = i4
)
*/

/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/






/*************************************************************
; DVDev Start Coding
**************************************************************/

/**********************************************************************
DESCRIPTION:  Find potential documentation
      NOTES:  This uses reqinfo->updt_id to find documentation from the
              provider.  We will use these docs to get the blobs and run
              our parsing on later.
***********************************************************************/
select into "nl:"
  from dd_contribution        dd
     , clinical_event         c
     , clinical_event         c2
     , encounter              e
  plan dd
   where dd.person_id        =  request->person_id
                             
  join e                     
   where e.encntr_id         =  dd.encntr_id
                             
  join c                     
   where c.event_id          =  dd.mdoc_event_id
     and c.encntr_id         =  dd.encntr_id
     and c.valid_until_dt_tm >  sysdate
     and c.event_cd          =  6693039  ; Discharge Summary
     and c.EVENT_TITLE_TEXT  = 'Discharge Summary - NICU/Newborn'
                             
  join c2                    
   where c2.event_id         =  dd.doc_event_id
     
order by c.performed_dt_tm desc, c.event_id
head c.event_id
    blob_events->cnt = blob_events->cnt + 1

    if(mod(blob_events->cnt, 10) = 1)
        stat = alterlist(blob_events->qual, blob_events->cnt + 9)
    endif

    blob_events->qual[blob_events->cnt]->event_id = c2.event_id
    blob_events->qual[blob_events->cnt]->event_dt = format(c2.event_end_dt_tm, "@SHORTDATETIMENOSEC")

foot report
    stat = alterlist(blob_events->qual, blob_events->cnt)

with nocounter

call echorecord(blob_events)


if(blob_events->cnt > 0)
    ;Just get the first one.
    set blob = cust_ceblob_get(blob_events->qual[1]->event_id)

endif

set reply->format = 1
set reply->text = blob





/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/



#exit_script


call echorecord(reply)

call echo(reply->text)


end
go


