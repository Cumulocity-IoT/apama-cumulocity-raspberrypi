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
# Get all the Dashboard registered to the Cumulocity tenant
param($tenantName="", $username="", $password="")

if ($tenantName -eq "" -Or $username -eq "" -Or $password -eq "" -Or $dashboardName -eq "") {
	echo "  Syntax : "
	echo "           ListDashboards [tenantName] [username] [password]"
	exit
}

# Get all of the Dashboards which have been uploaded to the Cumulocity tenant
$url = "https://$tenantName.cumulocity.com/inventory/managedObjects?query=c8y_Dashboard.name eq '*'"

# Encrypt username and password
$base64Authentication = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
Try {
    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64Authentication)} -uri $url 
}
Catch [Exception] {
    Write-Host "Error: "$_.Exception.Message -ForegroundColor Red
    exit
}

$response = $response.managedObjects | Select -Property c8y_Dashboard

if ($response) {
    echo ""
    echo "List of dashboards in tenant '$tenantName'"
    echo "--------------------------------------------------"
    foreach ($dashboard in $response) {
         echo $dashboard.c8y_Dashboard.name
    }
} else {
    echo "Tenant '$tenantName' does not contains any dashboards"
}
