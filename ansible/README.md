# Variables

To avoid having variables everywhere, they will be declared here, and used directly into the inventory file handled by ansible_vault. Here is the list : 

---

#### target_hostname

**Type** : str

**Playbooks** : install

*Description: Specify the hostname of the target VM.*

---

#### is_commander
**Type** : boolean

**Playbooks** : install

*Description: When set to **true**, indicates that the target is a commander, preventing auto apt-get upgrade that autobreaks ansible package, also disables the reboot and ppa*

---

#### fw_nohttp
**Type** : boolean

**Playbooks** : webserver

*Description: When set to **true**, prevent the rule that opens port **80** from running*

---

#### fw_nohttps
**Type** : boolean

**Playbooks** : webserver

*Description: When set to **true**, prevent the rule that opens port **443** from running*

---

#### fw_cloudflare_http
**Type** : boolean

**Playbooks** : webserver

*Description: When set to **true**, allows cloudflare public ips to firewall rules for port **80***

---

#### fw_cloudflare_https
**Type** : boolean

**Playbooks** : webserver

*Description: When set to **true**, allows cloudflare public ips to firewall rules for port **443***

---

