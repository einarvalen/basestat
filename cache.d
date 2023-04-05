/** Author einar@einarvalen.com 2016 */

module basestat.cache;

import std.stdio, std.file, std.string, std.conv;

struct Server {
	int port, pid;
	string cluster, machine, servername, domain, listenAddress, filename;
	bool isActive;
	void initialize() { port = 0, cluster = "", machine = "", servername = "", domain = "", listenAddress = "", filename = "", isActive = true; }
}

class Cache  {
	private Server[string] cache;
	this() { loadPersistentCache(); }


	void addToCache(ref Server server) {
		string key = server.servername ~ to!string(server.pid) ~ server.filename;
		cache[key] = server;
		debug(cache) writefln("cache unittest addToCache() - %s", key);
	}
	
	bool findInCache(out Server server, string filename, string servername, int pid) {
		string key = servername ~ to!string(pid) ~ filename;
	    if (key	in cache) {
			server = cache[key];
			server.isActive = true;
			return true;
		}
		return false;
	}
	
	static const format = "port=%d,cluster='%s',machine='%s',servername='%s',domain='%s',listenAddress='%s',filename='%s',pid=%d,isActive='%s'";
	static const string persistentFilename = "/tmp/basestat-cache.txt";
	
	private void persistCache() {
		auto file = File(persistentFilename, "wt"); 
		scope (exit) { file.flush(); file.close(); }
		debug(cache) writefln("persistCache() to file %s", persistentFilename);
		foreach(k, v; cache) if (v.isActive == true) {
			debug (cache) writefln(format, v.port, v.cluster, v.machine, v.servername, v.domain, v.listenAddress, v.filename, v.pid, v.isActive);
			file.writefln(format, v.port, v.cluster, v.machine, v.servername, v.domain, v.listenAddress, v.filename, v.pid, v.isActive);
		}
	}
	
	private void loadPersistentCache() {
		import std.format;
		if (!exists(persistentFilename)) return;
		debug(cache) writefln("loadPersistentCache() from file %s", persistentFilename);
		foreach (line; File(persistentFilename, "rt").byLine()) {
			Server v;
			formattedRead(line, format, &v.port, &v.cluster, &v.machine, &v.servername, &v.domain, &v.listenAddress, &v.filename, &v.pid, &v.isActive);
			addToCache(v);
		}
	}
}

unittest {
	string filename = "myFileName", servername = "myServerName";
	immutable int port = 123, pid = 456;
	try { remove(Cache.persistentFilename); } catch (Exception e) {}
	Server expectServer;
	expectServer.initialize();
	expectServer.filename = filename;
	expectServer.servername = servername;
	expectServer.port = port;
	expectServer.pid = pid;
	assert(expectServer.isActive == true);
	Cache cache = new Cache();
	cache.addToCache(expectServer);
	auto actualServer = Server();
	assert(cache.findInCache(actualServer, filename, servername, pid));
	assert(actualServer.port == port);
	assert(actualServer.servername == servername);
	assert(actualServer.isActive == true);
	assert(cache.findInCache(actualServer, filename, "missing", pid) == false);
	assert(cache.findInCache(actualServer, filename, servername, 0) == false);
	cache.persistCache();
	Cache cache2 = new Cache();
	assert(cache2.findInCache(actualServer, filename, servername, pid));
	assert(actualServer.port == port);
	actualServer.isActive = false;
	cache2.addToCache(actualServer);
	cache2.persistCache();
	Cache cache3 = new Cache();
	assert(false == cache3.findInCache(actualServer, filename, servername, pid));
}

