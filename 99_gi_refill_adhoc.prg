/*************************************************************************
 Program Title: GI Refill Adhoc
 
 Object name:   99_gi_refill_adhoc
 Source file:   99_gi_refill_adhoc.prg
 
 Purpose:       Find orders resulting from drug refills, and various metadata
                requested by GI.  Namely average count per month.
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 05/14/2020 Michael Mayes        220793 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 99_gi_refill_adhoc:dba go
create program 99_gi_refill_adhoc:dba
 
prompt 
	   "Output to File/Printer/MINE" = "MINE"
	 , "Form Start Date"             = "SYSDATE"
	 , "Form End Date"               = "SYSDATE"
with OUTDEV, BEG_DT, END_DT
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
%i cust_script:cust_timers_debug.inc
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 prov_id           = f8
        2 prov_name         = vc
        
        2 action            = vc
        
        2 refilled_enc      = f8
        2 refilled_fin      = vc
        2 refilled_ord_id   = f8
        2 refilled_ord_name = vc
        2 refilled_dt_tm    = dq8
        2 refilled_dt_txt   = vc
        
        2 refill_enc        = f8 
        2 refill_fin        = vc 
        2 refill_ord_id     = f8 
        2 refill_ord_name   = vc 
        2 refill_ord_dt     = dq8 
        2 refill_ord_dt_txt = vc 
)

record sum_data(
    1 cnt = i4
    1 qual[*]
        2 prov_id          = f8
        2 prov_name        = vc
                           
        2 highest          = f8
        2 lowest           = f8
        2 lowest_non_zero  = f8
        2 data_months      = f8
                           
        2 total            = f8
                           
        2 average          = f8
        2 average_non_zero = f8
        
        2 months[12]
            3 cnt = i4
)


record months(
    1 cnt = i4 
    1 qual[*]
        2 beg_dt_tm = dq8
        2 end_dt_tm = dq8
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
declare looper             = i4  with protect, noconstant(0)
declare looper2            = i4  with protect, noconstant(0)
declare pos                = i4  with protect, noconstant(0)
declare pos2               = i4  with protect, noconstant(0)
declare idx                = i4  with protect, noconstant(0)
declare datelooper         = dq8 with protect

declare panic              = i4  with protect, noconstant(0)

declare directory = vc with constant('/home/mmm174/')

declare date_rand_part = vc with constant(concat( format(cnvtdatetime(curdate, curtime3), 'YYYYMMDDhhmmss;;Q')
                                                , trim(substring(3, 3, cnvtstring(rand(0))))
                                                )
                                         )

declare filename     = vc with constant(concat('99_gi_refill_adhoc_'    , date_rand_part, '.csv'))
declare sum_filename = vc with constant(concat('99_gi_refill_adhoc_sum_', date_rand_part, '.csv'))
                        
declare file_path     = vc with protect,   constant(build2(directory, filename    ))
declare sum_file_path = vc with protect,   constant(build2(directory, sum_filename))
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
declare prog_timer = i4
set prog_timer = ctd_add_timer_seq('99_GI_REFILL_ADHOC', 100)


call echo(build('file_path    :', file_path    ))
call echo(build('sum_file_path:', sum_file_path))

set pos = 0

set datelooper = cnvtdatetime($beg_dt)

while(datelooper < cnvtdatetime($end_dt)
      and panic < 100
     )

    set months->cnt = months->cnt + 1
    set stat = alterlist(months->qual, months->cnt)
    
    set months->qual[months->cnt]->beg_dt_tm = datetimefind(datelooper, 'M', 'B', 'B')
    set months->qual[months->cnt]->end_dt_tm = datetimefind(datelooper, 'M', 'E', 'E')

    set datelooper = datetimeadd(months->qual[months->cnt]->end_dt_tm, 1)
    set datelooper = datetimefind(datelooper, 'M', 'B', 'B')

    if(months->qual[months->cnt]->beg_dt_tm < cnvtdatetime($beg_dt))
        set months->qual[months->cnt]->beg_dt_tm = cnvtdatetime($beg_dt)
    endif

    if(months->qual[months->cnt]->end_dt_tm > cnvtdatetime($end_dt))
        set months->qual[months->cnt]->end_dt_tm = cnvtdatetime($end_dt)
    endif
    
    set panic = panic + 1

endwhile

call echorecord(months)


declare main_query = i4 
set main_query =  ctd_add_timer('Main Query')
for(looper = 1 to months->cnt)
    
    /**********************************************************************
    DESCRIPTION:  Main query
          NOTES:  Big time performance grief if I tried to do too much here
                  Separating out into dummyts helps believe it or not.
    ***********************************************************************/
    call ctd_add_timer(notrim(build2('MONTH: '
                                    , format(months->qual[looper]->beg_dt_tm, '@SHORTDATETIME'), ' - '
                                    , format(months->qual[looper]->end_dt_tm, '@SHORTDATETIME')
                                    )
                             )
                      )
    select into 'nl:'
         
      from orders o
         , order_order_reltn ordr
         , order_action oa
         
     ;where o.orig_order_dt_tm        between cnvtdatetime('01-JUL-2023 00:00:00') and cnvtdatetime('01-JUL-2023 23:59:59')
     where o.orig_order_dt_tm        >= cnvtdatetime(months->qual[looper]->beg_dt_tm) 
       and o.orig_order_dt_tm        <= cnvtdatetime(months->qual[looper]->end_dt_tm)
       and o.catalog_type_cd         =  2516.000000  ;Pharmacy
       and o.product_id              =  0.0
       and o.activity_type_cd        =  705.0  ;Pharmacy
                                     
       and ordr.related_to_order_id  =  o.order_id
       and ordr.relation_type_cd     in ( 56656855  ;Renew 
                                        , 56656851  ;Repeat
                                        )
                                        
       and oa.order_id               =  o.order_id
       and oa.action_type_cd         =  2534.00  ;Order
       and oa.action_personnel_id    in ( 29316916.00  ;Akinmadelo, FNP, Omolola A.
                                        , 39262957.00  ;Ali, MD, Bilal   
                                        , 25479034.00  ;Alzayer, MD, Ghassan   
                                        , 34647129.00  ;Asamoah-Clark, MD, Nikiya O.   
                                        , 30070016.00  ;Barrow, MD, Jasmine Bahiya   
                                        , 39078677.00  ;Benedetto, NP, Heather   
                                        ,  3743811.00  ;Bhatia, MD, Abhijit S.   
                                        ,  1378223.00  ;Bowser, MD, Lester Kenneth   
                                        ,  1373818.00  ;Carroll, MD, John Edward   
                                        ,  5924639.00  ;Chalhoub, MD, Walid M.   
                                        , 35306428.00  ;Charbel, MD, Samer C   
                                        , 30521080.00  ;Chen, MD, Alan   
                                        , 16289916.00  ;Ciofoaia, MD, Victor   
                                        , 36614927.00  ;Desire, ACNP, Deanna D   
                                        ,  1403588.00  ;Doman, MD, David B.   
                                        , 39847151.00  ;Fond, MD, Aaron Michael   
                                        ,  2471459.00  ;Frank, MD, James H.   
                                        , 37946628.00  ;Ghazanfari, PA-C, Parnia   
                                        , 34895825.00  ;Green, NP-C, Anise M   
                                        ,  1374023.00  ;Haddad, MD, Nadim G.   
                                        , 16296381.00  ;Hussain, MD, Ali A.   
                                        ,  3821133.00  ;Jennings, MD, Joseph J.   
                                        ,  1516645.00  ;Johnson, CRNP, Amy N.   
                                        , 33338903.00  ;Kanth, MD, Priyanka   
                                        , 22878293.00  ;Keadle, FNP, Emily C   
                                        ,  2943173.00  ;Lewis, MD, James H.   
                                        , 19493222.00  ;Livesay, FNP, Lauren K   
                                        ,  1379246.00  ;Loughney, MD, Thomas M.   
                                        , 39124054.00  ;Marlatte, FNP, Denise L.   
                                        ,  2610655.00  ;Mattar, MD, Mark C.   
                                        , 30381631.00  ;Meighani, MD, Alireza   
                                        ,  2793988.00  ;Mills, MD, Lawrence   
                                        , 32275254.00  ;Myrtil, NP, Mildred   
                                        ,  8148070.00  ;Nath, MD, Anand   
                                        ,  5297506.00  ;Nocerino, MD, Angelica   
                                        , 34393319.00  ;Olsen, DO, Raena S   
                                        ,  1402266.00  ;Palese, MD, Caren Sabina   
                                        ,  5130094.00  ;Panko, CRNP, Alicia H.   
                                        , 30090895.00  ;Parungao, MD, Jose Mari D   
                                        , 28854547.00  ;Peacher, CRNP, Kathryn M   
                                        , 38537181.00  ;Peghini, MD, Paolo Lino   
                                        ,  5924666.00  ;Pietrak, MD, Stanley J.   
                                        ,  8530414.00  ;Real, MD, Mark J   
                                        ,  5581553.00  ;Richardson, CRNP, Shannan E   
                                        , 10342883.00  ;Rosenthal, MD, Linda E.   
                                        , 29692385.00  ;Sabatino, CRNP, Meggin   
                                        , 19625142.00  ;Sankineni, MD, Abhinav   
                                        , 31487610.00  ;Schaefer, PA-C, Stephanie D   
                                        , 38415352.00  ;Schenck, MD, Robert   
                                        ,  5040494.00  ;Shafa, MD, Shervin   
                                        ,  1352797.00  ;Shearer, MD, Danny T   
                                        ,  1369584.00  ;Shocket, MD, Ira David   
                                        ,  2800921.00  ;Sloane, MD, Dana A.   
                                        , 36032830.00  ;Sohal, MD, Kunwardeep Singh   
                                        , 16833175.00  ;Spencer, FNP, Brooke A   
                                        , 34593525.00  ;Tennyson, CRNP, Heather Renee  
                                        ,  1407866.00  ;Thompson, MD, Gary W   
                                        , 38616800.00  ;Vittal, MD, Anusha   
                                        , 33351048.00  ;Wells, CRNP, Amber   
                                        ,  1368124.00  ;West, MD, Arthur N.   
                                        , 26102854.00  ;Wiese, CRNP, Sandy   
                                        , 39076132.00  ;Wilcox, FNP, Molly R   
                                        )
       
    order by o.orig_order_dt_tm 

    detail
        data->cnt = data->cnt + 1
        
        stat = alterlist(data->qual, data->cnt)
        
        data->qual[data->cnt]->prov_id           = oa.action_personnel_id
        
        data->qual[data->cnt]->action            = uar_get_code_display(ordr.relation_type_cd)
        
        data->qual[data->cnt]->refilled_enc      = o.encntr_id
        data->qual[data->cnt]->refilled_ord_id   = o.order_id
        data->qual[data->cnt]->refilled_ord_name = trim(o.ordered_as_mnemonic, 3)
        data->qual[data->cnt]->refilled_dt_tm    = o.orig_order_dt_tm
        data->qual[data->cnt]->refilled_dt_txt   = format(o.orig_order_dt_tm, '@SHORTDATETIME')
        
        data->qual[data->cnt]->refill_ord_id     = ordr.related_from_order_id
        

    with nocounter
    call ctd_end_timer(0)
endfor
call ctd_end_timer(main_query)


/**********************************************************************
DESCRIPTION:  Find provider name 
      NOTES:  
***********************************************************************/
call ctd_add_timer('Name Query')
select into 'nl:'

  from prsnl p
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                  >  0
     and data->qual[d.seq]->prov_id >  0
  
  join p
   where p.person_id = data->qual[d.seq]->prov_id

detail
    data->qual[d.seq]->prov_name         = trim(p.name_full_formatted, 3)
    
with nocounter   
call ctd_end_timer(0)


/**********************************************************************
DESCRIPTION:  Find FIN
      NOTES:  
***********************************************************************/
call ctd_add_timer('FIN Query')
select into 'nl:'

  from encntr_alias fin
     , (dummyt d with seq = data->cnt)

  plan d 
   where data->cnt                       >  0
     and data->qual[d.seq]->refilled_enc >  0
  
  join fin
   where fin.encntr_id             = data->qual[d.seq]->refilled_enc
     and fin.encntr_alias_type_cd  = 1077.00    ; FIN
     and fin.active_ind            = 1

detail
    data->qual[d.seq]->refilled_fin      = trim(fin.alias, 3)
    
with nocounter   
call ctd_end_timer(0)


/**********************************************************************
DESCRIPTION:  Find info on older prescription.
      NOTES:  
***********************************************************************/
call ctd_add_timer('Old Prescription Query')
select into 'nl:'
  
  from orders oldo
     , encntr_alias ofin
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                        >  0
     and data->qual[d.seq]->refill_ord_id >  0
     
  join oldo
   where oldo.order_id                    =  data->qual[d.seq]->refill_ord_id
  
  join ofin
   where ofin.encntr_id                   =  oldo.encntr_id
     and ofin.encntr_alias_type_cd        =  1077.00    ; FIN
     and ofin.active_ind                  =  1

detail
    data->qual[d.seq]->refill_enc        = oldo.encntr_id
    data->qual[d.seq]->refill_fin        = trim(ofin.alias, 3) 
    data->qual[d.seq]->refill_ord_name   = trim(oldo.ordered_as_mnemonic, 3)
    data->qual[d.seq]->refill_ord_dt     = oldo.orig_order_dt_tm 
    data->qual[d.seq]->refill_ord_dt_txt = format(oldo.orig_order_dt_tm, '@SHORTDATETIME')
with nocounter
call ctd_end_timer(0)


call ctd_add_timer('Sum Looper')
for(looper = 1 to data->cnt)

    set pos = locateval(idx, 1, sum_data->cnt, data->qual[looper]->prov_id, sum_data->qual[idx]->prov_id)
    
    if(pos = 0)
        set sum_data->cnt = sum_data->cnt + 1
        
        set stat = alterlist(sum_data->qual, sum_data->cnt)
        
        set pos = sum_data->cnt
        
        set sum_data->qual[pos]->prov_id   = data->qual[looper]->prov_id
        set sum_data->qual[pos]->prov_name = data->qual[looper]->prov_name
        
        ;defaulting
        set sum_data->qual[pos]->lowest          = 999
        set sum_data->qual[pos]->lowest_non_zero = 999
        
    endif
    
    ;call echo(datetimepart(data->qual[looper]->refilled_dt_tm, 2))
    
    set pos2 = datetimepart(data->qual[looper]->refilled_dt_tm, 2)
    
    set sum_data->qual[pos]->months[pos2]->cnt = sum_data->qual[pos]->months[pos2]->cnt + 1

endfor
call ctd_end_timer(0)


call ctd_add_timer('Meta Looper')
for(looper = 1 to sum_data->cnt)

    for(looper2 = 1 to 12)
        ; We are actually only running 7-23 - 2-24
        if(looper2 in (7, 8, 9, 10, 11, 12, 1, 2))
            if(sum_data->qual[looper]->months[looper2]->cnt > sum_data->qual[looper]->highest)
                set sum_data->qual[looper]->highest = sum_data->qual[looper]->months[looper2]->cnt
            endif
            
            if(sum_data->qual[looper]->months[looper2]->cnt < sum_data->qual[looper]->lowest)
                set sum_data->qual[looper]->lowest = sum_data->qual[looper]->months[looper2]->cnt
            endif
            
            if(sum_data->qual[looper]->months[looper2]->cnt > 0)
                if(sum_data->qual[looper]->months[looper2]->cnt < sum_data->qual[looper]->lowest_non_zero)
                    set sum_data->qual[looper]->lowest_non_zero = sum_data->qual[looper]->months[looper2]->cnt
                endif
                
                set sum_data->qual[looper]->data_months = sum_data->qual[looper]->data_months + 1 
            endif
            
            set sum_data->qual[looper]->total = sum_data->qual[looper]->total + sum_data->qual[looper]->months[looper2]->cnt
        endif
    endfor
    
    ;Just defaulting this for the 8 months we are planning to run for now.
    set sum_data->qual[looper]->average          = sum_data->qual[looper]->total / 8
    
    set sum_data->qual[looper]->average_non_zero = sum_data->qual[looper]->total / sum_data->qual[looper]->data_months

endfor
call ctd_end_timer(0)

 
;Presentation time
;with heading, pcformat('"', ',', 1), format=stream, format,  nocounter , compress
;with format, separator = " ", time = 300
if (data->cnt > 0)
    
    select into value(file_path)
           PROV_ID         =                        data->qual[d.seq].prov_id
         , PROV_NAME       = trim(substring(1,  50, data->qual[d.seq].prov_name        ))
         , ACTION          = trim(substring(1,  20, data->qual[d.seq].action           ))
         , REFILLED_ENC    =                        data->qual[d.seq].refilled_enc
         , REFILLED_FIN    = trim(substring(1,  30, data->qual[d.seq].refilled_fin     ))
         , REFILLED_ORD_ID =                        data->qual[d.seq].refilled_ord_id
         , REFILLED_ORD    = trim(substring(1, 140, data->qual[d.seq].refilled_ord_name))
         , REFILLED_DATE   = trim(substring(1, 140, data->qual[d.seq].refilled_dt_txt  ))
         , REFILL_ENC      =                        data->qual[d.seq].refill_enc
         , REFILL_FIN      = trim(substring(1,  30, data->qual[d.seq].refill_fin       ))
         , REFILL_ORD_ID   =                        data->qual[d.seq].refill_ord_id
         , REFILL_ORD      = trim(substring(1, 140, data->qual[d.seq].refill_ord_name  ))
         , REFILL_DATE     = trim(substring(1, 140, data->qual[d.seq].refill_ord_dt_txt))

      from (dummyt d with SEQ = data->cnt)
    ;with format, separator = " ", time = 300
    with heading, pcformat('"', ',', 1), format=stream, format,  nocounter , compress

else
   select into value(file_path)
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


;Presentation time

if (sum_data->cnt > 0)
    
;    select into $outdev
    select into value(sum_file_path)
           PROV_ID             =                        sum_data->qual[d.seq].prov_id
         , PROV_NAME           = trim(substring(1,  50, sum_data->qual[d.seq].prov_name        ))
         
         , HIGHEST_MON_CNT     =                        sum_data->qual[d.seq].highest            
         , LOWEST_MON_CNT      =                        sum_data->qual[d.seq].lowest
         , LOWEST_MON_NON_ZERO =                        sum_data->qual[d.seq].lowest_non_zero         
         , MON_W_DATA          =                        sum_data->qual[d.seq].data_months
         
         , REFILL_TOTAL        =                        sum_data->qual[d.seq].total
         
         , AVG                 =                        sum_data->qual[d.seq].average    
         , AVG_NON_ZERO        =                        sum_data->qual[d.seq].average_non_zero      
         
         , JUL_23              =                        sum_data->qual[d.seq].months[ 7].cnt    
         , AUG_23              =                        sum_data->qual[d.seq].months[ 8].cnt
         , SEP_23              =                        sum_data->qual[d.seq].months[ 9].cnt    
         , OCT_23              =                        sum_data->qual[d.seq].months[10].cnt    
         , NOV_23              =                        sum_data->qual[d.seq].months[11].cnt    
         , DEC_23              =                        sum_data->qual[d.seq].months[12].cnt    
         , JAN_24              =                        sum_data->qual[d.seq].months[ 1].cnt
         , FEB_24              =                        sum_data->qual[d.seq].months[ 2].cnt    
         ;, MAR_              =                        sum_data->qual[d.seq].months[ 3].cnt
         ;, APR_              =                        sum_data->qual[d.seq].months[ 4].cnt    
         ;, MAY_              =                        sum_data->qual[d.seq].months[ 5].cnt    
         ;, JUN_              =                        sum_data->qual[d.seq].months[ 6].cnt
         

      from (dummyt d with SEQ = sum_data->cnt)
    ;with format, separator = " ", time = 300
    with heading, pcformat('"', ',', 1), format=stream, format,  nocounter , compress
else
   select into value(sum_file_path)
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
call echorecord(sum_data)

call ctd_end_timer(prog_timer)
call ctd_print_timers(null)

end
go
 
 

