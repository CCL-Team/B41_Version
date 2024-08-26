/* MDPCP Program Enrollment component
    This component is designed to 
*/

var cmmpeEllipse = 0;
var cmmpeInterval = 0;

//Component bootstrap.
$(document).ready(function(){
    
    //Looks like we double get doc ready... trying to protect us
    if(cmmpeInterval === 0){
        $(".cmmpe_parent").append( '<h5>' + 'Loading HealtheIntent Data' 
                                          + '<span class="cmmpeEllipse"><span>' 
                                 + '</h5>'
                                 );
                             
        cmmpeInterval = setInterval(cmmpeEllipseWait, 700);
    }
    
    cmmpeInit();
});


function cmmpeEllipseWait(){
    if(cmmpeEllipse < 3){
        $('.cmmpeEllipse').append('.');
        cmmpeEllipse++;
    }else{
        $('.cmmpeEllipse').empty();
        cmmpeEllipse = 0;
    }
    
}

// Function to return Advanced Directives and/or Advanced Planning Documents for this patient
function cmmpeInit(){
    try {
        // Initialize the request object
        var cclData, json, encType, refId;
        
        cclData = new XMLCclRequest();
        
        // Get the response
        cclData.onreadystatechange = function(){
            if(cclData.readyState == 4 && cclData.status == 200){
                clearInterval(cmmpeInterval);
                
                json = $.parseJSON(cclData.responseText);
                
                if(json && json.REC){
                    //alert(JSON.stringify(json));
                    
                    $(".cmmpe_parent").empty();  //emptying out the component before redrawing
                    cmmpeCreateBaseComp(json);
                }
            }
        }
        
        //  Call the ccl program and send the parameter string
        cclData.open('GET', "cust_mp_mdpcp_prog_enroll_data");
        cclData.send("^MINE^, value($PAT_Personid$), value($VIS_Encntrid$), 0");
        
    }
    catch(e){
        alert("function cmmpeInit():\n"+e.description+"\n"+e.Reason+"\n");
        return;
    }
    
    return;
}


/* cmmpeCreateBaseComp
   Rather than doing a bunch of HTML work in a bunch of places, we'll just do it here.
   
   Input:
        json - JSON object containing JSON return from backend driver.
*/
function cmmpeCreateBaseComp(json){
    var empanelDiv, careManDiv, diabBootDiv, empanelObj, careManObj, diabObj, diabInfoObj;
    
    empanelObj  = json.REC;
    careManObj  = json.REC.CARE_MGMT;
    diabObj     = json.REC.DIAB;
    diabInfoObj = json.REC.DIAB_INFO;
    
    perId = json.REC.PER_ID; 
    encId = json.REC.ENC_ID;
    
    empanelDiv  = cmmpeEmpanelDiv(empanelObj);
    careManDiv  = cmmpeRefCarManDiv(careManObj, perId, encId);
    diabBootDiv = cmmpeRefDiabBootDiv(diabObj, diabInfoObj, perId, encId);
    
    $(".cmmpe_parent").empty();
    $(".cmmpe_parent").append(empanelDiv);
    $(".cmmpe_parent").append(careManDiv);
    $(".cmmpe_parent").append(diabBootDiv);
}


/* cmmpeEmpanelDiv
   Create the header and div for the Empanelment Information
   
   Input:
        json - JSON subobject from json return from backend driver, the list of all the empanelment information.
*/
function cmmpeEmpanelDiv(json){
    var retDiv, divList = [], empDiv, empLine, attribDiv, attribLine, provLine, manageLine, attribTxt;
    
    //alert(JSON.stringify(json));
     
    retDiv = document.createElement('div');
    
    
    if(json.EMPANEL_STATUS === 'S'){
        if(json.EMPANEL_CNT === 0 && json.MDPCP_IND === 0 && json.ATTRIB_PROV_CNT === 0){
            empDiv = document.createElement('div');
            
            empLine = document.createElement('div');
            
            $(empLine).text("Patient is not currently enrolled in a managed care group.");
            
            $(empLine).addClass('cmmpeError');
            $(empDiv).append(empLine);
            divList.push(empDiv);
        }else{
            
            for(var i = 0; i < json.EMPANEL_CNT; i++){
                empDiv = document.createElement('div');
                
                $(empDiv).addClass('cmmpeEmpanelDiv');
                
                empLine = document.createElement('div');
                if     (json.EMPANEL[i].VALUE.length > 0) $(empLine).text('Empanelment Membership: ' + json.EMPANEL[i].VALUE  );
                else if(json.EMPANEL[i].NAME.length  > 0) $(empLine).text('Empanelment Membership: ' + json.EMPANEL[i].NAME  );
                
                $(empDiv).append(empLine);
                
                empLine = document.createElement('div');
                $(empLine).text('Date of Empanelment: '    + json.EMPANEL[i].BEG_DT);
                $(empDiv).append(empLine);
                
                divList.push(empDiv);
            }
        }
    }else{
        empDiv = document.createElement('div');
        
        $(empDiv).addClass('cmmpeEmpanelDiv');
            
        empLine = document.createElement('div');
        $(empLine).text( 'Empanelment API Error: ' 
                       + ' (' + json.EMPANEL_STATUS + ') ' 
                       + json.EMPANEL_STATUS_MSG
                       );
        
        $(empLine).addClass('cmmpeError');
        
        $(empDiv).append(empLine);
            
        divList.push(empDiv);
    }
    
    if(json.MDPCP_IND === 1){
        empDiv = document.createElement('div');
        
        $(empDiv).addClass('cmmpeEmpanelDiv');
        
        if(json.MDPCP.MDPCP_PROVIDER.length > 0){
            provLine = document.createElement('p');
            
            $(provLine).text('MDPCP Provider: ' + json.MDPCP.MDPCP_PROVIDER);
        
            $(empDiv).append(provLine);
        }
        
        if(json.MDPCP.CARE_MANAGER.length > 0){
            manageLine = document.createElement('p');
            
            $(manageLine).text(json.MDPCP.CARE_MAN_TITLE + ': ' + json.MDPCP.CARE_MANAGER);
        
            $(empDiv).append(manageLine);
        }
        
        divList.push(empDiv);
    }
    
    if(json.ATTRIB_STATUS === '1'){
        if(json.ATTRIB_PROV_CNT > 0){
            attribDiv = document.createElement('div');
            
            $(attribDiv).addClass('cmmpeEmpanelDiv');
            
            for(var i = 0; i < json.ATTRIB_PROV_CNT; i++){
                attribLine = document.createElement('div');
                
                attribTxt = 'Attributed Provider: ' + json.ATTRIB_PROV[i].NAME;
                
                if(json.ATTRIB_PROV[i].POSITION.length > 0) attribTxt += ' (' + json.ATTRIB_PROV[i].POSITION + ')';
                
                $(attribLine).text(attribTxt);
                
                $(attribDiv).append(attribLine);
                
            }
            
            divList.push(attribDiv);
        }
    }else{
        empDiv = document.createElement('div');
        
        $(empDiv).addClass('cmmpeEmpanelDiv');
            
        empLine = document.createElement('div');
        $(empLine).text( 'Attributed Provider API Error: ' 
                       + ' (' + json.ATTRIB_STATUS + ') ' 
                       + json.ATTRIB_STATUS_MSG
                       );
        
        $(empLine).addClass('cmmpeError');
        
        $(empDiv).append(empLine);
            
        divList.push(empDiv);
        
    }
    
    $(retDiv).addClass('cmmpeContentDiv');
    
    divList.forEach(function (element){
        $(retDiv).append(element);
    });
    
    return retDiv;
}


/* cmmpeRefCarManDiv
   Create the header and div for the Care Man Div
   
   Input:
        json - JSON subobject from json return from backend driver, the list of care management orders
        pId  - Person Id
        eId  - Encounter Id
*/
function cmmpeRefCarManDiv(json, pId, eId){
    var retDiv, header, select, option, defText;
    
    defText = 'Orders';
    
    //alert(JSON.stringify(json));
    
    retDiv = document.createElement('div');
    $(retDiv).addClass('cmmpeContentDiv');
    
    if(json.length > 0){
    
        header = document.createElement('h4');
        select = document.createElement('select');
        option = document.createElement('option');

        
        $(header).text('REFERRAL TO Care Management');
        
        
        $(option)
            .attr('value', defText)
            .text(defText);
            
        $(select)
            .addClass('cmmpeSelect')
            .append(option);
        
        for(var i = 0; i < json.length; i++){
            option = document.createElement('option');

            $(option)
                .attr('value', json[i].SYNONYM_ID)
                .text(json[i].SYNONYM_DISP);
                
            $(select).append(option);
        }
        
        $(select).on('change', function(){
            var val, text;
            
            val  = $(this).find(':selected').val();
            text = $(this).find(':selected').text();
            
            if(text !== defText) cmmpeOrder(val, pId, eId);
            
        });
        
        $(retDiv)
            .append(header)
            .append(select);
    }
    
    return retDiv;
}

/* cmmpeRefDiabBootDiv
   Create the header and div for the Diab Div
   
   Input:
        json - JSON subobject from json return from backend driver, the list of Diabetes Bootcamp orders
        pId  - Person Id
        eId  - Encounter Id
*/
function cmmpeRefDiabBootDiv(json, diabInfoJSON, pId, eId){
    var retDiv, header, select, option, defText, para, paraDivList = [];
    
    defText = 'Orders';
    
    retDiv = document.createElement('div');
    $(retDiv).addClass('cmmpeContentDiv');
    
    if(diabInfoJSON.A1C_QUAL_IND === 1){
        header = document.createElement('h4');
        select = document.createElement('select');
        option = document.createElement('option');
        para   = document.createElement('p');

        $(header).text('REFERRAL TO Diabetes Boot Camp');
        
        $(option)
            .attr('value', defText)
            .text(defText);
        
        $(select)
            .addClass('cmmpeSelect')
            .append(option);
        
        for(var i = 0; i < json.length; i++){
            option = document.createElement('option');

            $(option)
                .attr('value', json[i].SYNONYM_ID)
                .text(json[i].SYNONYM_DISP);
                
            $(select).append(option);
        }
        
        $(select).on('change', function(){
            var val, text;
            
            val  = $(this).find(':selected').val();
            text = $(this).find(':selected').text();
            
            if(text !== defText) cmmpeOrder(val, pId, eId);
            
        });
        
        
        paraDivList.push('<div class="cmmpeDiabSubPara">Please consider placing Referral to MedStar Diabetes Pathway/Bootcamp if patient\'s A1C Level is ≥8 %</div>');
        //paraDivList.push('<div class="cmmpeDiabSubPara"></div>');
        paraDivList.push('<div class="cmmpeDiabSubPara">Last A1C: ' + diabInfoJSON.A1C_RES 
                                           + ' from ' 
                                           + diabInfoJSON.A1C_RES_DT_TXT + '</div>');
        
        $(para)
            .addClass('cmmpeDiabPara')
            .append(paraDivList.join(''));
            
        
        $(retDiv)
            .append(header)
            .append(select)
            .append(para)
            ;
    }
    
    return retDiv;
}

/* cmmpeCreateBaseComp
   Rather than doing a bunch of HTML work in a bunch of places, we'll just do it here.
*/
function cmmpeOrder(synonym, pId, eId){
    MPAGES_EVENT('ORDERS', "" + pId + '|' + eId + '|{ORDER|' + synonym + '|0|0|0|0}|0|{2|127}|32')
}



