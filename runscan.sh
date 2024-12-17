#!/bin/bash

# Prints the help
function show_help {
	printf "runscan -l [list] \t Run the scan for the domains listed in file\n"
	printf "runscan -o [output] \t Write output to HTML outputfile, default is scanout.html\n"
	printf "runscan -n \t\t Use nmap to scan all ports on domain\n"
	printf "runscan -s \t\t Use sslscan to scan ssl-connection\n"
	printf "runscan -y \t\t Use sslyze to scan ssl-connection\n"
	printf "runscan -p \t\t Also output a PDF-file with the results\n"
	printf "runscan -h \t\t Show this help\n"
}

# Initialize variables
domains=""
number_of_domains=0
use_nmap=false
use_sslscan=false
use_sslyse=false
outputfile=scanout.html
output_pdf=false
a_record=""

# Reset if getops has been used previously
OPTIND=1

# Handle auguments
while getopts "pl:o:hnsy" opt; do
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
		p)
			output_pdf=true
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
echo "<div class=\"header\">" 2>&1 >> "$outputfile"
echo "<h1>Hang on!1</h1>" 2>&1 >> "$outputfile"

# Starting information
echo "Starting scan at: " >> "$outputfile" && echo "<br><b><i>" >> "$outputfile" && date -uR 2>&1 >> "$outputfile" && echo "</b></i><br>" >> "$outputfile" 

# Info on number of domains to be scanned
echo "<br>Number of domains to be scanned: <br><b><i>"$number_of_domains"</b></i><br>" >> "$outputfile"

# DNS-info - always do DNS-scanning
echo "<br>DNS-queries: <b><i><div class=\"green\">YES</div></b></i>" >> "$outputfile"

# Portscanning information
echo "<br>Scanning ports with nmap: " >> "$outputfile"
if [ "$use_nmap" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<div class=\"green\">YES</div>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<div class=\"red\">NO</div>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

# sslscan information
echo "<br>Analysis with sslscan: " >> "$outputfile"
if [ "$use_sslscan" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<div class=\"green\">YES</div>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<div class=\"red\">NO</div>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

# sslyze information
echo "<br>Analyses with sslyze: " >> "$outputfile"
if [ "$use_sslyze" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"green\">YES</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"red\">NO</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

# pdf-output information
echo "<br>Outputting PDF with pandoc: " >> "$outputfile" 
if [ "$output_pdf" = true ]; then 
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"green\">YES</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile" 
else
	echo "<b><i>" >> "$outputfile" && echo "<p class=\"red\">NO</p>" >> "$outputfile" && echo "</b></i>" >> "$outputfile"
fi

echo "<br>" >> "$outputfile"
echo "</div>" 2>&1 >> "$outputfile"
# echo "<br>" >> "$outputfile"

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
	
	# Find and store A-record - if no A-record found, store the value NONE 
	a_record=$(dig $i A +short)
	if [ -z "$a_record" ]; then
		a_record="NONE"
		echo "<p class=\"red\">NONE</p>" >> "$outputfile"
	else
		echo "<p class=\"green\">$a_record</p>" >> "$outputfile"
	fi

	# If an A-record exists, do reverse lookup
	echo "<hr>" >> "$outputfile"
	if [[ "$a_record" == "NONE" ]]; then
		echo "<h3>No A-record, skipping doing Reverse DNS-lookup</h3>" >> "$outputfile" 
	else
		echo "<h3>Reverse DNS for $i</h3>" 2>&1 >> "$outputfile"
		dig -x $a_record +short 2>&1 >> "$outputfile"
	fi

	# Check if domain has CNAME registered
	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking CNAME record</h3>" >> "$outputfile"
	dig $i CNAME +short  2>&1 >> "$outputfile"
	
	# Check if domain has MX records
	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking MX record<br></h3>" >> "$outputfile"
	dig $i MX +short 2>&1 >> "$outputfile"

	# Check if domain has TXT records
	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking TXT record</h3>" >> "$outputfile"
	dig $i TXT +short 2>&1 >> "$outputfile"
	
	# Check if domain has setup DNSSEC
	echo "<hr>" >> "$outputfile"
	echo "<h3>Checking for DNSSEC<br></h3>" >> "$outputfile"
	delv $i 2>&1 >> "$outputfile" 
	echo "<br><br></div>" 2>&1 >> "$outputfile"
	# echo "<br>" >> "$outputfile"

	# Use nmap if desired, and an A-record exists
	if [ "$use_nmap" = true ]; then
		if [[ "$a_record" == "NONE" ]]; then
			echo "<h3>No A-record, skipping portscan</h3>" >> "$outputfile" 
		else
			echo "<div class=\"info\">" 2>&1 >> "$outputfile"
			echo "<h3> Doing portscanning on $i</h3>" 2>&1 >> "$outputfile"
			# nmap -sS -sV -Pn -v -p0- -T4 $i 2>&1 >> "$outputfile"
			nmap -sS -sV -Pn -p0- -T4 $i 2>&1 >> "$outputfile"
			echo "</div>" 2>&1 >> "$outputfile"
		fi
	fi

	# Use sslscan if desired, and an A-record exists
	if [ "$use_sslscan" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		if [[ "$a_record" == "NONE" ]]; then
			echo "<h3>No A-record, skipping scanning SSL on host</h3>" >> "$outputfile" 
		else
			echo "<h3>Doing sslscan on $i</h3>" 2>&1 >> "$outputfile"
			sslscan --no-color $i:443 2>&1 >> "$outputfile"
		fi
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# Use sslyze if desired, and an A-record exists
	if [ "$use_sslyze" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		if [[ "$a_record" == "NONE" ]]; then
			echo "<h3>No A-record, skipping scanning SSL on host</h3>" >> "$outputfile" 
		else
			echo "<div class=\"info\">" 2>&1 >> "$outputfile"
			echo "<h3>Doing sslyze on $i</h3>" 2>&1 >> "$outputfile"
			sslyze $i 2>&1 >> "$outputfile"
		fi
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

# Put the tail on the outputfile
cat templates/htmltail >> "$outputfile"

# If use requests a PDF-file make it
	if [ "$output_pdf" = true ]; then
		# Use pandoc to create a PDF-file
		echo "Cooking PDF output"
		pandoc "$outputfile" -t latex -o "$outputfile".pdf 
	fi 