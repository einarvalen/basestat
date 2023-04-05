module basestat.ProcStuff;

import std.format, std.file, std.algorithm, std.array, std.stdio;

string readFile(int pid, string filenamePattern) {
	auto writer = appender!string();
	formattedWrite(writer, filenamePattern, pid);
	string f = writer.data;
	return exists(f) ? readText(f) : "";
}

struct ProcPidStatm {
	private int ints[6] = [0];
	this(int pid, string filenameFormat = "/proc/%s/statm") { 
		auto buf = readFile(pid, filenameFormat);
		formattedRead(buf, "%d %d %d %d %d %d", &ints[0], &ints[1], &ints[2], &ints[3], &ints[4], &ints[5]);
	}
	int total() const { return ints[0]; }
	int data() const {  return ints[5]; }
}

unittest {
	auto procPidStatm = ProcPidStatm(1, "test-statm.txt");
	assert(procPidStatm.total() == 660406);
	assert(procPidStatm.data() == 623034);
}

struct ProcPidStatus {
	private string status = "";
	this(int pid, string filenameFormat = "/proc/%s/status") { 
		status = readFile(pid, filenameFormat); 
	}	
	private int findIntValue(string needle) const {
		int ret; string crap;
		auto found = find(status, needle).until("\n");
		formattedRead(found, "%s\t%d", &crap, &ret);
		return ret;
	}
	int threads() const { return findIntValue("Threads:"); }
	int uid() const {  return findIntValue("Uid:"); }
	int gid() const {  return findIntValue("Gid:"); }
}

unittest {
	auto procPidStatus = ProcPidStatus(1, "test-status.txt");
	assert(procPidStatus.uid == 974);
	assert(procPidStatus.gid == 974);
	assert(procPidStatus.threads() == 23);
}

struct ProcMeminfo {
	private string meminfo = "";
	this(string filename) { 
		meminfo = readText(filename); 
	}
	private int findIntValue(string needle) const {
		int ret;
		string crap;
		auto line = find(meminfo, needle).until("\n");
		formattedRead(line, "%s %d", &crap, &ret);
		return ret;
	}
	int total() const { return findIntValue("MemTotal"); }
	int free() const {  return findIntValue("MemFree"); }
}

unittest {
	auto procMeminfo = ProcMeminfo("test-meminfo.txt");
	assert(procMeminfo.total() == 8057668);
	assert(procMeminfo.free() == 4718116);
}
