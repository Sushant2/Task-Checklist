<!DOCTYPE html>
<html>

<head>
    <title>Secondary Checklist Automation</title>
    <link id="fav" rel="icon" type="image/x-icon" href="checklistFavicon.png">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">          
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
            background-color: #1b8fc8;
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
            background-color: #186db3;
        }

        .form-analyse {
            background-color: #48b97b;
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
            background-color: #149e52;
        }
        .bulb-container {
            position: fixed;
            top: 20px;
            right: 20px;
            cursor: pointer;
        }
        .popup {
            position: fixed;
            top: 50px;
            right: 70px;
            width: 200px;
            background-color: #ffffff;
            border: 1px solid #dddddd;
            border-radius: 5px;
            padding: 10px;
            display: none;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            z-index: 1;
        }
        .bulb-icon {
            color: #000000; /* Change to the desired color */
        }
        li {
            font-size: 15px;
            line-height: 1;
            margin-bottom: 5px;
            color: #333;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="title">Secondary Checklist Automation</div>
        <form name="myForm" action="processChecklist.jsp" enctype="multipart/form-data" method="POST">
            <div class="form-group">
                <label class="form-label">Upload your checklist file:</label>
                <input class="form-input" name="file" type="file">
            </div>
            <div class="form-group">
                <input type="hidden" id="actAnalyse" name="act" value="analyse">
                <input onclick='return sendAtt(document.getElementById("actAnalyse").value);' class="form-analyse"
                    type="submit" value="Analyse">
            </div>
            <div class="form-group">
                <input type="hidden" id="actGenerateSQL" name="act" value="generateSecondrySQL">
                <input onclick='return sendAtt(document.getElementById("actGenerateSQL").value);' class="form-submit"
                    type="submit" value="Generate SQL">
            </div>
        </form>
    </div>
    <div class="bulb-container" onclick="togglePopup()">
        <i class='fa fa-lightbulb-o fa-2x bulb-icon'></i>
        <div class="popup" id="popup">
            <h4>Key Points To Import Checklist:</h4>
            <li>Convert your Checklist Sheet into CSV Format for compatibility.</li>
            <li>Ensure only a single row containing Column Names is present.</li>
            <li>Ensure that Checklist Sheet does not contain completely empty rows.</li>
            <li>Replace double quotes("") with single('') in Task/Item column.</li>
            <li>Replace (/) with (,).<br>
            <i>For example- Replace (Yes/No) as (Yes, No).</i>
            </li>
            <li>Remove unnecessary column(s).</li>
        </div>
    </div>    
</body>
<script>
    function sendAtt(myAct) {
        var fileInput = document.querySelector('input[name="file"]');
        if (fileInput.files.length === 0) {
            alert("Please choose a file before proceeding.");
            return false;
        }
        else{
            myForm.action = "processSecondary.jsp?act=" + myAct;
            myForm.submit();
            return true;
        }
    }
    function togglePopup() {
        var popup = document.getElementById("popup");
        popup.style.display = (popup.style.display === "block") ? "none" : "block";
    }
</script>

</html>
