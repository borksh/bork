---
name: iptables
---
asserts presence of iptables rule


### Usage

```bash
NOTE: does not assert ordering of rules
> iptables INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
```
