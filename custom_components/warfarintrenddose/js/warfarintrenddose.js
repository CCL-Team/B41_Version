$(document).ready(function(){
    wtdGetWarfarinTrendDose();
});

/* getWarfarinTrendDose
   Calls the smart template wrapper to get the RS as JSON, and calls the draw function.
*/
function wtdGetWarfarinTrendDose(){
    try {
        // Initialize the request object
        var cclData, json, jsonRet;
        
        cclData = new XMLCclRequest();
        
        // Get the response
        cclData.onreadystatechange = function(){
            if(cclData.readyState == 4 && cclData.status == 200){
                json = $.parseJSON(cclData.responseText);
                if(json && json.DOSING){
                    jsonRet = json.DOSING;
                    
                    wtdDrawComp(jsonRet);
                }
            }
        }
        
        //  Call the ccl program and send the parameter string
        cclData.open('GET', "mp_st_war_trend_dose");
        cclData.send("'MINE', $VIS_Encntrid$, $PAT_Personid$");
    }
    catch(e){
        alert("function getWarfarinTrendDose():\n"+e.description+"\n"+e.Reason+"\n");
        return;
    }
    
    return;
}

/* wtdDrawComp
   Given the filled JSON, draws the component.
   Inputs:
       json     (vc):  JSON record of the smart template for display.
   Example JSON:
       {
           "DOSING": {
               "CNT": 3,
               "QUAL": [{
                   "EVENT_ID": 13993445255,
                   "PAR_EVENT_ID": 13993445247,
                   "DATE": "/Date(2019-03-28T16:13:00.000+00:00)/",
                   "DATE_STR": "03/28/19 12:13:00",
                   "INR": "",
                   "TRANS_INR": "1.1",
                   "DOSE_TAB": "6 mg tab (Teal)",
                   "SUN_DOSE": "6",
                   "MON_DOSE": "6",
                   "TUE_DOSE": "5.5",
                   "WED_DOSE": "5.5",
                   "THU_DOSE": "5.5",
                   "FRI_DOSE": "5",
                   "SAT_DOSE": "5",
                   "WK_DOSE": 38.5,
                   "WK_DOSE_STR": "38.50",
                   "PER_CHNG": 82.795699,
                   "PER_CHNG_STR": "82.80"
               }, {
                   "EVENT_ID": 13993445223,
                   "PAR_EVENT_ID": 13993445215,
                   "DATE": "/Date(2019-03-28T16:12:00.000+00:00)/",
                   "DATE_STR": "03/28/19 12:12:00",
                   "INR": "",
                   "TRANS_INR": "1.2",
                   "DOSE_TAB": "7.5 mg tab (Yellow)",
                   "SUN_DOSE": "7.5",
                   "MON_DOSE": "7",
                   "TUE_DOSE": "7",
                   "WED_DOSE": "7",
                   "THU_DOSE": "6",
                   "FRI_DOSE": "6",
                   "SAT_DOSE": "6",
                   "WK_DOSE": 46.5,
                   "WK_DOSE_STR": "46.50",
                   "PER_CHNG": 79.487179,
                   "PER_CHNG_STR": "79.49"
               }, {
                   "EVENT_ID": 13993445191,
                   "PAR_EVENT_ID": 13993445183,
                   "DATE": "/Date(2019-03-28T16:11:00.000+00:00)/",
                   "DATE_STR": "03/28/19 12:11:00",
                   "INR": "",
                   "TRANS_INR": "1.0",
                   "DOSE_TAB": "10 mg tab (White)",
                   "SUN_DOSE": "10",
                   "MON_DOSE": "10",
                   "TUE_DOSE": "8.5",
                   "WED_DOSE": "7.5",
                   "THU_DOSE": "7.5",
                   "FRI_DOSE": "7.5",
                   "SAT_DOSE": "7.5",
                   "WK_DOSE": 58.5,
                   "WK_DOSE_STR": "58.50",
                   "PER_CHNG": 0,
                   "PER_CHNG_STR": ""
               }]
           }
       }
*/
function wtdDrawComp(json){
    var looper, table, tbody, dateRow;
    
    //This probably isn't necessary, but it is good in case the component exists multiple times in the page.
    $(".mwtd_parent").empty();  //emptying out the component before redrawing
    
    if(json.CNT > 0){
        table = document.createElement('table');
        tbody = document.createElement('tbody');
        
        dateRow     = document.createElement('tr');
        //Under the new change, we don't want to pull the resulted values.
        //INRRow      = document.createElement('tr');
        transINRRow = document.createElement('tr');
        doseTabRow  = document.createElement('tr');
        sunRow      = document.createElement('tr');
        monRow      = document.createElement('tr');
        tueRow      = document.createElement('tr');
        wedRow      = document.createElement('tr');
        thuRow      = document.createElement('tr');
        friRow      = document.createElement('tr');
        satRow      = document.createElement('tr');
        totRow      = document.createElement('tr');
        perRow      = document.createElement('tr');
        
        
        //Header appends
        //TODO Headers might be good to send up in the RS just to keep them in one spot.
        $(dateRow)    .append(wtdCreateCell('Date'               , 0));
        $(transINRRow).append(wtdCreateCell('Transcribed INR'    , 0));
        $(doseTabRow) .append($(wtdCreateCell('Dose Tab MG'      , 0)).addClass('wtd_bold'));
        $(sunRow)     .append(wtdCreateCell('Sunday Dose'        , 0));
        $(monRow)     .append(wtdCreateCell('Monday Dose'        , 0));
        $(tueRow)     .append(wtdCreateCell('Tuesday Dose'       , 0));
        $(wedRow)     .append(wtdCreateCell('Wednesday Dose'     , 0));
        $(thuRow)     .append(wtdCreateCell('Thursday Dose'      , 0));
        $(friRow)     .append(wtdCreateCell('Friday Dose'        , 0));
        $(satRow)     .append(wtdCreateCell('Saturday Dose'      , 0));
        $(totRow)     .append($(wtdCreateCell('Total Weekly Dose', 0)).addClass('wtd_bold'));
        $(perRow)     .append(wtdCreateCell('Dosage Change %'    , 0));
        
        
        for(looper = 0; looper < json.CNT; looper++){
            $(dateRow)    .append(wtdCreateCell(json.QUAL[looper].DATE_STR     , 1));
            $(transINRRow).append(wtdCreateCell(json.QUAL[looper].TRANS_INR    , 1));
            $(doseTabRow) .append($(wtdCreateCell(json.QUAL[looper].DOSE_STR   , 1)).addClass('wtd_bold'));
            $(sunRow)     .append(wtdCreateCell(json.QUAL[looper].SUN_DOSE_STR , 1));
            $(monRow)     .append(wtdCreateCell(json.QUAL[looper].MON_DOSE_STR , 1));
            $(tueRow)     .append(wtdCreateCell(json.QUAL[looper].TUE_DOSE_STR , 1));
            $(wedRow)     .append(wtdCreateCell(json.QUAL[looper].WED_DOSE_STR , 1));
            $(thuRow)     .append(wtdCreateCell(json.QUAL[looper].THU_DOSE_STR , 1));
            $(friRow)     .append(wtdCreateCell(json.QUAL[looper].FRI_DOSE_STR , 1));
            $(satRow)     .append(wtdCreateCell(json.QUAL[looper].SAT_DOSE_STR , 1));
            $(totRow)     .append($(wtdCreateCell(json.QUAL[looper].WK_DOSE_STR, 1)).addClass('wtd_bold'));
            $(perRow)     .append(wtdCreateCell(json.QUAL[looper].PER_CHNG_STR , 1));
        }
        
        
        $(tbody).append(dateRow    );
        //Under the new change, we don't want to pull the resulted values.
        //$(tbody).append(INRRow     );
        $(tbody).append(transINRRow);
        $(tbody).append(doseTabRow );
        $(tbody).append(sunRow     );
        $(tbody).append(monRow     );
        $(tbody).append(tueRow     );
        $(tbody).append(wedRow     );
        $(tbody).append(thuRow     );
        $(tbody).append(friRow     );
        $(tbody).append(satRow     );
        $(tbody).append(totRow     );
        $(tbody).append(perRow     );
        
        $(table).addClass('wtd_table');
        $(table).append(tbody);
        
        $(".mwtd_parent").append(table);
    }
}


/* wtdDrawComp
   Given text, returned as table cell
   Inputs:
       txt         (vc):  Text to be inside of cell
       dataCellind (i2):  If the width style should be applied
   Return:
       obj          : TD object to append
*/
function wtdCreateCell(txt, dataCellind){
    var td, text;
    
    td      = document.createElement('td');
    txtNode = document.createTextNode(txt);
    
    $(td).addClass('wtd_cell').append(txtNode);
    
    if(dataCellind) $(td).addClass('wtd_data_cell');
    else            $(td).addClass('wtd_head_cell');
    return(td);
}