/** Author einar@einarvalen.com 2015 */

module basestat.Collect;

import std.format, std.stdio, std.string, std.conv, std.process, std.algorithm;
import std.file, std.path, std.regex, std.parallelism, std.array;
import basestat.Options, basestat.ProcStuff, basestat.Common, basestat.ps, basestat.xml, basestat.cache;

string[string][string] collectData(string[string][string] container, const ref Options options) {
	debug (Collect) { writeln("collectData() - begin"); }
 	auto taskHostname = task!hostname();
	taskPool.put(taskHostname);
	auto procMeminfo = ProcMeminfo("/proc/meminfo");
	immutable auto ip = getIp(hostname);
	immutable auto hostName = taskHostname.workForce();
  bool[string] autoproBaseMap;
  auto autoproBaseSet = fetchAutoproBaseSet();
	psJava( delegate void(ref basestat.ps.Proc proc) {
		debug (Collect) { writeln("delegate() - begin"); }
		if (proc.isTomcat || proc.isWeblogic) {
			debug (Collect) { writef("delegate() - %s\n", proc.isTomcat ? "Tomcat" : "Weblogic"); }
			auto taskDu = task!du(proc.getInstanceDir());
			taskPool.put(taskDu);
			proc.ip = ip;
			proc.hostname = hostName;
			collectAppServerConfig(proc);
			collectProcessInfo(proc, procMeminfo);
			proc.jce = discoverJavaCryptographicExtension(proc.java) ? "JCE" : "";
			proc.diskUsage = taskDu.workForce();
			proc.java_user_opts = exists(proc.catalinaBase ~ "/init.d/java_user_opts");
      proc.isAutopro = (proc.basename in autoproBaseSet) !is null;
			addToContainer(container, proc, options);
		}
		debug (Collect) { writeln("delegate() - end, Proc: ", proc); }
	});
	debug (Collect) { writeln("collectData() - end"); }
	return container;
}

unittest {
	const Options options = Options("", OutputFormat.JSON, true, true);
	string[string][string] container;
	container = collectData(container, options);
	debug (Collect) { writeln(container); }
	debug (Collect) { writef("container.length=%d\n",container.length); }
	assert(container.length == 4);
}

private void collectAppServerConfig(ref Proc proc) {
	version (unittest) {
		const string tomcatFilename = "server.xml";
		string weblogicFilename = "weblogic-config.xml"; //"weblogic-config-2.xml";
	} else {
		const string tomcatFilename = proc.catalinaBase ~ "/conf/server.xml";
		string weblogicFilename = proc.wlscfg ~ "/config/config.xml";
	}
	if (isTomcat(proc)) {
		if (proc.catalinaBase.empty) return;
		proc.port = parseTomcatConfig(tomcatFilename);
	} else if (isWeblogic(proc)) {
		Server server;
		if (proc.wlscfg.empty)
		   try { proc.wlscfg = findWeblogicAdminServerCfg(proc.middlewareHome, proc.wlsname); } catch (Exception e) {}
		if (proc.wlscfg.empty) return;
		weblogicFilename = proc.wlscfg ~ "/config/config.xml";
		parseWeblogicConfig(server, weblogicFilename, proc.wlsname, proc.pid, proc.hostname);
		proc.port = server.port;
		proc.cluster = server.cluster;
		proc.machine = server.machine; 
		proc.servername = server.servername;
		proc.domain = server.domain;
	}
}

private void collectProcessInfo(ref Proc proc, ref ProcMeminfo procMeminfo) {
	auto statm = ProcPidStatm(proc.pid);
	proc.memoryTotal = statm.total();
	proc.memoryData = statm.data();
	auto status= ProcPidStatus(proc.pid);
	proc.threads = status.threads();
	proc.gid = status.gid();
	proc.uid = status.uid();
	proc.sysMemoryTotal = procMeminfo.total();
	proc.sysMemoryFree = procMeminfo.free();
}

private void addToContainer(ref string[string][string] container, ref Proc proc, const ref Options options) {
	if (isMatchingName(proc.basename ~ proc.wlsname, options.baseNameRegex))
		container[to!string(proc.pid)] = proc.asMap();
}

private string getInstanceDir(const Proc proc) {
	if (proc.isTomcat) {
		return dirName(proc.project, proc.cluster, proc.basename);
	} else if (proc.isWeblogic) {
		return proc.wlscfg;
	}
	return "JavaInstanceDir";
}


private string domainAdminServer(string middlewareHome, string serverName) {
	const string pathname = middlewareHome ~ "/user_projects/domains/"; 
	static auto ctr = ctRegex!(`^.*/domains/(?P<domain>.+?)/servers/.+?`,"m");
	auto dirName = dirEntries(pathname, SpanMode.breadth)
		.filter!(a => a.isDir && serverName == std.path.baseName(a.name)).array;
	return matchFirst(dirName.to!string, ctr)["domain"].to!string;
}

private string findWeblogicAdminServerCfg(string middlewareHome, string serverName) {
	auto domain = domainAdminServer(middlewareHome, serverName);
	return domain.empty ? "" : middlewareHome ~ "/user_projects/domains/" ~ domain;
}

unittest {
	static string mv = "/tmp/Oracle/Middleware";
	mkdirRecurse(mv ~ "/user_projects/domains/domain-adm-u02/servers/AdminServer7020"); 
	mkdirRecurse(mv ~ "/user_projects/domains/domain-ikt-u01/servers/AdminServer7001"); 
	assert("domain-ikt-u01" == domainAdminServer(mv, "AdminServer7001"));
	assert("domain-adm-u02" == domainAdminServer(mv, "AdminServer7020"));
	assert(findWeblogicAdminServerCfg(mv, "AdminServer7020") == mv ~ "/user_projects/domains/domain-adm-u02");
	assert(findWeblogicAdminServerCfg(mv, "AdminServer7001") == mv ~ "/user_projects/domains/domain-ikt-u01");
}
	
private bool[string] fetchAutoproBaseSet() {
	version (unittest) {
		string etcDir = "/tmp";
	} else {
		string etcDir = "/etc";
	}
	debug (Collect) { writeln("etcDir=",etcDir); }
  bool[string] hashSet;
	try {
  	string[] ary = dirEntries(etcDir, SpanMode.shallow)
  		.filter!(f => -1 < f.name.indexOf("base-") && !f.name.endsWith(".rb") && f.isFile)
  		.map!(f => std.path.baseName(f.name))
  		.array;
		debug (Collect) { writeln("ary=",ary); }
    foreach (tcBase; ary) {
		  debug (Collect) { writeln("tcBase=",tcBase); }
      hashSet[tcBase] = true;
    }
	} catch (Exception e) {
		// Ignore
	}
	return hashSet;
}

unittest {
  executeShell("touch /tmp/base-mariasys-01");
  executeShell("touch /tmp/base-mariasys-02");
  auto autoproBaseSet = fetchAutoproBaseSet();
  assert(autoproBaseSet.length == 2);
  assert("base-mariasys-01" in autoproBaseSet);
  string basename = "base-mariasys-02";
  bool isAutopro;
  isAutopro = (basename in autoproBaseSet) !is null;
  assert(isAutopro == true);
  assert(!("base-mariasys-03" in autoproBaseSet));
}
