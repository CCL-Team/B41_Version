/* xxx custHighRiskComp
    This component is designed to display specific high risk problems the patient has.  Using a McAlduff backend script.
*/

//Component init function.
$(document).ready(function(){
    custHighRiskComp();
});

// Function to bootstrap the component
function custHighRiskComp(){
    try {
        // Initialize the request object
        var cclData, json;
        
        cclData = new XMLCclRequest();
        
        // Get the response
        cclData.onreadystatechange = function(){
            if(cclData.readyState == 4 && cclData.status == 200){
                json = $.parseJSON(cclData.responseText);
                if(json && json.REC){
                    //alert(JSON.stringify(json));
                    console.log(json);
                    
                    $(".mhrc_parent").empty();  //emptying out the component before redrawing
                    chrcCreateBaseComp(json);
                    
                }
            }
        }
        
        //  Call the ccl program and send the parameter string
        cclData.open('GET', "jdm13_mp_high_risk_dx_jx");
        cclData.send("^MINE^, value($PAT_Personid$), 0");
        
    }
    catch(e){
        alert("function custHighRiskComp():\n"+e.description+"\n"+e.Reason+"\n");
        return;
    }
    
    
}


/* chrcCreateBaseComp
   Rather than doing a bunch of HTML work in a bunch of places, we'll just do it here.
*/
function chrcCreateBaseComp(json){
    var warnDiv, tableDiv;
    
    warnDiv          = document.createElement('div'  );
    tableDiv         = document.createElement('div'  );
    
    table            = document.createElement('table');
    
    tableHead        = document.createElement('thead');
    tableHeadRow     = document.createElement('tr');
    tableHeadDisp    = document.createElement('th'   );
    tableHeadSnomed  = document.createElement('th'   );
    tableHeadPersist = document.createElement('th'   );
    
    tableBody        = document.createElement('tbody');
    
    
    $(warnDiv).text('NOTE: This list is not all-inclusive.  Please refer to the Problem List component to review the full list of documented problems.')
              .addClass('mhrc_warning')
              ;
              
    $(tableHeadDisp   ).addClass('mhrc_thead_cell').text('Problem Name');
    $(tableHeadSnomed ).addClass('mhrc_thead_cell').text('Code'        );
    $(tableHeadPersist).addClass('mhrc_thead_cell').text('Persistence' );
    
    $(tableHeadRow    ).addClass('mhrc_thead_row')
                       .append(tableHeadDisp   )
                       .append(tableHeadSnomed )
                       .append(tableHeadPersist)
                       ;
    
    
    $(tableHead).addClass('mhrc_thead')
                .append(tableHeadRow)
                ;
                
    // Row creation
    var i;
    for(i = 0; i < json.REC.RCNT; i++){
        var trow, dispCell, snoCell, perCell
          , tempDisp, tempSno, tempPer;
        
        row      = document.createElement('tr');
        
        dispCell = document.createElement('td');
        snoCell  = document.createElement('td');
        perCell  = document.createElement('td');
        
        
        if(json.REC.RLIST[i].ANNOTATED_DISPLAY === '') tempDisp = '--'
        else                                           tempDisp = json.REC.RLIST[i].ANNOTATED_DISPLAY
        
        if(json.REC.RLIST[i].SNOMED_CD         === '') tempSno  = '--'
        else                                           tempSno  = json.REC.RLIST[i].SNOMED_CD
        
        if(json.REC.RLIST[i].PERSISTENCE       === '') tempPer  = '--'
        else                                           tempPer  = json.REC.RLIST[i].PERSISTENCE
        
        
        $(dispCell).addClass('mhrc_body_cell').text(tempDisp);
        $(snoCell ).addClass('mhrc_body_cell').text(tempSno );
        $(perCell ).addClass('mhrc_body_cell').text(tempPer );
        
        $(row).addClass('mhrc_body_row')
              .append(dispCell)
              .append(snoCell )
              .append(perCell )
              ;
        
        $(tableBody).addClass('mhrc_tbody')
                    .append(row);
    }
    
    if(json.REC.RCNT === 0){
        var trow, dispCell;
        
        row      = document.createElement('tr');
        dispCell = document.createElement('td');
        
        $(dispCell).addClass('mhrc_body_cell').attr('colspan', 3).text('No high risk problems found.');
        
        $(row).addClass('mhrc_body_row')
              .append(dispCell)
              ;
        
        $(tableBody).addClass('mhrc_tbody')
                    .append(row);
        
    }
    
    $(table).addClass('mhrc_table')
            .append(tableHead)
            .append(tableBody)
            ;
    
    $(tableDiv).addClass('mhrc_table_div')
               .append(table);
    
    $(".mhrc_parent").append(warnDiv )
                     .append(tableDiv)
                     ;
}
