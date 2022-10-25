# Base Install

> **IMPORTANT** : Informations provided on this readme **have** to be fully adapted to your topology / needs, and are only here to show how to get a working pfSense, from CA configuration, to OpenVPN and a lot of other stuff. This is an example among others, and every single guy/company should think about what they want to achieve first, plan their topology, and adapt where needed.
> The final filtering, and Firewall rules will heavily depend on your topology.

## I) Prerequisites 

### Proxmox Host

 - Create VMBR1 on proxmox **(empty conf)**
        
        Info : Administrative subnet : 10.99.0.0/24

 - Create VMBR2 on proxmox **(empty conf)**
   
        Info : Customer subnet : 10.99.1.0/24

 - Apply Network Configuration or reboot the Hypervisor : 
    
        WARNING : may need a hard reboot, in case it s needed, will be automatically done when applying the configuration

 - Create a trash VM that will allow us to make the first configuration step (basically configuring routing, and in general, public network reachability for pfSense)

 - Change the mac address of net0 on proxmox , on the pfSense VM, to match the IPFO mac created at OVH.

> About the trash VM :
> 
>>The trash VM should be bridged to vmbr1 
>> 
>> There is **no need** to run the installer, just use it as live CD

---

### pfSense VM

During the VM creation on Proxmox Host, add at least one interface on the pfSense VM to be able to have a WAN, and a LAN interface:

*Example of network splitting with 2 more interfaces :*

 *- **Administrative LAN :** Create 1 Network Device bridged to vmbr1 to be able to configure at least 1 WAN and 1 LAN interface : *vtnet1**

 *- **Customer LAN :** Create 1 Network Device bridged to vmbr2 : *vtnet2**

**VM Mandatory settings :**

Choose **BIOS** for autopartitionning

> **WAN interface** : vtnet0
> 
> **LAN interface** : vtnet1

When the pfsense shows the option menu, you're done (**WAN** ip address should be **empty**)

---

### Trash GUI VM

Basically launch any lightweight linux, we'll just need a browser.

Go to : `https://192.168.1.1`

---


## II) First conf (via Trash GUI VM)

### Step 2

> **Hostname** : Mempoule-pfSense
> 
> **Domain** : pfSense.localdomain
> 
> **Primary DNS Server** : 1.1.1.1
> 
> **Secondary DNS Server** : 1.0.0.1
> 
> **DNS Override** : untick

### Step 3

> **Time server Hostname** : 2.pfsense.pool.ntp.org
> 
> **Timezone** : Europe/Paris

### Step 4

 - Configure WAN interface : 

    > **SelectedType** : static


 - General Configuration : 

    > **MAC Address** : Failover MAC

 - Static IP configuration : 

    > **IP Address** : Failover IP
    > 
    > **Subnet Mask** : 32
    > 
    > **Upstream Gateway** : Proxmox Gateway

### Step 5

 - Configure LAN interface : 

    > **LAN IP Address** : 10.99.0.254
    >
    > **Subnet Mask** : 24

---

## III) Activate ipfo specific routing on pfsense

> This step will allow the WAN interface to be able to get connectivity to internet.

 - Open **pfSense** Qemu on proxmox

 - Select choice **8) - Shell**

> route add -net SERVER_IP.254/32 -iface vtnet0
> 
> route add default SERVER_IP.254

 - Test connectivity with a basic `ping 1.1.1.1`

 - Back on Trash VM GUI, `Diagnostics -> Ping` and test connectivity

---

## IV) ShellCMD to automate default routing for outgoing data at startup

On Trash VM GUI, go to `System -> Package Manager -> Available Packages`

 - Install `Shellcmd`

 - `Services -> Shellcmd`

 - **Command 1 :**  `route add -net SERVER_IP.254/32 -iface vtnet0`

 - **Command 2 :**  `route add default SERVER_IP.254`

 - `Diagnostics -> Reboot`

 - Test connectivity via QEMU or Trash GUI VM


---

## V) Activate SSH and https access from your own Public IP

    This will allow us to continue the configuration directly from your own computer. In case you 
    don't have a static IP, it is recommended to disable/harden those rules when the configuration is finished.
    In any case, you'll be able to also add rules for your VPN connection.

### Activation of SSH

On Trash VM GUI, go to `System -> Advanced`

- Secure Shell

> **Secure Shell Server :**  checked
>
> **SSHd Key Only :** Password or Public Key
> 
>     WARNING : Change it afterwards
> 
> **Allow Agent Forwarding :**  checked
> 
> **SSH port :** 22

 - Login Protection

> **Pass list :** Your own Public IP [whatismyipaddress](https://whatismyipaddress.com)

Click `Save`

---

## VI) Create the user in pfSense

Click on `System -> User Manager -> Add`
- User Properties :
    > **Defined by** : USER
    >
    > **Disabled** : Not checked
    >
    > **Username** : mempoule
    >
    > **Full name** : Mempoule_LaPoule
    >
    > **Group membership** : admins -> Move to member list

Click `Save` 

---

## VII) Alias creation for your own public IP
 
    Now we need to add the rules that will allow incoming traffic from your machine to pfSense,
    so you will be able to continue the configuration directly from it.

On Trash VM GUI, go to `Firewall -> Aliases -> IP -> Add`

 - Properties

> **Name :**  LaPoule_public
>
> **Description :** La Poule Public IP
> 
> **Type :**  Host(s)

 - Host(s)

> **IP or FQDN :**  Your machine Public IP [whatismyipaddress](https://whatismyipaddress.com)

Click `Save` and `Apply Changes`

---

##  VIII) Firewall rules for your own public IP

### SSH Rule

`Firewall -> Rules -> Add`

 - Edit Firewall Rule

> **Action :**  pass
>
> **Disabled :** unchecked
> 
> **Interface :**  WAN
> 
> **Address Family :** IPV4
> 
> **Protocol :** TCP

 - Source

> **Source :**  Single host or alias *LaPoule_Public*

 - Destination

> **Destination :**  WAN Address
>
> **Destination Port Range :** From 22 to 22

 - Extra Options

> **Log :**  unchecked
>
> **Description :** LaPoule Public IP SSH Access

Click `Save` and `Apply Changes`

---

### Https Rule

`Firewall -> Rules -> Add`

 - Edit Firewall Rule

> **Action :**  pass
>
> **Disabled :** unchecked
> 
> **Interface :**  WAN
> 
> **Address Family :** IPV4
> 
> **Protocol :** TCP

 - Source

> **Source :**  Single host or alias *LaPoule_Public*

 - Destination

> **Destination :**  WAN Address
>
> **Destination Port Range :** From 443 to 443

 - Extra Options

> **Log :**  unchecked
>
> **Description :** LaPoule Public IP HTTPS Access

Click `Save` and `Apply Changes`

---

##  IX) Test SSH and HTTPS and add public key for User

From your remote machine, test accessing the webGUI via `https://OpenVPN_Public_IP(FO)`

From a SSH terminal, test the login also.

    If the connection is successfull, stop the Trash GUI VM, then go back on the webGUI on your own machine

#### Add SSH Key to User

`System -> User Manager`

Edit newly created User : 

- Keys :
       
    > **Authorized SSH Keys** :
  > 
  > ssh-rsa XXXXXX
  > 
  > ssh-ed25519 XXXXXX
  
#### SSH Public key and password

`System -> Advanced`

- Secure Shell

> **SSHd Key Only :** Public Key Only

Click `Save` then test the connectivity with SSH console.

---

# OpenVPN Server

---

## I) Create CA

 - `System -> Cert. Manager`
 - Click `Add`
 - Create / Edit CA : 

    > **Descriptive name** : Mempoule CA
    > 
    > **Method** : Create an internal Certificate Authority
    > 
    > **Trust Store** : Check 
    >
    > **Randomize Serial** : Check 

 - Internal Certificate Authority : 

    > **Key type** : RSA
    > 
    >> **Length** : 4096
    > 
    > **Digest Algorithm** : sha256
    > 
    > **Lifetime** : 3650
    >
    > **Common Name** : Mempoule_CA
    > 
    > **Country Code** : FR
    > 
    > **State** : XXX
    >
    > **City** : XXX
    >
    > **Organization** : Mempoule 
    >
    > **Organizational Unit** : TechBranch  
    
    Click `Save` 

---

## II) Create Server Certificate

 - `System -> Cert. Manager -> Certificates`
 - Add/Sign a New Certificate
    > **Method** : Create an internal certificate
    > 
    > **Descriptive Name** : Mempoule Server Certificate
   
 - Add/Sign a New Certificate
    > **Certificate authority** : Mempoule CA
    >
    > **Key Type** : RSA
    >> **Length** : 4096 
    > 
    > **Digest Algorithm** : sha256
    > 
    > **Lifetime** : 3650
    >
    > **Common Name** : Mempoule_Server_Certificate
    >
    > **Country Code** : FR
    > 
    > **State** : XXX
    >
    > **City** : XXX
    >
    > **Organization** : Mempoule 
    >
    > **Organizational Unit** : TechBranch
   
 - Certificate Attributes
    > **Certificate Type** : Server Certificate
 
Click `Save`

---

## III) Create and link User Certificate

 - Click on `System -> User Manager` then edit the user you want to create a client certificate for.

 - Under the `User Certificates Tab`, click `Add`

 - Add/Sign a New Certificate
    > **Method** : Create an internal certificate
    > 
    > **Descriptive Name** : Mempoule Client Certificate LaPoule
   
 - Internal Certificate
    > **Certificate authority** : Mempoule CA
    >
    > **Key Type** : RSA
    >> **Length** : 4096 
    > 
    > **Digest Algorithm** : sha256
    > 
    > **Lifetime** : 3650
    >
    > **Common Name** : Mempoule_Client_Certificate_LaPoule
    >
    > **Country Code** : FR
    > 
    > **State** : XXX
    >
    > **City** : XXX
    >
    > **Organization** : Mempoule 
    >
    > **Organizational Unit** : TechBranch
   
 - Certificate Attributes
    > **Certificate Type** : User Certificate

 - Click `Save`

You should see the new certificate linked to the user now.

 - Click `Save`

---

## IV) Create OpenVPN Server

 - `VPN -> OpenVPN -> Add`
   
 - General Information :
    > **Description** : Mempoule OpenVPN Server
   > 
 - Mode Configuration :
    > **Server Mode** : Remote Access (SSL+TLS + User Auth)
    > 
    > **Backend for authentication** : Local Database
    >
    > **Device Mode** : tun - Layer 3

 - Endpoint Configuration :
    > **Protocol** : UDP on IPv4 Only
    > 
    > **Interface** : WAN
    >
    > **Local port** : 1194

 - Cryptographic Settings :
    > **TLS Configuration** : Check both `Use a TLS Key` and `Automatically generate a TLS Key`  
    > 
    > **Peer Certificate Authority** : Mempoule CA
    >
    > **OSCP Check** : Leave unchecked
    >
    > **Server Certificate** : Mempoule Server Certificate
    >
    > **DH Parameter Length** : 4096 Bits
    > 
    > **ECDH Curve** : Use default
    >
    > **Data Encryption Negociation** : Leave `checked` 
    >
    > **Data Encryption Algorithms** : AES-256-GCM - AES-128-GCM - CHACHA20-POLY1305
    >
    > **Fallback Data Encryption Algorithms** : AES-256-CBC
    > 
    > **Auth Digest algorithm** : SHA256
    >
    > **Hardware Crypto** : No Hardware crypto Acceleration
    >
    > **Certificate Depth** : One (Client+Server)
    >
    > **Strict User-CN Matching** : unchecked
    >
    > **Client Certificate Key Usage Validation** : Enforce key usage `checked`

 - Tunnel Settings :
    > **IPV4 Tunnel Network** : 10.99.99.0/24
    >
    > **IPV6 Tunnel Network** : none
    >
    > **Redirect IPV4 Gateway** : unchecked
    >
    > **Redirect IPV6 Gateway** : unchecked
    >
    > **IPV4 Local Networks** : 10.99.0.0/24,10.99.1.0/24
    >
    > **IPV6 Local Networks** : none
    >
    > **Concurrent connections** : 1
    >
    > **Allow compression** : Refuse any non-stub Compression (Most Secure)
    >
    > **Push Compression** : unchecked
    >
    > **ToS** : unchecked
    >
    > **Inter-client communication** : unchecked
    >
    > **Duplicate Connection** : unchecked

- Client Settings :
    > **Dynamic IP** :  unchecked
    >
    > **Topology** : Subnet


- Ping Settings :
    > **Inactive** :  300
    >
    > **Ping method** : keepalive
    >
    > **Interval** : 10
    >
    > **Timeout** : 60

- Advanced Client Settings :
    > **DNS Default Domain** : unchecked  
    >
    > **DNS Server enable** : unchecked
    >
    > **Block Outside DNS** : unchecked
    >
    > **Force DNS cache update** : unchecked
    >
    > **NTP Server enable** : unchecked
    >
    > **NetBIOS enable** : unchecked
  
- Advanced Configuration :
    > **Custom options** : push "route 10.99.0.0 255.255.255.0";push "route 10.99.1.0 255.255.255.0"
    >
    > **Username as Common Name** : unchecked
    >
    > **UDP fast I/O** : unchecked
    >
    > **Exit Notify** : Reconnect to this Server / Retry Once
    >
    > **Send/Receive Buffer** : Default
    >
    > **Gateway creation** : IPv4 only
    >
    > **Verbosity Level** : Default

Click `Save`

 - `VPN -> OpenVPN -> Servers` then edit the new server.

    > **TLS Key Usage Mode :** Change to `TLS Encryption and Authentication`

---

## V) Add Firewall Rules

### OpenVPN WAN Port opening

`Firewall -> Rules -> Add`

 - Edit Firewall Rule

> **Action :**  pass
>
> **Disabled :** unchecked
> 
> **Interface :**  WAN
> 
> **Address Family :** IPV4
> 
> **Protocol :** UDP

 - Source

> **Source :**  any

 - Destination

> **Destination :**  WAN Address
>
> **Destination Port Range :** From 1194 to 1194

 - Extra Options

> **Log :**  unchecked
>
> **Description :** OpenVPN Daemon port opening

Click `Save` and `Apply Changes`

### OpenVPN Interface Port opening

`Firewall -> Rules -> Add`

 - Edit Firewall Rule

> **Action :**  pass
>
> **Disabled :** unchecked
> 
> **Interface :**  OpenVPN
> 
> **Address Family :** IPV4
> 
> **Protocol :** UDP

 - Source

> **Source :**  Network - 10.99.99.0/24

 - Destination

> **Destination :**  any

 - Extra Options

> **Log :**  unchecked
>
> **Description :** OpenVPN Interface rule

Click `Save` and `Apply Changes`

---

## VI) Install the Export Package

`System -> Package Manager -> Available Packages`

Search for `openvpn-client-export` then `Install`


---

## VII) Export .ovpn file

`VPN -> OpenVPN -> Client Export`

- OpenVPN Server :
    > **Remote Access Server** : Mempoule-OpenVPN UDP4:1194  

- Client Connection Behavior :
    > **Host Name Resolution** : Interface IP Address
    >
    > **Verify Server CN** : Automatic - Use verify-x509-name when possible
    >
    > **Block Outside DNS** : unchecked
    >
    > **Legacy Client** : unchecked
    >
    > **Silent Installer** : unchecked
    >
    > **Bind Mode** : Do not bind the local port

- Certificate Export Options :
    > **PCKS#11 Certificate Storage** : unchecked
    >
    > **Microsoft Certificate Storage** : unchecked
    >
    > **Password Protect Certificate** : unchecked

- Proxy Options :
    > **Use a Proxy** : unchecked

Then just grab the inline configuration, and test it with your OpenVPN client.

## VIII) Tweaks

### Disable IPV6 on WAN interface

`Interfaces -> WAN`

- General Configuration :
  
    > **IPV6 Configuration Type** : none

Click `Save` and `Apply Changes`

    **WARNING :** This change will make the interface hang and not respond, reboot it manually via the Trash VM GUI,
                or ssh Console : **Globally, the changes when applied on the WAN interface needs a reboot**

### Disable IPV6 on LAN interface

`Services -> DHCPv6 Server & RA`

- DHCPv6 Options :
  
    > **DHCPv6 Server** : Uncheck

    Click `Save`

Then on the Router Advertisements TAB :

- Advertisements :
  
    > **Router Mode : disabled

    Click `Save`

---
`Interfaces -> LAN`

- General Options :
  
    > **IPV6 Configuration Type** : none

Click `Save` and `Apply Changes`

### Disable IPV6 globally

`System -> Advanced -> Networking`

- IPv6 Options :
  
    > **Allow IPv6** : uncheck

Click `Save`

---

### Remove the warning about self-signed certificate on GUI

`System -> Package Manager -> Available Packages`

Install `Acme`

`Services -> Acme -> Account Keys`

 - Edit Certificate options
  
    > **Name** : Mempoule ACME Account Key
    > 
    > **Description** : Mempoule ACME Account Key
    > 
    > **ACME Server** : Let's Encrypt Production ACME v2
    > 
    > **E-Mail Address** : mail_placeholder
    > 
    > **Account Key** : Click on `Create new account key`to generate
    >
    > **ACME account registration** : Click on `Register ACME account key`

Click on `Save`

Now we need to get the Application Key, Application Secret, et Consumer Key from [OVH](https://www.ovh.com/auth/api/createToken) :

> **Application Name** : subname.thedomain.tld
> 
> **Application description** : pfSense ACME certificate
> 
> **Validity** : Unlimited
> 
> **Rights** : 
>    > GET /domain/zone/thedomain/*
> 
>    > GET /domain/zone/thedomain/
> 
>    > POST /domain/zone/thedomain/*
> 
>    > PUT /domain/zone/thedomain/*
> 
>    > DELETE /domain/zone/thedomain/record/*
> 
> **Restricted IP** : pfsense public IP (IP_FO1)


Go to `Certificate` Tab, then click `Add`

 - Edit Certificate options
  
    > **Name** : Mempoule_ACME_Certificate
    > 
    > **Description** : Mempoule ACME Certificate
    > 
    > **Status** : Active
    > 
    > **Acme Account** : Mempoule ACME Account Key
    > 
    > **Private Key** : 4069-bit RSA
    >
    > **Preferred Chain** : leave blank
    >
    > **Domain SAN List - Mode** : Enabled
    >
    > **Domain SAN List - Domainname** : subname.thedomain.tld
    >
    > **Domain SAN List - Method** : DNS-ovh / kimsufi / soyoustart / runabove
    >
    > **Domain SAN List - Application Key** : paste the value here
    >
    > **Domain SAN List - Application Secret** : paste the value here
    >
    > **Domain SAN List - Consumer Key** : paste the value here
    >
    > **Domain SAN List - API Endpoint** : OVH Europe
    >
    > **Domain SAN List - Enable DNS alias mode** : blank
    >
    > **Domain SAN List - Enable DNS domain alias mode** : unchecked
    >
    > **DNS Sleep** : blank
    >
    > **Actions List - Mode** : enabled
    > 
    > **Actions List - Command** : `/etc/rc.restart_webgui`
    > 
    > **Actions List - Method** : ShellCommand
    >
    > **Last renewal** : 01-01-1970 01:00:00
    >
    > **Certificate renewal after** : leave blank

Then Click on `Issue/Renew` on `Services -> ACME -> Certificates`

Once done, and last renewed shows a valid date, the certificate is valid.

Go to `System -> Advanced` and change SSL/TLS Certificate to `Mempoule_ACME_Certificate`

Also change `Alternate Hostnames` from blank to `subname.thedomain.tld`

Click `Save`

    For maximum security, do NOT add a record on the DNS zone, just use local host file, unless you want the pfSense IP to be revealed publicly.

---

## IX) Activating additional network interfaces

We assume you created a brand new VMBR on the proxmox host, and added a NIC on the pfsense hardware tab, if that's the case, the new interface should be seen under `Interface -> Assignments`

Under Available Network Ports, choose the interface to activate, for example **vtnet2**, then click `Add`

Now Click on the newly created interface `OPTX`. 

For example, here is the configuration for our Customer specific LAN NIC : 

- General Configuration :
    > **Enable** : Checked
    >
    > **Description** : LAN2
    >
    > **IPv4 Configuration Type** : Static IPV4
    >
    > **IPv6 Configuration Type** : None

- Static IPv4 Configuration :
    > **IPv4 Address** : 10.99.1.254/24

Click `Save` and `Apply Changes`

## X) DHCP Server

>**Note :** This configuration is given only as an example, adapt it to your topology. Enforcing those rules will force you to grab the mac address once you created a new VM, and assign a **static** mapping. Obviously, direct IP addressing on the machine is totally possible, we are just making ultra sure that only IP/MAC pairs we specifically define will get a lease.

- General Options :
    > **Enable** : Checked
    >
    > **BOOTP** : unchecked
    >
    > **Deny unknown clients** : Allow known clients from only this interface
    > >Will only give DHCP leases to registered MAC addresses.
    > 
    > **Ignore denied clients** : unchecked
    > 
    > **Range** : 
    >   > **From :** 10.99.0.200
    > 
    >   > **To :** 10.99.0.250
    > 
    > **Ignore denied clients** : unchecked

- Servers :
    > **DNS Servers** : 1.1.1.1 and 1.0.0.1

Click `Save`

## X) VM settings for DHCP clients

`Services -> DHCP Server`

Select the interface you placed the VM behind, for example LAN, or LAN2, then click `Add` under `DHCP Static Mappings for this Interface`

- Static DHCP Mapping on LAN :
    > **MAC Address** : Use the generated MAC address of the Proxmox VM
    >
    > **Client Identifier** : Mempoule_commander_adm
    >
    > **IP Address** : 10.99.0.10
    > 
    > **Hostname** : Mempoule_commander_adm
    > 
    > **Description** : Mempoule Commander Adm
    >
    > **ARP Table Static Entry** : Checked
    >
    > **DNS Servers** : Leave blank
    >
    > **Gateway** : Leave blank
    >
    > **Domain name** : Leave blank

Click `Save` and `Apply`

The VM should now be able to grab its IP.

## XI) Allow Admins to target isolated VM's

### Assign a specific IP to the OpenVPN connection for a specific user

`VPN -> OpenVPN -> Client Specific Overrides`

- General Information :
    > **Description** : LaPoule Static VPN IP
    > 
    > **Disable** : leave unchecked
  
- Override Configuration :
    > **Common Name** : Mempoule_Client_Certificate_LaPoule
    > 
    > **Connection blocking** : leave unchecked
    >
    > **Server List** : OpenVPN Server 1 : Mempoule OpenVPN Server

- Client Settings :
    > **Advanced** : ifconfig-push 10.99.99.XX 255.255.255.0;

> **Note :** Make sure the static binding you apply for your user is an available IP address, on the OpenVPN network/CIDR.

Then restart the OpenVPN Server on `Status -> OpenVPN`

### Add that specific IP to an existing or new Alias

`Firewall -> Aliases`

### Add the Firewall Rule

`Firewall -> Rules -> Add`

 - Edit Firewall Rule

> **Action :**  pass
>
> **Disabled :** unchecked
> 
> **Interface :**  OpenVPN
> 
> **Address Family :** IPV4
> 
> **Protocol :** Any

 - Source

> **Source :**  Single host or alias *LaPoule_Public*

 - Destination

> **Destination :**  LAN net

 - Extra Options

> **Log :**  unchecked
>
> **Description :** LaPoule Public IP VPN LAN Access

Click `Save` and `Apply Changes`

Repeat this process either for direct LAN access, or specific IP allowance.



