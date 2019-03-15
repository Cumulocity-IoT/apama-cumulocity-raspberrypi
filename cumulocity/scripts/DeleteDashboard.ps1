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
# DeleteDashboard (by dashboard name) from Cumulocity
param($tenantName = "", $username="", $password="", $dashboardName="")

if ($tenantName -eq "" -Or $username -eq "" -Or $password -eq "" -Or $dashboardName -eq "") {
	echo "  Syntax : "
	echo "           DeleteDashboard [tenantName] [username] [password] [dashboardName]"
	exit
}

# Check to see if a dashboard with the name $newDashboardName exists
$url = "https://$tenantName.cumulocity.com/inventory/managedObjects?query=c8y_Dashboard.name eq '${dashboardName}'"

# Encrypt username and password
$base64Authentication = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
Try {
    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -uri $url 
}
Catch [Exception] {
    Write-Host "Error: "$_.Exception.Message -ForegroundColor Red;
    exit
}

if ($response.managedObjects) {

    # Get all of the dashboards which match the $dashboardName
    $url = "https://$tenantName.cumulocity.com/inventory/managedObjects?query=c8y_Dashboard.name eq '${dashboardName}'"

    Try {
        $response = Invoke-RestMethod -Method GET -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -uri $url 
    }
    Catch [Exception] {
        Write-Host "Error: "$_.Exception.Message -ForegroundColor Red
        exit
    }

    if ($response) {
	    $dashboard = $response.managedObjects | Select  id -first 1
    	$dashboardId = $dashboard.id;

    	$url = "https://$tenantName.cumulocity.com/inventory/managedObjects/$dashboardId"

	    # encrypt username and password
		$base64Authentication = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

		$response = Invoke-RestMethod -Method DELETE -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -uri $url

		if ($RestError) {
		    $HttpStatusCode = $RestError.ErrorRecord.Exception.Response.StatusCode.value__
			$HttpStatusDescription = $RestError.ErrorRecord.Exception.Response.StatusDescription
			Throw "Http Status Code: $($HttpStatusCode) `nHttp Status Description: $($HttpStatusDescription)"
		}
		else {
		    if ($response) {
			    echo $response
            }
			else {
			    echo "DashboardId: '$dashboardId', Name '$dashboardName' has been deleted";
			}
		}
    }
} else {
    Write-Host "Error: Tenant '$tenantName' does not contain a dashboard named '$dashboardName'" -ForegroundColor Red
}