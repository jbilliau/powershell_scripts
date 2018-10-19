$ExchangeServer = "EMAIL SERVER"
$FROM_ADDR = "WHERE YOUR EMAIL IS COMING FROM"   # From address used to send email on completion of new user build
$TO_ADDR = "PUT YOUR EMAIL OR IT DEPT EMAIL HERE"   # To address used to send email on completion of new user build
$Current = Get-Date -uFormat %B

#List out as many OU's as you'd like
$OUs = 
    'OU=PUT_YOUR_OU_HERE,DC=YOUR_DOMAIN,DC=net',
    'OU=PUT_YOUR_OU_HERE,DC=YOUR_DOMAIN,DC=net',
    'OU=PUT_YOUR_OU_HERE,DC=YOUR_DOMAIN,DC=net',
    'OU=PUT_YOUR_OU_HERE,DC=YOUR_DOMAIN,DC=net',
    'OU=PUT_YOUR_OU_HERE,DC=YOUR_DOMAIN,DC=net',
    'OU=PUT_YOUR_OU_HERE,OU=Users,OU=IT,DC=YOUR_DOMAIN,DC=net'

$STYLE = " 
        <STYLE>  
            BODY {  
                font-family: Verdana, Arial, Helvetica, sans-serif; 
                font-size: 13px; 
            } 
            TABLE {  
                border-width: 1px;  
                border-style: solid;  
                border-color: black;  
                border-collapse: collapse;  
            } 
            TH {  
                border-width: 1px; 
                padding: 5px; 
                border-style: solid; 
                border-color: black; 
                background-color: #005DAB; 
                color: #FFFFFF  
            } 
            TD {  
                border-width: 1px; 
                padding: 5px; 
                border-style: solid; 
                border-color: black; 
                background-color: #D2E6F4  
            } 
            .sizeRed {  
                background-color: Red  
            } 
            .sizeYellow {  
                background-color: Yellow 
            } 
            .summaryHeading { 
                font-style: italic; 
                font-weight: bold; 
                background-color: #A0A0A0; 
            } 
            .summaryLine { 
                background-color: #A0A0A0; 
                text-align: right; 
            } 
        </STYLE>"

Function SendHTMLEmail 
{ 
    Param( 
        [array]$ManagerList
    ) 
     
    $manager_html = $ManagerList | ConvertTo-Html -Fragment 
         
    $htmlBody=
	"
    <HTML> 
        <HEAD> 
            $STYLE 
        </HEAD> 
        <BODY> 
           This is an automated message for notification purposes.<br /><br />
           The following ($count)users have these <b>corresponding managers</b> defined on their account. These managers are <u>no longer are active</u>.  Please identify the correct
		   managers and address the issue.  <br /><br />
           $manager_html<br />
		  
        </BODY> 
    </HTML>
	"
  Send-MailMessage -From $FROM_ADDR -To $TO_ADDR -Subject "Active Directory Users-Manager Crosscheck - $Current Report" -Body $htmlBody -SmtpServer $ExchangeServer -BodyAsHtml -ErrorAction SilentlyContinue 
 }

$ListofOUs = $OUs | ForEach-Object {
get-aduser -searchbase $PSItem  -filter * -Properties manager, DisplayName
}	

#Create the empty array
$ManagerList = @()

#Loop through each OU and get users
Foreach($aduser in $ListofOUs)
{
    if($aduser.manager -ne $null)
    {	
        $manager = Get-ADUser -filter {Distinguishedname -eq $aduser.manager} -properties DisplayName
		
        if($manager.enabled -eq $false)
        {			
		   # Adds values to PS Custom Object
               $ManagerList += New-Object -TypeName psobject -Property @{
               #User = $aduser.SamAccountName
			   User = $aduser.Displayname + "--->"			   
			   #Manager = $manager.SamAccountName			  
			   Manager = $manager.Displayname
			  															 }																	
        } 	
    }
} 
#Orders the email headers
$ManagerList = $ManagerList | select User, Manager
#Counts the users
$count = $ManagerList.count

#send the report
SendHTMLEmail $ManagerList 