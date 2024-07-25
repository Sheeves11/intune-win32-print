# Intune-Win32-Print

Automatically deploy printers to endpoints using Microsoft Intune Win32 apps! I wrote this code and this guide at the University of Arkansas to help solve Intune's lack of printer deployment options. Once you have a printer set up in Intune it's a breeze to deploy it to large groups of computers in just a few clicks! No print server required! 

Alongside this guide I have included an example folder structure that includes scripts and drivers for a generic Xerox printer. Deploying your own printer is a matter of changing a few variables, adding your printer's driver files, compiling the intune.win package, and uploading to Intune as a Win32 app. This app can then be assigned to groups or computers or made avalible via Company Portal self-serve!

### **Introduction:**

Overview:

In brief, you will follow these steps:

- Download or find your printer drivers
- Gather your DNS name and print driver name
- Create a folder that includes driver package, PowerShell script, detection script, and start.bat in the appropriate places
- Edit the script files using the templates provided
- Package the intune.win using IntuneWinAppUtil.exe
- Upload to Intune
- Assign to groups and test

This guide is very long but it is not complicated and can be done in 15 minutes or less, once you've done the process a few things and understand how it works! Don't be intimidated by the length of this guide!

## Download Print Drivers

This is straightforward, although manufacturers can make their download pages confusing. You're looking for the folder containing .inf files, not the automated installers. Some companies hide these behind .exe automatic extractors. Some companies call these "Add Printer Wizard Driver" packages. Printer driver packages can contain one or multiple .inf files. The script will install all of them to be safe.

## Find Your DNS Name

The easiest way to do this is to print an information sheet from the printer and read what it says. If it only gives an IP address, use nslookup in a terminal, which will query the campus DNS server and find the address for a given IP.

## Find Print Driver Name

This is one of the more tricky parts of the process. You can open up a .inf file in an editor and search for the name, but sometimes they can be hard to find and sometimes you have multiple .inf files. The easiest way I have been able to find is to install the printer manually and use:

> printui /s /t2

This will open a list of installed print drivers on your system. The print driver name will be just as it's spelled in the "name" field. This has to be accurate or your script will fail.

## Create Your Package Directory

Set up a folder structure like this:

├── Printer Deployment Package

│ ├── Drivers

│ ├── intunewin

│ ├── detection.ps1

│ ├── installprinter.ps1

│ └── start.bat

Put your extracted driver files in the "Drivers" folder and create an empty "intunewin" folder. Create the script files as named here. You'll add the contents to these files in the next step.

### start.bat

This is a batch file that kicks off the whole thing. It contains one line:

> powershell.exe -executionpolicy bypass -File "installprinter.ps1"


"-executionpolicy bypass" means that your script won't get hung up on the PowerShell Execution Policy.

### installprinter.ps1

This is the script that does the work. I'm using a Xerox VersaLink B405 as an example for this readme. The code is self-documenting, so I'll just leave it here:

```powershell
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
```

Note that you will need to use "system32" instead of "sysnative" when you are testing on your local machine. This script will fail if you have these drivers, printers, or ports already installed on your local machine. It's best to test this on a clean slate. I'm using a Xerox VersaLink B405 as a demo here.

Update:

Adding this line of code prevents you from needing to swap between system32 and sysnative when testing:

```
# Check if running in a 32-bit context and relaunch in 64-bit PowerShell if necessary
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    &"$env:WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe" -File $PSCommandPath
    exit
}
```

### detectionscript.ps1

You can use any port name you want and you can call the printer anything you want. The DNS name and driver name are specific to this code and shouldn't be changed.

I just check the port name vs the one I tried installing earlier and return a 0 if found.

```
if ((Get-Printer).PortName -match "example-printer-intune") {
    write-output "Detected, exiting"
    exit 0
} else {
    exit 1
}
```
### Creating the intune.win

An intune.win is what gets uploaded to Intune and then deployed to computers. There is a packager called "IntuneWinAppUtil.exe" that you will need.

As of the current version 1.8.4, both 1.8.4 and 1.8.3 have shown instability issues. The recommended version is 1.8.2 and the download for it will be linked below.

[Download IntuneWinAppUtil.exe v1.8.2](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/tags/v1.8.2.zip)

From the downloaded zip archive, place IntuneWinAppUtil.exe in a directory on your user or system PATH environment variable. If you are able to place it within C:\Windows, that would suffice. Otherwise, you will need to place it within a folder you have access to and then see this guide to add that folder to your user or system PATH: Adding to PATH.

Once you have this program on your PATH, go ahead and run it. Fill the details out as follows:

You will obviously want to use your own directory you made here. When it asks you to specify a catalog folder, say no.

Now you have the file, start.intunewin that you will upload to Intune!
Uploading to Intune

From intune.microsoft.com, go to Apps -> All apps and then add a new app.

- Select "Windows App (Win32)" as your app category.
- Select your `start.intunewin` to be your app package file.
- App naming schemes typically follow this pattern "DEPT CODE - Printer Room Number"
- Add info as you find necessary and then upload a logo to make your Company Portal interface look nice.
- Your install command will be `start.bat`.
- I'm using "n/a" as the uninstall command for this example. Write an uninstall script if you wish to have that feature.
- Make sure to install using system context.
- You do not need any return code except 0.
- Don't worry about minimum specs. It's a printer.
- Select "Use a custom detection script" and then specify your `detection.ps1` script.
- Don't run as a 32-bit process and don't enforce script signature checks.
- You likely have no software dependencies or supersedence specifications.
- **Important:** Set your scope tags. Make sure "AllAdmins" is not checked unless you want to annoy every other tech at the university with your printer app.

Next you'll see the group deployment screen. I like to at minimum add our Tech group under the "Available for enrolled devices" section. This lets me test the script on computers I log into before deploying to others.

Finally you'll get a sanity check page and be allowed to start your upload.

Wait a few minutes, sync Company Portal on your test machine, and hope it works! If it doesn't work, you can always check the log in C:\tmp to see what went wrong.

Good luck!

