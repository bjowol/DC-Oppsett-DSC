<#
    created by: Bjørn Wolstad
    Credits: Fox Deploy
#>
function findInternetAdapter() {
    $Adapter = Get-NetAdapter
    return $Adapter[0].name;
}

$MachineName = "DP-DC01"
$InternetAlias = findInternetAdapter
$IP = '172.31.7.5'
$Subnet = '255.255.255.0'
$SubnetMask = '24'
$DGW = '172.31.7.1'
$DHCP_StartRange = '172.31.7.50'
$DHCP_EndRange = '172.31.7.120'
$DHCP_LeaseDuration = '07.00:0:0' #D.HH:MM:SS
$ScopeID = '172.31.7.0'
$DomainName = "DP.local"

$secpasswd = ConvertTo-SecureString 'IWouldLikeToRecover!' -AsPlainText -Force
$SafeModePW = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
$secpasswd = ConvertTo-SecureString 'IHaveSkills' -AsPlainText -Force
$localuser = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)

$firstDomainAdmin = (Get-Credential -UserName 'Administrator' -Message "Plase enter the Administrator credentials")

$OutputPath = "$PSScriptRoot\Config\"

Configuration ServerConf {
    Param
        (
            [string[]]$NodeName = 'localhost',

            [Parameter(Mandatory)][string]$MachineName,
            [Parameter(Mandatory)]$IP,
            [Parameter(Mandatory)]$Subnet,
            [Parameter(Mandatory)]$SubnetMask,
            [Parameter(Mandatory)]$DGW,
            [Parameter(Mandatory)]$InternetAlias,

            [Parameter(Mandatory)][string]$DHCP_StartRange,
            [Parameter(Mandatory)][string]$DHCP_EndRange,
            [Parameter(Mandatory)][string]$DHCP_LeaseDuration, #D.HH:MM:SS

            [Parameter(Mandatory)][string]$UserName,
            [Parameter(Mandatory)][string]$Password,

            [Parameter(Mandatory)][string]$DomainName,
            [Parameter(Mandatory)]$firstDomainAdmin,
            [Parameter(Mandatory)]$SafeModePW

        )
    #$Password = (Get-Credential -UserName 'Nisse' -Message 'Enter New Password for $UserName')

    # $resources = 'xNetworking','xComputerManagement','xActiveDirectory','xDHCpServer'#,'xSmbShare'
    # Import-DscResource -module $resources
    Import-DscResource -Module xNetworking
    Import-DscResource -Module xComputerManagement
    Import-DscResource -Module xActiveDirectory
    Import-DscResource -Module xDHCpServer
    # Import-DscResource -Module xSmbShare

    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node $NodeName {

        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = "ContinueConfiguration"
        }

        xComputer NewName {
            Name = $MachineName
        }

        xIPAddress NewIPAddress {
            DependsOn = '[xComputer]NewName' 
            IPAddress = "$($IP)/$($SubnetMask)"
            InterfaceAlias = $InternetAlias
            # SubnetMask = $SubnetMask
            AddressFamily = "IPV4"
        }

        xDefaultGatewayAddress SetDefaultGateway {
            DependsOn = '[xIPAddress]NewIPAddress'
            InterfaceAlias = $InternetAlias
            Address = $DGW
            AddressFamily = 'IPv4'
        }

        WindowsFeature WDSInstall {
            DependsOn = '[xIPAddress]NewIPAddress'
            Ensure = 'Present'
            Name = 'WDS'
            IncludeAllSubFeature = $true
        }

        WindowsFeature ADDSInstall { 
            DependsOn= '[WindowsFeature]WDSInstall'
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        }

        WindowsFeature RSATTools { 
            DependsOn= '[WindowsFeature]ADDSInstall'
            Ensure = 'Present'
            Name = 'RSAT-AD-Tools'
            IncludeAllSubFeature = $true
        }
 
        WindowsFeature DHCP {
            DependsOn = '[WindowsFeature]RSATTools'
            Name = 'DHCP'
            Ensure = 'PRESENT'
            IncludeAllSubFeature = $true

        }

        WindowsFeature DHCPTools {
            DependsOn = '[WindowsFeature]DHCP'
            Ensure = 'PRESENT'
            Name = 'RSAT-DHCP'
            IncludeAllSubFeature = $true

        }

        xDhcpServerScope Scope {
            DependsOn ='[WindowsFeature]DHCPTools'
            Ensure = 'Present'
            IPStartRange = $DHCP_StartRange
            IPEndRange = $DHCP_EndRange
            Name = 'DefaultScope'
            SubnetMask = $subnet 
            LeaseDuration = $DHCP_LeaseDuration
            State = 'Active'
            AddressFamily = 'IPv4'

        }

        xDhcpServerOption Option {
            DependsOn = '[xDhcpServerScope]Scope'
            Ensure = 'Present'
            ScopeID = $ScopeID
            DnsDomain = $DomainName
            DnsServerIPAddress = $IP
            AddressFamily = 'IPv4'
            Router = $DGW
        }
      
        xADDomain SetupDomain {
            DomainAdministratorCredential= $firstDomainAdmin
            DomainName= $DomainName
            SafemodeAdministratorPassword= $SafeModePW
            DependsOn='[xDhcpServerOption]Option'
            DomainNetbiosName = $DomainName.Split('.')[0]
        }

        xDhcpServerAuthorization Authorize {
           DependsOn = '[xADDomain]SetupDomain'
           Ensure = 'Present'
           IPAddress = $IP
           DnsName = $DomainName.Split('.')[0] #muligens en feil her
        }
        
    }   
}

#trengs for aa bruke plain text passord i Nodes

$configData = 'a'

$configData = @{
    AllNodes = @(
        @{
            NodeName="localhost"
            PSDscAllowPlainTextPassword = $true
         }
)}



#if (-not(test-path C:\PowerShell)){mkdir C:\PowerShell 

#Oppretter DSC Configen til $OutputPath
ServerConf -OutputPath  $OutputPath -MachineName $MachineName -DomainName $DomainName -InternetAlias $InternetAlias -Password `
 $localuser -UserName 'Administrator' -SafeModePW `
 $SafeModePW -firstDomainAdmin $firstDomainAdmin -ConfigurationData $configData -IP $IP -DGW $DGW -DHCP_StartRange $DHCP_StartRange -DHCP_EndRange $DHCP_EndRange -DHCP_LeaseDuration $DHCP_LeaseDuration -Subnet $Subnet -SubnetMask $SubnetMask


#Applyer DSC configen
Start-DscConfiguration -ComputerName localhost -Wait -Force -Verbose -path $OutputPath -Debug

#Setter opp automatisk restart av DSC etter reboot
cp "$PSScriptRoot\startup.bat" "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startup.bat"

Restart-Computer