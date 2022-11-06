config_opts['bootstrap_image'] = ''

config_opts['dnf.conf'] = """
[main]
keepcache=1
debuglevel=2
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=
install_weak_deps=0
metadata_expire=0
best=1
module_platform_id=platform:f{{ releasever }}
protected_packages=
user_agent={{ user_agent }}

# repos

[fedora-38-dist-riscv]
name=Fedora 38 RISC-V dist on OpenKoji
baseurl=https://openkoji.iscas.ac.cn/repos/fc38dist/$basearch/
cost=1000
enabled=1
skip_if_unavailable=False

[fedora-36-dev-riscv]
name=Fedora 36 RISC-V dev on OpenKoji
baseurl=https://openkoji.iscas.ac.cn/repos/fc36dev/$basearch/
cost=2000
enabled=1
skip_if_unavailable=True

[fedora-36-dev-riscv-source]
name=Fedora 36 RISC-V dev on OpenKoji - Source
baseurl=https://openkoji.iscas.ac.cn/repos/fc36dev/src/
cost=2000
enabled=1
skip_if_unavailable=True
"""
