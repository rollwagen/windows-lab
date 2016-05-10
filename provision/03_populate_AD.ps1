Start-Sleep 30

Add-ADGroupMember -Identity "Domain Admins" -Members "vagrant"

# Client User
Write-Host "Creating Dom Account..."
New-ADUser -Name "Dominique Broeglin" -GivenName Dominique -Surname Broeglin `
     -SamAccountName dom -UserPrincipalName dom@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PassThru | Enable-ADAccount
Write-Host "Dom Account created."

# IIS service account and DNS entry 
Write-Host "Creating IIS Account..."
New-ADUser -Name "IIS Service Account"  `
     -SamAccountName iis_svc -UserPrincipalName iis_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PasswordNeverExpires $True `
     -PassThru | Enable-ADAccount

Write-Host "IIS Account created:"
Get-ADUser iis_svc -Properties TrustedForDelegation,TrustedToAuthForDelegation,"msDS-AllowedToDelegateTo",ServicePrincipalNames

Add-DnsServerResourceRecord -ZoneName lab.local -A -Name www -IPv4Address 172.16.124.51

# Netscaler KCD service account
# Note: the account's SPN is not meaningful, it just allows us to activate delegation
Write-Host "Creating Netscaler Account..."
$User = New-ADUser -Name "Netscaler Service Account" `
     -SamAccountName ns_svc -UserPrincipalName ns_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -ServicePrincipalNames host/nsdbg `
     -PasswordNeverExpires $True `
     -PassThru

Set-ADAccountControl $User -TrustedForDelegation $False -TrustedToAuthForDelegation $True
Get-ADUser $User | Set-ADUser -Enabled $True -Replace @{
    "msDS-AllowedToDelegateTo" = "http/www.lab.local"
}

Write-Host "Netscaler Account created:"
Get-ADUser ns_svc -Properties TrustedForDelegation,TrustedToAuthForDelegation,"msDS-AllowedToDelegateTo",ServicePrincipalNames

# ADFS service account and DNS entry 
Write-Host "Creating ADFS Account..."
New-ADUser -Name "ADFS Service Account" `
     -SamAccountName adfs_svc -UserPrincipalName adfs_svc@lab.local `
     -AccountPassword (convertto-securestring "Passw0rd" -asplaintext -force) `
     -PasswordNeverExpires $True `
     -PassThru | Enable-ADAccount

Write-Host "ADFS Account created:"
Get-ADUser adfs_svc -Properties TrustedForDelegation,TrustedToAuthForDelegation,"msDS-AllowedToDelegateTo",ServicePrincipalNames
Add-ADGroupMember -Identity "Domain Admins" -Members "adfs_svc"

# Setup an external domain name
Get-DnsServerDiagnostics
Add-DnsServerPrimaryZone -Name "extlab.local" -ReplicationScope "Domain"

# External website name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name www -IPv4Address 172.16.124.12

# External aaa name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name aaa -IPv4Address 172.16.124.13

# ADFS name
Add-DnsServerResourceRecord -ZoneName extlab.local -A -Name sts -IPv4Address 172.16.124.51 # dc01 for now