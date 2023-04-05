/** Author einar@einarvalen.com 2015 */

module basestat.Common;

import std.format, std.file, std.array, std.socket, std.process, std.string, std.algorithm, std.regex;
import basestat.ps;

bool isMatchingName(string haystack, string needle) {
	if (0 == haystack.length) return false;
	if (0 == needle.length) return true;
	return !matchFirst(haystack,regex(needle)).empty();
}

string du(string dir) {
	if (dir == null || strip(dir) == "") return "";
	version (unittest) {
		auto pipes = pipeProcess(["du","-s","."], Redirect.stdout); 
	} else {
		auto pipes = pipeProcess(["du","-s",dir], Redirect.stdout); 
	}
	scope(exit) wait(pipes.pid);
	foreach (line; pipes.stdout.byLine) {
		string diskUsage;
		formattedRead(line, "%s\t", &diskUsage);
		return diskUsage;
	}
	return "";
}

unittest {
	assert(du(".") != "");
}

string hostname() {
	auto pipes = pipeProcess(["hostname","-f"], Redirect.stdout); 
	scope(exit) wait(pipes.pid);
	foreach (line; pipes.stdout.byLine) {
		string host;
		formattedRead(line, "%s", &host);
		return strip(host);
	}
	return "";
}

unittest {
	assert(hostname() != "");
}

string getIp(string hostname) {
	auto ih = new InternetHost;
	if (ih.getHostByName(hostname)) return InternetAddress.addrToString(ih.addrList[0]);
	return "0.0.0.0";
}

unittest {
	assert(getIp("localhost") == "127.0.0.1");
}

bool discoverJavaCryptographicExtension( string javaHome ) {
	try {
		string fileContents = readText( javaHome ~ "/jre/lib/security/README.txt" ); 
		return canFind( fileContents, "Unlimited Strength Java" );
	} catch (FileException e) {
		return false;
	}
}

string dirName(string project, string cluster,string basename) {
	auto writer = appender!string();
	formattedWrite(writer, "/opt/zqx/%s/%s/%s/", strip(project), strip(cluster), strip(basename));
	return writer.data;
}

unittest {
	assert( dirName("ikt","tc-ikt-u01", "base-soabaseldap-01") == "/opt/zqx/ikt/tc-ikt-u01/base-soabaseldap-01/");
	assert( dirName(" ikt","tc-ikt-u01 ", " base-soabaseldap-01 ") == "/opt/zqx/ikt/tc-ikt-u01/base-soabaseldap-01/");
}


