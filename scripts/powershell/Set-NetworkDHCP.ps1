# Active le mode DHCP sur toutes les interfaces réseau actives
Get-NetIPInterface | Where-Object { $_.Dhcp -eq "Disabled" -and $_.InterfaceOperationalStatus -eq "Up" } | ForEach-Object {
    Set-NetIPInterface -InterfaceIndex $_.InterfaceIndex -Dhcp Enabled
}
