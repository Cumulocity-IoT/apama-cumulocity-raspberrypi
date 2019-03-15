<#
 * Copyright (c) 2015-2018 Software AG, Darmstadt, Germany and/or its licensors.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
#>
# Upload a new dashboard to Cumulocity (linked to a pre configured [live | simulator] deviceId which will provide the data)
param($tenantName = "", $username="", $password="", $newDashboardName="", $sourceJSONFile="", $deviceId="")

if ($tenantName -eq "" -Or $username -eq "" -Or $password -eq "" -Or $newDashboardName -eq "" -Or $sourceJSONFile -eq "" -Or $deviceId -eq "") {
	echo '  Syntax : '
	echo '           UploadDashboard [tenantName] [username] [password] [newDashboardName] [sourceJSONFile] [deviceId]'
    echo ''
    echo "  To find the deviceId, log into Cumulocity and go to 'Device Management'"
    echo "     Click on 'All devices'"
    echo "     The deviceId is listed in the 'SYSTEM ID' column for your device" 
    exit
}

# Check the $sourceJSONFile exists
if (-not (Test-Path $sourceJSONFile)) {
    Write-Host "Error: File '$sourceJSONFile' does not exist" -ForegroundColor Red;
    exit
}

# Encrypt username and password
$base64Authentication = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))


# Check to see if a dashboard with the name $newDashboardName already exists
$checkDashboardExistsURL = "https://$tenantName.cumulocity.com/inventory/managedObjects?query=c8y_Dashboard.name eq '${newDashboardName}'"
Try {
    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -uri $checkDashboardExistsURL 
}
Catch [Exception] {
    Write-Host "Error: "$_.Exception.Message -ForegroundColor Red;
    exit
}

$response = $response.managedObjects | Select -Property id

if ($response) {
    Write-Host "Error: Tenant '$tenantName' already contains a dashboard named '$newDashboardName'" -ForegroundColor Red
    exit
}

# Upload the new dashboard using the sourceJSONFile
$uploadDashboardURL = "https://$tenantName.cumulocity.com/inventory/managedObjects/"

# Read in the json from a supplied file
$sourceJSON = (Get-Content $sourceJSONFile) | ConvertFrom-Json

# Update the dashboard name to be the $newDashboardName
$sourceJSON.c8y_Dashboard.name = $newDashboardName

# Expand the Powershell objects into full JSON
$sourceJSON = $sourceJSON | ConvertTo-Json -Depth 100

# Set the simulation deviceId and deviceName
$searchExpression1 = '\"device\":[\s|\S]*?\"name\":\s*\"([\S|\s]*?)\",[\s|\S]*?\"id\":[\s|\S]*?\"([\s|\S]*?)\"[\s|\S]*?}'
$replacementString1 = '"device": { "name":"' + $deviceName + '", "id":"' + $deviceId + '"}'
$sourceJSON = $sourceJSON -replace $searchExpression1, "$replacementString1"
    
$searchExpression2 = '\"__target\":[\s|\S]*?{[\s|\S]*?\"name\":[\s|\S]*?\"([\s|\S]*?)\",[\s|\S]*?\"id\":[\s|\S]*?\"([\s|\S]*?)\"[\s|\S]*?}'
$replacementString2 = '"__target": { "name":"' + $deviceName + '", "id":"' + $deviceId + '"}'
$sourceJSON = $sourceJSON -replace $searchExpression2, "$replacementString2"
    
$searchExpression3 = '\"c8y_Dashboard!device!([\s|\S]*?)\"'
$replacementString3 = '"c8y_Dashboard!device!' + $deviceId + '"'
$sourceJSON = $sourceJSON -replace $searchExpression3, "$replacementString3"

Try {
    # Upload the new dashboard
    $response = Invoke-RestMethod -uri $uploadDashboardURL -Method POST -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -Body $sourceJSON -ContentType "application/json" 
}
Catch [Exception] {
    Write-Host "Error: "$_.Exception.Message -ForegroundColor Red
    exit
}

if ($response) {
	echo $response
}
else {
	echo "New Dashboard '$newDashboardName' has been uploaded and linked to simulation deviceId '$deviceId'"
}
