---
title: nftables
lastmod: 2026-08-28 04:53:34
---

## Installation

```
xbps-install nftables runit-nftables
```

The `nftables` package provides a runit service, however this should be ignored
as `runit-nftables` provides a core service to ensure the ruleset is applied
early at boot.

## Configuration

A sane general configuration can be used as a starting point in
`/etc/nftables.conf`, with optional WireGuard support for routing within the
same subnet:

```
flush ruleset

table inet firewall {
	chain inbound_v4 {
		iifname wg0 icmp type echo-request limit rate 5/second accept
	}
	chain inbound_v6 {
		icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept
		iifname wg0 icmpv6 type echo-request limit rate 5/second accept
	}
	chain inbound_wg0 {
		# http, https, ircs
		tcp dport { 80, 443, 6697 } accept
	}
	chain inbound {
		type filter hook input priority 0; policy drop;
		ct state vmap { established : accept, related : accept, invalid : drop }
		iifname lo accept
		meta protocol vmap { ip : jump inbound_v4, ip6 : jump inbound_v6 }
		iifname wg0 jump inbound_wg0
		# ssh
		tcp dport { 22 } accept
		# wireguard
		udp dport { 51820 } accept
	}
	chain forward {
		type filter hook forward priority 0; policy drop;
	}
}
```

## Commands

```
# Apply ruleset
nft -f /etc/nftables.conf

# Check ruleset syntax
nft -nf /etc/nftables.conf
```
