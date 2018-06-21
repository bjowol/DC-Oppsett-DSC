               #Sharename     #Tilgang
$smb_shares = ("HomeFolders", "Tertitten.noGroup"), `
("Administrasjon", "AdministrasjonGroup"), `
("Interaksjonsdesign", "InteraksjonsdesignGroup"), `
("Systemutvikling","SystemutviklingGroup"), `
("Salg","SalgGroup"), `
("Felles","Tertitten.noGroup"),
("Ledelse","LedelseGroup")


function createShare($name, $permission) {
    #Endrer tilgangene p mappen sharet skal bli opprettet i

    $path = "C:\Shares\$name"

    
    
    New-Item $path -type Directory

    

    $acl = Get-Acl $path
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($permission,'Modify','ContainerInherit, ObjectInherit','None','Allow');
    $acl.SetAccessRule($Ar);
    Set-Acl $path $acl

    #Oppretter sharet
    New-SmbShare -Name $name -Path $path -FullAccess $permission -FolderEnumerationMode AccessBased
}

foreach($share in $smb_shares) {
    $name = $share[0]
    $permission = $share[1]

    echo $share[0]
    createShare -name $name -permission $permission
}