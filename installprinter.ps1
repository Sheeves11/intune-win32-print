#---installprinter.ps1--------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------
#
#   By Mia Quain for The U of A. This script imports a print driver, sets up the printer, and sets the default
#   printer on the system.
#
#   Notes: PrinterDriver -Name is specific to your driver file. To find it, install the printer on your
#   system and then run "printui /s /t2"
#
#   The PrinterPort -Name can be anything of your choosing, as well as the Printer -Name
#   
#   This script will fail if the port name is already in use, or the printer name is already in use.
#
#   TESTING: You will need to use "sysnative" in place of "system32" when you create an intune.win
#   file. This is because certain 64-bit commands don't work in a 32 bit context. Use system32 for
#   local testing and sysnative for deployment.
#
#------------------------------------------------------------------------------------------------------

#start logging
start-transcript -Path "C:\tmp\install-example-printer.txt"

#Stage all .inf driver files in the "\Drivers" folder
Get-ChildItem "$PSScriptRoot\Drivers" -Recurse -Filter "*inf" | ForEach-Object { C:\Windows\sysnative\pnputil.exe /add-driver $_.FullName /install } 

#Install the printer driver (this name is specific to each printer)
Add-PrinterDriver -Name 'Canon Generic Plus UFR II'
#Create Ports (use whatever name you want)
Add-PrinterPort -Name 'example-printer-intune' -PrinterHostAddress 'example-printer.ddns.uark.edu'
#Install Printer (use the same port as before and make up a name)
Add-Printer -Name 'Example Printer - Intune' -DriverName 'Canon Generic Plus UFR II' -PortName 'example-printer-intune'

stop-transcript