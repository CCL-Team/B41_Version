/**************************************************************************
 Program Title:   mPage Amb locations
 
 Object name:     cust_mp_amb_orgs
 Source file:     cust_mp_amb_orgs.prg
 
 Purpose:         Gets Ambulatory Orgs for dropdowns above in the mPages
 
 Tables read:
 
 Executed from:   MPage
 
 Special Notes:   Basing this off of mp_amb_locations which I was using before
                  but I think I need to flip to orgs instead... fighting
                  performance.
                    
                  
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 08/27/2024 Michael Mayes        239854    Initial
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
  drop program cust_mp_amb_orgs_test:dba go
create program cust_mp_amb_orgs_test:dba
 
 
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
 
free record orgs
record orgs(
    1 cnt         = i2
    1 org[*]
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
DESCRIPTION:  Gather the Ambulatory Locations, pulling their name and ids
***********************************************************************/
select into 'nl:'
                                                                        
from org_set         os                                                                        
   , org_set_org_r   osor                                                                
   , organization    o                                                                    
   , location        l                                                                        
                                                                                         
where os.name               in ('*Amb*','*Medstar Facilities*')                          
  and os.active_ind         =  1                                                         
                                                                                         
  and osor.org_set_id       =  os.org_set_id                                             
  and osor.active_ind       =  1                                                         
                                                                                         
  and o.organization_id     =  osor.organization_id                                      
  and o.active_ind          =  1                                                         
  and o.organization_id not in(   589723.00  /*Franklin Square Hospital Center        */ 
                              ,   627889.00  /*Good Samaritan Hospital                */ 
                              ,   628009.00  /*Harbor Hospital Center                 */ 
                              ,   628058.00  /*Union Memorial Hospital                */ 
                              ,   628085.00  /*Georgetown University Hospital         */ 
                              ,   628088.00  /*Washington Hospital Center             */ 
                              ,   628738.00  /*National Rehabilitation Hospital       */ 
                              ,   640191.00  /*Franklin Square Employee Health        */ 
                              ,   640192.00  /*Franklin Square Psych                  */ 
                              ,   640194.00  /*Union Memorial Psych                   */ 
                              ,   640196.00  /*WHC Psych                              */ 
                              ,   642194.00  /*UMH Tucker, Andrew                     */ 
                              ,   664189.00  /*GUH Psych                              */ 
                              ,   807419.00  /*GUH Quest Diagnostics Nichols Institute*/ 
                              ,   807425.00  /*GUH Labcorp                            */ 
                              ,   807427.00  /*WHC Labcorp                            */ 
                              ,  3440653.00  /*MedStar St Mary's Hospital             */ 
                              ,  3476823.00  /*Medstar Diversified                    */ 
                              ,  4678436.00  /*Medstar Affiliated Phys                */ 
                              ,  5335375.00  /*PAL Owings Mills                       */ 
                              ,  5335384.00  /*PAL Smyth                              */ 
                              ,  6591470.00  /*Dave Choi Vascular Surgery             */ 
                              ,  7232532.00  /*Rafael J. Convit Plastic Surgery       */ 
                              ,  7232553.00  /*Gastroenterology Consultants of DC     */ 
                              ,  7232577.00  /*Robinson Cardiology                    */ 
                              ,  7232590.00  /*Metro Renal Associates                 */ 
                              ,  7232615.00  /*National Capital Nephrology            */ 
                              ,  7316485.00  /*Maximed Associates                     */ 
                              ,  8608690.00  /*Emmanuel T Mbualungu MD                */ 
                              ,  8611509.00  /*Georges C Awah MD                      */ 
                              ,  9308346.00  /*MMC LabCorp                            */ 
                              ,  9448872.00  /*Krishna Dass MD                        */ 
                              ,  9514275.00  /*SMD LabCorp                            */ 
                              ,  1325870.00  /*MedStar Health                         */ 
                              ,  1650929.00  /*zzzFranklin Square Hospital Center     */ 
                              ,  2650023.00  /*WHC Labcorp Stats                      */ 
                              ,  3433629.00  /*Medstar Physician Partners             */ 
                              , 10608377.00  /*SMD Saint Mary's Stats                 */ 
                              , 10608446.00  /*SMD Health Fair                        */ 
                              , 10679417.00  /*Integrative Family Medicine            */ 
                              , 10843874.00  /*Integrative Family Medicine Gaithersbur*/ 
                              , 10925508.00  /*MSMHC Rehab Admin Only                 */ 
                              , 12012326.00  /*Irene F Ibarra MD PA                   */ 
                              )                                                          
                                                                                         
  and l.organization_id     =  o.organization_id                                         
  and l.location_type_cd    =  ( select cv.code_value                                    
                                   from code_value cv                                    
                                  where cv.code_set = 222                                
                                    and cdf_meaning = 'FACILITY'                         
                               )                                                         
  and l.beg_effective_dt_tm <  cnvtdatetime(curdate, curtime3)                           
  and l.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)                           
  and l.active_ind = 1                                                                   
                                                                                      
order by o.org_name  
head report
    orgs->cnt = 0
 
head o.organization_id
    orgs->cnt = orgs->cnt + 1
 
 
    if (mod(orgs->cnt, 100) = 1)
        stat = alterlist(orgs->org, orgs->cnt + 100)
    endif
 
 
    orgs->org[orgs->cnt].id   = o.organization_id
    orgs->org[orgs->cnt].name = trim(o.org_name, 3)
 
foot report
 
    stat = alterlist(orgs->org, orgs->cnt)
                                                                       
with nocounter                                                                            

 
 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
#exit_script
 
call echorecord(orgs)
call echojson(orgs)
 
if(size(orgs->org,5) > 0)
    set orgs->status_data->status = "S"
else
    set orgs->status_data->status = "Z"
endif
 
 
call putRSToFile($outdev, orgs)
 
 
end
go
 