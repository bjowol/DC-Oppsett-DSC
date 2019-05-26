#Sharename     #Tilgang
$smb_shares = @()
$smb_shares += @{"HomeFolders" = "DP.localGroup"}
$smb_shares += @{"Konsulenter"= "KonsulenterGroup"}
$smb_shares += @{"Ledelse"= "LedelseGroup"}
$smb_shares += @{"Systemutvikling"="SystemutviklingGroup"}
$smb_shares += @{"Salg"="SalgGroup"}
$smb_shares += @{"Felles"="DP.localGroup"}
$smb_shares += @{"Ledelse"="LedelseGroup"}

#sjekker og stopper hvis Data disk ikke er tilstede
$ErrorActionPreference = "stop"
$drive = get-psdrive -Name 'Z'
if(!$drive){
    throw "Data drive for shares not present. dont install in C:drive"
}
if(-not(Test-Path -Path "Z:\Shares")){
    try {
        New-Item -ItemType Directory -Path "Z:\Shares"
    }
    catch {
        throw $_
    }
}


function createShare($name, $permission) {
    #Endrer tilgangene p mappen sharet skal bli opprettet i

    $path = "Z:\Shares\$name"
    
    New-Item $path -type Directory

    $acl = Get-Acl $path
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($permission,'Modify','ContainerInherit, ObjectInherit','None','Allow');
    $acl.SetAccessRule($Ar);
    Set-Acl $path $acl

    #Oppretter sharet
    New-SmbShare -Name $name -Path $path -FullAccess $permission -FolderEnumerationMode AccessBased
}

foreach($share in $smb_shares) {
    # $name = $share[0]
    # $permission = $share[1]
    $name = $share.Keys
    $permission = $share.values
    # $name
    # $permission

    $share[0]
    createShare -name $name -permission $permission
    # Read-Host -Prompt "next"
}