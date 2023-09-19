---
title: "Windows Server 2012/2012 R2 - End of support, what to do with Security Updates?"
date: '2023-09-19T14:00:00+02:00'
excerpt: 'Do you have Windows Server 2012/2012 R2 in your environment? If so, you need to read this post to understand what to do with security updates after the end of support date.'
tags: 
  - Arc
  - ESU
  - AzureUpdateManager
toc: true
header:
  og_image: /assets/PatchTuesday.png
---

![](/assets/PatchTuesday.png)

# End of Support for Windows Server 2012/2012 R2

Windows Server 2012 and Windows Server 2012 R2 will soon enter a phase called End of Support (EOS) and the date for that is on October 10, 2023. After this date, these products will no longer receive security updates, non-security updates, bug fixes, technical support, or online technical content updates. If you cannot upgrade to the next version, you will need to use Extended Security Updates (ESUs) for up to three years.

This meeans that security updates via "Patch-Tuesday" will no longer be delivered within the operating system's mainstream support from Microsoft.

# What does End of Support mean?

Microsoft's Lifecycle Policy offers 10 years of support (5 years for Mainstream Support and 5 years for Extended Support) for products like SQL Server and Windows Server. According to the policy, there will be no patches or security updates after the end of the extended support period, which can cause security and compliance issues. If customers cannot upgrade to the next version, Microsoft offers Extended Security Updates (ESU) for up to 3 years to keep customers secure on their software versions that end with support.

The security updates you get with the help of ESU are:
- Critical: A vulnerability whose exploitation could allow code execution without user interaction, strongly recommended to apply these updates immediately.
- Important: A vulnerability whose exploitation could compromise the confidentiality, integrity, or availability of user data, strongly recommended to apply these updates as soon as possible.
- More info about the Severity Rating: [Security Update Severity Rating System](https://www.microsoft.com/en-us/msrc/security-update-severity-rating-system)

ESU is a so-called "last resort option", and for Windows 2012/2012 R2, the end date will be October 13, 2026, i.e., in three years, regardless of whether the servers are in Azure or on-premises.

However, it is possible to get these security updates in other ways if one cannot move to newer operating systems, and these ways are:

- Migrate to Azure, this way we automatically get ESU, costs nothing, and no MAK-keys are needed.
- Azure Arc-enabled servers, through the Azure Arc agent, we can assign ESU licenses to specific servers that we manage ourselves in the Azure portal, the cost will be added to the Azure subscription where you create the ESU licenses (see prices further down in this post).
- Azure Stack (incl. HCI, Hub & Edge), Azure VMware Solutions, Azure Dedicated Hosts, Azure Nutanix Solution: then you get ESU at no extra cost.

# ESU variants

Everything depends on what your environment looks like, whether we can consolidate all Windows Server 2012/2012 R2 VMs to the same hypervisor host (with redundancy if required, which is recommended) or if you should buy a license per VM.

ESU is offered in two flavors, Physical Core or Virtual Core.
- Physical Core: Min. 16 cores when purchasing, match if the server runs Standard or Enterprise version of Windows Server.
  - Standard Edition allows 2 VMs (in accordance with Windows Server licensing)
  - Datacenter Edition has no limitation regarding the number of VMs.
- Virtual Core: Min 8 cores when purchasing. In the Azure portal, you see two different Core Packs (16 cores and 2 cores).

So depending on the number of VMs you want to cover in your environment, you have to calculate whether the Datacenter or Standard license is sufficient for the purpose.

Microsoft clarifies: "Each processor needs to be licensed with a minimum of eight cores (four 2-pack Core Licenses). Each physical server, including single-processor servers, will need to be licensed with a minimum of 16 Core Licenses (eight 2-pack of Core Licenses or one 16-pack of Core Licenses). Additional cores can then be licensed in increments of two cores (one 2-pack of Core Licenses) for servers with core densities higher than 8."

## Price of ESU in Euro for Windows Server 2012/2012 R2

| ESU      | Datacenter Edition price | Standard Edition price     |
|  :----:  | :----: | :----: |
| 16 core  | €403   | €70    |
| 8 core   | €201   | €35    |
| 2 core   | €51    | €8.74  |

# Clarification

From Microsoft:
The minimum number of cores is 16 for physical and 8 for virtual core license.
In order to purchase ESUs, you must have Software Assurance through Volume Licensing Programs such as an Enterprise Agreement (EA), Enterprise Agreement Subscription (EAS), Enrollment for Education Solutions (EES), or Server and Cloud Enrollment (SCE).

# Quick examples

We have 4 physical servers with 8 cores each running Windows Server Standard: Buy 4 ESU of 16 cores per license (min. is 16 cores per license).
We have a physical server with 4 VMs each with 4 cores, the host has 16 cores and runs Standard Edition: Buy 1 16 core standard license and apply to Arc objects.
We have a physical server with 4 VMs each with 8 cores, the host has 32 cores and runs Standard Edition: Buy as option 1 or buy 4 8 cores licenses and apply to Arc objects.

# Pre-requisites for ESU via Azure

- Azure Arc onboarded, a later version than version 1.34.
Windows Server 2012/2012 R2.
- The VM itself cannot run in Azure Stack HCI, Azure VMware Solution, or as an Azure VM - then ESU is free.
- To then be able to use the security updates that Microsoft releases monthly during Patch-Tuesday, we recommend Azure Update Manager, which today costs $5 per server per month for Arc-enabled servers. For Azure VMs, the solution is free.