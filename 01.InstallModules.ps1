$installPath = "$env:ProgramFiles\WindowsPowerShell\Modules\";

$modulePaths = @(
    "$PSScriptRoot\xModules\")


foreach($module in $modulePaths) {
    Copy-Item "$module*" $installPath -Recurse -Force
}