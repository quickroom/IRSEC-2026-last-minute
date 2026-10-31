# IRSeC 2026 pfSense read-only defense toolkit

Safe shell helpers for the `barrier` firewall (pfSense 2.7.2 / FreeBSD). They collect evidence and support manual troubleshooting. They do not change firewall rules, accounts, services, packages, routes, configuration, or scoring.

## Competition safety boundary

- Run competition actions only during an announced Hands On period and only from the provided physical competitor machine.
- In scope: your team LAN `10.x.1.0/24` and team cloud `192.168.x.0/24`, where `x` is your team number. Anything not explicitly listed as in scope is out of scope.
- Never disable, remove, restrict, or impersonate `whiteteam`. It must retain administrative access.
- Never change, delete, inspect for remediation, or restrict Datadog users, groups, services, files, directories, or traffic. Do not block any address on Datadog's official US5 IP list.
- Preserve the `syslog-ng` path from `barrier` to `timing` on both TCP and UDP port 514.
- Do not block subnets. The packet permits only individual-IP blocking, and never for an out-of-scope IP. This toolkit does not block anything.
- Do not change topology, scored services, or scoring behavior. Do not attack, scan other teams, scan out-of-scope networks, use ARP/DHCP attacks, or exfiltrate artifacts.
- Do not install or run AI agents or AI-powered tools on competition infrastructure, and do not connect AI tools to it. These static scripts contain no AI component and make no network callbacks.
- Outputs remain local. Review them for secrets before copying or sharing, and follow White Team direction if rules or scope change.

White/Black Team directives override this README.

## First five minutes

1. Confirm Hands On has started. Record your team number, expected services, interfaces, and the current Hermes diagnostics.
2. Copy this directory to the approved competitor workstation or firewall using an approved method. Do not use a personal device to access competition infrastructure.
3. At the pfSense shell, run `sh bin/00-baseline.sh -o /root/irsec-evidence -t barrier`.
4. Run `sh bin/10-persistence-audit.sh -o /root/irsec-evidence -t barrier`.
5. Run `sh bin/20-config-snapshot.sh -o /root/irsec-evidence -t barrier`.
6. Review results manually. Treat unfamiliar items as leads, not proof. Ask White Team before touching protected or ambiguous components.

Do not assume early traffic is safe. A baseline records what exists; it does not create a trustworthy allowlist.

## Commands

### Full baseline

```sh
sh bin/00-baseline.sh -o /root/irsec-evidence -t barrier
```

Captures interfaces, routes, neighbor cache, PF status/rules/NAT/states/tables, sockets, processes, services, protected-component observations, and configuration hashes. It does not copy `config.xml` contents.

### Accounts, SSH, cron, startup, and persistence

```sh
sh bin/10-persistence-audit.sh -o /root/irsec-evidence -t barrier
```

Collects account/group data, UID 0 accounts, SSH effective settings, authorized-key fingerprints, privilege and scheduled-task metadata, startup scripts, recent executables, temporary-path processes, and recent web-GUI file metadata. It does not print private keys or authorized-key bodies.

### Log triage, filesystem timeline, and process map

```sh
sh bin/11-log-triage.sh -o /root/irsec-evidence -t barrier
sh bin/12-filesystem-timeline.sh -o /root/irsec-evidence -t barrier -d 8
sh bin/13-process-map.sh -o /root/irsec-evidence -t barrier
```

These summarize local authentication, GUI, firewall, service, and configuration logs; record recently modified files and hashes; and correlate processes with sockets and executable information. Datadog-named paths are excluded from targeted filesystem and certificate searches.

### Configuration fingerprints and monitoring

```sh
sh bin/20-config-snapshot.sh -o /root/irsec-evidence -t barrier
sh bin/21-config-monitor.sh -o /root/irsec-evidence -t barrier -i 60
```

The monitor compares hashes every 60 seconds and logs only changed paths/hashes. Stop it with Ctrl-C. For a bounded test or short watch, add `-n 5` for five comparisons.

### Configuration history and PF counter monitoring

```sh
sh bin/22-config-history-audit.sh -o /root/irsec-evidence -t barrier
sh bin/23-pf-counter-monitor.sh -o /root/irsec-evidence -t barrier -i 30 -n 10
```

The history audit records only file metadata and hashes. It does not expose configuration contents or restore anything. The PF monitor takes a bounded series of rule-counter and state-summary snapshots without loading, flushing, enabling, or disabling PF.

### Bounded packet capture and offline analysis

```sh
ifconfig -l
sh bin/30-capture.sh -i em0 -c 500 -f 'host 192.168.X.4 and port 514' -o /root/irsec-evidence -t barrier
sh bin/31-analyze-pcap.sh -r /root/irsec-evidence/CASE/traffic.pcap -o /root/irsec-evidence -t barrier
```

Replace `em0`, `X`, and `CASE` with verified local values. Captures stop at the packet limit and remain local. Prefer narrow filters. Do not send captures to online scanners, personal devices, or external services.

### Scoring troubleshooting

```sh
sh bin/40-score-troubleshoot.sh -d 10.X.1.5 -p 21 -P tcp -o /root/irsec-evidence -t garage-ftp
```

This records a route lookup, local listeners, matching PF states, and PF/NAT counters. It sends no traffic. Use Hermes' per-check detail, verify the service locally, then test the exact scored endpoint from an approved source if permitted. Check the host firewall and router path separately. Never change a rule merely to make a check appear green.

### GUI certificates, DNS, and time

```sh
sh bin/41-gui-cert-health.sh -o /root/irsec-evidence -t barrier
sh bin/42-dns-time-health.sh -o /root/irsec-evidence -t barrier
```

The GUI helper records process/listener health, recent errors, and public certificate metadata without copying certificate bodies or private keys. The DNS/time helper records local configuration and status but sends no probes and changes no settings.

### Human incident notebook

```sh
sh bin/50-incident-note.sh -s 'unexpected-admin-login' -H barrier -o /root/irsec-notes
```

This creates a timestamped blank finding template for a registered team member to complete. It does not generate findings, inject text, or the final Incident Response Report.

### Evidence integrity

Every case directory contains `MANIFEST.sha256` (or a `cksum` fallback). Verify one with:

```sh
sh bin/90-verify-evidence.sh /root/irsec-evidence/CASE
```

## Manual review checklist

- Compare PF rules/NAT/state counters against the documented topology and scored services. Look for unexpected pass-all rules, scored-port blocks, redirects, or unfamiliar tables. Do not edit automatically.
- Verify `whiteteam` still exists with administrative permissions. Do not change it.
- Confirm `syslog-ng` is present and TCP/UDP 514 traffic from `barrier` to `timing` remains allowed.
- Treat every Datadog-named object and Datadog address as protected. If it appears suspicious, escalate rather than inspect or alter it.
- Review new UID 0 accounts, unknown authorized-key fingerprints, SSH settings, cron/periodic tasks, boot scripts, recent executables, and unexpected web-GUI file changes.
- Correlate process, listener, PF-state, packet, and configuration-change timestamps. Preserve notes and screenshots for the human-written Incident Response Report.
- Before any remediation, note the current state, expected service impact, rollback path, and White Team guidance where needed. Recheck Hermes and service reachability after an authorized manual change.

## Limitations

The scripts use commands normally present on pfSense/FreeBSD. Missing commands or insufficient privileges are recorded rather than repaired. Configuration contents may contain credentials, so the toolkit fingerprints them instead of copying them. Packet captures and process arguments can still contain sensitive data; keep evidence access restricted.

## Local validation

The included test checks POSIX shell syntax, scans for prohibited mutating/upload command forms, and proves that evidence tampering is detected:

```sh
sh tests/run-tests.sh
```

