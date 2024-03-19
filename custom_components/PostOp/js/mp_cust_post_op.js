/*Days Post Op
Examines past surg procedures and displays days since 
Surgery as well as the procedure name in a component. 
*/

/* Component document ready hook
       This should get called when the page is ready to draw components.  You are free to go 
       hog wild with the JS at this point.  You'll still need to make sure you don't interfere 
       with other JS on the page, so you might want to namespace or prefix all your functions/globals 
       with something that is unique.
*/
mcpoCCLCall = function(script, fn, stat) {
    
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
};



//mp_cust_get_pat_post_op
mcpoCreateTable = function(){
    var table, tbody, row, parseReply, opts;
    
    
    table = $('<table/>')
                .addClass('mcpo_table')
                .append('<thead><th>Procedure</th> <th>Surgery Date</th> <th># of Days Post Op</th></thead>');
    
    tbody = $('<tbody/>');
    
    
    
    opts = "^MINE^, value($PAT_PersonId$)"
    parseReply = function(json){
        var cnt
          , lst
          , today
          , procDate
          , row;
        
        today = new Date();
        
        cnt = json.OUT_RS.CNT;
        lst = json.OUT_RS.QUAL;
        
        if(cnt === 0) $(tbody).append('<tr><td>No results found</td></tr>');
        
        for(i = 0; i < cnt; i++){
            row = '<tr><td>' + lst[i].PROC_NAME + '</td><td>' + lst[i].PROC_DATE + '</td>';
            
            if(lst[i].PROC_DATE !== '--'){
                procDate = new Date(lst[i].PROC_DT_TM);
                
                row += '<td>' + mcpoDateDiff(today, procDate) + '</td></tr>';
            }else{
                row += '<td>' + lst[i].POST_OP_DAYS + '</td></tr>';
            }
            
            $(tbody).append(row);
        }
        
        $(table).append(tbody);
        
        $(".mcpo_parent").empty();
        $(".mcpo_parent").append(table);
    }
    mcpoCCLCall('mp_cust_get_pat_post_op', parseReply)(opts);
}

mcpoDateDiff = function(date1, date2){
    var intervals = ['years','days']
      , moment1 = moment(date1)
      , moment2 = moment(date2)
      , i
      , values = []
      , diff;
    
    for(i = 0; i < intervals.length; i++){
        diff = moment1.diff(moment2, intervals[i]);
        
        moment2.add(diff, intervals[i]);
        
        if(diff === 1)    values.push(diff + ' ' + intervals[i].slice(0, -1));
        else if(diff > 0) values.push(diff + ' ' + intervals[i]);
    }
    
    return values.join(', ');
}

$(document).ready(function(){
    mcpoCreateTable();
});