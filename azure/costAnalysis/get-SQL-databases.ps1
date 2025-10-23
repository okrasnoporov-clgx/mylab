<#
.SYNOPSIS
  Collects a list of SQL Servers and SQL Databases across multiple subscriptions.

.DESCRIPTION
  The script takes an array of subscription IDs or Names,
  switches context to each subscription,
  and retrieves SQL Server and SQL Database resources.
  It prints the result to the console and optionally saves it to CSV.

.NOTES
  AI Generated. Requires Az PowerShell module (Install-Module Az) and additional testing.
#>

# --- User Settings ---
# List of subscriptions. You can specify SubscriptionId or SubscriptionName.
$subscriptions = @(
    "digital-dev-001",
    "digital-dev-002" 
)

# Output file for CSV (set to $null to disable saving)
$outputCsv = "$PSScriptRoot\sql-resources-report.csv"

# # Azure login (if not already authenticated)
# try {
#     if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
#         Write-Host "Az module not found. Installing..." -ForegroundColor Yellow
#         Install-Module Az -Scope CurrentUser -Force -AllowClobber
#     }
#     # Check if already logged in
#     $ctx = Get-AzContext -ErrorAction SilentlyContinue
#     if (-not $ctx) {
#         Write-Host "Signing in to Azure..." -ForegroundColor Cyan
#         Connect-AzAccount -ErrorAction Stop
#     }
# }
# catch {
#     Write-Error "Failed to connect to Azure or install Az module: $_"
#     exit 1
# }

# Collection for final results
$results = @()

foreach ($sub in $subscriptions) {
    Write-Host "==============================" -ForegroundColor DarkCyan
    Write-Host "Processing subscription: $sub" -ForegroundColor Cyan

    try {
        # Try selecting subscription by ID, if fails — try by Name
        try {
            Select-AzSubscription -SubscriptionId $sub -ErrorAction Stop
            $selected = Get-AzContext
        }
        catch {
            Select-AzSubscription -SubscriptionName $sub -ErrorAction Stop
            $selected = Get-AzContext
        }

        Write-Host "Current context: $($selected.Subscription)" -ForegroundColor Green

        # --- Preferred way: Use dedicated SQL cmdlets ---
        $servers = @()
        try {
            $servers = Get-AzSqlServer -ErrorAction Stop
        }
        catch {
            Write-Warning "Get-AzSqlServer returned no data or failed: $_"
            $servers = @()
        }

        if ($servers.Count -eq 0) {
            Write-Host "No SQL servers found (Get-AzSqlServer returned 0)." -ForegroundColor Yellow
        }

        foreach ($srv in $servers) {
            Write-Host ""
            Write-Host "Server: $($srv.ServerName) (ResourceGroup: $($srv.ResourceGroupName))" -ForegroundColor Magenta

            # Get databases for the server
            $dbs = @()
            try {
                $dbs = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to get databases for $($srv.ServerName): $_"
                $dbs = @()
            }

            if ($dbs.Count -eq 0) {
                Write-Host "  No databases found." -ForegroundColor Yellow
            }

            foreach ($db in $dbs) {
                $out = [PSCustomObject]@{
                    SubscriptionId    = $selected.Subscription.Id
                    SubscriptionName  = $selected.Subscription.Name
                    ServerName        = $srv.ServerName
                    ServerResourceId  = $srv.Id
                    ServerLocation    = $srv.Location
                    ResourceGroup     = $srv.ResourceGroupName
                    DatabaseName      = $db.DatabaseName
                    DatabaseStatus    = $db.Status
                    Edition           = $db.Edition
                    ServiceObjective  = ($db.CurrentServiceObjectiveName -as [string])
                    MaxSizeBytes      = $db.MaxSizeBytes
                }
                $results += $out

                # Print to console
                Write-Host "  DB: $($db.DatabaseName)  Status: $($db.Status)  Edition: $($db.Edition)"
            }
        }

        # --- Alternative: fallback to Get-AzResource if SQL cmdlets returned nothing ---
        if ($servers.Count -eq 0) {
            Write-Host "Trying fallback search with Get-AzResource..." -ForegroundColor Cyan
            try {
                $sqlResources = Get-AzResource -ResourceType "Microsoft.Sql/servers","Microsoft.Sql/servers/databases" -ErrorAction Stop
            }
            catch {
                Write-Warning "Get-AzResource failed: $_"
                $sqlResources = @()
            }

            foreach ($res in $sqlResources) {
                # Server resource
                if ($res.ResourceType -eq "Microsoft.Sql/servers") {
                    Write-Host "Found server resource: $($res.Name) (RG: $($res.ResourceGroupName))"
                }
                # Database resource
                if ($res.ResourceType -eq "Microsoft.Sql/servers/databases") {
                    $dbOut = [PSCustomObject]@{
                        SubscriptionId    = $selected.Subscription.Id
                        SubscriptionName  = $selected.Subscription.Name
                        ServerName        = $res.Properties.serverName
                        ServerResourceId  = ($res.Id -split "/databases/")[0]
                        ServerLocation    = $res.Location
                        ResourceGroup     = $res.ResourceGroupName
                        DatabaseName      = $res.Name
                        DatabaseStatus    = ($res.Properties.status -as [string])
                        Edition           = ($res.Properties.edition -as [string])
                        ServiceObjective  = ($res.Properties.currentServiceObjectiveName -as [string])
                        MaxSizeBytes      = ($res.Properties.maxSizeBytes -as [string])
                    }
                    $results += $dbOut
                    Write-Host "  DB: $($res.Name) (type: Get-AzResource)" -ForegroundColor Magenta
                }
            }
        }

    }
    catch {
        Write-Error ("Error while processing subscription {0}: {1}" -f $sub, $_)
        continue
    }
}

# --- Final output ---
if ($results.Count -gt 0) {
    Write-Host "`n===== Final result: Found SQL resources =====" -ForegroundColor Green
    $results | Select-Object SubscriptionName, SubscriptionId, ResourceGroup, ServerName, DatabaseName, Edition, DatabaseStatus, ServiceObjective, MaxSizeBytes |
        Format-Table -AutoSize

    # Save to CSV if configured
    if ($outputCsv) {
        try {
            $results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
            Write-Host "Result saved to: $outputCsv" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to save CSV: $_"
        }
    }
}
else {
    Write-Host "No SQL resources found." -ForegroundColor Yellow
}
