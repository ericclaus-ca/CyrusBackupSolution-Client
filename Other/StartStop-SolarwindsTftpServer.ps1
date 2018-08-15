function Start-TftpServer {
    # Start SolarWinds TFTP Server
    #echo "Starting TFTP server..."
    #Start-Service -Name “SolarWinds TFTP Server”

    # Enable the TFTP firewall rule
    echo "Enabling TFTP firewall rule..."
    netsh advfirewall firewall set rule name="TFTP" new enable=yes
}
function Stop-TftpServer {
    # Stop Solarwinds TFTP Server
    #echo "Stopping TFTP server..."
    #Stop-Service -Name "SolarWinds TFTP Server"

    # Disable the TFTP firewall rule
    echo "Disabling TFTP firewall rule..."
    netsh advfirewall firewall set rule name="TFTP" new enable=no
}