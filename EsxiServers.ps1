$viserver =connect-viserver -Credential (Get-Credential -Message "Vi server credentials") -Server OC-VCSA01.hverven.local

$template = Get-Template -Name OC-LAB-S-01TemplatePatched
$osconfig = Get-OSCustomizationSpec -Name w10-TemplateProve
$vmhost = (get-vm -name OC-LAB-01).vmhost


$Servers = @()
$NumberOfServers = 10..12
foreach ($Number in $NumberOfServers) {
    $Servers += "OC-LAB-$($Number)"
}

foreach ($Server in $Servers) {
    Write-Output ("Setting up server {0}" -f $Server)
    New-VM -Name $Server -Template $template -OSCustomizationSpec $osconfig -VMHost $vmhost

}


#Credentials til Lokale Systemet
$guestcred = Get-Credential -Message "guest credentials" -UserName "Administrator"

#lopper igjennom enhver server
foreach ($Server in $Servers) {
    #Henter vmen
    $vm = get-vm -Name $Server
    #lager script/funksjon som skal kjøres på vm'en. her blir da riktig computername senere sendt til maskinen
    $Script = @"
hostname
"@
    #Hvis server ikke er på. skru den på og vent til den kommer online
    if($vm.PowerState -eq "PoweredOn"){
        Invoke-VMScript -VM $vm -HostCredential $vicred -GuestCredential $guestcred -ScriptType Powershell -ScriptText $script
    }else{
        Write-Output ("starting server"-f $server)
        $vm = Start-VM -VM $vm
        
        #vent intill den er online igjen
        do {
            Write-Output ("Cannot contact VM: {0}, waiting for contact"-f $vm.Name)
            sleep 10
        } until ((Get-VM $vm.Name).PowerState -eq "PoweredOn")
        try {
            Invoke-VMScript -VM $vm -HostCredential $vicred -GuestCredential $guestcred -ScriptType Powershell -ScriptText $script
        }
        catch {
              if($error[0].CategoryInfo.Category -eq "OperationTimeout"){
                Write-Output ("Timeout reached, trying again")
                sleep 10
              }
              do {
                try {
                    $script = Invoke-VMScript -VM $vm -HostCredential $vicred -GuestCredential $guestcred -ScriptType Powershell -ScriptText $script
                }
                catch {
                    if($error[0].CategoryInfo.Category -ne "OperationTimeout"){ Throw $_  }
                    $script = $_
                }    
              } until ($script)
              $script
        }
    }#end else

}#end foreach


#lopper igjennom enhver server
foreach ($Server in $Servers) {
    #Henter vmen
    $vm = get-vm -Name $Server
    if($vm.PowerState -ne "PoweredOn"){
        Start-VM -VM $vm
    }
}

#move-vm -location $folderid