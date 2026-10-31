# Non-negotiable safeguards

This toolkit is observation-only. It contains no calls to `pfctl` that load, flush, enable, or disable rules; no `easyrule`; no account modification; no service restart; no package installation; and no outbound upload.

Stop and ask White Team when:

- a finding touches `whiteteam`, Datadog, `syslog-ng`, `timing`, TCP/UDP 514, management infrastructure, `*.irsec.club`, or `*.ritsec.cloud`;
- the scope or team number is uncertain;
- a proposed change could affect topology, a scored service, administrative access, logging, or monitoring;
- a tool behaves unexpectedly or might degrade the competition.

The Blue Team Packet and later White/Black Team directives are authoritative.

