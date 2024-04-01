---
title: "Deploy and destroy Copilot for Security with Bicep and GitHub Actions"
date: '2024-04-01T21:00:00+02:00'
excerpt: 'Copilot for Security is now GA, how can we provision the service to save some money? Warning - Early Proof of Concept!'
tags: 
  - Bicep
  - GitHub
  - Copilot for Security
toc: true
header:
  og_image: /assets/Deploy-CopilotSecurity.png
---

![](/assets/Deploy-CopilotSecurity.png)

# Introduction and pricing

{% include alerts/important.html content="**Proof of Concept!**<br/>

This is a very early proof of concept to save some bucks on Copilot for Security." %}

1st of April and Copilot for Security is now in General Availability (GA). The cost for the service is no April fool joke. 

| SKU | Price per hour | Estimated price per month |
|----------|----------|----------|
| Provisioned    | $4    | $2,920    |

One month = 730 hours

*Provision capacity in Security Compute Units (SCU) to run Copilot for Security workloads. These workloads provide insights, evaluate prompts, run promptbooks and automate them in both the standalone product and embedded experiences across Microsoft Security.*

Pricing page - https://azure.microsoft.com/en-gb/pricing/details/microsoft-copilot-for-security/

# Coding time

Let's see what we can do with code! 

Take a look at my new repo in GitHub - [pthoor | Copilot for Security](https://github.com/pthoor/Copilot-for-Security)

I've written to very simple bicep files for deployment of Copilot for Security.

{% include alerts/tip.html content="The resource name of Copilot for Security is limited between 3-63 characters, and you can only as for now deploy it in the regions listed in the main.bicep file." %}

## Deploy Copilot for Security with Bicep

**main.bicep**

```sql
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(63)
param capacityName string

var uniqueStringNoHyphens = replace(uniqueString(resourceGroup().id), '-', '')
var uniqueCapacityName = '${toLower(capacityName)}${uniqueStringNoHyphens}'

@allowed([
    'EU'
    'ANZ'
    'US'
    'UK'
])
param geo string

var locationMap = {
  EU: 'westeurope'
  ANZ: 'australiaeast'
  US: 'eastus'
  UK: 'uksouth'
}

var location = contains(locationMap, geo) ? locationMap[geo] : 'defaultlocation'

param numberOfUnits int

@allowed([
    'NotAllowed'
    'Allowed'
])
param crossGeoCompute string

resource Copilot 'Microsoft.SecurityCopilot/capacities@2023-12-01-preview' = {
    name: uniqueCapacityName
    location: location
    properties: {
        numberOfUnits: numberOfUnits
        crossGeoCompute: crossGeoCompute
        geo: geo
    }
}
```

**main.bicepparam**

```sql
using 'main.bicep'

param capacityName = 'thoorcopilot'
param geo = 'EU'
param numberOfUnits = 1
param crossGeoCompute = 'NotAllowed'
```

## Deployment and deletion with GitHub Actions

Not sure this part will work as expected with the billing or the need to configure everything from the ground up when it comes to Copilot for Security. But here you go...

In GitHub Actions I created two supersimple, yet effective, yml files - one for deployment and one for destroyiong and deleting the resources.

The GitHub Actions workflow runs on either manual trigger or it will deploy Copilot for Security at 08:00 AM Monday to Friday.

The destroy workflow will delete the resourcegroup at 5 PM Monday to Friday.

> Fun to try out so why not.

### Deploy

**deploy.yml**

```yml
name: Deploy Resources

on:
  workflow_dispatch: # Allows you to run the workflow manually
  schedule:
    - cron: '0 8 * * 1-5' # Runs at 8 AM UTC, Monday to Friday

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Deploy Bicep template
      run: |
        az deployment group create --name CopilotDeployment --resource-group CopilotTest --template-file ./main.bicep --parameters ./main.bicepparam
```

### Destroy

**destroy.yml**

```yml
name: Destroy Resources

on:
  workflow_dispatch: # Allows you to run the workflow manually
  schedule:
    - cron: '0 17 * * 1-5' # Runs at 5 PM UTC, Monday to Friday

jobs:
  destroy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Destroy Resource Group
      run: |
        az group delete --name CopilotTest --yes --no-wait
```

# Summary

![Deploy Copilot for Security](/assets/Deploy-CopilotSecurity.png)

If you want to follow along with the setup and configuration, visit the GitHub repo - https://github.com/pthoor/Copilot-for-Security

![Delete Copilot for Security](/assets/Delete-CopilotSecurity.png)

![Destroy Copilot for Security](/assets/Destroy-CopilotSecurity.png)