/**
 Author einar@einarvalen.com 2015 

 Prints status for Tomcat and weblogic instances on localhost

*/

module basestat.main;

import std.stdio;
import basestat.Options, basestat.Output, basestat.Collect;

void main(string[] args) {
	Options options;
	parseArguments(options, args);
  	if (options.outputFormat == OutputFormat.Help) {
		printHelp();
	} else {
		string[string][string] container; // Associative string array with key type string
		writeOutput(options, collectData(container, options));
	}
}

void printHelp() {
	writeln(
		"Prints status for Tomcat-bases on localhost\n\nUsage: basestat [options]\n"
		"   basename-regex: Regular expression to qualify a base to list\n"
		"   --help:   This display.\n"
		"   --name:   basename-regex. \n"
		"   --json:   Output in json format.\n"
		"   --splunk: Special output format for Splunk to read.\n"
		"   --csv :   Output is Comma Separated Value format.\n"
		"   --skip_headings: Csv output without headings.\n"
		"   --tomcat: Expect only Tomcat related data.\n"
		"   --weblogic: Expect only Weblogic related data.\n"
		"      Example:\n"
		"         skip_headings=''\n"
		"         for host in hostA hostB hostC; do\n"
		"           ssh -C user@${host} \"basestat --csv $skip_headings --name kanal\"\n"
		"           skip_headings='--skip_headings'\n"
		"         done\n"
	);
}
