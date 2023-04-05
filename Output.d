/** Author einar@einarvalen.com 2015 */

module basestat.Output;

import std.stdio, std.datetime, std.json, std.csv;
import basestat.Options, basestat.ps;

void writeOutput(const ref Options options, const string[string][string] container) {
	switch (options.outputFormat) {
		default: { writeDefaultOutput(container); break; }
		case  OutputFormat.CSV: { writeCSV(container, false, getFilter(options)); break; }
		case  OutputFormat.CSV_SkipHeadings: { writeCSV(container, true, getFilter(options)); break; }
		case  OutputFormat.JSON: { writeJSON(container); break; }
		case  OutputFormat.Splunk: { writeSplunkOutput(container); break; }
	}
}

private void writeCSV(const string[string][string] container, bool skip_headings, Filter filter) {
	bool first = true;
	foreach (row; container.values ) {
		if (first && !skip_headings) {
			writestr( toCsv(row, true, filter) );
			first = false;
		} 
		writestr(toCsv(row, false, filter));
	}
}

private string toCsv(const string[string] map, bool headings, Filter filter) {
	string results = "";
	bool first = true;
	foreach (string key; Proc.fieldnames) {
		if (filter(key)) {
		//	auto value = map[to!string(key)];
			auto value = map.get(key, "");
			string str = headings ? key : value;
			if (first) {
				results ~= "\"" ~ str ~ "\""; 
				first = false;
			} else {
				string s = ",\"" ~ str ~ "\"";
				results ~= s;
			} 
		}
	}
	return results;
}

private void writeJSON(const string[string][string] container) {
	JSONValue json = container;
	writestr(json.toString());
}

private void writeSplunkOutput(const string[string][string] container) {
	foreach (pocAsMap; container.values) {
	    string separator = "\n" ~ Clock.currTime().toISOExtString() ~ " severity=info ";
		foreach (key; pocAsMap.keys) {
			writef("%s%s=\"%s\"", separator, translateToSplunkTerms(key), pocAsMap[key]);
			separator = ", ";
		}
	}
}

private void writeDefaultOutput(const string[string][string] container) {
	foreach (pocAsMap; container.values) {
		foreach (key; pocAsMap.keys) {
			writef("%s=%s\n", key, pocAsMap[key]);
		}
	}
}

private string translateToSplunkTerms(string termToTranslate) {
	switch  (termToTranslate) {
		default: break;
		case "Pid" : return "process_id";
		case "Port" : return "dest_port";
		case "Threads" : return "thread_count";
		case "MemoryTotal" : return "committed_memory";
		case "DiskUsage" : return "storage_used";
		case "SysMemoryTotal" : return "mem";
		case "SysMemoryFree" : return "mem_free";
		case "Pcpu" : return "cpu_load_percent";
		case "User" : return "user";
		case "Basename" : return "process";
		case "WlsName" : return "process";
		case "Hostname" : return "dest_host";
		case "Ip" : return "dest_ip";
	}
	return termToTranslate;
}


private bool includeTomcat(string key) @safe nothrow {
	int[string] inclTomcat = [
		"Pid":1,"Port":1,"Threads":1,"Uid":1,"Gid":1,"MemoryTotal":1,"MemoryData":1,"DiskUsage":1,"SysMemoryTotal":1,
		"SysMemoryFree":1,"Pcpu":1,"Java":1,"JCE":1,"CatalinaBase":1,"CatalinaHome":1,"User":1,"Project":1,"Cluster":1,
		"Basename":1,"Hostname":1,"Ip":1,"Xms":1,"Xmx":1,"MiddlwareHome":0,"Domain":0,"WlsName":0,"WlsCfg":0,"machine":0,
		"servername":0,"/data/b/conf":1,"isLogDirSet":1,"java_user_opts":1,"WarFilesInWebapps":1,"/data/b/warfiles":1,"isAutopro":1
	];
	return key in inclTomcat && inclTomcat[key] == 1;
}

private bool includeWeblogic(string key) @safe nothrow {
	int[string] inclWeblogic = [
		"Pid":1,"Port":1,"Threads":1,"Uid":1,"Gid":1,"MemoryTotal":1,"MemoryData":1,"DiskUsage":1,"SysMemoryTotal":1,
		"SysMemoryFree":1,"Pcpu":1,"Java":1,"JCE":0,"CatalinaBase":0,"CatalinaHome":0,"User":1,"Project":0,"Cluster":1,
		"Basename":0,"Hostname":1,"Ip":1,"Xms":1,"Xmx":1,"MiddlwareHome":1,"Domain":1,"WlsName":1,"WlsCfg":1,"machine":1,
		"servername":1,"/data/b/conf":0,"isLogDirSet":0,"java_user_opts":0,"WarFilesInWebapps":0,"/data/b/warfiles,":0,"isAutopro":0
	];
	return key in inclWeblogic && inclWeblogic[key] == 1;
}

private bool includeAll(string key) @safe nothrow {
	return true;
}

alias Filter = bool function(string);

private Filter getFilter(const ref Options options) {
	if (options.outputTomcatColumns) return &includeTomcat;
	if (options.outputWeblogicColumns) return &includeWeblogic;
	return &includeAll;
}

version (unittest) {
	static string result;
	private void writestr(string str) {
		result ~= str ~ '\n';
	}
} else {
	private void writestr(string str) {
		writeln(str);
	}
}

unittest {
	import basestat.ps, std.string;
	bool containsHeadings() {
		return result.indexOf("Ip") > -1;
	}
	bool containsData() {
		return result.indexOf("42") > -1 && result.indexOf("43") > -1;
	}
	bool containsTomcatColumns() {
		return result.indexOf("catalinaHome-") > -1;
	}
	bool containsWeblogicColumns() {
		return result.indexOf("domain-") > -1;
	}
	void testOutputCsvWeblogicIncludeHeadings(const string[string][string] container) {
		const Options opts = Options("", OutputFormat.CSV, false, true);
		writeOutput(opts, container);
		assert(containsData()); 
		assert(containsHeadings()); 
		assert(containsWeblogicColumns()); 
		assert(!containsTomcatColumns());
		result = "";
	}
	void testOutputCsvWeblogicSkipHeadings(const string[string][string] container) {
		const Options opts = Options("", OutputFormat.CSV_SkipHeadings, false, true);
		writeOutput(opts, container);
		assert(containsData()); 
		assert(!containsHeadings()); 
		assert(containsWeblogicColumns()); 
		assert(!containsTomcatColumns());
		result = "";
	}
	void testOutputCsvTomcatIncludeHeadings(const string[string][string] container) {
		const Options opts = Options("", OutputFormat.CSV, true, false);
		writeOutput(opts, container);
		assert(containsData()); 
		assert(containsHeadings()); 
		assert(!containsWeblogicColumns()); 
		assert(containsTomcatColumns());
		result = "";
	}
	void testOutputCsvTomcatSkipHeadings(const string[string][string] container) {
		const Options opts = Options("", OutputFormat.CSV_SkipHeadings, true, false);
		writeOutput(opts, container);
		assert(containsData()); 
		assert(!containsHeadings()); 
		assert(!containsWeblogicColumns()); 
		assert(containsTomcatColumns());
		result = "";
	}
	void testOutputJson(const string[string][string] container) {
		const Options opts = Options("", OutputFormat.JSON, true, true);
		writeOutput(opts, container);
		assert(containsData()); 
		assert(containsHeadings()); 
		assert(containsWeblogicColumns()); 
		assert(containsTomcatColumns());
		result = "";
	}
	Proc procA = Proc(42), procB = Proc(43);
	procA.catalinaHome = "catalinaHome-A";	procA.domain = "domain-A";
	procB.catalinaHome = "catalinaHome-B";	procB.domain = "domain-B";
	string[string][string] container;
	container["proc-A"] = procA.asMap();	
	container["proc-B"] = procB.asMap();
	testOutputCsvWeblogicIncludeHeadings(container);
	testOutputCsvWeblogicSkipHeadings(container);
	testOutputCsvTomcatIncludeHeadings(container);
	testOutputCsvTomcatSkipHeadings(container);
	testOutputJson(container);
}
