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
# Get a Dashboard (by dashboard name) from Cumulocity
param($tenantName="", $username="", $password="", $dashboardName="", $outputJSONFileName="")

if ($tenantName -eq "" -Or $username -eq "" -Or $password -eq "" -Or $dashboardName -eq "") {
	echo "  Syntax : "
	echo "           GetDashboard [tenantName] [username] [password] [dashboardName]"
	exit
}

# Set the default .json file if it hasn't been provided
if ($outputJSONFileName -eq "") {
	$outputJSONFileName = $dashboardName + ".json"
}

# Get all of the ManagedObjectIds which match the dashboardName
$url = "https://$tenantName.cumulocity.com/inventory/managedObjects?query=c8y_Dashboard.name eq '${dashboardName}'"

# Encrypt username and password
$base64Authentication = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
Try {
    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -uri $url 
}
Catch [Exception] {
    Write-Host "Error: "$_.Exception.Message -ForegroundColor Red
    exit
}

# Need to use an exclusions list as we need to ensure that we keep 'c8y_Dashboard!device!<deviceId' propertyName in the output .json
$response = $response.managedObjects | Select -Property * -ExcludeProperty assetParents, childAssets, additionParents, childAdditions, childDevices, creationTime, deviceParents, lastUpdated, owner, self, c8y_Global

if ($response) {
    # Get the dashboardId
    $x = $response | ConvertTo-Json -Depth 100
    $found = $x -match '\"c8y_Dashboard!device!(\d*)\"'
    if ($found) {
        $dashboardId = $matches[1]
        echo "ManagedObjectId is '$dashboardId'"
    }

	# Get the dashboard Name
	$dashboardName = $response.c8y_Dashboard.name;
    echo "DashboardName is '$dashboardName'"
        
    # Save the first dashboard (as multiple dashboards with the same name should be identical) as a sample into a .json file
    $response | Select -Property * -ExcludeProperty id -first 1 | ConvertTo-Json -Depth 20 | Out-file -filepath $outputJSONFileName
    echo "JSON data has been saved to file '$outputJSONFileName'"

} else {
    Write-Host "Error: Tenant '$tenantName' does not contain dashboard '$dashboardName'" -ForegroundColor Red
}