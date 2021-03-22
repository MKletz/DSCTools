function ConvertFrom-Mof {
<#
.SYNOPSIS
    Parses a MOF file and converts the resource instances it contains to PowerShell Objects.
.DESCRIPTION
    Parses a MOF file and converts the resource instances it contains to PowerShell Objects.
.PARAMETER Path
    The path of the MOF file to parse.
.EXAMPLE
    Get-ChildItem -Path "C:\DSCConfigs\Output" -File -Filter "*.mof" -Recurse | ConvertFrom-DscMof
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf -Include "*.mof"})]
        [Alias('FullName')]
        [string]$Path
    )

    Begin {
    }

    Process {
        Return [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportInstances($Path, 4)
    }

    End {
    }
}
