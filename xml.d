/** Author einar@einarvalen.com 2015 */

module basestat.xml;

import std.regex, std.stdio, std.file, std.conv, std.string, std.parallelism;
import basestat.cache;

static private Cache cache;

static this() {
	cache = new Cache();
}

void parseWeblogicConfig(out Server server, string filename, string servername, int pid, string listenAddress) {
	if (cache.findInCache(server, filename, servername, pid)) return;
	static auto ctrDomain = ctRegex!(`<name>(?P<domain>.*?)</name>`,"is");
	static auto ctrServer = ctRegex!(`<server>(?P<servertag>.*?)</server>`,"is");
	static auto ctrName = ctRegex!(`<name>(?P<servername>.*?)</name>`,"is");
	static auto ctrMachine = ctRegex!(`<machine>(?P<machinename>.*?)</machine>`,"is");
	static auto ctrPort = ctRegex!(`<listen-port>(?P<port>.*?)</listen-port>`,"is");
	static auto ctrCluster = ctRegex!(`<cluster>(?P<clustername>.*?)</cluster>`,"is");
	static auto ctrListenAddress = ctRegex!(`<listen-address>(?P<listenaddress>.*?)</listen-address>`,"is");
	auto immutable content = readText(filename);
	auto immutable domain = to!string(matchFirst(content,ctrDomain)["domain"]);
	foreach (m; matchAll(content, ctrServer)) {
		auto serverTag =  removeSslTag(m["servertag"]);
		server.initialize();
		server.pid = pid;
		server.servername = to!string(matchFirst(serverTag,ctrName)["servername"]);
		debug (xml) { writeln(server.servername); }
		server.machine = to!string(matchFirst(serverTag,ctrMachine)["machinename"]);
		try { server.port = to!int(matchFirst(serverTag,ctrPort)["port"]); } catch (Exception e) {}
		server.cluster = to!string(matchFirst(serverTag,ctrCluster)["clustername"]);
		server.listenAddress = to!string(matchFirst(serverTag,ctrListenAddress)["listenaddress"]);
		if (server.listenAddress.length == 0) server.listenAddress = listenAddress;
		server.domain = domain;
		server.filename = filename;
		cache.addToCache(server);
	}
	if (cache.findInCache(server, filename, servername, pid)) return;
	server.initialize();
}

private string removeSslTag(string str) {
	auto start = str.indexOf("<ssl>");
	auto end = str.indexOf("</ssl>");
	if (start < 0 || end < 0 || start > end) return str;
	return str[0..start] ~ str[end+6..str.length];
}

unittest {
	assert( "be" == removeSslTag("b<ssl>m</ssl>e"));
}

int parseTomcatConfig( string filename) {
	static auto ctr = ctRegex!(`<server\s+?port=.+?<Service name=\"Catalina\">.*?<Connector\s+?port=\"(?P<port>\d+?)\"\s+?protocol=\"HTTP.*?</server>`,"is");
	auto m = matchFirst(readText(filename), ctr); 
	auto port = m["port"];
	return port.length == 0 ? 0 : to!int(port);
}

private string disregardDomain(string hostname) {
	auto idx = hostname.indexOf(".");
	if (idx < 0) return hostname;
	return hostname[0 .. idx];
}

unittest {
	void output(Datasource datasource) {
		writeln("\nname: ", datasource.name);
  }
	void output(Server server) {
		writeln("\nServername: ", server.servername);
		writeln("ListenAddress: ", server.listenAddress);
		writeln("Machine: ", server.machine);
		writeln("Port: ", server.port);
		writeln("Cluster: ", server.cluster);
		writeln("Domain: ", server.domain);
	}
	int port = parseTomcatConfig("server.xml");
	assert(port == 16000);
	debug (xml) { writeln("\nTomcat port: ", port); }
	Server server;
	int pid = 456;
	parseWeblogicConfig(server, "weblogic-config.xml", "server-ehf-01", pid, "zqxujapp06.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp06");
	assert(server.port == 7140);
	assert(server.cluster == "cluster-ehf-01");
	assert(server.domain == "domain-oko-u01");
	parseWeblogicConfig(server, "weblogic-config.xml", "AdminServer7014", pid, "");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp01");
	assert(server.port == 7014);
	assert(server.cluster == "");
	parseWeblogicConfig(server, "weblogic-config.xml", "server-ehf-02", pid, "zqxujapp07.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp07");
	assert(server.port == 7140);
	assert(server.cluster == "cluster-ehf-01");
	///cache = cache.init;
	parseWeblogicConfig(server, "weblogic-config.xml", "non-existing-server", pid, "zqxujapp06.somesite.no");
	//writeln("server.port=", server.port);
	assert(server.port == 0);
	assert(disregardDomain("a.b.c") == "a");
	assert(disregardDomain("a") == "a");
	parseWeblogicConfig(server, "weblogic-config-2.xml", "server-qweloggen-01", pid, "zqxujapp21.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp21");
	assert(server.port == 7560);
	assert(server.cluster == "cluster-qweloggen-01");
	assert(server.domain == "domain-vt-u05");
	parseWeblogicConfig(server, "weblogic-config-3.xml", "server-nortraf-01", pid, "zqxujapp02.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp02");
	assert(server.port == 7170);
	assert(server.cluster == "cluster-nortraf-01");
	assert(server.domain == "domain-tmt-u02");
	parseWeblogicConfig(server, "weblogic-config-4.xml", "server-areg-01", pid, "zqxujapp02.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp02");
	assert(server.port == 7300);
	assert(server.cluster == "cluster-areg-01");
	assert(server.domain == "domain-tk-u01");
	parseWeblogicConfig(server, "weblogic-config-5.xml", "server-brutus-02", pid, "zqxujapp14.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "machine-zqxujapp14");
	assert(server.cluster == "cluster-brutus-01");
	assert(server.domain == "domain-tmt-u03");
	assert(server.port == 8600);
	parseWeblogicConfig(server, "weblogic-config-6.xml", "bi_server2", pid, "zqxujapp29.somesite.no");
	debug (xml) { output(server); }
	assert(server.machine == "zqxujapp29");
	assert(server.cluster == "bi_cluster");
	assert(server.domain == "domain-obiee-u01");
	assert(server.port == 19704);
}

unittest {
	void output(Datasource datasource) {
		writeln("\nname: ", datasource.name);
  }
  Datasource datasource;
  parseTomcatDatasource(datasource, "datasource-1.xml");
	debug (xml) { output(datasource); }
  parseTomcatDatasource(datasource, "datasource-2.xml");
	debug (xml) { output(datasource); }
}

void parseTomcatDatasource(datasource, "datasource-1.xml") {
}
