$Computer = $env:COMPUTERNAME

Install-WindowsFeature -Name WDS -IncludeManagementTools
    #(Get-Command -Module WDS).count
    #(Get-Command -Module WDS)

    # MAA ENDRE SERVER:<NAVN>
    #wdsutil.exe /Verbpse /Progress /initialize-server /Server:"$Computer" /remInst: "C:\RemoteInstall"
## Endre ":Server" til computername
WDSUTIL /Verbose /Progress /Initialize-Server /Server:FHSDC01 /RemInst:"C:\RemoteInstall" 


$TestPath = "C:\BootAndInstall"
$PathExists = Test-Path $TestPath
if($PathExists -Eq $false){

    New-Item C:\BootAndInstall -Type Directory
}

Write-Warning "You need to put boot file and install file in C:\BootAndInstall" -WarningAction Inquire
    #Importerer boot imabe
Import-WdsBootImage -Path "C:\BootAndInstall\boot.wim" -NewImageName "Windows Boot Image x64" -NewDescription "x64 processors." -NewFileName "Win10X64Boot.wim" -SkipVerify
    #Lager ny ImageGroup


New-WdsInstallImageGroup -Name "Win10Group" -ErrorAction SilentlyContinue

WDSUTIL /Add-Image /ImageFile:"C:\BootAndInstall\install.wim" /ImageType:Install /ImageGroup:"Win10Group"
    #Copy-Item -Path "C:\BootAndInstall\install.wim" -Destination "C:\RemoteInstall\Images\Win10Group" -Force
    ## Endre ":Server" til computername

WDSUTIL /Start-server /server:FHSDC01

#skjekke eller restarte wds server for tanking
WDSUTIL /Set-Server /AnswerClients:All /ResponseDelay:4


Remove-Item -path C:\BootAndInstall -Force -Confirm:$False
