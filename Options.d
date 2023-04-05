/** Author einar@einarvalen.com 2015 */

module basestat.Options;

import core.stdc.stdio, std.conv, std.getopt, std.socket, std.datetime;

enum OutputFormat { Default, JSON, CSV, CSV_SkipHeadings, Splunk, Help };

struct Options { string baseNameRegex; OutputFormat outputFormat; bool outputTomcatColumns; bool outputWeblogicColumns; }

Options parseArguments(ref Options options, string[] args) {
	bool jsonOutput, csvOutput, splunkOutput, help, skip_headings;
 	getopt(args, 
			"json", &jsonOutput, "csv", &csvOutput, "skip_headings", &skip_headings, 
			"splunk", &splunkOutput, "help", &help, "name", &options.baseNameRegex, 
			"tomcat", &options.outputTomcatColumns, "weblogic",	&options.outputWeblogicColumns
	);
	if (help) options.outputFormat = OutputFormat.Help;
	else if (skip_headings) options.outputFormat = OutputFormat.CSV_SkipHeadings;
	else if (csvOutput) options.outputFormat = OutputFormat.CSV;
	else if (jsonOutput) options.outputFormat = OutputFormat.JSON;
	else if (splunkOutput) options.outputFormat = OutputFormat.Splunk;
	else options.outputFormat = OutputFormat.Default;
	return options;
}

///
unittest {
	import std.stdio;
	Options options;
	assert(options.parseArguments(["programName"]).outputFormat == OutputFormat.Default);
	assert(options.parseArguments(["programName", "--json"]).outputFormat == OutputFormat.JSON);
	assert(options.parseArguments(["programName", "--splunk"]).outputFormat == OutputFormat.Splunk);
	assert(options.parseArguments(["programName", "--help"]).outputFormat == OutputFormat.Help);
	options.parseArguments(["programName", "--name", "aktk", "--csv", "--skip_headings", "--tomcat", "--weblogic"]);
	assert(options.baseNameRegex ==  "aktk");
   	assert(options.outputFormat == OutputFormat.CSV_SkipHeadings);
  	assert(options.outputTomcatColumns);
 	assert(options.outputWeblogicColumns);
}
