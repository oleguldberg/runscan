#!/bin/bash

# Prints the help
function show_help {
	printf "runscan -l [list] \t Run the scan for the domains listed in file\n"
	printf "runscan -o [output] \t Write output to HTML outputfile, default is scanout.html\n"
	printf "runscan -n \t\t Use nmap to scan all ports on domain\n"
	printf "runscan -s \t\t Use sslscan to scan ssl-connection\n"
	printf "runscan -y \t\t Use sslyze to scan ssl-connection\n"
	printf "runscan -h \t\t Show this help\n"
}

# Initialize variables
domains=""
use_nmap=false
use_sslscan=false
use_sslyse=false
outputfile=scanout.html

# Reset if getops has been used previously
OPTIND=1

# Handle auguments
while getopts "l:o:hnsy" opt; do
	case "$opt" in
		l)
			domains="$OPTARG"
			;;
		o)
			outputfile="$OPTARG"
			;;
		n)
			use_nmap=true
			;;
		s)
			use_sslscan=true
			;;
		y)
			use_sslyze=true
			;;
		h)
			show_help
			exit 0
			;;
	esac
done

echo "Reading domains from $domains and outputting to $outputfile"

# Put the head in the outputfile
cat templates/htmlhead > "$outputfile"

# Add information about starting scan
#  TODO: Add more information on the scanning for example which tools the scan is using.
echo "<div class=\"header\">" 2>&1 >> "$outputfile"
echo "<h1>Starting scan ... Hang on!1</h1>" 2>&1 >> "$outputfile"
date -uR 2>&1 >> "$outputfile"
echo "</div>" 2>&1 >> "$outputfile"
echo "<br>" >> "$outputfile"

# Loop and handle domains
for i in $(cat $domains)
do
	echo "<div class=\"section\">" 2>&1 >> "$outputfile"
	echo "<h2>Scanning $i </h2>" 2>&1 >> "$outputfile"
	echo "</div>" 2>&1 >> "$outputfile"

	# Do DNS recon
	echo "<div class=\"info\">" 2>&1 >> "$outputfile"
	echo "<h3>Doing dns-recon on $i</h3>" 2>&1 >> "$outputfile"
	# dnsrecon -d $i -w -n 8.8.4.4  2>&1 >> "$outputfile"
	
	echo "<hr>" >> "$outputfile"
	echo "<h4>Checking A record</h4>" >> "$outputfile"
	dig $i A +short 2>&1 >> "$outputfile"

	echo "<hr>" >> "$outputfile"
	echo "<h4>Checking CNAME record</h4>" >> "$outputfile"
	dig $i CNAME +short  2>&1 >> "$outputfile"
	
	echo "<hr>" >> "$outputfile"
	echo "<h4>Checking MX record<br></h4>" >> "$outputfile"
	dig $i MX +short 2>&1 >> "$outputfile"

	echo "<hr>" >> "$outputfile"
	echo "<h4>Checking TXT record</h4>" >> "$outputfile"
	dig $i TXT +short 2>&1 >> "$outputfile"
	
	echo "<hr>" >> "$outputfile"
	echo "<h4>Checking for DNSSEC<br></h4>" >> "$outputfile"
	delv $i 2>&1 >> "$outputfile" 
	echo "</div>" 2>&1 >> "$outputfile"
	echo "<br>" >> "$outputfile"

	# Use nmap if desired
	if [ "$use_nmap" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h3> Doing portscanning on $i</h3>" 2>&1 >> "$outputfile"
		nmap -sS -sV -Pn -v -p0- -T4 $i 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
		echo "<br>" >> "$outputfile"
	fi

	# Use sslscan if desired
	if [ "$use_sslscan" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h3>Doing sslscan on $i</h3>" 2>&1 >> "$outputfile"
		sslscan $i:443 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
		echo "<br>" >> "$outputfile"
	fi

	# Use sslyze if desired
	if [ "$use_sslyze" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h3>Doing sslyze on $i</h3>" 2>&1 >> "$outputfile"
		sslyze $i 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
		echo "<br>" >> "$outputfile"
	fi

done

# Add information about ending scan
#  TODO: Add more information on the scanning for example which tools the scan is using.
echo "<div class=\"header\">" 2>&1 >> "$outputfile"
echo "<h1>Ending scan... Hope you enjoyed the ride</h1>" 2>&1 >> "$outputfile"
date -uR 2>&1 >> "$outputfile"
echo "</div>" 2>&1 >> "$outputfile"
echo "<br>" >> "$outputfile"


# put the tail on the outputfile
cat templates/htmltail >> "$outputfile"