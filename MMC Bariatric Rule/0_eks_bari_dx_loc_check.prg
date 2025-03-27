/*************************************************************************
 Program Title: Bariatric Diag and Loc check

 Object name:   0_eks_bari_dx_loc_check
 Source file:   0_eks_bari_dx_loc_check.prg

 Purpose:       Identify the most recent Bariatric Procedure, and location
                for a patient for a couple of Bariatric rules.

 Tables read:

 Executed from: Rules
                CUST_BARI_OS_RESULT
                CUST_BARI_OS_SZ_NOTIFY
                CUST_ED_BARI_OS_PROC_DAYS

 Special Notes:

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 12/05/2024 Michael Mayes        347124 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_bari_dx_loc_check:dba go
create program 0_eks_bari_dx_loc_check:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)

/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/



/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare ord_loc        = vc  with protect, noconstant('')
declare ord_dxes       = vc  with protect, noconstant('')
declare ord_prov       = vc  with protect, noconstant('')

/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_bari_dx_loc_check failed during execution"



/**********************************************************************
DESCRIPTION:  Find Location of the Patient
      NOTES:  We are after
                FSH UMH GSH HH
                WHC GUH
                MMC
                SMH
                SMHC
***********************************************************************/
select into 'nl:'
  from encounter e
 where e.encntr_id  =  trigger_encntrid
detail
    ;Defaulting a case in
    ord_loc = 'Unknown'

    case(e.organization_id)
    of  589723.00:  ord_loc = 'FSH' ;FSH
    of  628058.00:  ord_loc = 'UMH' ;UMH
    of  627889.00:  ord_loc = 'GSH' ;GSH
    of  628009.00:  ord_loc = 'HH'  ;HH
    of  628088.00:  ord_loc = 'WHC' ;WHC
    of  628085.00:  ord_loc = 'GUH' ;GUH
    of 3763758.00:  ord_loc = 'MMC' ;MMC
    of 3440653.00:  ord_loc = 'SMH' ;SMH
    of 3837372.00:  ord_loc = 'SMHC';SMHC
    of  628738.00:  ord_loc = 'NRH' ;NRH - not in specs... probably not covered.

    endcase
with nocounter


/**********************************************************************
DESCRIPTION:  Find Diagnosis on Linked Order
      NOTES:  (I hope this is what I am supposed to do.)
***********************************************************************/
select into "nl:"

  from dcp_entity_reltn der
     , diagnosis d
     , nomenclature n1
     , nomenclature n2

 where der.entity1_id        = link_orderid
   and der.entity_reltn_mean = "ORDERS/DIAGN"
   and der.active_ind        = 1
   
   and d.diagnosis_id = der.entity2_id
   
   and n1.nomenclature_id = d.nomenclature_id

   and outerjoin(d.originating_nomenclature_id) = n2.nomenclature_id

order by der.entity1_id, der.rank_sequence, d.diagnosis_id

head d.diagnosis_id
    ord_dxes = trim(concat(ord_dxes, trim(d.diagnosis_display, 3), ";"), 3)

with nocounter


/**********************************************************************
DESCRIPTION:  Find Ordering Provider
      NOTES:  
***********************************************************************/
select into "nl:"

  from orders       o
     , order_action oa
     , prsnl        pr
     
 where o.order_id = link_orderid
 
   and oa.order_id       =  o.order_id 
   and oa.action_type_cd =  2534.00    ;ORDER
   
   and pr.person_id      =  oa.order_provider_id

detail
    ord_prov = trim(pr.name_full_formatted, 3)

with nocounter


;Debugging here eventually.
;set ord_loc = "SMH"
;set ord_dxes = ""
;set ord_prov = "Mayes, Michael"


;Quick to protect our rule parser
if(ord_dxes = "") set ord_dxes = '--'
endif


; Build out a datamessage for the rules
set log_misc1 = notrim(build2(     'LOC'     , '|', ord_loc
                             ,'|', 'ORDDX'   , '|', ord_dxes
                             ,'|', 'ORDPROV' , '|', ord_prov
                             )
                      )


;For this one we are going to always auto success... we'll catch the no data messages, and set some default.
set retval      =  100
set log_message =  "0_eks_bari_dx_loc_check found Data"



/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echo(build('retval     :', retval         ))
call echo(build('log_message:', log_message    ))
call echo(build('log_misc1  :', log_misc1      ))


end
go


