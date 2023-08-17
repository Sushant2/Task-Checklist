<!DOCTYPE html>
<html>

<head>
    <title>Task Checklist Automation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f7f7f7;
        }

        .container {
            max-width: 400px;
            margin: 50px auto;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            background-color: #ffffff;
        }

        .title {
            text-align: center;
            font-size: 25px;
            font-weight: bold;
            margin-bottom: 30px;
            color: #333333;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-label {
            font-size: 14px;
            font-weight: bold;
            color: #555555;
        }

        .form-input {
            width: 100%;
            padding: 10px;
            border: 1px solid #dddddd;
            border-radius: 5px;
            font-size: 14px;
            color: #333333;
        }

        .form-submit {
            background-color: #34a4d8;
            color: white;
            padding: 12px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            width: 100%;
            font-size: 16px;
            font-weight: bold;
            transition: background-color 0.2s ease;
        }

        .form-submit:hover {
            background-color: #1b8fc8;
        }

        .form-analyse {
            background-color: #d9922b;
            color: white;
            padding: 12px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            width: 100%;
            font-size: 16px;
            font-weight: bold;
            transition: background-color 0.2s ease;
        }

        .form-analyse:hover {
            background-color: #c37c27;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="title">Task Checklist Automation</div>
        <form name="myForm" action="processChecklist.jsp" enctype="multipart/form-data" method="POST">
            <div class="form-group">
                <label class="form-label">Upload your checklist file:</label>
                <input class="form-input" name="file" type="file">
            </div>
            <div class="form-group">
                <input type="hidden" id="actAnalyse" name="act" value="analyse">
                <input onclick='sendAtt(document.getElementById("actAnalyse").value);' class="form-analyse"
                    type="submit" value="Analyse">
            </div>
            <div class="form-group">
                <input type="hidden" id="actGenerateSQL" name="act" value="generateTaskSQL">
                <input onclick='sendAtt(document.getElementById("actGenerateSQL").value);' class="form-submit"
                    type="submit" value="Generate SQL">
            </div>
        </form>
    </div>
</body>
<script>
    function sendAtt(myAct) {
        myForm.action = "processChecklist.jsp?act=" + myAct;
        myForm.submit();
    }
</script>

</html>
