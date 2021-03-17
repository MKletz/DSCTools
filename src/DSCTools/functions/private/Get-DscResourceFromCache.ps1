function Get-DscResourceFromCache {
<#
.SYNOPSIS
    Generates a MOF file for a specified composite resource with the provided parameters.
.DESCRIPTION
    Generates a MOF file for a specified composite resource with the provided parameters.
.PARAMETER Module
    Name of the module containing the composite resource.
.PARAMETER OutPath
    Directory to generate the MOF file in. Default is $ENV:TEMP
.PARAMETER Parameters
    Parameters for the resource in hashtable format. Default is an empty hashtable for no parameters.
.PARAMETER Resource
    Name of the composite resource.
.EXAMPLE
    Get-ChildItem -Path "C:\DSCConfigs\Output" -File -Filter "*.mof" -Recurse | ConvertFrom-DscMof
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$Module,
        [Parameter(Mandatory)]   
        [string]$Resource
    )

    Process {
        [string]$Key = "$($Module):$($Resource)"

        if ($script:ResourcePropertyCache.keys -notcontains $Key){
            Write-Debug -Message "$($Key) not found in resource cache."
            Import-Module -Name $Module
            $Properties = @{}
            (Get-DscResource -Name $Resource -Module $Module).Properties | Where-Object -FilterScript {$_.PropertyType -ne '[PSCredential]'} | ForEach-Object -Process {
                $CleanPropertyType = $_.PropertyType.Substring(1,$_.PropertyType.Length - 2)
                if ($CleanPropertyType -eq 'bool'){
                    $CleanPropertyType = 'boolean'
                }

                if($CleanPropertyType -notlike "system.*"){
                    $CleanPropertyType = "system.$($CleanPropertyType)"
                }

                $_ | Add-Member -Name TypeObject -Value ([type]::GetType($CleanPropertyType,$False,$True)) -MemberType NoteProperty
                $Properties.Add($_.Name,$_)
            }
            $script:ResourcePropertyCache.add($Key,$Properties)
        }

        return $script:ResourcePropertyCache[$Key]
    }
}
