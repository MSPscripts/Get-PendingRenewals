#Requires -Modules MSonline
[CmdletBinding()]
param (
    #Integer for the number of days out to look for expiring subscriptions. Defaults to 30.
    [Parameter()]
    [int32]$DaysAway = 30,
    #Lets you run it and only export to CSV
    [Parameter()]
    [switch]$Quiet = $false,
    #Lets user specify path for the CSV but default to working directory
    [Parameter()]
    [string]$Path,
    [Parameter()]
    [switch]$MyTenant = $false
)

#Have to connect to partner tenant with MSOnline module

try {
    Connect-MSOLService -ErrorAction Stop
    }
    catch {
        Write-Error "You didn't get signed in bro. Do you have the MSOnline module installed?"
        Exit
    }
    
    #Get all our DAP'd clients
   if (!$MyTenant){
    $alltenants = Get-MsolPartnerContract -All
    }
    #this is for the filename
    $now = Get-Date -Format "MMddyyHHmms"
    
    if ($path) {
        Write-Output "Writing to output file $path"
    }
    else {
        $Path = "ExpiringSubscriptions$($now).csv"
        Write-Output "Writing to output file $path"
    }

    #The idea here is to spit out the client name and expiring (within 30 days) subscription, where applicable. Filtering free SKUs with the "less than 5000 total licenses" bit
    if (!$MyTenant){
        foreach ($client in $alltenants)
            {
                $ClientInfo = Get-MsolCompanyInformation -TenantId $($client.tenantid)
                $Expiring = $null
                $Expiring = Get-MsolSubscription -TenantId $($client.tenantid) `
                | Where-Object {(($_.status -notlike "suspended") -or ($_.status -notlike "locked*" ) ) `
                -and ($_.NextLifecycleDate -lt (Get-Date).adddays($DaysAway)) `
                -and ($_.totallicenses -lt "5000")}
        
                #Since the "SKU" part can have multiple items, I had to iterate creating the custom object for each in order
                #to get it to export to CSV without just showing up as "[System.Object]" in there.
        
                if ($Expiring) {
                    foreach ($SKU in $Expiring){
                    $Export = [PSCustomObject]@{
                            "Customer" = $ClientInfo.DisplayName
                            "SKU" = $SKU.Skupartnumber
                            "Quantity" = $SKU.totallicenses
                            "Expiry" = $SKU.NextLifecycleDate
                        }
        
                        $Export | Export-Csv -NoTypeInformation -Path $Path -Append
                    }
                    #Not strictly necessary, just thought it was nice to tee it to the session as well as the file.
                    if (!$Quiet) {
                    Write-Output "Customer:",$ClientInfo.displayname
                    Write-Output "Expiring Subscriptions: $($Expiring.Skupartnumber)"
                    }
                }
            }
        }

        else {
            $Expiring = $null
            $Expiring = Get-MsolSubscription `
            | Where-Object {(($_.status -notlike "suspended") -or ($_.status -notlike "locked*" ) ) `
                -and ($_.NextLifecycleDate -lt (Get-Date).adddays($DaysAway)) `
                -and ($_.totallicenses -lt "5000")}
                
            if ($Expiring) {
                    foreach ($SKU in $Expiring){
                    $Export = [PSCustomObject]@{
                            "SKU" = $SKU.Skupartnumber
                            "Quantity" = $SKU.totallicenses
                            "Expiry" = $SKU.NextLifecycleDate
                        }
        
                        $Export | Export-Csv -NoTypeInformation -Path $Path -Append
                    }
                    #Not strictly necessary, just thought it was nice to tee it to the session as well as the file.
                    if (!$Quiet) {
                    Write-Output "Expiring Subscriptions: $($Expiring.Skupartnumber)"
                        }
                }
            }
