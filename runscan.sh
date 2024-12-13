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
number_of_domains=0
use_nmap=false
use_sslscan=false
use_sslyse=false
outputfile=scanout.html
a_record=""

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

number_of_domains=$(wc -l < $domains)

# Output to terminal
echo "Reading $number_of_domains from $domains and outputting to $outputfile"

# Put the head in the outputfile
cat templates/htmlhead > "$outputfile"

# Add information about starting scan
#  TODO: Add more information on the scanning for example which tools the scan is using.
echo "<div class=\"header\">" 2>&1 >> "$outputfile"
echo "<h1>Hang on!1</h1>" 2>&1 >> "$outputfile"

# Starting information
echo "Starting scan at: " >> "$outputfile" && echo "<b><i>" >> "$outputfile" && date -uR 2>&1 >> "$outputfile" && echo "</b></i>" >> "$outputfile" 

# Info on number of domains to be scanned
echo "<br>Number of domains to be scanned: <b><i>"$number_of_domains"</b></i>" >> "$outputfile"

# DNS-info - always do DNS-scanning
echo "<br>DNS-queries: <b><i>YES</b></i>" >> "$outputfile"

# Portscanning information
echo "<br>Scanning ports with nmap: " >> "$outputfile"
if [ "$use_nmap" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"green\">YES</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"red\">NO</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

# sslscan information
echo "<br>Analysis with sslscan: " >> "$outputfile"
if [ "$use_sslscan" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"green\">YES</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"red\">NO</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

# sslyze information
echo "<br>Analyses with sslyze: " >> "$outputfile"
if [ "$use_sslyze" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"green\">YES</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"green\">NO</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

echo "<br><br>" >> "$outputfile"
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
	# dnsrecon -d $i -w -n 8.8.4.4  2>&1 >> "$outputfile"
	
	# echo "<hr>" >> "$outputfile"
	echo "<h3>Checking A record</h3>" >> "$outputfile"
	
	a_record=$(dig $i A +short)
	if [ -z "$a_record" ]; then
		a_record="NONE"
		echo "<p class=\"red\">NONE</p>" >> "$outputfile"
	else
		echo "<p class=\"green\">$a_record</p>" >> "$outputfile"
	fi

	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking CNAME record</h3>" >> "$outputfile"
	dig $i CNAME +short  2>&1 >> "$outputfile"
	
	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking MX record<br></h3>" >> "$outputfile"
	dig $i MX +short 2>&1 >> "$outputfile"

	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking TXT record</h3>" >> "$outputfile"
	dig $i TXT +short 2>&1 >> "$outputfile"
	
	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking for DNSSEC<br></h3>" >> "$outputfile"
	delv $i 2>&1 >> "$outputfile" 
	echo "<br><br></div>" 2>&1 >> "$outputfile"
	# echo "<br>" >> "$outputfile"

	# Use nmap if desired
	if [ "$use_nmap" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h3> Doing portscanning on $i</h3>" 2>&1 >> "$outputfile"
		nmap -sS -sV -Pn -v -p0- -T4 $i 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# Use sslscan if desired
	if [ "$use_sslscan" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		if [[ "$a_record" == "NONE" ]]; then
			echo "No A-record, skipping scanning SSL on host" >> "$outputfile" 
		else
			echo "<h3>Doing sslscan on $i</h3>" 2>&1 >> "$outputfile"
			sslscan $i:443 2>&1 >> "$outputfile"
		fi
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# Use sslyze if desired
	if [ "$use_sslyze" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h3>Doing sslyze on $i</h3>" 2>&1 >> "$outputfile"
		sslyze $i 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# Breakline before next domain
	echo "<br>" >> "$outputfile"

	# clear a_record before next domain
	a_record=""
done

# Add information about ending scan
echo "<div class=\"header\">" 2>&1 >> "$outputfile"
echo "<h1>Ending scan... Hope you enjoyed the ride</h1>" 2>&1 >> "$outputfile"
echo "Ending scan at: " >> "$outputfile" && echo "<b><i>" >> "$outputfile" && date -uR 2>&1 >> "$outputfile" && echo "</b></i>" >> "$outputfile"
echo "<br><br></div>" 2>&1 >> "$outputfile"
echo "<br>" >> "$outputfile"

# put the tail on the outputfile
cat templates/htmltail >> "$outputfile"