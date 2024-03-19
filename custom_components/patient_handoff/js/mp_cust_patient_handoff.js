/* TOP Patient Handoff
   The desire is for this component to call two smart templates and display them in a
   custom component.  In addition, this will allow for a freetext entry that is saved in
   a custom clinical event using the handoff rules.
   
   MAs will be making the notes and providers will be viewing at the moment.
*/
mPageCCLCall = function(script, fn, stat) {
    
    return function(opts) {
        var ajax = new XMLCclRequest();
        ajax.onreadystatechange = function() {
            if (ajax.readyState === 4 && ajax.status === 200) {
                var callFn, json, statusData;
                
                callFn = true;
                json = $.parseJSON(ajax.responseText);
                statusData = null;
                for (var i in json) {
                    if (json[i]["STATUS_DATA"]) {
                        statusData = json[i]["STATUS_DATA"];
                        break; 
                    } 
                }
                if (statusData && statusData.STATUS) {
                    if (stat) {
                        stat(statusData);
                    } else if (/[fp]/i.test(statusData.STATUS)) {
                        callFn = false;
                    }
                }
                callFn && fn(json);
            }else if (ajax.readyState === 4 && ajax.status >= 400 && ajax.status <= 599) {
                alert("The page did not load properly, please refresh the page to try again.");
            }
        };
        ajax.open("GET", script);
        ajax.send(opts);
    };
}

mcph_redraw = function(){
    
    $('.mcph_parent').empty();
    
    var parseReply, opts;
    
    opts = "^MINE^,value($PAT_PersonId$),value($VIS_EncntrId$)";
    parseReply = function(json){
        var hm_st, ord_st, label, textbox, button, docLabel, eventCd, handoffTxt, docDate;
        
        hm_st      = json.OUT_RS.HM_ST_REPLY;
        ord_st     = json.OUT_RS.ORD_ST_REPLY;
        eventCd    = json.OUT_RS.EVENT_CD;
        handoffTxt = json.OUT_RS.EVENT_REPLY;
        docDate    = json.OUT_RS.EVENT_DT_TXT;
        
        label      = $('<p><span class="mcph_title">Handoff Notes</span><span class="mcph_subtitle">(255 char limit)</span>')
        //Regex goofiness brought to you by the fact that the rule seems to parser fail if it sees an @ in the text.
        textbox    = $('<textarea/>').addClass('mcph_text_input').text(handoffTxt.replace(/&#x40;/g, '@')).attr({
            'rows': '5',
            'maxlength': 255
        });
        button     = $('<button/>').text('Submit');
        docLabel   = $('<span/>').addClass('mcph_subtitle');
        
        if(docDate !== '') $(docLabel).text('Last Documented: ' + docDate);
        
        $(button).click(function(){
            var parseReply, opts;
            
            //Replace goofiness brought to you by the fact that the rule seems to parser fail if it sees an @ in the text.
            opts = "^MINE^, value($VIS_EncntrId$), ^" + eventCd + "^, ^" + $('.mcph_text_input').text().replace('@','&#x40;') + "^";
            
            parseReply = function(json){
                mcph_redraw();
            }
            mPageCCLCall('medstar_mp_add_sticky_note', parseReply)(opts);
        });
        
        $('.mcph_parent').append(hm_st + '<br/>' + ord_st+ '<br/>');
        $('.mcph_parent').append(label);
        $('.mcph_parent').append(textbox);
        $('.mcph_parent').append(button);
        $('.mcph_parent').append(docLabel);
    }
    mPageCCLCall('mp_cust_get_patient_handoff', parseReply)(opts);
}


$(document).ready(function(){
    mcph_redraw();
});

