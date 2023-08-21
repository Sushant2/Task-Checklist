<%@ page import="java.io.*, java.sql.*" %>
<%@ page import="java.io.BufferedWriter"%>
<%@ page import="java.io.File"%>
<%@ page import="java.io.FileWriter"%>
<%@ page import="java.io.IOException"%>
<%@ page import="java.util.List"%>
<%@ page import="java.lang.Math"%>
<%@ page import="java.util.StringTokenizer"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="org.apache.commons.fileupload.*"%>
<%@ page import="org.apache.commons.fileupload.disk.*"%>
<%@ page import="org.apache.commons.fileupload.servlet.*"%>
<%@ page import="com.appnetix.app.util.sqlqueries.ResultSet"%>
<%@ page import="com.appnetix.app.util.QueryUtil"%>

<html>
    <head>
        <title>Task Checklist Automation</title>
    <style>
        body {
            font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            margin: 2%;
        }
        .headA{
            background-color: rgb(214, 146, 43);
            color: white;
            border-radius: 5px;
            margin: auto;
            width: 50%;
            padding: 10px;
            left: 50%;
        }
        .headU {
            font-size: 16px;
            font-weight: 400;
            line-height: 1.6;
            margin-bottom: 10px;
            padding: 5px;
            border-radius: 5px;
            background-color: #f0f0f0;
            transition: background-color 0.3s ease;
        }
        .headU:hover {
        background-color: #ddd;
        cursor: pointer;
        }
        .highSpan{
            text-decoration: underline;
        }
        li {
            font-size: 16px;
            font-weight: 400;
            line-height: 1.6;
            margin-bottom: 3px;
            padding: 2px 5px;
            border-radius: 5px;
            transition: background-color 0.3s ease;
        }
        li:hover {
            background-color: #f0f0f0;
            cursor: pointer;
        }

    </style>
<%
String action = request.getParameter("act"); //analyse/generateTaskSQL 
String contentType = request.getContentType();
if ((contentType != null) && (contentType.indexOf("multipart/form-data") >= 0)) {
    DataInputStream in = new DataInputStream(request.getInputStream());
    int formDataLength = request.getContentLength();
    byte dataBytes[] = new byte[formDataLength];
    int byteRead = 0;
    int totalBytesRead = 0;
    
    while (totalBytesRead < formDataLength) {
        byteRead = in.read(dataBytes, totalBytesRead, formDataLength);
        totalBytesRead += byteRead;
    }
    String file = new String(dataBytes);
    String saveFile = file.substring(file.indexOf("filename=\"") + 10);
    System.out.println("saveFile=" + saveFile);
    saveFile = saveFile.substring(saveFile.lastIndexOf("\\") + 1, saveFile.indexOf("\""));
    System.out.println("saveFile=" + saveFile);
    saveFile = file.substring(file.indexOf("filename=\"") + 10);
    saveFile = saveFile.substring(0, saveFile.indexOf("\n"));
    saveFile = saveFile.substring(saveFile.lastIndexOf("\\") + 1, saveFile.indexOf("\""));
    int lastIndex = contentType.lastIndexOf("=");
    String boundary = contentType.substring(lastIndex + 1, contentType.length());
    int pos;
    
    pos = file.indexOf("filename=\"");
    pos = file.indexOf("\n", pos) + 1;
    pos = file.indexOf("\n", pos) + 1;
    pos = file.indexOf("\n", pos) + 1;
    int boundaryLocation = file.indexOf(boundary, pos) - 4;
    int startPos = ((file.substring(0, pos)).getBytes()).length;
    int endPos = ((file.substring(0, boundaryLocation)).getBytes()).length;
    
    FileOutputStream fileOut = new FileOutputStream(saveFile);
    fileOut.write(dataBytes, startPos, (endPos - startPos));

    //To write sql queries in a file
    FileWriter writer = null;
    BufferedWriter bufferedWriter = null;
    File myNewFile = null;
    if(action.equals("analyse")){%>
        <b class="headA">File <%= saveFile %> analysed successfully.</b>
        <br>
        <br>
        <hr>
    <%}else if(action.equals("generateTaskSQL")){
        String wslPath = "/home/sushant/builddocs/taskAutomationSQL.sql";
        myNewFile = new File(wslPath);
      // Create the file if it doesn't exist
        if (!myNewFile.exists()) {
            myNewFile.createNewFile();
        }
        // Assign FileWriter and BufferedWriter objects
        writer = new FileWriter(wslPath);
        bufferedWriter = new BufferedWriter(writer);
    
        %>
        <p class="headU">File for <b><%= saveFile %></b> successfully saved to <span class="highSpan"><%= wslPath %></span></p>
    <%}%>
    <%!
    public static String[] mySplit(String line, char del){
        String[] cells = line.split(",");
        List<String> modifiedCell = new ArrayList<>();
        int i = 0;
        while(i<cells.length){
            if(cells[i].length() > 0 && '\"' == cells[i].charAt(0) && '\"' != cells[i].charAt(1)){
                String newCell = null;
                newCell = cells[i].substring(1, cells[i].length())+",";
                i++;
                while(i<cells.length){
                    cells[i] = cells[i].trim();
                    if('\"' == cells[i].charAt(cells[i].length()-1)){
                        newCell += cells[i].substring(0, cells[i].length()-1);
                        i++;
                        break;
                    }
                    else{
                        newCell += cells[i].trim()+",";
                    }
                    i++;
                }
                modifiedCell.add(newCell);
            }
            else{
                modifiedCell.add(cells[i]);
                i++;
            }
        }
        if (line.endsWith(",")){
            modifiedCell.add("");
        }
        return modifiedCell.toArray(new String[modifiedCell.size()]);
    }
    public static String UpIfLower(String str) {
        char[] strArr = str.toCharArray();
        if (strArr[0] >= 'a' && strArr[0] <= 'z')
            strArr[0] = (char) (strArr[0] - ('a' - 'A'));

        return String.valueOf(strArr);
    }
    %>
    <% Connection con = null;
    PreparedStatement pst = null; 
    try {
        ArrayList<String> analyseSummary = new ArrayList<String>();
        StringBuilder contents = new StringBuilder();
        List<String[]> data = new ArrayList<>();
        BufferedReader input = new BufferedReader(new FileReader(saveFile));
        Class.forName("com.mysql.jdbc.Driver");
        con = DriverManager.getConnection("jdbc:mysql://10.2.179.20/Sports_Clip_SushantDB?user=sterling&password=sterling");
        
        String line = null;
        int lineCount = 0;
        boolean firstLine = true;
        String refParent = null;
        String refField = null;
        String contactNames = null;
        ArrayList<Integer> orderSave = new ArrayList<Integer>();
        /* Our Column Order Assumption : 
        TASK = 0 RES AREA = 1 CONTACT = 2 STORE = 3 GROUP = 4 FRANCHISEE = 5 PRIORITY = 6 CRITICAL = 7 DEP ON = 8 TIMING = 9 OTHER CHECKLIST = 10 INIT DEP = 11 SCHEDULE_START = 12 SCHEDULE_START_D = 13 SCHEDULE_COMPLETION = 14 SCHEDULE_COMPLETION_D = 15 START_ALERT_DATE = 16 ALERT_DATE = 17 WEB_URL_LINK=18*/
        while ((line = input.readLine()) != null) {
            lineCount++;
            if(firstLine){
                boolean onceSchDays = false, onceSchPrior = false;
                String[] columnOrder = mySplit(line, ',');
                for(String colName : columnOrder){
                    if(colName.indexOf("Task") != -1)
                        orderSave.add(0);
                    else if(colName.indexOf("Responsibility") != -1)
                        orderSave.add(1);
                    else if(colName.indexOf("Contact") != -1)
                        orderSave.add(2);
                    else if(colName.indexOf("Store") != -1)
                        orderSave.add(3);
                    else if(colName.indexOf("Group") != -1)
                        orderSave.add(4);
                    else if(colName.indexOf("Franchisee") != -1)
                        orderSave.add(5);
                    else if(colName.indexOf("Priority") != -1)
                        orderSave.add(6);
                    else if(colName.indexOf("Critical") != -1)
                        orderSave.add(7);
                    else if(colName.indexOf("Dependent") != -1)
                        orderSave.add(8);
                    else if(colName.indexOf("Timing") != -1)
                        orderSave.add(9);
                    else if(colName.indexOf("Other Checklist") != -1)
                        orderSave.add(10);
                    else if(colName.indexOf("Initialize") != -1)
                        orderSave.add(11);
                    //schedule date start
                    else if(!onceSchDays && colName.indexOf("# of Day") != -1){
                        orderSave.add(12);
                        onceSchDays = true;
                    }
                    else if(!onceSchPrior && colName.indexOf("Prior to") != -1){
                        orderSave.add(13);
                        onceSchPrior = true;
                    }
                    //completion date start
                    else if(colName.indexOf("# of Day") != -1)
                        orderSave.add(14);
                    else if(colName.indexOf("Prior to") != -1)
                        orderSave.add(15);
                    else if(colName.indexOf("Start Reminder") != -1)
                        orderSave.add(16);
                    else if(colName.indexOf("Completion Reminder") != -1)
                        orderSave.add(17);
                    else if(colName.indexOf("Web Url") != -1)
                        orderSave.add(18);
                }
                firstLine = false;
                continue;
            }   
            System.out.println("Line : " + line);
            String[] columns = mySplit(line, ',');
            int i = 0;
            String suffix = "";
            PreparedStatement tempQ = null;
            while(i<orderSave.size()){
                if(lineCount % 10 == 1)
                    suffix = "st";
                else if(lineCount % 10 == 2)
                    suffix = "nd";
                else if(lineCount % 10 == 3)
                    suffix = "rd";
                else
                    suffix = "th";
                tempQ = null;
                if(orderSave.get(i) == 1){
                    if(columns[orderSave.indexOf(1)].equals("")){
                        analyseSummary.add("Note: Empty value for 'Responsibilty Area(s)' in " + lineCount + suffix + " row!");
                    }
                    else{
                        String[] cols = columns[orderSave.indexOf(1)].split(",");
                        for(String col : cols){
                            col = UpIfLower(col);
                            String query = "SELECT RESPONSIBILITY_AREA_ID FROM SM_RESPONSIBILITY_AREA WHERE RESPONSIBILITY_AREA = ?";
                            String[] queryParams = { col };
                            ResultSet rs = QueryUtil.getResult(query, queryParams);
                            if(!rs.next()){
                                analyseSummary.add("'" + col + "' not found in 'Responsibilty Area(s)', we'll add it!");
                                int ranNo = (int)Math.floor(Math.random() * (99999999 - 1 + 1));
                                String q = "INSERT INTO SM_RESPONSIBILITY_AREA VALUES(?, ?, 'N')";
                                String[] qParams = { String.valueOf(ranNo), col };
                                tempQ = con.prepareStatement(q);
                                tempQ.setString(1, String.valueOf(ranNo));
                                tempQ.setString(2, col);
                                String queStr = tempQ.toString();
                                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                if(action.equals("analyse"))
                                    analyseSummary.add("Query: " + finalQueStr);
                                else if(action.equals("generateTaskSQL")){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                // QueryUtil.update(q, qParams);
                            }
                        }
                    }
                }
                else if(orderSave.get(i) == 2){
                    if(columns[orderSave.indexOf(2)].equals("")){
                        analyseSummary.add("Note: Empty value for 'Contact(s)' in " + lineCount + suffix + " row!");
                    }
                    else{
                        String[] cols = columns[orderSave.indexOf(2)].split(",");
                        for(String col : cols){
                            col = UpIfLower(col);
                            String que1 = "SELECT USER_NO FROM USERS WHERE CONCAT(USER_FIRST_NAME, ' ', USER_LAST_NAME) IN (?)";
                            String que2 = "SELECT SUPPLIER_NO FROM SUPPLIERS WHERE SUPPLIER_NAME IN (?)";
                            String que3 = "SELECT CONCAT('-', FIELD_ID, 'S') FROM FIM_CONTACT_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                            String[] queryParams = { col };
                            ResultSet rs1 = QueryUtil.getResult(que1, queryParams);
                            ResultSet rs2 = QueryUtil.getResult(que2, queryParams);
                            ResultSet rs3 = QueryUtil.getResult(que3, queryParams);
                            if (!rs1.next() && !rs2.next() && !rs3.next()) {
                                analyseSummary.add("'" + col + "' not found in 'Contact(s)', we'll add it!");
                                String q = "INSERT INTO FIM_CONTACT_CUSTOMIZATION_FIELD (CUSTOM_FORM_ID, DISPLAY_NAME, DATA_TYPE, ORDER_NO, FIELD_NO, AVAILABLE) VALUES (1, ?, 'Text', (SELECT nextOrderNo FROM (SELECT MAX(ORDER_NO) + 1 AS nextOrderNo FROM FIM_CONTACT_CUSTOMIZATION_FIELD) AS table1), (SELECT nextFieldNo FROM (SELECT MAX(FIELD_NO) + 1 AS nextFieldNo FROM FIM_CONTACT_CUSTOMIZATION_FIELD) AS table2), 0)";
                                String[] qParams = { col };
                                tempQ = con.prepareStatement(q);
                                tempQ.setString(1, String.valueOf(col));
                                String queStr = tempQ.toString();
                                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                if(action.equals("analyse"))
                                    analyseSummary.add("Query: " + finalQueStr);
                                else if(action.equals("generateTaskSQL")){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                // QueryUtil.update(q, qParams);
                            }
                        }
                    }
                }
                else if(orderSave.get(i) == 3){
                    if(columns[orderSave.indexOf(3)].equals("")){
                        analyseSummary.add("Note: Empty value for 'Store Type(s)' in " + lineCount + suffix + " row!");
                    }
                    else{
                        String[] cols = columns[orderSave.indexOf(3)].split(",");
                        for(String col : cols){
                            col = UpIfLower(col);
                            String que = "SELECT ST_ID FROM STORE_TYPE WHERE ST_NAME IN (?)";
                            String[] queryParams = { col };
                            ResultSet rs = QueryUtil.getResult(que, queryParams);
                            if(!rs.next() && !col.equals("All") && !col.equals("Default Store")){
                                analyseSummary.add("'" + col + "' not found in 'Store Type(s)', we'll add it!");
                                String q = "INSERT INTO STORE_TYPE (ST_NAME, ST_ORDER) VALUES(?, (SELECT nextStoreOrder FROM (SELECT MAX(ST_ORDER) + 1 AS nextStoreOrder FROM STORE_TYPE) AS table1))";
                                String[] qParams = { col };
                                tempQ = con.prepareStatement(q);
                                tempQ.setString(1, col);
                                String queStr = tempQ.toString();
                                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                if(action.equals("analyse"))
                                    analyseSummary.add("Query: " + finalQueStr);
                                else if(action.equals("generateTaskSQL")){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                // QueryUtil.update(q, qParams);
                            }
                        }
                    }
                }
                else if(orderSave.get(i) == 4){
                    String phase = columns[orderSave.indexOf(4)];
                    if(phase.equals("")){
                        analyseSummary.add("Note: Empty value for 'Group' in " + lineCount + suffix + " row!");
                    }
                    else if(Character.isDigit(phase.charAt(0))){
                        analyseSummary.add("'" + phase + "' not found in 'Group', Please correct it!");
                    }
                    else{
                        phase = UpIfLower(phase);
                        String que = "SELECT GROUP_ID FROM CHECKLIST_GROUPS WHERE GROUP_NAME = ?";
                        String[] queryParams = { phase };
                        ResultSet rs = QueryUtil.getResult(que, queryParams);
                        if(!rs.next()){
                            analyseSummary.add("'" + phase + "' not found in 'Group', we'll add it!");
                            String q = "INSERT INTO CHECKLIST_GROUPS (GROUP_NAME, GROUP_ORDER) VALUES(?, (SELECT nextGroupOrder FROM (SELECT MAX(GROUP_ORDER) + 1 AS nextGroupOrder FROM CHECKLIST_GROUPS) AS table1))";
                            String[] qParams = { phase };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, phase);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("analyse"))
                                analyseSummary.add("Query: " + finalQueStr);
                            else if(action.equals("generateTaskSQL")){
                                bufferedWriter.write(finalQueStr+";");
                                bufferedWriter.newLine();
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if(orderSave.get(i) == 5){
                    String franAccess = columns[orderSave.indexOf(5)];
                    if(franAccess.equals("")){
                        analyseSummary.add("Note: Empty value for 'Franchisee Access' in " + lineCount + suffix + " row, Hence default value 'Update Status' will be added.");
                    }else{
                        franAccess = UpIfLower(franAccess);
                        String que = "SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='8102' AND DATA_VALUE = ?";
                        String[] queParams = { franAccess };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if(!rs.next()){
                            analyseSummary.add("'" + franAccess + "' not found in 'Franchisee Access', we'll add it!");
                            String q = "INSERT INTO MASTER_DATA (DATA_TYPE, PARENT_DATA_ID, DATA_VALUE) VALUES('8102', -1, ?)";
                            String[] qParams = { franAccess };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, franAccess);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("analyse"))
                                analyseSummary.add("Query: " + finalQueStr);
                            else if(action.equals("generateTaskSQL")){
                                bufferedWriter.write(finalQueStr+";");
                                bufferedWriter.newLine();
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if(orderSave.get(i) == 6){
                    String priority = columns[orderSave.indexOf(6)];
                    if(priority.equals("")){
                        analyseSummary.add("Note: Empty value for 'Priority' in " + lineCount + suffix + " row, Hence default value 'Recommended' will be added.");
                    }else{
                        priority = UpIfLower(priority);
                        String que = "SELECT PRIORITY_ID FROM SM_CHECKLIST_ITEMS_PRIORITY WHERE PRIORITY = ?";
                        String[] queParams = { priority };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if(!rs.next()){
                            analyseSummary.add("'" + priority + "' not found in 'Priority', we'll add it!");
                            String q = "INSERT INTO SM_CHECKLIST_ITEMS_PRIORITY (PRIORITY) VALUES(?)";
                            String[] qParams = { priority };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, priority);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("analyse"))
                                analyseSummary.add("Query: " + finalQueStr);
                            else if(action.equals("generateTaskSQL")){
                                bufferedWriter.write(finalQueStr+";");
                                bufferedWriter.newLine();
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if(orderSave.get(i) == 7){
                    String criLevel = columns[orderSave.indexOf(7)];
                    if(criLevel.equals("")){
                        analyseSummary.add("Note: Empty value for 'Critical Level' in " + lineCount + suffix + " row, Hence default value 'System Item' will be added.");
                    }
                    else {
                        criLevel = UpIfLower(criLevel);
                        String que = "SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='130320' AND DATA_VALUE = ?";
                        String[] queParams = { criLevel };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if(!rs.next()){
                            analyseSummary.add("'" + criLevel + "' not found in 'Critical Level', we'll add it!");
                            String q = "INSERT INTO MASTER_DATA (DATA_TYPE, PARENT_DATA_ID, DATA_VALUE) VALUES('130320', (SELECT nextParentId FROM (SELECT MAX(PARENT_DATA_ID) + 1 AS nextParentId FROM MASTER_DATA WHERE DATA_TYPE='130320') AS table1), ?)";
                            String[] qParams = { criLevel };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, criLevel);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("analyse"))
                                analyseSummary.add("Query: " + finalQueStr);
                            else if(action.equals("generateTaskSQL")){
                                bufferedWriter.write(finalQueStr+";");
                                bufferedWriter.newLine();
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if (orderSave.get(i) == 8) {
                    refParent = columns[orderSave.indexOf(8)];
                    refField = columns[orderSave.indexOf(10)];
                    if(refParent.equals("")){
                        analyseSummary.add("Note: Empty value for 'Dependent On' in " + lineCount + suffix + " row, Please mention it!");
                    }
                    else if (refParent.indexOf("Project") != -1) {
                        refParent = UpIfLower(refParent);
                        String que = "SELECT FIELD_ID FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                        String[] queParams = { refParent };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if (!rs.next()) {
                            analyseSummary.add("'" + refParent + "' not found in 'Dependent On', we'll add it!");
                            String q = "INSERT INTO FO_CUSTOMIZATION_FIELD (DISPLAY_NAME, DATA_TYPE, FIELD_NO, ORDER_NO, EXPORTABLE, SEARCHABLE, AVAILABLE) VALUES(?, 'Date', (SELECT nextFieldNo FROM (SELECT MAX(FIELD_NO) + 1 AS nextFieldNo FROM FO_CUSTOMIZATION_FIELD) AS table1), (SELECT nextOrderNo FROM (SELECT MAX(ORDER_NO) + 1 AS nextOrderNo FROM FO_CUSTOMIZATION_FIELD) AS table1), 1, 1, 0)";
                            String[] qParams = { refParent };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, refParent);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("analyse"))
                                analyseSummary.add("Query: " + finalQueStr);
                            else if(action.equals("generateTaskSQL")){
                                bufferedWriter.write(finalQueStr+";");
                                bufferedWriter.newLine();
                            }
                            // QueryUtil.update(q, qParams);
                        }
                        String refParentQuery = "SELECT CONCAT('FO_CUSTOM_FIELD_C', FIELD_ID) AS NEW_FIELD FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                        String[] refParentQueryParams = { refParent };
                        ResultSet res = QueryUtil.getResult(refParentQuery, refParentQueryParams);
                        if (res.next()){
                            refField = res.getString("NEW_FIELD"); //FO_CUSTOM_FIELD_C...
                            refParent = null;
                        }
                    }
                    else if(refParent.indexOf("Multiple") != -1 && refParent.equalsIgnoreCase("Multiple Checklist")){
                        refParent = "MULTIPLE_CHECKLIST";
                        refField = "";
                    }
                    else if(refParent.indexOf("Task") != -1 && refParent.equalsIgnoreCase("Task Checklist")){
                        refParent = "TASK_CHECKLIST";
                        if(refField.equals("")){
                            analyseSummary.add("Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!");
                        }
                        else{
                            String que = "SELECT TASK_ID FROM SM_TASK_CHECKLIST WHERE TASK LIKE '%" + refField + "%'";
                            ResultSet rs = QueryUtil.getResult(que, null);
                            if(rs.next())
                                refField = rs.getString("TASK_ID");
                        }
                    }
                    else if(refParent.indexOf("Equipment") != -1 && refParent.equalsIgnoreCase("Equipment Checklist")){
                        refParent = "EQUIPMENT_CHECKLIST";
                        if(refField.equals("")){
                            analyseSummary.add("Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!");
                        }else{
                            String que = "SELECT EQUIPMENT_ID FROM SM_EQUIPMENT_CHECKLIST WHERE EQUIPMENT_NAME LIKE '%" + refField + "%'";
                            ResultSet rs = QueryUtil.getResult(que, null);
                            if(rs.next())
                                refField = rs.getString("EQUIPMENT_ID");
                        }
                    }
                    else if(refParent.indexOf("Document") != -1 && refParent.equalsIgnoreCase("Document Checklist")){
                        refParent = "DOCUMENT_CHECKLIST";
                        if(refField.equals("")){
                            analyseSummary.add("Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!");
                        }
                        else{
                            String que = "SELECT DOCUMENT_ID FROM SM_DOCUMENT_CHECKLIST WHERE DOCUMENT_NAME LIKE '%" + refField + "%'";
                            ResultSet rs = QueryUtil.getResult(que, null);
                            if(rs.next())
                                refField = rs.getString("DOCUMENT_ID");
                        }
                    }
                    else if(refParent.indexOf("Picture") != -1 && refParent.equalsIgnoreCase("Picture Checklist")){
                        refParent = "PICTURE_CHECKLIST";
                        if(refField.equals("")){
                            analyseSummary.add("Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!");
                        }
                        else{
                            String que = "SELECT PICTURE_ID FROM SM_PICTURE_CHECKLIST WHERE TITLE LIKE '%" + refField + "%'";
                            ResultSet rs = QueryUtil.getResult(que, null);
                            if(rs.next())
                                refField = rs.getString("PICTURE_ID");
                        }
                    }
                    else if(refParent.indexOf("Secondary") != -1 && refParent.equalsIgnoreCase("Secondary Checklist")){
                        refParent = "SECONDRY_CHECKLIST";
                        if(refField.equals("")){
                            analyseSummary.add("Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!");
                        }
                        else{
                            String que = "SELECT ITEM_ID FROM SM_SECONDRY_CHECKLIST WHERE ITEM_NAME LIKE '%" + refField + "%'";
                            ResultSet rs = QueryUtil.getResult(que, null);
                            if(rs.next())
                                refField = rs.getString("ITEM_ID");
                        }
                    }
                    else {
                        refParent = null;
                        refField = "GRAND_STORE_OPENING_DATE";
                    }
                }
                i++;
            }
            System.out.println();
            data.add(columns);

            //Now Adding Data...

            String[] row = data.get(data.size() - 1); //Last Row
            String[] values1 = null;
            String resArea = null;
            if(!columns[orderSave.indexOf(1)].equals("")){
                values1 = row[orderSave.indexOf(1)].split(",");
                resArea= String.join("\',\'", values1);
            }
            String[] values2 = null;
            String contacts = null;
            if(!columns[orderSave.indexOf(2)].equals("")){
                values2 = row[orderSave.indexOf(2)].split(",");
                contacts= String.join("\',\'", values2);
            }
            String[] values3 = null;
            String storeNames = null;
            String stID=null;
            if(!columns[orderSave.indexOf(3)].equals("")){
                values3 = row[orderSave.indexOf(3)].split(",");
                storeNames= String.join("\',\'", values3);
                if(storeNames.equals("Default Store"))
                    storeNames = "Default";
                String storeTypeQuery = "SELECT ST_ID FROM STORE_TYPE WHERE ST_NAME IN ('" + storeNames + "')";
                String[] queryParams = {  };
                ResultSet rs = QueryUtil.getResult(storeTypeQuery, queryParams);
                if(rs.next())
                    stID=rs.getString("ST_ID");
                else if("All".equals(storeNames))
                    stID="666";
            }
            String groupType = null;
            if(Character.isDigit(columns[orderSave.indexOf(4)].charAt(0)))
                groupType = "";
            else if(!columns[orderSave.indexOf(4)].equals(""))
                groupType = row[orderSave.indexOf(4)];
            String franAccess = row[orderSave.indexOf(5)];
            if(franAccess.equals(""))
                franAccess = "Update Status";
            String priority = row[orderSave.indexOf(6)];
            if(priority.equals(""))
                priority = "Recommended";
            String criLevel = row[orderSave.indexOf(7)];
            if(criLevel.equals(""))
                criLevel = "System Item";
            String refFlag = row[orderSave.indexOf(9)];
            if(refFlag.equals("")){
                analyseSummary.add("Note: Empty value for 'Timing trigger for task' in " + lineCount + suffix + " row!");
            }else if(refFlag.indexOf("omple") != -1)
                refFlag = "Complete";
            else if(refFlag.indexOf("tart") != -1){
                refFlag = "Start";
            }else if(refFlag.indexOf("nd") != -1){
                refFlag = "End";
            }
            String depFlag = row[orderSave.indexOf(11)];
            if(depFlag.equals(""))
                analyseSummary.add("Note: Empty value for 'Initialize Dependency' in " + lineCount + suffix + " row!");
            else if("Yes".equals(depFlag))
                depFlag = "Y";
            else 
                depFlag = "N";
            String startDate = row[orderSave.indexOf(12)];
            String startFlag = row[orderSave.indexOf(13)];
            if("Days after".equals(startFlag))
                startFlag = "After";
            else if("Days prior".equals(startFlag))
                startFlag = "Prior";

            String scheduleDate = row[orderSave.indexOf(14)];
            String scheduleFlag = row[orderSave.indexOf(15)];
            if("Days after".equals(scheduleFlag))
                scheduleFlag = "After";
            else if("Days prior".equals(scheduleFlag))
                scheduleFlag = "Prior";

            if(startDate.equals("")){
                analyseSummary.add("Note: Empty value for 'Start Date' in " + lineCount + suffix + " row!");
                startDate = "0";
            }
            if(scheduleDate.equals("")){
                analyseSummary.add("Note: Empty value for 'Completion Date' in " + lineCount + suffix + " row!");
                scheduleDate = "0";
            }
            if(startFlag.equals(""))
                analyseSummary.add("Note: Empty value for 'Start prior to or after' in " + lineCount + suffix + " row!");
            if(scheduleFlag.equals(""))
                analyseSummary.add("Note: Empty value for 'Schedule prior to or after' in " + lineCount + suffix + " row!");
            if(!startDate.equals("") && !scheduleDate.equals("") && !startFlag.equals("") && !scheduleFlag.equals("")){
                if((startFlag.equals("Prior") && scheduleFlag.equals("Prior") && Integer.parseInt(startDate) < Integer.parseInt(scheduleDate)) || (startFlag.equals("After") && scheduleFlag.equals("After") &&  Integer.parseInt(scheduleDate) < Integer.parseInt(startDate)) || (startFlag.equals("After") && scheduleFlag.equals("Prior"))){
                    analyseSummary.add("Note: Schedule Completion should be greater than Schedule Start in " + lineCount + suffix + " row!");
                }
            }
            String startRem = null, completionRem = null;
            if(orderSave.size()>16){
                startRem = row[orderSave.indexOf(16)];
                completionRem = row[orderSave.indexOf(17)];
                if(!startRem.equals("") && !completionRem.equals("")){
                    if(Integer.parseInt(startRem) < Integer.parseInt(completionRem)){
                        analyseSummary.add("Note: Reminder Schedule Completion should be greater than Reminder Schedule Start in " + lineCount + suffix + " row!");
                    }
                }
            }
            String webUrl = null;
            if(orderSave.indexOf(18) != -1){
                webUrl = row[orderSave.indexOf(18)];
            }
            if(orderSave.size() == 16 && orderSave.indexOf(15) != -1){
                pst = con.prepareStatement("INSERT INTO SM_TASK_CHECKLIST (TASK, TASK_ID, RESPONSIBILITY_AREA, CONTACT, ST_ID, GROUP_ID, FRANCHISEE_ACCESS, PRIORITY_ID, CRITICAL_LEVEL_ID, REFERENCE_PARENT, REFERENCE_FLAG, REFERENCE_FIELD, DEPENDENCY_FLAG, START_DATE, START_FLAG, SCHEDULE_DATE, SCHEDULE_FLAG) VALUES (?, NULL, (SELECT GROUP_CONCAT(RESPONSIBILITY_AREA_ID) FROM SM_RESPONSIBILITY_AREA WHERE RESPONSIBILITY_AREA IN ('" + resArea + "')), (SELECT GROUP_CONCAT(CONTACT_INFO) FROM (SELECT USER_NO AS CONTACT_INFO FROM USERS WHERE CONCAT(USER_FIRST_NAME, ' ', USER_LAST_NAME) IN ('" + contacts + "') UNION SELECT SUPPLIER_NO AS CONTACT_INFO FROM SUPPLIERS WHERE SUPPLIER_NAME IN ('" + contacts + "') UNION SELECT CONCAT('-', FIELD_ID, 'S') AS CONTACT_INFO FROM FIM_CONTACT_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN ('" + contacts + "')) AS CONTACT),("+stID+"),(SELECT GROUP_ID FROM CHECKLIST_GROUPS WHERE GROUP_NAME IN ('" + groupType + "')), (SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='8102' AND DATA_VALUE IN ('" + franAccess + "')), (SELECT PRIORITY_ID FROM SM_CHECKLIST_ITEMS_PRIORITY WHERE PRIORITY IN ('" + priority + "')), (SELECT PARENT_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='130320' AND DATA_VALUE IN ('" + criLevel + "')), '" + refParent + "', '"+refFlag+"', '" + refField + "', '"+depFlag+"' ,"+startDate+",('"+startFlag+"'),"+scheduleDate+",('"+scheduleFlag+"'))");
            }
            else if(orderSave.indexOf(18) != -1){
                pst = con.prepareStatement("INSERT INTO SM_TASK_CHECKLIST (TASK, TASK_ID, RESPONSIBILITY_AREA, CONTACT, ST_ID, GROUP_ID, FRANCHISEE_ACCESS, PRIORITY_ID, CRITICAL_LEVEL_ID, REFERENCE_PARENT, REFERENCE_FLAG, REFERENCE_FIELD, DEPENDENCY_FLAG, START_DATE, START_FLAG, SCHEDULE_DATE, SCHEDULE_FLAG, START_ALERT_DATE, ALERT_DATE, WEB_URL_LINK) VALUES (?, NULL, (SELECT GROUP_CONCAT(RESPONSIBILITY_AREA_ID) FROM SM_RESPONSIBILITY_AREA WHERE RESPONSIBILITY_AREA IN ('" + resArea + "')), (SELECT GROUP_CONCAT(CONTACT_INFO) FROM (SELECT USER_NO AS CONTACT_INFO FROM USERS WHERE CONCAT(USER_FIRST_NAME, ' ', USER_LAST_NAME) IN ('" + contacts + "') UNION SELECT SUPPLIER_NO AS CONTACT_INFO FROM SUPPLIERS WHERE SUPPLIER_NAME IN ('" + contacts + "') UNION SELECT CONCAT('-', FIELD_ID, 'S') AS CONTACT_INFO FROM FIM_CONTACT_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN ('" + contacts + "')) AS CONTACT),("+stID+"),(SELECT GROUP_ID FROM CHECKLIST_GROUPS WHERE GROUP_NAME IN ('" + groupType + "')), (SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='8102' AND DATA_VALUE IN ('" + franAccess + "')), (SELECT PRIORITY_ID FROM SM_CHECKLIST_ITEMS_PRIORITY WHERE PRIORITY IN ('" + priority + "')), (SELECT PARENT_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='130320' AND DATA_VALUE IN ('" + criLevel + "')), '" + refParent + "', '"+refFlag+"', '" + refField + "', '"+depFlag+"' ,"+startDate+",('"+startFlag+"'),"+scheduleDate+",('"+scheduleFlag+"'), "+startRem+", "+completionRem+", '"+webUrl+"')");
            }
            else{
                pst = con.prepareStatement("INSERT INTO SM_TASK_CHECKLIST (TASK, TASK_ID, RESPONSIBILITY_AREA, CONTACT, ST_ID, GROUP_ID, FRANCHISEE_ACCESS, PRIORITY_ID, CRITICAL_LEVEL_ID, REFERENCE_PARENT, REFERENCE_FLAG, REFERENCE_FIELD, DEPENDENCY_FLAG, START_DATE, START_FLAG, SCHEDULE_DATE, SCHEDULE_FLAG, START_ALERT_DATE, ALERT_DATE) VALUES (?, NULL, (SELECT GROUP_CONCAT(RESPONSIBILITY_AREA_ID) FROM SM_RESPONSIBILITY_AREA WHERE RESPONSIBILITY_AREA IN ('" + resArea + "')), (SELECT GROUP_CONCAT(CONTACT_INFO) FROM (SELECT USER_NO AS CONTACT_INFO FROM USERS WHERE CONCAT(USER_FIRST_NAME, ' ', USER_LAST_NAME) IN ('" + contacts + "') UNION SELECT SUPPLIER_NO AS CONTACT_INFO FROM SUPPLIERS WHERE SUPPLIER_NAME IN ('" + contacts + "') UNION SELECT CONCAT('-', FIELD_ID, 'S') AS CONTACT_INFO FROM FIM_CONTACT_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN ('" + contacts + "')) AS CONTACT),("+stID+"),(SELECT GROUP_ID FROM CHECKLIST_GROUPS WHERE GROUP_NAME IN ('" + groupType + "')), (SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='8102' AND DATA_VALUE IN ('" + franAccess + "')), (SELECT PRIORITY_ID FROM SM_CHECKLIST_ITEMS_PRIORITY WHERE PRIORITY IN ('" + priority + "')), (SELECT PARENT_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='130320' AND DATA_VALUE IN ('" + criLevel + "')), '" + refParent + "', '"+refFlag+"', '" + refField + "', '"+depFlag+"' ,"+startDate+",('"+startFlag+"'),"+scheduleDate+",('"+scheduleFlag+"'), "+startRem+", "+completionRem+")");
            }
            pst.setString(1, row[0]);
            if(action.equals("generateTaskSQL")){
                String queStr = pst.toString();
                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                bufferedWriter.write(finalQueStr+";");
                bufferedWriter.newLine();
            }
            System.out.println("FINAL QUERY:" + pst.toString());
            // pst.executeUpdate();
    }
    // Return Analyse Summary :
        if(action.equals("analyse")){
            %><ol><%
            for(String summary : analyseSummary){
                %>
                <li><%= summary %></li>
                <%
            }
            %></ol><%
        // Generating SQL file
        }else if(action.equals("generateTaskSQL")){
            bufferedWriter.close();
            writer.close();
        }
        System.out.println("---------------------Data Processed Successfully---------------------");
        input.close();
        con.close();
    } catch (IOException  e) {
        e.printStackTrace();
    } finally {
        try {
            if (pst != null) {
                pst.close();
            }
            if (con != null) {
                con.close();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
%>
</html>