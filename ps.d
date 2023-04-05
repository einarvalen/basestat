/** Author einar@einarvalen.com 2015 */

// TODO: find /opt/Oracle/Middleware/user_projects/domains -name AdminServer701

module basestat.ps;

import std.format, std.regex, std.stdio, std.process, std.conv, std.file, std.string, std.path, std.algorithm, std.array;

struct Proc {
	int pid, threads, uid, gid, memoryTotal, memoryData, sysMemoryTotal, sysMemoryFree, port, xms, xmx;
	double pcpu;
	bool conformsToConfigconvention, isLogDirSet, java_user_opts, warFilesInWebapps, dataBaseWarFiles, isAutopro;
	string java, jce, catalinaBase, catalinaHome, user, project, cluster, basename, hostname, ip, diskUsage, 
		   middlewareHome, domain, wlsname, machine, wlscfg, servername;
	immutable static string[] fieldnames = ["Basename","CatalinaBase","CatalinaHome","Cluster","DiskUsage",
			  "Domain","Gid","Hostname","Ip","Java","JCE","Machine","MemoryData","MemoryTotal","MiddlwareHome",
			  "Pcpu","Pid","Port","Project","Servername","SysMemoryFree","SysMemoryTotal","Threads","Uid",
			  "User","WlsCfg","WlsName","Xms","Xmx","/data/b/conf","isLogDirSet","java_user_opts",
			  "WarFilesInWebapps","/data/b/warfiles","isAutopro"];
	string[string] asMap() {
		string[string] map;
		map["Pid"] = to!string(pid);  // process_id
		map["Port"] = to!string(port);  // dest_port
		map["Threads"] = to!string(threads); // tread_count
		map["Uid"] = to!string(uid);
		map["Gid"] = to!string(gid);
		map["MemoryTotal"] = to!string(memoryTotal);  // committed_memory
		map["MemoryData"] = to!string(memoryData);
		map["DiskUsage"] = diskUsage;  // storage_used
		map["SysMemoryTotal"] = to!string(sysMemoryTotal);  // mem
		map["SysMemoryFree"] = to!string(sysMemoryFree);  // mem_free
		map["Pcpu"] = to!string(pcpu);  // cpu_load_percent
		map["Java"] = java;
		map["JCE"] = jce;
		map["CatalinaBase"] = catalinaBase;
		map["CatalinaHome"] = catalinaHome;
		map["User"] = user; // user
		map["Project"] = project;
		map["Cluster"] = cluster;
		map["Basename"] = basename;  // process
		map["Hostname"] = hostname;  //dest_host
		map["Ip"] = ip; // dest_ip
		map["Xms"] = to!string(xms);
		map["Xmx"] = to!string(xmx);
		map["MiddlwareHome"] = middlewareHome;
		map["Domain"] = domain;
		map["WlsName"] = wlsname;
		map["WlsCfg"] = wlscfg;
		map["Machine"] = machine;
		map["Servername"] = servername;
		map["/data/b/conf"] = (conformsToConfigconvention ? "true" : "false");
		map["isLogDirSet"] = (isLogDirSet ? "true" : "false");
		map["isAutopro"] = (isAutopro ? "true" : "false");
		map["java_user_opts"] = (java_user_opts ? "true" : "false");
		map["WarFilesInWebapps"] = (warFilesInWebapps ? "true" : "false");
		map["/data/b/warfiles"] = (dataBaseWarFiles ? "true" : "false");
		return map;
	}
}

void psJava(void delegate(ref Proc ) sink) {
	version (unittest) {
		string[] psCommand = ["cat","test-ps-collect.txt"];
	} else {
		string[] psCommand = ["ps","-C","java","-o", "pid,user,pcpu,command","--no-headers"];
	}
	auto pipes = pipeProcess(psCommand, Redirect.stdout);
	scope(exit) wait(pipes.pid);
	foreach (line; pipes.stdout.byLine) {
		debug (ps) { writeln("psjava() - begin"); }
		Proc proc;
		if (extractProcessInfo(to!string(line), proc)) 
			sink(proc);
		debug (ps) { writeln("psjava() - end"); }
	}
}

unittest {
	bool called = false;
	psJava( delegate void(ref Proc proc) {
			called = true;
			if (proc.pid == 1) {
				assert(proc.user == "tcikt06");
				assert(proc.pcpu == 0.0);
				assert(proc.catalinaBase == "/opt/suv/ikt/tc-ikt-u06/base-soabasisvaluta-01");
				assert(proc.java == "/opt/java/1.8");
			} else if (proc.pid == 2) {
				assert(proc.user == "tcvt07");
				assert(proc.pcpu == 1.3);
				assert(proc.catalinaBase == "/opt/suv/vt/tc-vt-u07/base-datex2-01");
				assert(proc.catalinaHome == "/opt/apache/tomcat/8.0");
			}
		});
	assert( called);
}

private bool extractProcessInfo(string line, ref Proc proc) {
	static auto ctrPs = ctRegex!(`\s*?(?P<pid>\d+)\s+?(?P<user>\w+)\s+?(?P<pcpu>[\d\.]+)\s+?(?P<java>\S+)/bin/java\s+?(?P<options>.*)`,"m");
	static auto ctrXms = ctRegex!(`^.*-Xms(?P<xms>\d+)\w\s.+?`,"m");
	static auto ctrXmx = ctRegex!(`^.*-Xmx(?P<xmx>\d+)\w\s.+?`,"m");
	static auto ctrConfIsOnCp = ctRegex!(`-classpath\s+.*?/data/(?P<basename>.+?)/conf.*\s`,"m");
	static auto ctrCatalinaHome = ctRegex!(`-Dcatalina.home=(?P<catalina_home>.+?)\s+?`, "m");
	static auto ctrCatalinaBase = ctRegex!(`-Dcatalina.base=(?P<catalina_base>.+?)\s+?`, "m");
	static auto ctrMiddlewareHome = ctRegex!(`-Dplatform.home=(?P<middleware_home>.+?)/wlserver`, "m");
	static auto ctrWlsCfg = ctRegex!(`-Dweblogic.system.BootIdentityFile=(?P<wlscfg>.+?)/servers`, "m");
	static auto ctrWlsName = ctRegex!(`-Dweblogic.Name=(?P<wlsname>.+?)\s+?`, "m");
	auto m = matchFirst(line, ctrPs);
	if (m.empty) return false;
	try { proc.pid = to!int(m["pid"]); } catch (Exception e) {}
	try { proc.user =  to!string(m["user"]); } catch (Exception e) {}
	if (m["java"] != null) try { proc.pcpu = to!double(m["pcpu"]); } catch (Exception e) {}
	try { proc.java = to!string(m["java"]); } catch (Exception e) {}
	proc.conformsToConfigconvention = isConformingToSuvConfigConventions(matchFirst(line, ctrConfIsOnCp)["basename"]);
	debug (ps) writefln("proc.conformsToConfigconvention=%s", proc.conformsToConfigconvention ? "true" : "false");
	auto options =  m["options"];
	try { proc.xms = to!int(matchFirst(options,ctrXms)["xms"]); } catch (Exception e) {}
	try { proc.xmx = to!int(matchFirst(options,ctrXmx)["xmx"]); } catch (Exception e) {}
	proc.catalinaHome = to!string(matchFirst(options,ctrCatalinaHome)["catalina_home"]);
	proc.catalinaBase = to!string(matchFirst(options,ctrCatalinaBase)["catalina_base"]);
	proc.middlewareHome =  to!string(matchFirst(options,ctrMiddlewareHome)["middleware_home"]);
	proc.wlscfg = to!string(matchFirst(options,ctrWlsCfg)["wlscfg"]);
	proc.wlsname = to!string(matchFirst(options,ctrWlsName)["wlsname"]);
	proc.isLogDirSet = isLogDirEnvVariableSet();
  debug (ps) writefln("proc.catalinaBase=%s;",proc.catalinaBase);
	extractBase( proc.catalinaBase, proc);
	proc.warFilesInWebapps = listWarFilesInDir(proc.catalinaBase ~ "/webapps").length > 0;
	proc.dataBaseWarFiles = listWarFilesInDir("/data/" ~ proc.basename ~ "/warfiles").length > 0;
	return isTomcat(proc) || isWeblogic(proc);
}
	
bool isConformingToSuvConfigConventions(string basename) {
	try {
		auto propertiesFiles = filter!`endsWith(a.name,".properties")`(dirEntries("/data/" ~ basename ~ "/conf/", SpanMode.depth));
		foreach(f;  propertiesFiles) {
    		debug (ps) writeln(f.name);
			return true;
		}
	} catch (Exception e) {
	}
	return false;
}

bool isTomcat(const ref Proc proc) @safe pure nothrow @nogc {
	return proc.catalinaBase.length > 0;	
}
		
bool isWeblogic(const ref Proc proc) @safe pure nothrow @nogc {
	return proc.wlsname.length > 0;	
}

private void extractBase( string catalinaBase, ref Proc proc) {
	if (catalinaBase.length > 0 && catalinaBase.startsWith("/opt/suv/") )
		formattedRead(catalinaBase, "/opt/suv/%s/%s/%s", &proc.project, &proc.cluster, &proc.basename);
}

private bool isLogDirEnvVariableSet() {
	static auto ctrXms = ctRegex!(`LOGDIR`);
	foreach (line; File("/proc/self/environ", "r").byLine(KeepTerminator.no, '\x00')) {
		if (!matchFirst(line,ctrXms).empty()) return true;
	}
	return false;
}

private string[] listWarFilesInDir(string path) {
	string[] ary;
	try {
	ary =  dirEntries(path, SpanMode.shallow)
		.filter!(f => f.name.endsWith(".war") && !f.name.endsWith("demods.war") && f.isFile)
		.map!(f => std.path.baseName(f.name))
		.array;
	} catch (Exception e) {
		// Ignore
	}
	return ary;
}

unittest {
	Proc proc;
	extractBase("", proc);
	extractBase("/opt/suv/ikt/tc-ikt-u06/base-soabasisvaluta-01", proc);
	assert(proc.basename == "base-soabasisvaluta-01");
	assert(proc.project == "ikt");
	assert(proc.cluster == "tc-ikt-u06");
	assert(!isLogDirEnvVariableSet());
	assert(proc.isLogDirSet == false);
	assert(proc.java_user_opts == false);
	Proc proc2;
	extractBase("/opt/suv/vt/tc-vt-u07/base-datex2-01", proc2);
	assert(proc2.basename == "base-datex2-01");
	assert(proc2.project == "vt");
	assert(proc2.cluster == "tc-vt-u07");
}

unittest {
	void output(const ref Proc proc) {
		writeln("Pid: ", proc.pid);
		writeln("User: ", proc.user);
		writeln("Pcpu: ", proc.pcpu);
		writeln("Java: ", proc.java);
		writeln("Xms: ", proc.xms);
		writeln("Xmx: ", proc.xmx);
		writeln("CatalinaHome: ", proc.catalinaHome);
		writeln("CatalinaBase: ", proc.catalinaBase);
		writeln("MiddlewareHome: ", proc.middlewareHome);
		writeln("Domain: ", proc.domain);
		writeln("WlsName: ", proc.wlsname);
	}
	int count = 0;
	foreach (line; File("test-ps.txt", "r").byLine) {
		Proc proc;
		if (!extractProcessInfo(to!string(line), proc) ) continue;
		debug (ps) { output(proc); }
		if (proc.pid == 3433) { assert(proc.user == "tcikt06"); ++count; }
		if (proc.pid == 8357) { assert(proc.pcpu == 1.3); ++count; }
		if (proc.pid == 8357) { assert(proc.java == "/opt/java/1.8"); ++count; }
		if (proc.pid == 3433) { assert(proc.xms == 128); ++count; }
		if (proc.pid == 8357) { assert(proc.xmx == 2048); ++count; }
		if (proc.pid == 8357) { assert(proc.catalinaHome == "/opt/apache/tomcat/8.0"); ++count; }
		if (proc.pid == 3433) { assert(proc.catalinaBase == "/opt/suv/ikt/tc-ikt-u06/base-soabasisvaluta-01"); ++count; }
		if (proc.pid == 3433) { assert(proc.middlewareHome== ""); ++count; }
		if (proc.pid == 8357) { assert(proc.wlscfg == ""); ++count; }
		if (proc.pid == 6342) { assert(proc.user == "weblogic"); ++count; }
		if (proc.pid == 6342) { assert(proc.pcpu == 2.0); ++count; }
		if (proc.pid == 6342) { assert(proc.java == "/opt/Oracle/Middleware/jrmc-4.0.1-1.6.0"); ++count; }
		if (proc.pid == 5708) { assert(proc.xms == 1768); ++count; }
		if (proc.pid == 5708) { assert(proc.xmx == 1768); ++count; }
		if (proc.pid == 6342) { assert(proc.middlewareHome== "/opt/Oracle/Middleware"); ++count; }
		if (proc.pid == 6342) { assert(proc.wlscfg == "/opt/Oracle/Middleware/user_projects/domains/domain-vt-u02"); ++count; }
		if (proc.pid == 6342) { assert(proc.catalinaHome == ""); ++count; }
		if (proc.pid == 6342) { assert(proc.catalinaBase == ""); ++count; }
		if (proc.pid == 7343) { assert(proc.xms == 4444); ++count; }
		if (proc.pid == 7343) { assert(proc.xmx == 5555); ++count; }
		if (proc.pid == 23428) { assert(proc.user == "tcvt14"); ++count; }
	}
	debug (ps) { writefln("Count=%s", count); }
	assert(count == 21);
}

