
if (!( $env:Subscription)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable Subscription"
    exit 1
}
if (!( $env:ContainerResourceGroupName)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable ContainerResourceGroupName"
    exit 1
}
if (!( $env:ContainerGroupName)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable ContainerGroupName"
    exit 1
}
if (!( $env:DNSZoneResourceGroupName)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable DNSZoneResourceGroupName"
    exit 1
}
if (!( $env:DNSZone)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable DNSZone"
    exit 1
}
if (!( $env:DNSRecord)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable DNSRecord"
    exit 1
}
if (!( $env:ClientID)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable ClientID"
    exit 1
}
if (!( $env:SecureStringPwd)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable SecureStringPwd"
    exit 1
}
if (!( $env:TenantID)) {
    Write-Output "Can't continue. Could Not Find the Environment Variable TenantID"
    exit 1
}
try{
    $SecureStringPwd = $env:SecureStringPwd | ConvertTo-SecureString -AsPlainText -Force
    $pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:ClientID, $SecureStringPwd
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $env:TenantID -WarningAction Ignore -ErrorAction Stop -ErrorVariable MyError
    }
catch [System.Management.Automation.ActionPreferenceStopException] {
    Write-Output "Error: Cannot continue if you don't provide authentication."
    exit 1
    }

catch {
    Write-Output "$($MyError)"
    exit 1
    }

try {
    Write-Output $env:Subscription
    Set-AzContext -Subscription $env:Subscription -ErrorAction Stop -ErrorVariable MyError
    }
catch [System.Management.Automation.ActionPreferenceStopException] {
    Write-Output "Error: No valid Azure Subscription Name provided so I couldn't set Context."
    exit 1
    }
catch {
    Write-Output "Error: $($MyError)"
    exit 1
    }


if ($env:ContainerResourceGroupName) {
    $null = Get-AzResourceGroup -Name $env:ContainerResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable ContainerResourceGroupNamePresent
    if ($ContainerResourceGroupNamePresent) {
        Write-Output "Error: Resource group name provided for Container could not be found on this Azure Subscription."
        exit 1        
    }
    else
    {
        $null = Get-AzContainerGroup -ResourceGroupName $env:ContainerResourceGroupName -Name $env:ContainerGroupName -ErrorAction SilentlyContinue -ErrorVariable ContainerGroupPresent
        if ($ContainerGroupPresent){
            # ContainerGroup doesn't exist
            Write-Output "Error: Container group could not be found on this Azure Subscription."
            exit 1        
        }
    }
}
    
if ($env:DNSZoneResourceGroupName) {
    $null = Get-AzResourceGroup -Name $env:DNSZoneResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable DNSZoneResourceGroupNamePresent
    if ($DNSZoneResourceGroupNamePresent) {
        Write-Output "Error: Resource group provided for DNS Zone could not be found on this Azure Subscription."
        exit 1        
    }
}
    
#Get ContainerInstance IP 
$CI_IP=$(Get-AzContainerGroup -ResourceGroupName $env:ContainerResourceGroupName -Name $env:ContainerGroupName).IPAddressIP
Write-Output "Container Group has IP address $($CI_IP)"

if (Get-AzPrivateDnsZone -Name $env:DNSZone -ResourceGroupName $env:DNSZoneResourceGroupName) {
    if (Get-AzPrivateDnsRecordSet -Name $env:DNSRecord -ZoneName $env:DNSZone -ResourceGroupName $env:DNSZoneResourceGroupName -RecordType A -ErrorAction SilentlyContinue){
        Write-output "Update the existing DNS Record entry"
        $RecordSet = Get-AzPrivateDnsRecordSet -Name $env:DNSRecord -ZoneName $env:DNSZone -ResourceGroupName $env:DNSZoneResourceGroupName -RecordType A
        $RecordSet.Ttl = "60"
        $RecordSet.Records = $null
        Add-AzPrivateDnsRecordConfig -RecordSet $RecordSet -Ipv4Address $CI_IP
        Set-AzPrivateDnsRecordSet -RecordSet $RecordSet
    }
    else
    {
        Write-output "Create a new DNS Record"
        $RecordSet = New-AzPrivateDnsRecordSet -Name $env:DNSRecord -RecordType A -ResourceGroupName $env:DNSZoneResourceGroupName -TTL 60 -ZoneName $env:DNSZone -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $CI_IP)
    }
}
else
{
    Write-Output "Error: Private DNS Zone could not be found on provided Resource Group."
    exit 1        
}