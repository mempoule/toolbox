# General

## Inventory Variables

To avoid having variables everywhere, they will be declared here, and used directly into the inventory file handled by ansible_vault. Here is the list : 

---

#### target_hostname

**Type** : str

**Playbooks** : install

*Description: Specify the hostname of the target VM.*

---

#### is_commander
**Type** : boolean

**Roles** : install

*Description: When set to **true**, indicates that the target is a commander, preventing auto apt-get upgrade that autobreaks ansible package, also disables the reboot and ppa*

---

#### fw_nohttp
**Type** : boolean

**Roles** : nginx

*Description: When set to **true**, prevent the rule that opens port **80** from running*

---

#### fw_nohttps
**Type** : boolean

**Roles** : nginx

*Description: When set to **true**, prevent the rule that opens port **443** from running*

---

#### fw_cloudflare_http
**Type** : boolean

**Roles** : nginx

*Description: When set to **true**, allows cloudflare public ips to firewall rules for port **80***

---

#### fw_cloudflare_https
**Type** : boolean

**Roles** : nginx

*Description: When set to **true**, allows cloudflare public ips to firewall rules for port **443***

---

#### project_name
**Type** : str

**Roles** : nginx_private

*Description: Used to tell ansible which project you want to deploy on the target*

---

#### project_cloudflare_originCA
**Type** : bool

**Roles** : nginx_private

*Description: Used to include cloudflare certs in case you are behind cloudflare and use this option*

---

#### force_virtualhost
**Type** : bool

**Roles** : nginx_private

*Description: forces override in case there is already a virtualhost for this project*

---

#### force_wwwfiles
**Type** : bool

**Roles** : nginx_private

*Description: forces override in case there are already wwwfiles in the folder*

---

#### force_certificate
**Type** : bool

**Roles** : nginx_private

*Description: forces override in case there are already wwwfiles in the folder*

---

#### force_api_keys
**Type** : bool

**Roles** : nginx_private

*Description: forces override*

---

#### force_htpassswd
**Type** : bool

**Roles** : nginx_private

*Description: forces override*

---



## Private folder

For obvious reasons, when configuring a website, an app, or anything with customer/sensitive info, you don't want to have it published on git. This part will explain how the nginx_private role works, and how to autodeploy when you have all the files needed. It will simplify the nginx configuration, and make the deployment available relatively easy / fast.

**Warning :** this is NOT intended to be a solution for delegated hosting, that's absolutely not the purpose, here we will keep the whole control over infrastructure / files, the goal is to be able to be fast during the developpement / presentation process. Hosting is nor our job ;)

#### Initialize the directory : 

    mkdir ~/mempoule_private

#### Create your project folder :

    mkdir ~/mempoule_private/<project_name>

#### Example of the directory tree : 

```
mempoule_private
└── mempoule.tld
    └── nginx
        ├── api_keys.conf
        ├── certificate.crt
        ├── certificate.key
        ├── files.tar.gz
        ├── htpasswd.conf
        └── virtualhost.conf
```

---

## Specific Roles

### nginx_private

#### Place the config files in the private nginx folder on the commander : `/home/<commander_user>/<project_name>/nginx`

> **Info :** An ultra basic version will be shown under each file to ease understanding, **DO NOT use it in production**

**Mandatory Files :** 

 - **virtualhost.conf** : 

        server {
                listen 80;
        
                root /var/www/mempoule.wtf/html;
                index index.html index.htm index.nginx-debian.html;
        
                server_name test.com www.test.com;
        
                location / {
                        try_files $uri $uri/ =404;
                }
        }
   
 - **files.tar.gz :** The full folder of your website.


**Optional files :**

 - **certificate.crt** :
    
    > Generated with :
    > 
    >`openssl genrsa 2048 > certificate.key` 
    > 
    >`openssl req -new -x509 -nodes -sha256 -days 365 -key certificate.key -out certificate.crt`
    
    **In case your domain is behind cloudflare, please use [project_cloudflare_originCA](####project_cloudflare_originCA)**

       -----BEGIN CERTIFICATE-----
       MIIDazCCAlOgAwIBAgIUfilgrwj+5dDJxoNNobH2rtGp8Y4wDQYJKoZIhvcNAQEL
       BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
       uyum6FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0f8fogyurAPh5bZeN28r7
       drfKBiTA8Wv7i53qbR2hlApvfS/xe4H9PmFYhNKeolWWw82jmax/3hWFwnCgWZxu
       4Sa+Nh+PAbNS2U/CeQFb
       -----END CERTIFICATE-----

 - **certificate.key** :

       -----BEGIN PRIVATE KEY-----
       MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDWbp6cORw8OZ9W
       xscMPEOMgFm4yG7UsodBO1OMsx5TdlbN9UvTJsRDhki7a81IRdGUBvMKjztbEPpX
       0W/vHQ+HCRFPLQMhalCFGBaO7M/r5epXfzeMsMrj9x/ob34p0PnvdRsYieQUKpY+
       wcPr0+DPVHTKCbbA9QVDkr1LbwTpQQACKQrbW/3A+vHPr8TMx3HZFtLu0Nf0PhAJ
       RbcBqVG1AWY6gA7tdtpEXpY=
       -----END PRIVATE KEY-----

 - **api_keys.conf :**
    
       "PQ1G8SDDSQDq/H6LMxAQVO" "mempoule_user"

 - **htpasswd.conf :**
    
       user1:$apr1$/woDSQDDDQSDQSdsqDSeSMjTtn0E9Q0
       user2:$apr1$QdR8fNLDDSDSQDQSDQSDQSDDNpSoBh/
       user3:$apr1$Mr.DSKLKMLj39Hp5FfxRkneklXaMrr/