[String]$ModuleRoot = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'src\DSCTools'
Import-Module -Name $ModuleRoot -Force

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        $ManifestPath = Join-Path -Path "$(Split-Path -Path $PSScriptRoot -Parent)" -ChildPath 'src\DSCTools\DSCTools.psd1'
        Test-ModuleManifest -Path $ManifestPath | Should -Not -BeNullOrEmpty
    }
}

Describe 'ConvertFrom-Mof' {
    It 'Imports all items from the Mof' {
        (ConvertFrom-Mof -Path "$($PSScriptRoot)\test.mof" | Measure-Object).Count | Should -Be 2
    }

    It 'Takes pipeline input' {
        { "$($PSScriptRoot)\test.mof" | ConvertFrom-Mof } | Should -Not -Throw
    }

    It 'Imports all properties of the items' {
        $Resources = ConvertFrom-Mof -Path "$($PSScriptRoot)\test.mof"
        $Resources[0]['UserName'] | Should -Be 'pesterUser'
        $Resources[0]['Description'] | Should -Be 'pester test user'
        $Resources[0]['ResourceName'] | Should -Be 'User'
    }
}

Describe 'New-DscMof' {
    It 'Does not throw' {
        { New-DscMof -ModuleName 'PSDscResources' -Resource 'User' -Parameters @{UserName='MyUser'; Description='MyDescription'} } | Should -Not -Throw
    }

    It 'Produces a MOF file' {
        Test-Path -Path "$($ENV:TEMP)\temp.mof" | Should -be $true
    }

    It 'Passes in provided properties' {
        $Resource = ConvertFrom-Mof -Path "$($ENV:TEMP)\temp.mof"
        $Resource['UserName'] | Should -be 'MyUser'
        $Resource['Description'] | Should -be 'MyDescription'
    }

    Remove-Item -Path "$($ENV:TEMP)\temp.mof" -Force -ErrorAction 'SilentlyContinue'
}
