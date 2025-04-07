![logo](https://raw.githubusercontent.com/the8bitbyte/discon-spy/refs/heads/main/resources/one.png)

# discon-spy
A tool written in shell that uses repeated nmap scans to detect disconnections from networks

can be used for mac address spoofing in order to take the place of a authenticated device once they disconnect.

## Installation

1. clone the repository, ``` git clone git@github.com:the8bitbyte/discon-spy.git ```
2. ensure you have nmap installed, ``` sudo pacman -S nmap ```
3. make discon.sh executable, ``` chmod +x discon.sh ```
4. run it, ``` sudo ./discon.sh ```

## Usage
the -i flag can be used to specify the interface, exampe:  ``` sudo ./discon.sh -i wlan0 ```
if not provided the script will assume and select the first active interface (ignoring loopback)
