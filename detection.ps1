if ((Get-Printer).PortName -match "example-printer-intune") {    write-output "Detected, exiting"
exit 0
}
else {
exit 1
}