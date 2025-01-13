# Runscan - run a scan ...
Runscan scans a list of domains and outputs the results as HTML.

Runscan takes the following commandline-options:

runscan -l [list]       Run the scan for the domains listed in file

runscan -o [output]     Write output to HTML outputfile, default is scanout.html

runscan -n 		        Use nmap to scan all ports on domain

runscan -s              Use sslscan to scan ssl-connection

runscan -y              Use sslyze to scan ssl-connection

runscan -g              Use Google DNS-server for DNS queries

runscan -p              Also output to PDF

runscan -h              Show help

## Prerequisites

You need:

- dig (with delv)
- whois
- nmap
- sslscan
- sslyze
- pandoc

## Notes on delv on MacOS
The delv command on default MacOS doesnt work when trying to check for DNSSEC. Install the delv command with Homebrew:

brew install bind

Restart your terminal and confirm you are using the Homebrew delv

 ~ % which delv

/opt/homebrew/bin/delv