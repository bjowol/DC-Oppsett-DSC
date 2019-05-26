$Computer = $env:COMPUTERNAME
Install-WindowsFeature -Name WDS -IncludeManagementTools
    
# MAA ENDRE SERVER:<NAVN>
WDSUTIL /Verbose /Progress /Initialize-Server /Server:DP-DC01 /RemInst:"C:\RemoteInstall" 

#Sjekker og lager mappe til .wim filene
$TestPath = "C:\BootAndInstall"
$PathExists = Test-Path $TestPath
if($PathExists -Eq $false){

    New-Item C:\BootAndInstall -Type Directory
}

Write-Warning "You need to put boot file and install file in C:\BootAndInstall" -WarningAction Inquire
    #Importerer boot imabe
#importerer boot image
Import-WdsBootImage -Path "C:\BootAndInstall\boot.wim" -NewImageName "InstallImage" -NewDescription "x64 processors." -NewFileName "WinX64Boot.wim" -SkipVerify

#Lager capture image basert på boot image over og importerer dette.
#WDSUTIL /verbose /progress /New-CaptureImage /server:FHSDC01 /image:"Windows Boot Image x64" /filename:captureimage.wim /Architecture:x64 /DestinationImage /Filepath:"C:\captureimage.wim" /name:"CaptureImage" /Description:"WinPE Image with capture utils" /Overwrite:No 
WDSUTIL /New-CaptureImage /Image:"InstallImage" /Architecture:x64 /DestinationImage /FilePath:"C:\BootAndInstall\CaptureImage.wim"
Import-WdsBootImage -Path "C:\BootAndInstall\CaptureImage.wim" -NewImageName "CaptureImage" -NewDescription "x64 processors" -NewFileName "Winx64Captureimg.wim" -SkipVerify

#lager to install grupper. En for Captured images og en for vanlig klient tanking
New-WdsInstallImageGroup -Name "OfficialStockImage" -ErrorAction SilentlyContinue
New-WdsInstallImageGroup -Name "CapturedImages" -ErrorAction SilentlyContinue

#henter installimage, som er stock windows image.
WDSUTIL /Add-Image /ImageFile:"C:\BootAndInstall\install.wim" /ImageType:Install /ImageGroup:"OfficialStockImage"
    #Copy-Item -Path "C:\BootAndInstall\install.wim" -Destination "C:\RemoteInstall\Images\Win10Group" -Force
    ## Endre ":Server" til 

#starter tjenesten
WDSUTIL /Start-server /server:DP-DC01

#Aktiverer og gjør klar tjenesten til å akkseptere tanke forespørsler.
WDSUTIL /Set-Server /NewMachineDomainJoin:Yes /AnswerClients:All /ResponseDelay:4

#Må endre OU-Location
#Plasserer alle nye klienter under "OU=Computers,OU=FHS.Local,DC=fhs,DC=local"
WDSUTIL /Set-Server /newMachineOU /type:Custom /OU:"OU=Tanking,OU=Enheter,OU=DP.local,DC=Tertitten,DC=no" 

#sletter .wim filene igjen om ønsket.
Remove-Item -path C:\BootAndInstall -Force -Confirm:$True
