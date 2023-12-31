module sysinfo

import os

fn init() {
	if os.user_os() != "linux" {
		panic("sysinfo is not supported on OS '${os.user_os()}'")
	}
}

// Internal test function that prints out the results of all the sysinfo functions
fn test() {
	print("arch: ")
	println(arch() or {
		panic("failed to get arch")
	})

	print("cpu_count: ")
	println(cpu_count() or {
		panic("failed to get cpu_count")
	})

	print("cpu_model: ")
	println(cpu_model() or {
		panic("failed to get cpu_model")
	})

	print("cpu_speed: ")
	println(cpu_speed() or {
		panic("failed to get cpu_speed")
	})

	print("cpu_temp: ")
	println(cpu_temp() or {
		panic("failed to get cpu_temp")
	})

	print("cpu_usage: ")
	println(cpu_usage())

	print("disks: ")
	println(disk_usage().len)

	print("loadavg: ")
	println(loadavg() or {
		panic("failed to get loadavg")
	})

	print("network_interfaces: ")
	println(network_interfaces() or {
		panic("failed to get network_interfaces")
	})

	print("memory_total: ")
	println(memory_total() or {
		panic("failed to get memory_total")
	})

	print("memory_free: ")
	println(memory_free() or {
		panic("failed to get memory_free")
	})

	print("memory_available: ")
	println(memory_available() or {
		panic("failed to get memory_available")
	})

	print("processes: ")
	println(processes().len)

	print("release: ")
	println(release() or {
		panic("failed to get release")
	})

	print("uname: ")
	println(uname())

	print("uptime: ")
	println(uptime() or {
		panic("failed to get uptime")
	})
}

// Internal function that gets a value from lscpu
fn get_lscpu_value(name string) string {
	lscpu := os.execute("LANG=C lscpu")

	if lscpu.exit_code != 0 {
		panic("could not run lscpu; error: " + lscpu.output)
	}

	for line in lscpu.output.split('\n') {
		if line.starts_with(name) {
			return line.split(':')[1].trim_space()
		}
	}

	panic("failed to get lscpu value '${name}'")
}

pub struct SystemInfo {
	pub:
	arch string
	cpu_count int
	cpu_model string
	cpu_speed int
	cpu_temp int
	cpu_usage int
	disk_usage []Disk
	loadavg []f32
	network_interfaces []NetworkInterface
	memory_total int
	memory_free int
	memory_available int
	processes []Process
	uname os.Uname
	uptime int
}

// Returns a SystemInfo struct with all the information about the system
pub fn get_system_info() SystemInfo {
	varch := arch() or { panic("failed to get arch") }
	vcpu_count := cpu_count() or { panic("failed to get cpu_count") }
	vcpu_model := cpu_model() or { panic("failed to get cpu_model") }
	vcpu_speed := cpu_speed() or { panic("failed to get cpu_speed") }
	vcpu_temp := cpu_temp() or { panic("failed to get cpu_temp") }
	vcpu_usage := cpu_usage()
	vdisk_usage := disk_usage()
	vloadavg := loadavg() or { panic("failed to get loadavg") }
	vnetwork_interfaces := network_interfaces() or { panic("failed to get network_interfaces") }
	vmemory_total := memory_total() or { panic("failed to get memory_total") }
	vmemory_free := memory_free() or { panic("failed to get memory_free") }
	vmemory_available := memory_available() or { panic("failed to get memory_available") }
	vprocesses := processes()
	vuname := uname()
	vuptime := uptime() or { panic("failed to get uptime") }

	return SystemInfo {
		arch: varch,
		cpu_count: vcpu_count,
		cpu_model: vcpu_model,
		cpu_speed: vcpu_speed,
		cpu_temp: vcpu_temp,
		cpu_usage: vcpu_usage,
		disk_usage: vdisk_usage,
		loadavg: vloadavg,
		network_interfaces: vnetwork_interfaces,
		memory_total: vmemory_total,
		memory_free: vmemory_free,
		memory_available: vmemory_available,
		processes: vprocesses,
		uname: vuname,
		uptime: vuptime,
	}
}

pub struct SimpleSystemInfo {
	pub:
	cpu_count int
	cpu_speed int
	cpu_temp int
	cpu_usage int
	memory_total int
	memory_free int
	memory_available int
	uptime int
}

// Returns a SimpleSystemInfo struct with only live important information about the system
pub fn get_simple_system_info() SimpleSystemInfo {
	vcpu_count := cpu_count() or { panic("failed to get cpu_count") }
	vcpu_speed := cpu_speed() or { panic("failed to get cpu_speed") }
	vcpu_temp := cpu_temp() or { panic("failed to get cpu_temp") }
	vcpu_usage := cpu_usage()
	vmemory_total := memory_total() or { panic("failed to get memory_total") }
	vmemory_free := memory_free() or { panic("failed to get memory_free") }
	vmemory_available := memory_available() or { panic("failed to get memory_available") }
	vuptime := uptime() or { panic("failed to get uptime") }

	return SimpleSystemInfo {
		cpu_count: vcpu_count,
		cpu_speed: vcpu_speed,
		cpu_temp: vcpu_temp,
		cpu_usage: vcpu_usage,
		memory_total: vmemory_total,
		memory_free: vmemory_free,
		memory_available: vmemory_available,
		uptime: vuptime,
	}
}

// Returns the architecture of the system as returned by lscpu
pub fn arch() !string {
	return get_lscpu_value("Architecture")
}

// Returns the number of cores as returned by lscpu
pub fn cpu_count() !int {
	return get_lscpu_value("CPU(s)").int()
}

// Returns the model name of the CPU as returned by lscpu
pub fn cpu_model() !string {
	return get_lscpu_value("Model name")
}

// Return the max CPU speed in MHz
pub fn cpu_speed() !int {
	return get_lscpu_value("CPU max MHz").int()
}

// Return the temperature of the CPU in Celsius
pub fn cpu_temp() !int {
	result := os.read_file("/sys/class/thermal/thermal_zone0/temp")!

	return result.int() / 1000
}

// Returns CPU usage as a percentage (from 0-100) from vmstat.
// Will suspend for one second, as vmstat is run twice with a one second delay
pub fn cpu_usage() int {
    result := os.execute("echo $[100-$(LANG=C vmstat 1 2|tail -1|awk '{print $15}')]")

	if result.exit_code != 0 {
		panic("failed to get cpu_usage; error: " + result.output)
	}

	return result.output.int()
}

pub struct Disk {
	pub:
	name string
	mountpoint string
	size int
	used int
	available int
	percent_used int
}

pub fn disk_usage() []Disk {
	result := os.execute("LANG=C df")
	mut disks := []Disk{}

	if result.exit_code != 0 {
		panic("failed to run df; error: " + result.output)
	}

	lines := result.output.split('\n')[1..]
	for line in lines {
		if line == "" { continue }

		fields := line.split(' ').filter(fn (field string) bool {
			return field != ""
		})

		name := fields[0]
		size := fields[1].int()
		used := fields[2].int()
		available := fields[3].int()
		percent_used := fields[4].trim_right('%').int()
		mountpoint := fields[5]

		disks << Disk {
			name: name,
			mountpoint: mountpoint,
			size: size,
			used: used,
			available: available,
			percent_used: percent_used,
		}
	}

	return disks
}

// Return the load average as returned by /proc/loadavg
pub fn loadavg() ![]f32 {
	result := os.read_file("/proc/loadavg")!

	return result.split(' ')[0..3].map(fn (str string) f32 {
		return str.f32()
	})
}

pub struct NetworkInterface {
	pub:
	name string
	ip string
	bytes int
}

pub fn network_interfaces() ![]NetworkInterface {
	result := os.ls("/sys/class/net")!
	mut interfaces := []NetworkInterface{}

	for name in result {
		if name == "lo" { continue }

		ip := os.execute("LANG=C ip addr show ${name} | grep 'inet ' | awk '{print $2}' | cut -d/ -f1").output.trim_space()
		if ip == "" { continue }

		bytes := os.read_file("/sys/class/net/${name}/statistics/rx_bytes")!

		interfaces << NetworkInterface {
			name: name,
			ip: ip,
			bytes: bytes.int(),
		}
	}

	return interfaces
}

// Return the total memory in kB
pub fn memory_total() !int {
	result := os.read_file("/proc/meminfo")!

	return result.split('\n')[0].split(':')[1].trim_space().int()
}

// Return the free memory in kB
pub fn memory_free() !int {
	result := os.read_file("/proc/meminfo")!

	return result.split('\n')[1].split(':')[1].trim_space().int()
}

// Return the available memory in kB
pub fn memory_available() !int {
	result := os.read_file("/proc/meminfo")!

	return result.split('\n')[2].split(':')[1].trim_space().int()
}

struct Process {
	pub:
	pid int
	user string
	cpu f32
	memory f32
	command string
}

pub fn processes() []Process {
	result := os.execute("LANG=C ps aux")
	mut processes := []Process{}

	if result.exit_code != 0 {
		panic("failed to run ps; error: " + result.output)
	}

	lines := result.output.split('\n')[1..]
	for line in lines {
		if line == "" { continue }

		fields := line.split(' ').filter(fn (field string) bool {
			return field != ""
		})

		pid := fields[1].int()
		user := fields[0]
		cpu := fields[2].f32()
		memory := fields[3].f32()
		command := fields[10]

		processes << Process {
			pid: pid,
			user: user,
			cpu: cpu,
			memory: memory,
			command: command
		}
	}

	return processes
}

// Returns the OS name as returned by /etc/os-release
pub fn release() !string {
	result := os.read_file("/etc/os-release")!

	for line in result.split('\n') {
		if line.starts_with("PRETTY_NAME=") {
			return line.split('=')[1].trim_space().replace("\"", "")
		}
	}

	return "N/A"
}

// Return os.uname() for completeness
pub fn uname() os.Uname {
	return os.uname()
}

// Return the uptime of the system in seconds
pub fn uptime() !int {
	result := os.read_file("/proc/uptime")!

	return result.split(' ')[0].int()
}