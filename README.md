# Runscan - run a scan ...
Runscan scans a list of domains and outputs the results as HTML.

Runscan takes the following commandline-options:

## Notes on delv on MacOS
The delv command on default MacOS doesnt work when trying to check for DNSSEC. Install the delv command with Homebrew:

brew install bind

Restart your terminal and confirm you are using the Homebrew delv

 ~ % which delv
/opt/homebrew/bin/delv
