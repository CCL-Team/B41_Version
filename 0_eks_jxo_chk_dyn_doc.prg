/*************************************************************************
 Program Title: Check Dyndoc for Tagged Note and Verbiage
 
 Object name:   0_eks_jxo_chk_dyn_doc.prg
 Source file:   0_eks_jxo_chk_dyn_doc.prg
 
 Purpose:   This script looks for the terms "Medical Student" and
            also the dotphrase (.medstudentwithresidentsuper or .attestationmedicalstudent)
            used in the provider note specified by the clinical event ID passed by the rule.
            If the ED Student Note is found and the verbiage is not found then it will return
            true for the rule.
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: I borrowed some logic from Swetha's 11_eks_wordsearch.prg.
                0x_token_mayes_test.prg
                
                Looks like the rule for this is: ed_med_attestation_ce_01
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 01/08/2025 Joseph Opinion       352436
002 03/13/2025 Joseph Opinion
003 04/24/2025 Michael Mayes        352436 Taking ownership from Joseph and finishing.
*
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
  drop program 0_eks_jxo_chk_dyn_doc:dba go
create program 0_eks_jxo_chk_dyn_doc:dba

prompt
    "Output to File/Printer/MINE" = "MINE"
     , "Enter EventID:"           = ""
     , "Enter Note:"              = ""
     , "Enter Search Phrase"      = ""

with OUTDEV, eventID, searchNote, searchPhrase


/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
%i cust_script:0_cust_ce_blob_func.inc
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record blob_events(
    1 cnt              = i4
    1 criteria_met = i2
    1 qual[*]
        2 event_id     = f8
        2 event_dt     = vc
        2 found_note   = i4
        2 found_phrase = i4
        2 text         = vc
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
;declare log_message = vc with protect, noconstant("")
;declare retval      = i4 with protect, noconstant(0)
;declare log_misc1   = vc with protect, noconstant("")
declare provider    = vc with protect, noconstant("")
declare looper      = i4 with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/

/**********************************************************************
DESCRIPTION:  
      NOTES:  
***********************************************************************/
select into "nl:"
  from clinical_event    c       ; Clinical event of note
     , prsnl             pr
     , clinical_event    c2      ; This is the child clinical event of the blob

  /*****Note that the clinical event id is different from the event id*****/
  plan c 
   where c.clinical_event_id        =  cnvtint($eventID)
  
  join pr 
   where pr.person_id               =  c.updt_id
  
  join c2 
   where c2.parent_event_id         =  c.parent_event_id
     and c2.valid_until_dt_tm       >  cnvtdatetime(curdate, curtime)
     and c2.result_status_cd        in (25.00, 34.00, 35.00)
     and c2.view_level              =  0
     and c2.note_importance_bit_map =  2
     and c2.event_class_cd          =  224.00          ; DOC
     and c2.entry_mode_cd           =  66762423.00     ; Dynamic Documentation

/***** Using the event id, dyanamically resize the array every 10 events.
Stores the event ID and formatted event date in the array
In the foot report section - Finalizes the size of the array to match the actual count of events
Once everything is said and done, display the blob_events to display the collected events
*****/
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



;call echorecord(blob_events)

;I'm running with Joesph's idea, but in theory we should just have the one blob eh?
for(looper = 1 to blob_events->cnt)

    set blob_events->qual[looper]->text = cust_ceblob_get(blob_events->qual[looper]->event_id)
    
    set blob_events->qual[looper]->found_note   = findstring($searchNote  , blob_events->qual[looper]->text)
    set blob_events->qual[looper]->found_phrase = findstring($searchPhrase, blob_events->qual[looper]->text)
    
    if(    blob_events->qual[looper]->found_note   > 1
       and blob_events->qual[looper]->found_phrase = 0
      )
        set blob_events->criteria_met = 1
    endif
    
endfor




/*** Logic to determine if criteria are met:
     - found_note > 1 means "ED Student Note" was found
     - found_phrase = 0 means the attestation phrase was NOT found
     This combination indicates a student note that needs attestation ***/

if(blob_events->criteria_met = 1)   
    set log_message = "Search Criteria Met."
    set retval      = 100
else
    set log_message = "Search Criteria Not Met."
    set retval      = 0
endif

call echo(log_message)

#EXITSCRIPT
end
go

/*****For testing purposes*****/
;0_eks_jxo_chk_dyn_doc:group1 "mine", "26858022782.00", "ED Student Note",
;"was present with a medical student who participated in the documentation of this note" go