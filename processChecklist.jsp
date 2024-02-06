<%@ page import="java.io.*, java.util.*, java.sql.*"%>
<%@ page import="java.io.BufferedWriter"%>
<%@ page import="java.io.File"%>
<%@ page import="java.io.FileWriter"%>
<%@ page import="java.io.IOException"%>
<%@ page import="java.util.List"%>
<%@ page import="java.lang.Math"%>
<%@ page import="java.util.StringTokenizer"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.util.Date"%>
<%@ page import="org.apache.commons.fileupload.*"%>
<%@ page import="org.apache.commons.fileupload.disk.*"%>
<%@ page import="org.apache.commons.fileupload.servlet.*"%>
<%@ page import="com.appnetix.app.util.sqlqueries.ResultSet"%>
<%@ page import="com.appnetix.app.util.QueryUtil"%>

<html>
    <head>
        <title>Task Checklist Automation</title>
        <link id="fav" rel="icon" type="image/x-icon" href="checklistFavicon.png">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <style>
        body {
            font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            margin: 2%;
            background-color: #f5f5f5;
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
        .key {
            position: relative;
            cursor: pointer;
            padding: 10px;
            background-color: #f2f2f2;
            border: 1px solid #ccc;
            border-radius: 5px;
            margin-bottom: 15px;
        }
        .key p {
            margin: 0;
            font-size: 16px;
            display: flex;
            align-items: center;
        }
        .strings {
            display: none;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
            background-color: #fff;
            margin-bottom: 10px;
        }
        .show {
            display: block;
        }
        .headInfo {
            font-weight: bold;
            margin-right: 5px;
        }
        .tooltip {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            padding: 2px 5px;
            background-color: rgb(214, 146, 43);
            color: white;
            border-radius: 3px;
            font-size: 12px;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .key:hover .tooltip {
            opacity: 1;
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
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd");
        String currentDate = dateFormat.format(new Date());
        String wslPath = System.getProperty("user.home") + "/builddocs/Checklist Automation/taskChecklistSQL_" + currentDate + ".sql";
        // Create the folder if it doesn't exist
        File folder = new File(System.getProperty("user.home") + "/builddocs/Checklist Automation");
        if (!folder.exists()) {
            folder.mkdirs(); 
        }
        // Create the file if it doesn't exist
        myNewFile = new File(wslPath);
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
            String newCell = null;
            //handle if cell has multiple/3 double quotes in starting & end
            if (cells[i].length() > 0 && "\"\"\"".equals(cells[i].substring(0, Math.min(3, cells[i].length())))){
                //if the same cell is also the last cell ending with multiple/3 quotes
                if("\"\"\"".equals(cells[i].substring(cells[i].length()-3, cells[i].length()))){
                    newCell = cells[i].substring(3, cells[i].length()-3);
                    i++;
                }
                //if the same cell is starting with 3 double quotes & ending with only one double quote
                else if('\"'== (cells[i].charAt(cells[i].length()-1)) && '\"' != cells[i].charAt(cells[i].length()-2)){
                    newCell = cells[i].substring(3, cells[i].length()-1);
                    i++;
                }
                else{
                    newCell = cells[i].substring(3, cells[i].length());
                    i++; 
                    while(i<cells.length){
                        if("\"\"\"".equals(cells[i].substring(cells[i].length()-3, cells[i].length()))){
                            newCell += "," + cells[i].substring(0, cells[i].length()-3);
                            i++;
                            break;
                        }
                        else if('\"' == (cells[i].charAt(cells[i].length()-1)) && '\"' != cells[i].charAt(cells[i].length()-2)){
                            newCell += "," + cells[i].substring(0, cells[i].length()-1);
                            i++;
                            break;
                        } 
                        else
                            newCell += "," + cells[i].substring(0, cells[i].length());
                        i++;
                    }
                }
                modifiedCell.add(newCell);
            }
            //handles if a cell has multiple values separated using comma
            else if(cells[i].length() > 0 && '\"' == cells[i].charAt(0) && '\"' != cells[i].charAt(1)){
                newCell = null;
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
        /* 
        TASK = 0 RES AREA = 1 CONTACT = 2 STORE = 3 GROUP = 4 FRANCHISEE = 5 PRIORITY = 6 CRITICAL = 7 DEP ON = 8 TIMING = 9 OTHER CHECKLIST = 10 INIT DEP = 11 SCHEDULE_START = 12 SCHEDULE_START_D = 13 SCHEDULE_COMPLETION = 14 SCHEDULE_COMPLETION_D = 15 START_ALERT_DATE = 16 ALERT_DATE = 17 WEB_URL_LINK=18 
        */
        ArrayList<String> orderInfoMap = new ArrayList<>(Arrays.asList(
            "Task", "Responsibility Area(s)", "Contact(s)", "Applicable To Store Type(s)", "Group", "Franchisee Access", "Priority", "Critical Level", "Dependent On", "Timing trigger for task", "Other Checklist task on which this task is dependent", "Initialize Dependency", "SCHEDULE_START", "SCHEDULE_START_D", "SCHEDULE_COMPLETION", "SCHEDULE_COMPLETION_D", "START_ALERT_DATE", "ALERT_DATE", "WEB_URL_LINK"
        ));
        HashMap<Integer, HashSet<String>> analyseSum = new HashMap<>();
        HashSet<String> sqlQuery = new HashSet<>();
        //initializing hashmap
        for(int i = 0;i<=18;i++)
            analyseSum.put(i, new HashSet<>());
        StringBuilder contents = new StringBuilder();
        List<String[]> data = new ArrayList<>();
        BufferedReader input = new BufferedReader(new FileReader(saveFile));
        Class.forName("com.mysql.jdbc.Driver");

        Properties prop = new Properties();
        InputStream inputBuildProps = null;

        try {
            String buildPropsPath = getServletContext().getRealPath("WEB-INF/mvnForumHome/build.properties");
            inputBuildProps = new FileInputStream(buildPropsPath);
            prop.load(inputBuildProps);
            String databaseName = prop.getProperty("sushant.db");
            String dbServer = prop.getProperty("dbServer");
            String[] serverParts = dbServer.split(":");
            String host = serverParts[0];
            System.out.println("jdbc:mysql://" + host + "/" + databaseName + "?user=sterling&password=sterling");
            con = DriverManager.getConnection("jdbc:mysql://" + host + "/" + databaseName + "?user=sterling&password=sterling");
        } catch (IOException | SQLException e) {
            e.printStackTrace();
        } finally {
            if (inputBuildProps != null) {
                try {
                    inputBuildProps.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        
        String line = null;
        int lineCount = 0;
        Boolean firstLine = true;
        String refParent = null;
        String refField = null;
        String contactNames = null;
        ArrayList<Integer> orderSave = new ArrayList<Integer>();
        /* Our Column Order Assumption : 
        TASK = 0 RES AREA = 1 CONTACT = 2 STORE = 3 GROUP = 4 FRANCHISEE = 5 PRIORITY = 6 CRITICAL = 7 DEP ON = 8 TIMING = 9 OTHER CHECKLIST = 10 INIT DEP = 11 SCHEDULE_START = 12 SCHEDULE_START_D = 13 SCHEDULE_COMPLETION = 14 SCHEDULE_COMPLETION_D = 15 START_ALERT_DATE = 16 ALERT_DATE = 17 WEB_URL_LINK=18*/
        while ((line = input.readLine()) != null) {
            String franRegiContact = "";
            Boolean onlyOnceIfLast = null;
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
            System.out.println();
            System.out.println("Line" + lineCount +": " + line);
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
                    HashSet<String> analyseSet = analyseSum.get(1);
                    if(columns[orderSave.indexOf(1)].equals("")){
                        String analyseMessage = "Note: Empty value for 'Responsibilty Area(s)' in " + lineCount + suffix + " row!";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(1, analyseSet);
                    }
                    else{
                        String[] cols = columns[orderSave.indexOf(1)].split(",");
                        for(String col : cols){
                            col = UpIfLower(col);
                            String query = "SELECT RESPONSIBILITY_AREA_ID FROM SM_RESPONSIBILITY_AREA WHERE RESPONSIBILITY_AREA = ?";
                            String[] queryParams = { col };
                            ResultSet rs = QueryUtil.getResult(query, queryParams);
                            if(!rs.next()){
                                String analyseMessage = "'" + col + "' not found in 'Responsibilty Area(s)', we'll add it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(1, analyseSet);
                                int ranNo = (int)Math.floor(Math.random() * (99999999 - 1 + 1));
                                String q = "INSERT INTO SM_RESPONSIBILITY_AREA VALUES(?, ?, 'N')";
                                String[] qParams = { String.valueOf(ranNo), col };
                                tempQ = con.prepareStatement(q);
                                tempQ.setString(1, String.valueOf(ranNo));
                                tempQ.setString(2, col);
                                String queStr = tempQ.toString();
                                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                if(action.equals("generateTaskSQL")){
                                    if(!sqlQuery.contains(col)){
                                        bufferedWriter.write(finalQueStr+";");
                                        bufferedWriter.newLine();
                                    }
                                    sqlQuery.add(col);
                                }
                                // QueryUtil.update(q, qParams);
                            }
                        }
                    }
                }
                else if(orderSave.get(i) == 2){
                    HashSet<String> analyseSet = analyseSum.get(2);
                    if(columns[orderSave.indexOf(2)].equals("")){
                        String analyseMessage = "Note: Empty value for 'Contact(s)' in " + lineCount + suffix + " row!";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(2, analyseSet);
                    }
                    else{
                        String[] cols = columns[orderSave.indexOf(2)].split(",");
                        for(String col : cols){
                            if(col.equals("Regional User") && franRegiContact != ""){
                                franRegiContact += ", -2";
                            }
                            else if(col.equals("Regional User")){
                                franRegiContact = "-2";
                            }
                            else if((col.equals("Franchise User") || col.equals("Franchisee User")) && franRegiContact != ""){
                                franRegiContact += ", 0";
                            }
                            else if(col.equals("Franchise User") || col.equals("Franchisee User")){
                                franRegiContact = "0";
                            }

                            col = UpIfLower(col);
                            String que1 = "SELECT USER_NO FROM USERS WHERE CONCAT(USER_FIRST_NAME, ' ', USER_LAST_NAME) IN (?)";
                            String que2 = "SELECT SUPPLIER_NO FROM SUPPLIERS WHERE SUPPLIER_NAME IN (?)";
                            String que3 = "SELECT CONCAT('-', FIELD_ID, 'S') FROM FIM_CONTACT_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                            String[] queryParams = { col };
                            ResultSet rs1 = QueryUtil.getResult(que1, queryParams);
                            ResultSet rs2 = QueryUtil.getResult(que2, queryParams);
                            ResultSet rs3 = QueryUtil.getResult(que3, queryParams);
                            if (!rs1.next() && !rs2.next() && !rs3.next() && !col.equals("Franchise User") && !col.equals("Regional User")) {
                                String analyseMessage = "'" + col + "' not found in 'Contact(s)', we'll add it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(2, analyseSet);
                                String q = "INSERT INTO FIM_CONTACT_CUSTOMIZATION_FIELD (CUSTOM_FORM_ID, DISPLAY_NAME, DATA_TYPE, ORDER_NO, FIELD_NO, AVAILABLE) VALUES (1, ?, 'Text', (SELECT nextOrderNo FROM (SELECT MAX(ORDER_NO) + 1 AS nextOrderNo FROM FIM_CONTACT_CUSTOMIZATION_FIELD) AS table1), (SELECT nextFieldNo FROM (SELECT MAX(FIELD_NO) + 1 AS nextFieldNo FROM FIM_CONTACT_CUSTOMIZATION_FIELD) AS table2), 0)";
                                String[] qParams = { col };
                                tempQ = con.prepareStatement(q);
                                tempQ.setString(1, String.valueOf(col));
                                String queStr = tempQ.toString();
                                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                if(action.equals("generateTaskSQL")){
                                    if(!sqlQuery.contains(col)){
                                        bufferedWriter.write(finalQueStr+";");
                                        bufferedWriter.newLine();
                                    }
                                    sqlQuery.add(col);
                                }
                                // QueryUtil.update(q, qParams);
                            }
                        }
                    }
                }
                else if(orderSave.get(i) == 3){
                    HashSet<String> analyseSet = analyseSum.get(3);
                    if(columns[orderSave.indexOf(3)].equals("")){
                        String analyseMessage = "Note: Empty value for 'Store Type(s)' in " + lineCount + suffix + " row!";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(3, analyseSet);
                    }
                    else{
                        String[] cols = columns[orderSave.indexOf(3)].split(",");
                        for(String col : cols){
                            col = UpIfLower(col);
                            String que = "SELECT ST_ID FROM STORE_TYPE WHERE ST_NAME IN (?)";
                            String[] queryParams = { col };
                            ResultSet rs = QueryUtil.getResult(que, queryParams);
                            if(!rs.next() && !col.equalsIgnoreCase("All") && !col.equalsIgnoreCase("Default Store") && !col.equalsIgnoreCase("All Stores")){
                                String analyseMessage = "'" + col + "' not found in 'Store Type(s)', we'll add it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(3, analyseSet);
                                String q = "INSERT INTO STORE_TYPE (ST_NAME, ST_ORDER) VALUES(?, (SELECT nextStoreOrder FROM (SELECT MAX(ST_ORDER) + 1 AS nextStoreOrder FROM STORE_TYPE) AS table1))";
                                String[] qParams = { col };
                                tempQ = con.prepareStatement(q);
                                tempQ.setString(1, col);
                                String queStr = tempQ.toString();
                                String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                if(action.equals("generateTaskSQL")){
                                    if(!sqlQuery.contains(col)){
                                        bufferedWriter.write(finalQueStr+";");
                                        bufferedWriter.newLine();
                                    }
                                    sqlQuery.add(col);
                                }
                                // QueryUtil.update(q, qParams);
                            }
                        }
                    }
                }
                else if(orderSave.get(i) == 4){
                    HashSet<String> analyseSet = analyseSum.get(4);
                    String phase = "";
                    if(orderSave.indexOf(4) < columns.length)
                        phase = columns[orderSave.indexOf(4)];
                    if(phase.equals("")){
                        String analyseMessage = "Note: Empty value for 'Group' in " + lineCount + suffix + " row!";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(4, analyseSet);
                    }
                    else{
                        phase = UpIfLower(phase);
                        String que = "SELECT GROUP_ID FROM CHECKLIST_GROUPS WHERE GROUP_NAME = ?";
                        String[] queryParams = { phase };
                        ResultSet rs = QueryUtil.getResult(que, queryParams);
                        if(!rs.next()){
                            String analyseMessage = "'" + phase + "' not found in 'Group', we'll add it!";
                            analyseSet.add(analyseMessage);
                            analyseSum.put(4, analyseSet);
                            String q = "INSERT INTO CHECKLIST_GROUPS (GROUP_NAME, GROUP_ORDER) VALUES(?, (SELECT nextGroupOrder FROM (SELECT MAX(GROUP_ORDER) + 1 AS nextGroupOrder FROM CHECKLIST_GROUPS) AS table1))";
                            String[] qParams = { phase };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, phase);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("generateTaskSQL")){
                                if(!sqlQuery.contains(phase)){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                sqlQuery.add(phase);
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if(orderSave.get(i) == 5){
                    HashSet<String> analyseSet = analyseSum.get(5);
                    String franAccess = "";
                    if(orderSave.indexOf(5) < columns.length)
                        franAccess = columns[orderSave.indexOf(5)];
                    if(franAccess.equals("")){
                        String analyseMessage = "Note: Empty value for 'Franchisee Access' in " + lineCount + suffix + " row, Hence default value 'Update Status' will be added.";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(5, analyseSet);
                    }else{
                        franAccess = UpIfLower(franAccess);
                        String que = "SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='8102' AND DATA_VALUE = ?";
                        String[] queParams = { franAccess };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if(!rs.next()){
                            String analyseMessage = "'" + franAccess + "' not found in 'Franchisee Access', we'll add it!";
                            analyseSet.add(analyseMessage);
                            analyseSum.put(5, analyseSet);
                            String q = "INSERT INTO MASTER_DATA (DATA_TYPE, PARENT_DATA_ID, DATA_VALUE) VALUES('8102', -1, ?)";
                            String[] qParams = { franAccess };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, franAccess);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("generateTaskSQL")){
                                if(!sqlQuery.contains(franAccess)){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                sqlQuery.add(franAccess);
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if(orderSave.get(i) == 6){
                    HashSet<String> analyseSet = analyseSum.get(6);
                    String priority = "";
                    if(orderSave.indexOf(6) < columns.length)
                        priority = columns[orderSave.indexOf(6)];
                    if(priority.equals("")){
                        String analyseMessage = "Note: Empty value for 'Priority' in " + lineCount + suffix + " row, Hence default value 'Recommended' will be added.";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(6, analyseSet);
                    }else{
                        priority = UpIfLower(priority);
                        String que = "SELECT PRIORITY_ID FROM SM_CHECKLIST_ITEMS_PRIORITY WHERE PRIORITY = ?";
                        String[] queParams = { priority };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if(!rs.next()){
                            String analyseMessage = "'" + priority + "' not found in 'Priority', we'll add it!";
                            analyseSet.add(analyseMessage);
                            analyseSum.put(6, analyseSet);
                            String q = "INSERT INTO SM_CHECKLIST_ITEMS_PRIORITY (PRIORITY) VALUES(?)";
                            String[] qParams = { priority };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, priority);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("generateTaskSQL")){
                                if(!sqlQuery.contains(priority)){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                sqlQuery.add(priority);
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if(orderSave.get(i) == 7){
                    HashSet<String> analyseSet = analyseSum.get(7);
                    String criLevel = "";
                    if(orderSave.indexOf(7) < columns.length)
                        criLevel = columns[orderSave.indexOf(7)];
                    if(criLevel.equals("")){
                        String analyseMessage = "Note: Empty value for 'Critical Level' in " + lineCount + suffix + " row, Hence default value 'System Item' will be added.";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(7, analyseSet);
                    }
                    else {
                        criLevel = UpIfLower(criLevel);
                        String que = "SELECT MASTER_DATA_ID FROM MASTER_DATA WHERE DATA_TYPE='130320' AND DATA_VALUE = ?";
                        String[] queParams = { criLevel };
                        ResultSet rs = QueryUtil.getResult(que, queParams);
                        if(!rs.next()){
                            String analyseMessage = "'" + criLevel + "' not found in 'Critical Level', we'll add it!";
                            analyseSet.add(analyseMessage);
                            analyseSum.put(7, analyseSet);
                            String q = "INSERT INTO MASTER_DATA (DATA_TYPE, PARENT_DATA_ID, DATA_VALUE) VALUES('130320', (SELECT nextParentId FROM (SELECT MAX(PARENT_DATA_ID) + 1 AS nextParentId FROM MASTER_DATA WHERE DATA_TYPE='130320') AS table1), ?)";
                            String[] qParams = { criLevel };
                            tempQ = con.prepareStatement(q);
                            tempQ.setString(1, criLevel);
                            String queStr = tempQ.toString();
                            String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                            if(action.equals("generateTaskSQL")){
                                if(!sqlQuery.contains(criLevel)){
                                    bufferedWriter.write(finalQueStr+";");
                                    bufferedWriter.newLine();
                                }
                                sqlQuery.add(criLevel);
                            }
                            // QueryUtil.update(q, qParams);
                        }
                    }
                }
                else if (orderSave.get(i) == 8) {
                    HashSet<String> analyseSet = analyseSum.get(8);
                    refParent = "";
                    if(orderSave.indexOf(8) < columns.length){
                        refParent = columns[orderSave.indexOf(8)];
                        if(refParent.contains("Timeless") || refParent.contains("None"))
                            refParent = "-1";
                    }

                    if(refParent.equals("-1")){
                        refField = "-1";
                    }
                    else{
                        refField = "";
                        if(orderSave.indexOf(10) < columns.length)
                            refField = columns[orderSave.indexOf(10)];
                        if(refParent.equals("")){
                            String analyseMessage = "Note: Empty value for 'Dependent On' in " + lineCount + suffix + " row, Please mention it!";
                            analyseSet.add(analyseMessage);
                            analyseSum.put(8, analyseSet);
                        }
                        else if (refParent.indexOf("Multiple") == -1 && refParent.indexOf("Task") == -1 && refParent.indexOf("Equipment") == -1 && refParent.indexOf("Document") == -1 && refParent.indexOf("Picture") == -1 && refParent.indexOf("Secondary") == -1 && refParent.indexOf("Opening Date") == -1) {
                            refParent = UpIfLower(refParent);
                            String que = "SELECT FIELD_ID FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                            String[] queParams = { refParent };
                            ResultSet rs = QueryUtil.getResult(que, queParams);
                            if (!rs.next()) {
                                String analyseMessage = "'" + refParent + "' not found in 'Dependent On', we'll add it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(8, analyseSet);
                                String findFieldIdQuery = "SELECT FIELD_ID FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME='' LIMIT 2";
                                ResultSet rsFFQ = QueryUtil.getResult(findFieldIdQuery, null);
                                String refFieldId = null;
                                String refFieldIdLast = null;
                                if(rsFFQ.next()){
                                    refFieldId = rsFFQ.getString("FIELD_ID");
                                    if (rsFFQ.next()) {
                                        refFieldIdLast = rsFFQ.getString("FIELD_ID");
                                    }
                                }

                                if (refFieldId != null && refFieldIdLast == null && onlyOnceIfLast == null)
                                    onlyOnceIfLast = true;
                        
                                if (refFieldId != null && !refFieldId.equals("") && (onlyOnceIfLast == null || onlyOnceIfLast)) {
                                    //turning onlyOnceIfLast as false
                                    onlyOnceIfLast = false;
                                    String orderNoQuery = "SELECT MAX(ORDER_NO)+1 AS ORDER_NO FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME!=''";
                                    ResultSet rsON = QueryUtil.getResult(orderNoQuery, null);
                                    String orderNo = null;
                                    if (rsON.next())
                                        orderNo = rsON.getString("ORDER_NO");
                                
                                    String updateRefQuery = "UPDATE FO_CUSTOMIZATION_FIELD SET DISPLAY_NAME = ?, DATA_TYPE = 'Date', ORDER_NO = (SELECT COALESCE(MAXNO,1) FROM (SELECT (MAX(ORDER_NO) + 1) AS MAXNO FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME != '') AS TMP), AVAILABLE = 0, MILESTONE_APPLICABLE = 'Y' WHERE FIELD_ID = (SELECT FIELD_ID FROM (SELECT FIELD_ID FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME = '' LIMIT 1) AS TMP)";
                                    
                                    String[] qParams = {refParent};

                                    tempQ = con.prepareStatement(updateRefQuery);
                                    tempQ.setString(1, refParent);
                                    String queStr = tempQ.toString();
                                    String finalQueStr = queStr.substring(queStr.indexOf(": ") + 2, queStr.length());
                                    
                                    if (action.equals("generateTaskSQL")) {
                                        if (!sqlQuery.contains(refParent)) {
                                            bufferedWriter.write(finalQueStr + ";");
                                            bufferedWriter.newLine();
                                        }
                                        sqlQuery.add(refParent);
                                    }
                                    // QueryUtil.update(q, qParams);
                                    String refParentQ = "SELECT CONCAT('FO_CUSTOM_FIELD_C', FIELD_ID) AS NEW_FIELD FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                                    tempQ = con.prepareStatement(refParentQ);
                                    tempQ.setString(1, String.valueOf(refParent));
                                    String strQ = tempQ.toString();
                                    String strQFinal = strQ.substring(strQ.indexOf(": ")+2, strQ.length());
                                    refField = "("+strQFinal+")";
                                    refParent = null;
                                }
                                else{
                                    String q = "INSERT INTO FO_CUSTOMIZATION_FIELD (DISPLAY_NAME, DATA_TYPE, FIELD_NO, ORDER_NO, EXPORTABLE, SEARCHABLE, AVAILABLE) VALUES(?, 'Date', (SELECT nextFieldNo FROM (SELECT MAX(FIELD_NO) + 1 AS nextFieldNo FROM FO_CUSTOMIZATION_FIELD) AS table1), (SELECT nextOrderNo FROM (SELECT MAX(ORDER_NO) + 1 AS nextOrderNo FROM FO_CUSTOMIZATION_FIELD) AS table1), 1, 1, 0)";
                                    String[] qParams = { refParent };
                                    tempQ = con.prepareStatement(q);
                                    tempQ.setString(1, refParent);
                                    String queStr = tempQ.toString();
                                    String finalQueStr = queStr.substring(queStr.indexOf(": ")+2, queStr.length());
                                    if(action.equals("generateTaskSQL")){
                                        if(!sqlQuery.contains(refParent)){
                                            bufferedWriter.write(finalQueStr+";");
                                            bufferedWriter.newLine();
                                        }
                                        sqlQuery.add(refParent);
                                    }
                                    // QueryUtil.update(q, qParams);

                                    String refParentQuery = "SELECT CONCAT('FO_CUSTOM_FIELD_C', FIELD_ID) AS NEW_FIELD FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                                    String[] refParentQueryParams = { refParent };
                                    ResultSet res = QueryUtil.getResult(refParentQuery, refParentQueryParams);
                                    if (res.next()){
                                        refField = "'" + res.getString("NEW_FIELD") + "'"; //FO_CUSTOM_FIELD_C...
                                        refParent = null;
                                    }
                                }
                            }
                            else{
                                String refParentQuery = "SELECT CONCAT('FO_CUSTOM_FIELD_C', FIELD_ID) AS NEW_FIELD FROM FO_CUSTOMIZATION_FIELD WHERE DISPLAY_NAME IN (?)";
                                String[] refParentQueryParams = { refParent };
                                ResultSet res = QueryUtil.getResult(refParentQuery, refParentQueryParams);
                                if (res.next()){
                                    refField = "'" + res.getString("NEW_FIELD") + "'"; //FO_CUSTOM_FIELD_C...
                                    refParent = null;
                                }
                            }
                        }
                        else if(refParent.indexOf("Multiple") != -1 || refParent.equalsIgnoreCase("Multiple Checklist")){
                            refParent = "MULTIPLE_CHECKLIST";
                            refField = "";
                        }
                        else if(refParent.indexOf("Task") != -1 || refParent.equalsIgnoreCase("Task Checklist")){
                            refParent = "TASK_CHECKLIST";
                            if(refField.equals("")){
                                String analyseMessage = "Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(8, analyseSet);
                            }
                            else{
                                String que = "SELECT TASK_ID FROM SM_TASK_CHECKLIST WHERE TASK LIKE '%" + refField + "%'";
                                ResultSet rs = QueryUtil.getResult(que, null);
                                if(rs.next())
                                    refField = "'" + rs.getString("TASK_ID") + "'";
                            }
                        }
                        else if(refParent.indexOf("Equipment") != -1 || refParent.equalsIgnoreCase("Equipment Checklist")){
                            refParent = "EQUIPMENT_CHECKLIST";
                            if(refField.equals("")){
                                String analyseMessage = "Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(8, analyseSet);
                            }else{
                                String que = "SELECT EQUIPMENT_ID FROM SM_EQUIPMENT_CHECKLIST WHERE EQUIPMENT_NAME LIKE '%" + refField + "%'";
                                ResultSet rs = QueryUtil.getResult(que, null);
                                if(rs.next())
                                    refField = "'" +  rs.getString("EQUIPMENT_ID") + "'";
                            }
                        }
                        else if(refParent.indexOf("Document") != -1 || refParent.equalsIgnoreCase("Document Checklist")){
                            refParent = "DOCUMENT_CHECKLIST";
                            if(refField.equals("")){
                                String analyseMessage = "Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(8, analyseSet);
                            }
                            else{
                                String que = "SELECT DOCUMENT_ID FROM SM_DOCUMENT_CHECKLIST WHERE DOCUMENT_NAME LIKE '%" + refField + "%'";
                                ResultSet rs = QueryUtil.getResult(que, null);
                                if(rs.next())
                                    refField = "'" + rs.getString("DOCUMENT_ID") + "'";
                            }
                        }
                        else if(refParent.indexOf("Picture") != -1 || refParent.equalsIgnoreCase("Picture Checklist")){
                            refParent = "PICTURE_CHECKLIST";
                            if(refField.equals("")){
                                String analyseMessage = "Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(8, analyseSet);
                            }
                            else{
                                String que = "SELECT PICTURE_ID FROM SM_PICTURE_CHECKLIST WHERE TITLE LIKE '%" + refField + "%'";
                                ResultSet rs = QueryUtil.getResult(que, null);
                                if(rs.next())
                                    refField = "'" + rs.getString("PICTURE_ID") + "'";
                            }
                        }
                        else if(refParent.indexOf("Secondary") != -1 || refParent.equalsIgnoreCase("Secondary Checklist")){
                            refParent = "SECONDRY_CHECKLIST";
                            if(refField.equals("")){
                                String analyseMessage = "Note: Empty value for 'Other Checklist tasks' in " + lineCount + suffix + " row, Please mention it!";
                                analyseSet.add(analyseMessage);
                                analyseSum.put(8, analyseSet);
                            }
                            else{
                                String que = "SELECT ITEM_ID FROM SM_SECONDRY_CHECKLIST WHERE ITEM_NAME LIKE '%" + refField + "%'";
                                ResultSet rs = QueryUtil.getResult(que, null);
                                if(rs.next())
                                    refField = "'" + rs.getString("ITEM_ID") + "'";
                            }
                        }
                        else {
                            refParent = null;
                            refField = "'GRAND_STORE_OPENING_DATE'";
                        }
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
                else if("All".equals(storeNames) || storeNames.equals("All Stores"))
                    stID="666";
            }
            String groupType = null;
            if(columns[orderSave.indexOf(4)].length() > 0 && Character.isDigit(columns[orderSave.indexOf(4)].charAt(0)))
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
            String refFlag = "";
            if(orderSave.indexOf(9) < row.length)
                refFlag = row[orderSave.indexOf(9)];
            if(refFlag.equals("")){
                if(refParent != null && (refParent.equals("-1"))){
                    refFlag = "-1";
                }
                else{
                    HashSet<String> analyseSet = analyseSum.get(9);
                    String analyseMessage = "Note: Empty value for 'Timing trigger for task' in " + lineCount + suffix + " row!";
                    analyseSet.add(analyseMessage);
                    analyseSum.put(9, analyseSet);
                }     
            }else if(refFlag.indexOf("omple") != -1)
                refFlag = "Complete";
            else if(refFlag.indexOf("tart") != -1){
                refFlag = "Start";
            }else if(refFlag.indexOf("nd") != -1){
                refFlag = "End";
            }
            String depFlag = "";
            if(orderSave.indexOf(11) < row.length)
                depFlag = row[orderSave.indexOf(11)];
            if(depFlag.equals("")){
                if((refFlag.equals("-1"))){
                    depFlag = "1";
                }
                else{
                    HashSet<String> analyseSet = analyseSum.get(11);
                    String analyseMessage = "Note: Empty value for 'Initialize Dependency' in " + lineCount + suffix + " row!";
                    analyseSet.add(analyseMessage);
                    analyseSum.put(11, analyseSet);
                }
            }else if("Yes".equals(depFlag))
                depFlag = "Y";
            else if("No".equals(depFlag))
                depFlag = "N";
            String startDate = "";
            if(orderSave.indexOf(12) < row.length)
                startDate = row[orderSave.indexOf(12)];
            String startFlag = "";
            if(orderSave.indexOf(13) < row.length)
                startFlag = row[orderSave.indexOf(13)];
            if(startFlag.contains("fter"))
                startFlag = "After";
            else if(startFlag.contains("rior"))
                startFlag = "Prior";
            else if(refFlag.equals("-1"))
                startFlag = "NULL";

            String scheduleDate = "";
            if(orderSave.indexOf(14) < row.length)
                scheduleDate = row[orderSave.indexOf(14)];
            String scheduleFlag = "";
            if(orderSave.indexOf(15) < row.length)
                scheduleFlag = row[orderSave.indexOf(15)];
            if(scheduleFlag.contains("fter"))
                scheduleFlag = "After";
            else if(scheduleFlag.contains("rior"))
                scheduleFlag = "Prior";
            else if(refFlag.equals("-1"))
                scheduleFlag = "NULL";

            if(startDate.equals("")){
                HashSet<String> analyseSet = analyseSum.get(12);
                String analyseMessage = "Note: Empty value for 'Start Date' in " + lineCount + suffix + " row!";
                analyseSet.add(analyseMessage);
                analyseSum.put(12, analyseSet);
                startDate = "NULL";
            }
            if(scheduleDate.equals("")){
                HashSet<String> analyseSet = analyseSum.get(14);
                String analyseMessage = "Note: Empty value for 'Completion Date' in " + lineCount + suffix + " row!";
                analyseSet.add(analyseMessage);
                analyseSum.put(14, analyseSet);
                scheduleDate = "NULL";
            }
            if(startFlag.equals("")){
                HashSet<String> analyseSet = analyseSum.get(13);
                String analyseMessage = "Note: Empty value for 'Start prior to or after' in " + lineCount + suffix + " row!";
                analyseSet.add(analyseMessage);
                analyseSum.put(13, analyseSet);
            }
            if(scheduleFlag.equals("")){
                HashSet<String> analyseSet = analyseSum.get(15);
                String analyseMessage = "Note: Empty value for 'Schedule prior to or after' in " + lineCount + suffix + " row!";
                analyseSet.add(analyseMessage);
                analyseSum.put(15, analyseSet);
            }
            if(!startDate.equals("") && !scheduleDate.equals("") && !startFlag.equals("") && !scheduleFlag.equals("")){
                if((startDate != "NULL" && scheduleDate != "NULL") && (startFlag.equals("Prior") && scheduleFlag.equals("Prior") && Integer.parseInt(startDate) < Integer.parseInt(scheduleDate)) || (startFlag.equals("After") && scheduleFlag.equals("After") &&  Integer.parseInt(scheduleDate) < Integer.parseInt(startDate)) || (startFlag.equals("After") && scheduleFlag.equals("Prior"))){
                    HashSet<String> analyseSet = analyseSum.get(15);
                    String analyseMessage = "Note: Schedule Completion should be greater than Schedule Start in " + lineCount + suffix + " row!";
                    analyseSet.add(analyseMessage);
                    analyseSum.put(15, analyseSet);
                }
            }
            String startRem = null, completionRem = null;
            if(orderSave.size()>16){
                startRem = "";
                if(orderSave.indexOf(16) < row.length)
                    startRem = row[orderSave.indexOf(16)];
                completionRem = "";
                if(orderSave.indexOf(17) < row.length)
                    completionRem = row[orderSave.indexOf(17)];
                
                if(!startRem.equals("") && !completionRem.equals("")){
                    if(Integer.parseInt(startRem) < Integer.parseInt(completionRem)){
                        HashSet<String> analyseSet = analyseSum.get(17);
                        String analyseMessage = "Note: Reminder Schedule Completion should be greater than Reminder Schedule Start in " + lineCount + suffix + " row!";
                        analyseSet.add(analyseMessage);
                        analyseSum.put(17, analyseSet);
                    }
                }
                if(startRem == "" || startRem.equals("NULL"))
                    startRem = "-1";
                if(completionRem == "" || completionRem.equals("NULL"))
                    completionRem = "-1";
            }
            String webUrl = null;
            if(orderSave.indexOf(18) != -1){
                webUrl = "";
                if(orderSave.indexOf(18) < row.length)
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
    // Displaying analysis
    if(action.equals("analyse")){
        for (Map.Entry<Integer, HashSet<String>> entry : analyseSum.entrySet()) {
            int key = entry.getKey();
            HashSet<String> sumSet = entry.getValue();
            int countEmpty = 0, schComp = 0, remSchComp = 0;
            boolean onceEmpty = false, onceComp = false, onceSchComp = false;
            if (!sumSet.isEmpty()) {
                for (String str : sumSet) {
                    if (str.indexOf("Empty value for") != -1) {
                        countEmpty++;
                    } else if (str.indexOf("Schedule Completion should be greater") != -1) {
                        schComp++;
                    } else if (str.indexOf("Reminder Schedule Completion should be greater") != -1) {
                        remSchComp++;
                    }
                }
            }
            if(!sumSet.isEmpty()){
                %>
                <div class="key" onclick="toggleStrings(this)">
                    <p> <i style="font-size:24px" class="fa">&#xf0a9;</i>&nbsp;Following issues were observed in&nbsp;<span class="headInfo">'<%= orderInfoMap.get(key) %>'</span> <span class="tooltip">Click to expand</span>
                    </p>
                </div>
                <div class="strings">
                    <ol>
                    <% for (String str : sumSet) {
                        if(countEmpty > 3 && !onceEmpty){
                            onceEmpty = true;
                            %>
                            <li>Note: Multiple empty values present in '<%= orderInfoMap.get(key) %>'.</li>
                            <%
                        }else if(schComp > 3 && !onceComp){
                            onceComp = true;
                            %>
                            <li>Note: Schedule Completion should be greater than Schedule Start in '<%= orderInfoMap.get(key) %>'.</li>
                            <%
                        }else if(remSchComp > 3 && !onceSchComp){
                            onceSchComp = true;
                            %>
                            <li>Note: Reminder Schedule Completion should be greater than Reminder Schedule Start in '<%= orderInfoMap.get(key) %>'.</li>
                            <%
                        }else if(onceEmpty || onceComp || onceSchComp){
                            //do nothing - skip
                        }
                        else{
                            %>
                            <li><%= str %></li>
                            <%
                        }
                        %>
                    <% } %>
                    </ol>
                </div>
                <%
            }
        }
    }
    // Generating SQL file
    else if(action.equals("generateTaskSQL")){
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
<script>
    function toggleStrings(element) {
        var stringsElement = element.nextElementSibling;
        //when click on p tag it'll toggle the show class
        stringsElement.classList.toggle("show");
        var pTag = element.querySelector('p');
        var tooltip = pTag.querySelector('.tooltip');
        var isExpanded = stringsElement.classList.contains("show");
        if (isExpanded)
            pTag.querySelector('.tooltip').textContent = 'Click to collapse';
        else 
            pTag.querySelector('.tooltip').textContent = 'Click to expand';
    }
</script>
</html>