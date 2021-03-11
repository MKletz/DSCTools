function ConvertFrom-Mof {
<#
.SYNOPSIS
   Parses a MOF file and converts the resource instances it contains to PowerShell Objects.
.DESCRIPTION
   Parses a MOF file and converts the resource instances it contains to PowerShell Objects.
.PARAMETER Path
    The path of the MOF file to parse.
.EXAMPLE
   Get-ChildItem "C:\DSCConfigs\Output" -File -Filter "*.mof" -Recurse | ConvertFrom-DscMof
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf -Include "*.mof"})]
        [Alias('FullName')]
        [string]$Path
    )

    Begin {
    }

    Process {
        # Code here was taken then modified from: https://github.com/MathieuBuisson/Powershell-Utility/blob/master/ConvertFrom-DscMof/ConvertFrom-DscMof.psm1
        
        $FileContent = Get-Content -Path $Path

        $LineWithFirstBrace = ($FileContent | Select-String -Pattern 'instance of ' | Where-Object -FilterScript { $_.Line -notmatch 'MSFT_Credential' })[0].LineNumber

        # Removing the lines preceding the first resource instance
        $Resources = $FileContent | Select-Object -Skip $LineWithFirstBrace | Where-Object -FilterScript { $_ -notmatch "^\s*$" }

        # Reformatting multi-value properties to allow ConvertFrom-StringData to process them
        $Resources = $Resources -replace ";",''
        $Resources = $resources -join "`n"
        $Resources = $Resources -replace '(?m)\{[\r\n]+\s*',''
        $Resources = $Resources -replace 'instance of \w+.*',''
        $Resources = $Resources -replace '(?m)\,[\r\n]+\s*',','
        $Resources = $Resources -replace "(?m)\}[\r\n]+^\s*$",''
        $Resources = $Resources -replace "(?m)$\s*\}[\r\n]+","`n"

        # Removing the empty last item and the ConfigurationDocument instance from the collection
        $ResourceHashTables = ($Resources -Split '(?m)^\s*$') | Select-Object -SkipLast 1 | ForEach-Object -Process {
            $ResourceHashTable = $_ | ConvertFrom-StringData
            Foreach ($Key in $($ResourceHashTable.Keys)) {
                $ResourceHashTable[$Key] = ($ResourceHashTable[$Key]).Trim('}')
                $ResourceHashTable[$Key] = ($ResourceHashTable[$Key]).Trim('"')
            }
            $ResourceHashTable['ResourceName'] = ($ResourceHashTable['SourceInfo'] -split '::')[-1]
            $ResourceHashTable
        }

        Return ,$ResourceHashTables
    }

    End {
    }
}
