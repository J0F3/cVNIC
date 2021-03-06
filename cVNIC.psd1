@{
# Version number of this module.
ModuleVersion = '1.0.0.0'

# ID used to uniquely identify this module
GUID = '67e68531-9690-4d35-9799-eaeeb1cd78f2'

# Author of this module
Author = 'Jonas Feller c/o J0F3'

# Company or vendor of this module
CompanyName = 'jofe.ch'

# Copyright statement for this module
Copyright = '(c) 2015 Jonas Feller. All rights reserved.'

# Description of the functionality provided by this module
Description = 'DSC Module to create and configuring virutal network adapters for Hyper-V host management'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = @("Get-TargetResource", "Set-TargetResource", "Test-TargetResource")

# Cmdlets to export from this module
CmdletsToExport = '*'
}