## DKIM OVH hosted-exchange API steps

---

### Step 1 : Get selectors

https://api.ovh.com/console/#/email/exchange/{organizationName}/service/{exchangeService}/domain/{domainName}/dkimSelector~GET

> **organizationName :** hosted-baxxxxx
> 
> **exchangeService :** hosted-baxxxxx
> 
> **domainName :** xxxx.fr

Response :

    [
        "ovhexXXXX-selector1"
        "ovhexXXXX-selector2"
    ]

---

### Step 2 : Ask for pub/priv key creation

https://api.ovh.com/console/#/email/exchange/{organizationName}/service/{exchangeService}/domain/{domainName}/dkim~POST

If eveything is at OVH (ns etc...), **tick** the ConfigureDkim checkbox to ask OVH to gen those keys

> **organizationName :** hosted-baxxxxx
> 
> **selectorName :** ovhexXXXX-selector1
> 
> **exchangeService :** hosted-baxxxxx
> 
> **domainName :** xxxx.fr

---

### Step 3 : Get the DKIM selector infos to be able to configure the ns record

https://api.ovh.com/console/#/email/exchange/{organizationName}/service/{exchangeService}/domain/{domainName}/dkim/{selectorName}~GET

> **organizationName :** hosted-baxxxxx
> 
> **selectorName :** ovhexXXXX-selector1
> 
> **exchangeService :** hosted-baxxxxx
> 
> **domainName :** xxxx.fr


Response :

    {
        selectorName: "ovhexXXXX-selector1",
        taskPendingId: XXXXXXXX,
        recordType: "CNAME",
        status: "waitingRecord",
        targetRecord: "ovhexXXXX-selector1._domainkey.XXX.aa.dkim.mail.ovh.net",
        lastUpdate: "2022-10-13T12:50:39+02:00",
        customerRecord: "ovhexXXXX-selector1._domainkey.xxxx.fr",
        header: "from;to;subject;date"

    }

*As you can see, it's waiting for the record (status : waitingRecord)*

---

### Step 4 : Create the corresponding CNAME record

> Possible to do this via UI also

https://api.ovh.com/console/#/domain/zone/{zoneName}/record~POST

> **zoneName :** xxxx.fr
> 
> **fieldType :** CNAME
> 
> **subDomain :** ovhexXXXX-selector1._domainkey
> 
> **target :** *targetRecord* obtained at previous step


### Then refresh the zone : 

https://api.ovh.com/console/#/domain/zone/{zoneName}/refresh~POST

> **EXAMPLE of a good formatted CNAME record:**
> 
> ovhexXXXX-selector1._domainkey     60 IN CNAME  ovhexXXXX-selector1._domainkey.XXX.aa.dkim.mail.ovh.net

---

### Step 5 : wait for the "InProduction" status of step 3

This step is just about waiting a few minutes, the robot checks every 5 minutes, and will switch the status from waitingRecord to Inproduction

---

### Step 6 : Activate DKIM

https://api.ovh.com/console/#/email/exchange/{organizationName}/service/{exchangeService}/domain/{domainName}/dkim/{selectorName}/enable~POST

> **organizationName :** hosted-baxxxxx
> 
> **selectorName :** ovhexXXXX-selector1
> 
> **exchangeService :** hosted-baxxxxx
> 
> **domainName :** xxxx.fr
