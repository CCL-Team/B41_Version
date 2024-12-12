drop program promptcare_clear_covid_msg:dba go
create program promptcare_clear_covid_msg:dba

/* new query based on NO Task ID

MCGA: 224944

Jessica Johnson -
From: Joy, Amanda <Amanda.Joy@medstar.net>
Sent: Friday, November 20, 2020 9:51 PM
To: Napier, Sara <Sara.Napier@Medstar.net>; Johnson, Jessica A <Jessica.A.Johnson@medstar.net>
Cc: Delasobera, Bronson E <Bronson.E.Delasobera@MEDSTAR.NET>
Subject: COVID results
Sara and Jessica,
We are getting a large amount of tent patients to our clinical all pool because they are ordering the test
under the EVisit provider (that also works for us). Is it possible to turn off COVID only results to out pools
because we are managing them all from the Phoenix grid Mpage anyway?

Request:
We would want to move all COVID-19 results from the Prompt Care Clinical ALL pool completely as they will be
signed using the centralized call back process.  What information would be helpful to develop the solution? I
can offer order names, result DTA and provider names.

UC is spending at least 2 hours every day working through these results and is asking this request be prioritized
given the current demands on the clinicians due to paitent volumes.

select * from clinical_event where event_id =
18767932536.00
go

CE_PRCS_QUEUE_ID    CE_EVENT_ACTION_ID  EVENT_ID        QUEUE_TYPE_CD    CREATE_DT_TM   PRCS_DT_TM   QUEUE_STATUS_CD    UPDT_APPLCTX
  47918748015.00        47918748014.00  18796842728.00      4146570.00      12/08/20    12/08/20        4146572.00              0.00

ACTION_PRSNL_GROUP_ID ASSIGN_PRSNL_ID EN
          43546567.00            0.00

endorse_status_cd =  252930922.00 ;pending -> audit out not filter

move from OPS job to clinical_event -> real time.
OPS job runs every 60 minutes starting at 6:15a to 6:15p.

MCGA entered: 229361
Add logic to remove the provider, by removing the pool, the provider action is not required.
so remove both pool and provider and set action to saved.
There is a process in place to call back UC Urgent Care Covid results.

10/27 - user logged issue about results for covid not showing up.  Adding filter for AndrewDugas to track for a few weeks.
Clinical All Pool. prsnl_id = 31681705.

;6/2/22 - unique constraint violation: XAK1CE_EVENT_ACTION: event_id, action_prsnl_id, action_type_cd

July 17, 2023: MCGA 235229
Engineer: Swetha Srinivasaraghavan
Updates completed:
    Added STI and Urine pregnancy event codes to the list.
    Added Urgent Care Clinical Lab pool to the list.
    Modified the frequency of OPS Job, COVID Promptcare Clear Msg, from every hour to every 5 mins.

July 12, 2024: INC0745653
Engineer: Michael Mayes
Updates completed:
    Vamsi was trying a hot fix on the 9th... where the temp RS below needed to have a duplicate entry removed...
    However he wasn't aware of the Suffixing on the file name that you folks are up with this file... and made his changes on
    the naked promptcare_clear_covid_msg source.

    I think 006_1 is the most recent... and I've repulled it... and added Vamsi's change below.

    Hopefully saving us from both the problem he was investigating... and reincluding all the changes made since last year.

DEC 06, 2024: MCGA 350165
Engineer: Michael Mayes
Updates completed:
    There is work at the botton of this script to move messages around rather than delete.

    I believe in the past we were constraint violating on our attempt to move to the group 0.  So there is work down there to try
    and move the action_prsnl_id around... it has two options to use.

    But based on how the query is currently written... if both places are filled... it will pick one,
    try, and constraint violate.  Sending an error to ops, but processing further messages, and leaving the bad one in place.

    I'm going to catch that both filled case and do nothing for now.
 */
record temp (
    1 cnt = i4
    1 q [*]
        ;2 ce_event_action_id = f8
        2 person_id = f8
        2 encntr_id = f8
        2 event_id = f8
        2 action_prsnl_id = f8
        2 event_tag = vc
        2 event_cd = vc
        2 ce_event_action_id = f8
        2 order_id = f8
        2 name_full_formatted = vc
        2 action_prsnl_group_id = f8;10/27

        2 error_chk = i2 ;6/10/22
)

;FREE SET REPLY ;004

record  reply  (
1  status_data
    2  status  =  c1
    2  subeventstatus [1 ]
        3  operationname  =  c25
        3  operationstatus  =  c1
        3  targetobjectname  =  c25
        3  targetobjectvalue  =  vc
)

/************************************************************************
* Declare and Initialize variables and record structures
************************************************************************/
SET  REPLY -> STATUS_DATA -> STATUS  = "F"

;main query
select into "nl:"
        ce.person_id
        , ce.encntr_id
        , ce.event_id
        , ca.action_prsnl_id
        , tag=substring(1, 17, ca.event_tag)
        , event=uar_get_code_display(ce.event_cd)
        , ca.ce_event_action_id
        , ce.order_id
        , p.name_full_formatted

from ce_event_action ca
    , ce_prcs_queue cp
    , clinical_event ce
    , person p

plan ca where ca.action_prsnl_group_id in (41971939.00  ;Urgent Care Alexandria Clinical
                        , 41972055.00   ;Urgent Care Wheaton Clinical
                        , 41971936.00   ;Urgent Care Alexandria Admin
                        , 41971945.00   ;Urgent Care Belair Clinical
                        , 41971979.00   ;Urgent Care Capitol Hill Clinical
                        , 41971982.00   ;Urgent Care Chevy Chase Admin
                        , 41971988.00   ;Urgent Care Federal Hill Admin
                        , 41972008.00   ;Urgent Care Gaithersburg Clinical
                        , 41972049.00   ;Urgent Care Waldorf Clinical
                        , 41972011.00   ;Urgent Care Hyattsville Admin
                        , 41971970.00   ;Urgent Care Belcamp Admin
                        , 41972017.00   ;Urgent Care Perry Hall Admin
                        , 41972040.00   ;Urgent Care Towson Admin
                        , 41972043.00   ;Urgent Care Towson Clinical
                        , 41971930.00   ;Urgent Care Adams Morgan Admin
                        , 41971973.00   ;Urgent Care Belcamp Clinical
                        , 41971976.00   ;Urgent Care Capitol Hill Admin
                        , 41972014.00   ;Urgent Care Hyattsville Clinical
                        , 41972020.00   ;Urgent Care Perry Hall Clinical
                        , 41972046.00   ;Urgent Care Waldorf Admin
                        , 41971933.00   ;Urgent Care Adams Morgan Clinical
                        , 41971985.00   ;Urgent Care Chevy Chase Clinical
                        , 41972005.00   ;Urgent Care Gaithersburg Admin
                        , 41972052.00   ;Urgent Care Wheaton Admin
                        , 43546567.00   ;Urgent Care Clinical All -> parent pool
                        , 41971942.00   ;Urgent Care Belair Admin
                        , 41971991.00   ;Urgent Care Federal Hill Clinical
                        , 65020311.00   ;Urgent Care Charlotte Hall Clinical
                        , 65020308.00   ;Urgent Care Charlotte Hall Admin
                        , 238047623.00  ;Urgent Care La Plata Admin
                        , 238047624.00  ;Urgent Care Olney Admin
                        , 238047621.00  ;Urgent Care Gaithersburg Muddy Branch Admin
                        , 238048704.00  ;Urgent Care Potomac Clinical
                        , 238048707.00  ;Urgent Care Silver Spring Clinical
                        , 238176437.00  ;Urgent Care Waldorf Shoppers World Admin
                        , 238176439.00  ;Urgent Care Waugh Chapel Admin
                        , 238176440.00  ;Urgent Care Waugh Chapel Clinical
                        , 238045470.00  ;Urgent Care Arundel Mills Admin
                        , 238089759.00  ;Urgent Care Towson Hillside Admin
                        , 255779780.00  ;Urgent Care Referral Navigator
                        , 238089763.00  ;Urgent Care Towson Hillside Clinical
                        , 255779782.00  ;Urgent Care E-Visit Referral Navigator
                        , 238174270.00  ;Urgent Care Catonsville Admin
                        , 238174272.00  ;Urgent Care Frederick Admin
                        , 238174275.00  ;Urgent Care Frederick Clinical
                        , 238089770.00  ;Urgent Care Waldorf Shoppers World Clinical
                        , 238083317.00  ;Urgent Care Annapolis Admin
                        , 238083330.00  ;Urgent Care Bethesda Admin
                        , 238083336.00  ;Urgent Care California Admin
                        , 238083321.00  ;Urgent Care Annapolis Clinical
                        , 238083327.00  ;Urgent Care Arundel Mills Clinical
                        , 238083339.00  ;Urgent Care California Clinical
                        , 238084307.00  ;Urgent Care Catonsville Clinical
                        , 238084310.00  ;Urgent Care Columbia Admin
                        , 238089717.00  ;Urgent Care Olney Clinical
                        , 238089729.00  ;Urgent Care Pikesville Admin
                        , 238089732.00  ;Urgent Care Pikesville Clinical
                        , 238083332.00  ;Urgent Care Bethesda Clinical
                        , 238084314.00  ;Urgent Care Columbia Clinical
                        , 238089696.00  ;Urgent Care Gaithersburg Muddy Branch Clinical
                        , 238089699.00  ;Urgent Care Germantown Admin
                        , 238089702.00  ;Urgent Care Germantown Clinical
                        , 238089723.00  ;Urgent Care Pasadena Clinical
                        , 238089709.00  ;Urgent Care La Plata Clinical
                        , 238089720.00  ;Urgent Care Pasadena Admin
                        , 238089735.00  ;Urgent Care Potomac Admin
                        , 238089739.00  ;Urgent Care Rockville Admin
                        , 238089742.00  ;Urgent Care Rockville Clinical
                        , 238089745.00  ;Urgent Care Silver Spring Admin
                        , 344023518.00  ;Urgent Care Clinical Lab
                    )
join cp where ca.ce_event_action_id = cp.ce_event_action_id
            and cp.queue_type_cd = 4146570.00 ;endorse
join ce where cp.event_id = ce.event_id
            and ce.event_cd in (2238539103 ;Respiratory Virus Pnl PCR
                            , 2258265897    ;CoVID19-SARS-CoV-2 by PCR
                            , 2254653289    ;COVID 19 (DH/CDC)
                            , 2259614555    ;COVID-19/Coronavirus RNA PCR
                            , 2258239523    ;COVID-19 (SARS-CoV-2, NAA)
                            , 2265151661    ;CoVID_19 (SARS-CoV2, NAA)
                            , 2258239523    ;COVID-19 (SARS-CoV-2, NAA)
                            , 2270692929    ;CoVID 19-SARS-CoV-2 Overall Result
                            , 2258265897    ;CoVID 19-SARS-CoV-2 by PCR
                            , 2270688963    ;CoVID 19-PAN-SARS-CoV-2 by PCR
                            , 2259601949    ;COVID19(SARS-CoV-2)
                            , 2276648185.00 ; NEW POC ORDER
                            , 2270013289.00 ;covid testing tent note
                            , 2385455807.00 ;COVID-19 SARS CoV-2 Ag
                            , 2435117743.00 ;COVID-19(SARS-CoV-2) Ag
                            , 2689513413.00 ;SARS-CoV-2, NAA2 Day TAT
                            , 3715370811.00;72 POC Chlamydia PCR by Visby Med
                            , 3715377891.00;72 POC Gonorrhoeae PCR by Visby Med
                            , 3715379935.00;72 POC Trichomonas PCR by Visby Med
                            , 21891715.00 ;Pregnancy, Urine
                        )
            and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
join p where ce.person_id = p.person_id
order by ca.ce_event_action_id
detail
    temp->cnt = temp->cnt+1
    stat = alterlist(temp->q, temp->cnt)
    temp->q[temp->cnt].ce_event_action_id = ca.ce_event_action_id
    temp->q[temp->cnt].person_id = ce.person_id
    temp->q[temp->cnt].encntr_id = ce.encntr_id
    temp->q[temp->cnt].event_id = ce.event_id
    temp->q[temp->cnt].action_prsnl_id = ca.action_prsnl_id
    temp->q[temp->cnt].event_tag = substring(1,35, ca.event_tag)
    temp->q[temp->cnt].event_cd = uar_get_code_display(ce.event_cd)
    temp->q[temp->cnt].order_id = ce.order_id
    temp->q[temp->cnt].name_full_formatted = p.name_full_formatted
    temp->q[temp->cnt].action_prsnl_group_id = ca.action_prsnl_group_id ;10/27
with nocounter

call echorecord (temp)

if (curqual = 0)
    go to end_script
endif

for ( x = 1 to temp->cnt)

    if(temp->q[x].ce_event_action_id > 0)
        if (temp->q[x].action_prsnl_id = 31681705 and temp->q[x].action_prsnl_group_id = 43546567.00)
            ;Urgent Care Clinical All )) ;0/27
            update into ce_event_action c
            set c.updt_task = 248889
                , c.action_prsnl_group_id = 0
            where c.ce_event_action_id = temp->q[x].ce_event_action_id;252930929.00     4002700 SAVED        Saved
            commit
        else

            select into "nl:"
            from ce_event_action c
            where c.event_Id = temp->q[x].event_id
            and c.ce_event_action_id != temp->q[x].ce_event_action_id;
                and c.action_prsnl_id in (0,1415232.00)
            order by c.ce_event_action_id
            detail
            ;Mayes Dec 06, changing the below.
            ;if (c.action_prsnl_id in (0))
            ;    temp->q[x].error_chk = 1
            ;elseif (c.action_prsnl_id in (1415232.00))
            ;    temp->q[x].error_chk = 2
            ;endif
            if (c.action_prsnl_id in (0))
                temp->q[x].error_chk = temp->q[x].error_chk + 1
            elseif (c.action_prsnl_id in (1415232.00))
                temp->q[x].error_chk = temp->q[x].error_chk + 2
            endif
            with nocounter

            ;unique constraint violation: XAK1CE_EVENT_ACTION: event_id, action_prsnl_id, action_type_cd

            if(temp->q[x].error_chk = 0)
                update into ce_event_action c
                set c.action_prsnl_group_id = 0
                    , c.updt_task = 248888
                    , c.endorse_status_cd = 252930929.00 ;003->saved
                    , c.action_prsnl_id = 0 ;003
                where c.ce_event_action_id = temp->q[x].ce_event_action_id
                commit

            elseif(temp->q[x].error_chk = 1)
                update into ce_event_action c
                set c.action_prsnl_group_id=0, c.updt_task=248888
                    , c.endorse_status_cd = 252930929.00 ;003->saved
                    , c.action_prsnl_id = 1415232.00 ;005 - unassigned ?
                ;why create two events for the same order action(103)?
                where c.ce_event_action_id = temp->q[x].ce_event_action_id
                commit
            elseif(temp->q[x].error_chk = 2)
                update into ce_event_action c
                set c.action_prsnl_group_id=0, c.updt_task=248888
                    , c.endorse_status_cd = 252930929.00 ;003->saved
                    , c.action_prsnl_id = 0 ;005 - unassigned ?
                ;why create two events for the same order action(103)?
                where c.ce_event_action_id = temp->q[x].ce_event_action_id
                commit
            ;Mayes Dec 06, adding this to catch my case.
            elseif(temp->q[x].error_chk > 3)
                ;But we don't want to do the commit... or the action... so... just debug echoing for now.
                
                call echo(notrim(build2('Preventing constraint violation on ', temp->q[x].ce_event_action_id)))
            endif

        endif
    endif
endfor
#end_script

set last_mod = "scs937/ks2488 07/17/2023"
set reply->status_data->status = "s"

call echorecord (reply)

end
go

