---
title: "Demystifying Microsoft Defender for Cloud and Defender CSPM cost"
date: '2024-03-22T09:00:00+02:00'
excerpt: 'Do you find it hard to understand the mapping of features and capabilities Microsoft Defender for Cloud and Defender CSPM can offer? And which features are in-scope for e.g. Azure VMs and Azure Arc-enabled servers, or direct onboarding? And what is the cost of these services? In this blog post, I will try to make it a bit more clear for you.'
tags: 
  - MDC
  - DefenderforCloud
  - CSPM
  - DevOps
toc: true
header:
  og_image: /assets/MDC-CSPM-cost.jpg
---

![](/assets/MDC-CSPM-cost.jpg)

# Introduction
Microsoft Defender for Cloud (MDC) is a cloud-native security solution that helps you prevent, detect, and respond to security threats across your cloud workloads. It provides a comprehensive set of security capabilities that are designed to help you secure your cloud resources and workloads. Defender for Cloud is a part of the Microsoft Defender suite of security products, which also includes Defender for Endpoint, Defender for Identity, and Defender for Office 365.

Defender for Cloud is a massive product with a lot of features and capabilities. It can be a bit overwhelming to understand the cost of Defender for Cloud and how to save money on it. If we are looking at both Cloud Adoption Framework and Well-Architected Framework, we need to make sure that we are using the right services and features to secure our cloud resources and workloads. We also need to make sure that we are not spending more money than we need to.

In this post we will focus on virtual machines, so both Azure VMs and on-premise servers - in short Azure Arc-enabled servers and how we map those workloads to the different plans within Defender for Cloud and CSPM. 

# What is Defender for Cloud?
First, welcome to the world of acronyms, because in Defender for Cloud we do have a lot of them. Defender for Cloud, which is CNAPP (Cloud Native Application Protection Platform), is currently divided into three main pillars, CSPM (Cloud Security Posture Management), CWPP (Cloud Workload Protection Platform), and DevSecOps (Development Security Operations).

* CSPM (Cloud Security Posture Management) - Is helping us to secure our cloud resources and workloads. It is helping us to find misconfigurations, compliance issues, and security threats in our cloud environment. But we have two flavors of CSPM, Foundational CSPM and Defender CSPM - which one should we use? And do we need to activate Defender CSPM, which cost $5 per **billable** resource, on all of our Azure subscriptions (in our Enterprise Scale Landing Zone)?

* CWPP (Cloud Workload Protection Platform) - Make sure to protect your cloud workloads, which could be virtual machines, containers, databases, storage accounts, APIs, and so on. It is helping us to find vulnerabilities, malware, and security threats in our cloud workloads.

* DevSecOps (Development Security Operations) - Is helping us to implement good security practices, early in the development lifecycle. We have seen a lot of code secrets in public repositories, and this is a way to prevent that. We can also find Infrastructure as Code (IaC) misconfigurations and secure our multi-pipeline environments. But to be able to do all this, we need to have a good understanding of the cost of these services. Because this is quite tricky...

I will try to make a virtual (in your own mind) desicion tree for you so you can decide which toogle to switch On.

# Roles and security responsibilities

![](/assets/rolesandresponsibilities.png)

I would say that every subscription owner should have a good understanding of the cost of Defender for Cloud. It is important to understand the cost of these services and how to use them effectively to secure your resources and workloads. And also have an understanding in the overall setup of the Enterprise Scale Landing Zone, because Defender for Cloud is activated on a per subscription level, but we are forcing the activation of the different plans with Azure Policy on the higher Management Group level. To understand that threats can be discovered from the Azure control plane (which Defender for Resource Manager does) to files within Azure Files or an exploit of an Azure Key Vault is very important. Threats is not just happening in our on-premises environment, but also in the cloud.

In bigger organizations we may structure the roles and responsibilities a bit different, but the overall responsibility is the same. We need to make sure that we are using the right services and features to secure our cloud resources and workloads. We also need to make sure that we are not spending more money than we need to.

# DevSecOps
## Defender for DevOps
Let's start with Defender for DevOps. Defender for DevOps is a set of security features and capabilities that help you secure your DevOps environment and protect your code, infrastructure as code, and cloud resources. Defender for DevOps is designed to help you find and fix security vulnerabilities in your code, infrastructure as code, and cloud resources, and to help you secure your DevOps environment.

As of March 2024, you need to have Defender CSPM to activate the premium DevOps security value. 

*If you have the Defender CSPM plan enabled on a cloud environment (Azure, AWS, GCP) within the same tenant your DevOps connectors are created in, you'll continue to receive premium DevOps capabilities at **no extra cost**.*

[Enforcement of Defender CSPM for Premium DevOps Security Value](https://learn.microsoft.com/en-us/azure/defender-for-cloud/upcoming-changes#enforcement-of-defender-cspm-for-premium-devops-security-value)

Which DevOps capabilities are in-scope per CSPM plan? See the table below.

| Feature                          | Foundational CSPM                         | Defender CSPM                             | Prerequisites | Cost |
|----------------------------------|:-----------------------------------------:|:-----------------------------------------:|---------------|------|
| Connect Azure DevOps repositories | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Permission to connect and Defender for Cloud | Free |
| Security recommendations to fix code vulnerabilities | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | GitHub Advanced Security for Azure DevOps for CodeQL findings, Microsoft Security DevOps extension | $49 per active committer per month |
| Security recommendations to discover exposed secrets | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | GitHub Advanced Security for Azure DevOps | $49 per active committer per month |
| Security recommendations to fix open source vulnerabilities | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | GitHub Advanced Security for Azure DevOps | $49 per active committer per month |
| Security recommendations to fix infrastructure as code misconfigurations | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Microsoft Security DevOps extension | Free |
| Security recommendations to fix DevOps environment misconfigurations | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | N/A | Free |
| Pull request annotations | | ![Yes](../assets/yes-icon.png) | For GitHub you need GitHub Advanced Security and configure Microsoft Security DevOps GitHub action<br/>For Azure DevOps you need to configure the Microsoft Security DevOps Azure DevOps extension | Free in Azure DevOps, for GitHub you need the Advanced Security plan |
| Code to cloud mapping for Containers | | ![Yes](../assets/yes-icon.png) | Microsoft Security DevOps extension | Free |
| Code to cloud mapping for Infrastructure as Code templates | | ![Yes](../assets/yes-icon.png) | Microsoft Security DevOps extension | Free |
| Attack path analysis | | ![Yes](../assets/yes-icon.png) | Enable Defender CSPM on an Azure Subscription, AWS Connector, or GCP Connector in the same tenant as the DevOps Connector | No cost really, as described in the pre-req column, make sure to activate Defender CSPM |
| Cloud security explorer | | ![Yes](../assets/yes-icon.png) | Enable Defender CSPM on an Azure Subscription, AWS Connector, or GCP connector in the same tenant as the DevOps Connector | No cost really, as described in the pre-req column, make sure to activate Defender CSPM |

The feature called 'Security recommendations to fix DevOps environment misconfigurations' is a fantastic way to really improve your security posture. It will look at the [DevOps threat matrix](https://www.microsoft.com/en-us/security/blog/2023/04/06/devops-threat-matrix/) and give you recommendations on how to fix those misconfigurations to prevent code injection, data exfiltration, privilege escalation and so on. The scanner, called DevOps scanner, runs every 24 hours and will look at the following resources.

- Builds
- Secure Files
- Variable Groups
- Service Connections
- Organizations
- Repositories

In other words, for some features you need to activate Defender CSPM on **ONE** Azure subscription, AWS Connector, or GCP Connector in the same tenant as the DevOps Connector - and that subscription doesn't need to have **billable resources** for Defender CSPM. But wait, I have now mentioned **billable resources** for Defender CSPM twice, what is that?

### Billable resources for Defender CSPM are resources of the types:

| Azure Service | Azure Resource Type | Doesn't Cost When... |
|---------------|-------------|------|
| Compute | Microsoft.Compute/virtualMachines<br/>Microsoft.Compute/virtualMachineScaleSets/virtualMachines<br/>Microsoft.ClassicCompute/virtualMachines | - Deallocated VMs<br/>- Databricks VMs |
| Storage | Microsoft.Storage/storageAccounts | Storage accounts without blob containers or file shares |
| DBs | Microsoft.Sql/servers<br/>Microsoft.DBforPostgreSQL/servers<br/>Microsoft.DBforMySQL/servers<br/>Microsoft.Sql/managedInstances<br/>Microsoft.DBforMariaDB/servers<br/>Microsoft.Synapse/workspaces | N/A |

## Defender for Servers
The fundamental protection for your servers, whether they are on-premises, in the cloud, or in a hybrid environment. Defender for Servers provides a comprehensive, cross-platform solution for detecting and mitigating security threats across your server workloads.

Defender for Servers plans is some different from the plans in Defender for Endpoint.

Plan 1 - Is the entry level and servers can be onboarded either by Direct Onboarding or by Azure Arc. 

Plan 2 - The premium plan, everything included. 


| Feature | Details | Plan 1 | Plan 2 |
|:---|:---|:---:|:---:|
| **Defender for Endpoint integration** | Defender for Servers integrates with Defender for Endpoint and protects servers with all the features, including:<br/><br/>- Attack surface reduction to lower the risk of attack.<br/><br/> - Next-generation protection, including real-time scanning and protection and Microsoft Defender Antivirus.<br/><br/> - EDR, including threat analytics, automated investigation and response, advanced hunting, and Endpoint Attack Notifications.<br/><br/> - Vulnerability assessment and mitigation provided by Microsoft Defender Vulnerability Management (MDVM) as part of the Defender for Endpoint integration. With Plan 2, you can get premium MDVM features, provided by the MDVM add-on.| ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) |
| **Licensing** | Defender for Servers covers licensing for Defender for Endpoint. Licensing is charged per hour instead of per seat, lowering costs by protecting virtual machines only when they're in use.| ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) |
| **Defender for Endpoint provisioning** | Defender for Servers automatically provisions the Defender for Endpoint sensor on every supported machine that's connected to Defender for Cloud.| ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) |
| **Unified view** | Alerts from Defender for Endpoint appear in the Defender for Cloud portal. You can get detailed information in the Defender for Endpoint portal.| ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) |
| **Threat detection for OS-level (agent-based)** | Defender for Servers and Defender for Endpoint detect threats at the OS level, including virtual machine behavioral detections and *fileless attack detection*, which generates detailed security alerts that accelerate alert triage, correlation, and downstream response time. | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) |
| **Threat detection for network-level (agentless security alerts)** | Defender for Servers detects threats that are directed at the control plane on the network, including network-based security alerts for **Azure virtual machines**. | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Microsoft Defender Vulnerability Management (MDVM) Add-on** | Enhance your vulnerability management program consolidated asset inventories, security baselines assessments, application block feature, and more. | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Security Policy and Regulatory Compliance** | Customize a security policy for your subscription and also compare the configuration of your resources with requirements in industry standards, regulations, and benchmarks. Learn more about regulatory compliance and security policies | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png)|
|**Adaptive application controls** | Adaptive application controls define allowlists of known safe applications for machines. Identify software your organization banned but is nevertheless running on your machines. Identify outdated or unsupported versions of applications. Increase oversight of apps that access sensitive data To use this feature, Defender for Cloud must be enabled on the subscription. **Support on Azure VMs and Arc-enabled servers, both Linux and Windows** | Not supported in Plan 1 |![Yes](../assets/yes-icon.png) |
| **Free data ingestion (500 MB) to Log Analytics workspaces** | Free data ingestion is available for specific data types to Log Analytics workspaces. Data ingestion is calculated per node, per reported workspace, and per day. It's available for every workspace that has a *Security* or *AntiMalware* solution installed. | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Free Azure Update Manager Remediation for Arc machines** | Azure Update Manager remediation of unhealthy resources and recommendations is available at no additional cost for Arc enabled machines. | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Just-in-time virtual machine access** | Just-in-time virtual machine access locks down machine ports to reduce the attack surface. **Only Azure VMs.** | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Adaptive network hardening** | Network hardening filters traffic to and from resources by using network security groups (NSGs) to improve your network security posture. Further improve security by hardening the NSG rules based on actual traffic patterns. To use this feature, Defender for Cloud must be enabled on the subscription. **Because we are talking NSGs here, only Azure VMs is supported.** | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **File integrity monitoring** | File integrity monitoring examines files and registries for changes that might indicate an attack. A comparison method is used to determine whether suspicious modifications have been made to files. **Uses Azure Change Tracking solution so both Azure VMs and Arc-enabled servers is supported.** | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Docker host hardening** | Assesses containers hosted on Linux machines running Docker containers, and then compares them with the Center for Internet Security (CIS) Docker Benchmark. | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |
| **Network map** | Provides a geographical view of recommendations for hardening your network resources. **Only Azure.** | Not supported in Plan 1| ![Yes](../assets/yes-icon.png) |
| **Agentless scanning** | Scans **Azure virtual machines** by using cloud APIs to collect data. | Not supported in Plan 1 | ![Yes](../assets/yes-icon.png) |

### Azure VMs
My take on it is to activate Plan 2 on all Azure VMs. 

### Azure Arc-enabled servers
For hybrid environments, I would activate Plan 2 on all Azure Arc-enabled servers, just because you will get more features, but not all because some of the features requires an Azure VM. You will get features like:
- Azure Update Manager for free
- Adaptive application controls
- File integrity monitoring
- Free data ingestion (500 MB) to Log Analytics workspaces
- Premium MDVM features

And all of the other features listed requires an Azure VM, and not an Arc-enabled server.

### Direct onboarding
**"But, I don't want to install Azure Arc on my servers on-prem, can I use Defender for Servers then?"* 

Yes, you can use Direct Onboarding. Direct Onboarding is a way to onboard servers to Defender for Servers without using Azure Arc. You can onboard servers running Windows or Linux operating systems, and you can onboard servers that are running in other clouds or on-premises.

You take the onboarding package from the Defender XDR portal (security.microsoft.com) which have the tenant ID already filled in, in the onboarding package. 

You can choose between P1 and P2 for Direct Onboarding as well. But be aware that for the P2 plan you will get limited features. This is a good way if you don't want the server management capabilities that Azure Arc provides, such as Azure Update Manager, Extended Security Updates, Azure Policy and Guest Configuration, other Azure extensions and so on.

On the designated Azure subscription of your choice when you activate the Direct Onboarding feature you can choose the P2 plan. Go in to Defender for Cloud > Environment settings > Choose the direct onboarding subscription > Select P2 for virtual machines on Defender for Servers.

What will you then get with the P2 plan for Direct Onboarding?

You will have access to all Defender for Servers Plan 1 features and the Defender Vulnerability Management Addon features included in Plan 2.

### Defender Vulnerability Management (MDVM)
Defender Vulnerability Management (MDVM) is natively integrated into Defender for Cloud. But what's included in Defender for Servers Plan 1 and Plan 2?

|Capability|Defender For Servers Plan 1|Defender For Servers Plan 2|
|:----|:----:|:----:|
| Vulnerability assessment |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Configuration assessment |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Risk based prioritization |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Remediation tracking |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Continuous monitoring |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Software inventory |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Software usages insights |![Yes](../assets/yes-icon.png)|![Yes](../assets/yes-icon.png)|
| Security baselines assessment |-|![Yes](../assets/yes-icon.png)|
| Block vulnerable applications |-|![Yes](../assets/yes-icon.png)|
| Browser extensions assessment |-|![Yes](../assets/yes-icon.png)|
| Digital certificate assessment |-|![Yes](../assets/yes-icon.png)|
| Network share analysis |-|![Yes](../assets/yes-icon.png)|
| Hardware and firmware assessment |-|![Yes](../assets/yes-icon.png)|
| Authenticated scan for Windows |-|![Yes](../assets/yes-icon.png)|

Make sure to run [supported operating system](https://learn.microsoft.com/en-us/microsoft-365/security/defender-vulnerability-management/tvm-supported-os?view=o365-worldwide) for your servers (or clients) to be able to use the full potential of MDVM.

# Defender CSPM vs Foundational CSPM

*In the table below, I'm only comparing Azure against on-premise, look at Microsoft Official Documentation for more information about AWS and GCP.*

| Feature | Foundational CSPM | Defender CSPM | Availability | My take on it |
|--|--|--|--|--|
| Security recommendations | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png)| Azure, on-premises | Make sure to take action on those recommendations, please! |
| Asset inventory | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure, on-premises | No wow effect here |
| Secure score | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure, on-premises | Make sure to follow-up and take action |
| Data visualization and reporting with Azure Workbooks | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure, on-premises | It's Azure Resource Graph (ARG) |
| Data exporting | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure, on-premises | Use of Event Hub or Log Analytics, those services cost as well |
| Workflow automation | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure, on-premises | A feature that doesn't get a lot of love, make sure to use it |
| Tools for remediation | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure, on-premises | |
| Microsoft Cloud Security Benchmark | ![Yes](../assets/yes-icon.png) | ![Yes](../assets/yes-icon.png) | Azure | Great compliance standard to start with! |
| Security governance | - | ![Yes](../assets/yes-icon.png) | Azure, on-premises | |
| Regulatory compliance standards | - | ![Yes](../assets/yes-icon.png) | Azure, on-premises | |
| Cloud security explorer | - | ![Yes](../assets/yes-icon.png) | Azure | Just learn KQL, it's fun! |
| Attack path analysis | - | ![Yes](../assets/yes-icon.png) | Azure | Cool feature, but only for cloud resources 😒 |
| Agentless scanning for machines | - | ![Yes](../assets/yes-icon.png) | Azure | Great, but only for Azure VMs, and not a real-time protection |
| Agentless container security posture | - | ![Yes](../assets/yes-icon.png) | Azure | |
| Container registries vulnerability assessment, including registry scanning | - | ![Yes](../assets/yes-icon.png) | Azure | |
| Data aware security posture | - | ![Yes](../assets/yes-icon.png) | Azure | |
| EASM insights in network exposure | - | ![Yes](../assets/yes-icon.png) | Azure | |
| Permissions management (Preview) | - | ![Yes](../assets/yes-icon.png) | Azure | |

The agentless capabilities are not "that" agentless as you might think. Microsoft is taking a snapshot of the disk and then analyzing it and then gives you the result in form of an report. This is happening every 24-hours. This is not a real-time protection, but it's a good start. 

And if we circle back to the DevOps capabilities, we just need to activate Defender CSPM on one Azure subscription to be able to get those capabilities.
For Defender EASM, or Defender External Attack Surface Management, it's basically the same thing. We need to activate Defender CSPM on one Azure subscription to be able to get those capabilities.

My belief is that we should use Enterprise Scale Landing Zone to be able to activate the features we want. Since Defender for Cloud is activated on per subscription level, we need to make sure that we are using the features and capabilites we need, and not spending a dime more than we need to. Because we can activate all the premium stuff, but do we not follow-up, make sure we are compliant, taking actions on **ALERTS** and truly use the service - then why bother?

And again, which Azure resources are billable for Defender CSPM?

### Billable resources for Defender CSPM are resources of the types:

| Azure Service | Azure Resource Type | Doesn't Cost When... |
|---------------|-------------|------|
| Compute | Microsoft.Compute/virtualMachines<br/>Microsoft.Compute/virtualMachineScaleSets/virtualMachines<br/>Microsoft.ClassicCompute/virtualMachines | - Deallocated VMs<br/>- Databricks VMs |
| Storage | Microsoft.Storage/storageAccounts | Storage accounts without blob containers or file shares |
| DBs | Microsoft.Sql/servers<br/>Microsoft.DBforPostgreSQL/servers<br/>Microsoft.DBforMySQL/servers<br/>Microsoft.Sql/managedInstances<br/>Microsoft.DBforMariaDB/servers<br/>Microsoft.Synapse/workspaces | N/A |

# Defender for Cloud Coverage & Cost workbooks
These two workbooks are great to use to get an overview of your Defender for Cloud coverage and cost. 

You will find these workbooks directly in the Defender for Cloud portal in the blade called 'Workbooks'. Take a look at them and see your current coverage and what the cost will be if you activate all the features and capabilities.

# Summary
Confusing? Yes, it is. But I hope that I have made it a bit more clear for you, and that I have given you some guidance and thinking points in your choice of Defender for Cloud plans.