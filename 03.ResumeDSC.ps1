Start-DscConfiguration -ComputerName localhost -Wait -Force -Verbose -path "$PSScriptRoot\Config" -Debug

$RebootRequired = Get-DscConfigurationStatus

if($RebootRequired.RebootRequested -eq $true) {
    Restart-Computer
}

 