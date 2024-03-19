
$(document).ready(function(){
    getTopGenInfo();
});

// Function to return Advanced Directives and/or Advanced Planning Documents for this patient
function getTopGenInfo(){
    try {
        // Initialize the request object
        var cclData, json, jsonRet;
        
        cclData = new XMLCclRequest();
        
        // Get the response
        cclData.onreadystatechange = function(){
            if(cclData.readyState == 4 && cclData.status == 200){
                json = $.parseJSON(cclData.responseText);
                
                if(json && json.OUT_RS){
                    jsonRet = json.OUT_RS;
                    
                    $(".mtgi_parent").empty();  //emptying out the component before redrawing
                    
                    if(jsonRet.ACTIVITY_ID > 0){
                        //Just using the first activity_id, they should all be the same, and we know we have at least 1.
                        tgiCreateFormLink(jsonRet.PER_ID, jsonRet.ENC_ID, jsonRet.ACTIVITY_ID, 
                                           jsonRet.FORM_NAME, 0, jsonRet.EVENT_END_DT_TM, 
                                           jsonRet.FORM_REF_ID, jsonRet.FORM_NAME);
                    }else{
                        tgiCreateFormLink(jsonRet.PER_ID, jsonRet.ENC_ID, 0, 
                                           'NO ' + jsonRet.FORM_NAME + ' Documented', 1, '',
                                           jsonRet.FORM_REF_ID, jsonRet.FORM_NAME);
                    }
                }
            }
        }
        
        //  Call the ccl program and send the parameter string
        cclData.open('GET', "mp_top_get_get_doc");
        cclData.send("^MINE^, value($PAT_Personid$), value($VIS_Encntrid$)");
    }
    catch(e){
        alert("function getTopGenInfo():\n"+e.description+"\n"+e.Reason+"\n");
        return;
    }
    
    return;
}


/* tgiCreateFormLink
   Creates a message to display in the component, with the link to an empty powerform.
   
   Inputs:
       perId     (f8):  Person ID
       encId     (f8):  Encounter ID
       actId     (f8):  Activity ID
       txt      (str):  Text to show in the message
       styleInd  (i2):  0 - Normal Form
                        1 - Empty Form
       dateTxt  (str):  Date that the form was entered.
       formRef   (f8):  The PowerForm ref id for launching (Just so the magic number stays in one place in CCL)
       formName (str):  The PowerForm name
*/
function tgiCreateFormLink(perId, encId, actId, txt, styleInd, dateTxt, formRef, formName){
    var msgP, icon, wrap, style, title, date;

    try{
        wrap = document.createElement('span');
        icon = document.createElement('span');
        msgP = document.createElement('span');
        
        style = styleInd === 1 ? 'tgi_error' 
                               : 'tgi_form';
        title = styleInd === 1 ? "Click to open *new* " + formName + " PowerForm" 
                               : "Click to open " + formName + " PowerForm";
        
        $(wrap)
            .attr('title', title)
            .addClass('tgi_link_cursor')
            .on('click', function(){
                             tgiopenPowerForm(encId, perId, actId, formRef, 0);
                             
                             //redraw after coming back
                             $(".mtgi_parent").empty();
                             getTopGenInfo();
                         });
        
        $(icon)
            .text(String.fromCharCode(0x00A4)) //Icon for a notepad
            .addClass('tgi_wing'); 
        
        $(msgP)
            .text(txt)
            .addClass(style);
        
        $(wrap).append(icon).append(msgP);
        
        if(styleInd === 0){
            date = document.createElement('span');

            $(date)
                .text(' (' + dateTxt + ')')
                .addClass('tgi_date');
            
            $(wrap).append(date);
        }
        
        $(".mtgi_parent").append(wrap);
    } catch(e){
        alert("function tgiCreateFormLink():\n"+e.description+"\n"+e.Reason+"\n");
    }
}


//Stolen from summary2 mpage
function tgiopenPowerForm(encntrId,personId,activityId,formId,chartMode)
{
  //var chartMode = 0;      // 0=Read/Write; 1=Read Only
  var obj = window.external.DiscernObjectFactory("POWERFORM");
  obj.OpenForm(parseFloat(personId), parseFloat(encntrId), parseFloat(formId), parseFloat(activityId), chartMode);
}