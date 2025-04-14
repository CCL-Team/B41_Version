/**************************************************************************
 Program Title:   mPage Get Providers
 
 Object name:     mmm_mp_get_providers
 Source file:     mmm_mp_get_providers.prg
 
 Purpose:         Gets a list of providers for dropdowns above in the mPages
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   I couldn't find a good spot to borrow code from.  Everyone
                  seems to do this a bit differently.  For the time being, 
                  I'm going to just pull all active physicians from prsnl
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 02/21/2018 Michael Mayes        210739    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mmm_mp_get_providers:dba go
create program mmm_mp_get_providers:dba


prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
with OUTDEV


/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/

free record providers
record providers(
    1 cnt         = i2
    1 provider[*]
        2 id      = f8
        2 name    = vc
%i cust_script:mmm_mp_status.inc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/


/**************************************************************
; DVDev Start Coding
**************************************************************/


/***********************************************************************
DESCRIPTION:  Gather providers, pulling their names and ids
***********************************************************************/

select into 'nl:'
  from prsnl p
 where p.active_ind = 1
   ;and p.physician_ind = 1     ;TODO this is temporary for testing... I think we just want physicians
   and p.position_cd = 441.00   ;TODO this is DBA, and temporary... the amount of docs coming back was killing the frontend.
order by p.name_full_formatted
head report
    providers->cnt = 0

head p.name_full_formatted
    providers->cnt = providers->cnt + 1

    
    if (mod(providers->cnt, 100) = 1)
        stat = alterlist(providers->provider, providers->cnt + 100)
    endif

    
    providers->provider[providers->cnt].id   = p.person_id
    providers->provider[providers->cnt].name = trim(p.name_full_formatted, 3)

foot report

    stat = alterlist(providers->provider, providers->cnt)
with format, separator = " "
   


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
#exit_script

call echorecord(providers)

if(size(providers->provider,5) > 0)
    set providers->status_data->status = "S"
else
    set providers->status_data->status = "Z"
endif


call putStringToFile($outdev, providers)


end
go
 