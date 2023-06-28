# sysinfo

this is a module for the [V programming language](https://vlang.io/) that makes accessing system information (such as cpu, free memory, or disk usage) easy, as the standard v [os](https://modules.vlang.io/os.html) module is lacking in these regards.

**currently this module only works on linux!** i might port it to windows and macos some day, or let someone in a pr do that. it isn't a priority at the moment

you should also note that this module is reliant on some specific files and executables being available. this shouldn't be a problem for most modern linux systems, but it is important to remember:
- `df`
- `lscpu`
- `ps`
- `vmstat`
- `/proc/loadavg`
- `/proc/meminfo`
- `/proc/stat`
- `/proc/uptime`
- `/sys/class/net`
- `/sys/class/thermal/thermal_zone*/temp`

## functions

there is no actual documentation, refer to the source code if you don't know how something works

```v
arch() string
cpu_count() int
cpu_model() string
cpu_speed() int
cpu_temp() int
cpu_usage() int
disk_usage() []Disk
loadavg() []f32
network_interfaces() []NetworkInterface
memory_total() int
memory_free() int
memory_available() int
processes() []Process
uname() os.Uname
uptime() int
```