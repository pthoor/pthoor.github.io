---
title: "New Patch Management tool in the cloud - Azure Update Manager (AUM) is now GA"
date: '2023-09-21T09:00:00+02:00'
excerpt: 'Azure Update Manager (AUM) is now GA and is a new Patch Management tool in Azure that can be used to patch Windows and Linux systems in Azure, on-premises, and other clouds. In this post we will look at the cost of AUM.'
tags: 
  - Arc
  - ESU
  - AzureUpdateManager
toc: true
header:
  og_image: /assets/PatchSystems.png
---

![](/assets/PatchSystems.png)

# Azure Update Manager (AUM) is now GA
Finally we have a more streamlined patch management tool in Azure, and it's called Azure Update Manager (AUM). It's now GA (Generally Available) from Microsoft. This is the new Patch Management tool in the cloud that can be used to patch Windows and Linux servers in Azure, on-premises, and other clouds. In this post we will look at the cost of AUM.

During the preview, AUM was free to use, but now that it's GA, we have to pay for it - or do we? The cost of AUM is based on some logic behind the scene, and you will learn that in this post.

# What is Azure Update Manager (AUM)?
Have you used Automation Update management before? Azure Update Manager is the version 2 of that product, and now we don't need Log Analytics agent (MMA) to be installed on the servers we want to patch. We can patch Windows and Linux servers in Azure, on-premises, and other clouds. The good thing is that this is now a native Azure service. 

# Price for AUM

| VM Type                                              | Price per day   | Price per month |
| :----:                                               | :----: | :----: |
| Azure VM                                             | Free   | Free   |
| Arc-enabled VM without Defender for Cloud            | $0.167 | $5     |
| Arc-enabled VM with Defender for Cloud Plan 1        | $0.167 | $5     |
| Arc-enabled VM with Defender for Cloud Plan 2        | Free   | Free   |
| Arc-enabled VM with Extended Security Update license | Free   | Free   |

So if you have an Arc-enabled VM without Defender for Cloud license and that machine are connected 10 days per month, the cost will be $1.67 per month for that server.

## What's driving the price for Arc-enabled servers with AUM?

When determining the cost for using Azure Update Manager, it's essential to understand how a machine is classified as 'managed' for a given day. A machine falls under this category if:

1. The machine shows a 'Connected' status for Arc during any operation (whether it's patching on-demand, through a scheduled task, or an assessment). This connection can be at any specific time of the day, especially if it's linked to a schedule, even if no tasks are carried out that day.

2. Any of the following activities occur on that day:
  1. A direct command to patch or assess is given.
  2. The machine undergoes a routine check for outstanding patches.
  3. The machine is linked to an active schedule, either in a fixed or flexible manner.

## Quick AUM pricing examples with Azure Arc-enabled servers

### Example 1
Let's say you have a server that is connected to Azure Arc, but you don't have any schedule for patching. You will not be charged for this server.

### Example 2
Let's say you have a server that is connected to Azure Arc the entire month, and you have a schedule for patching. You will be charged for this server at the maximum price of $5 per month.

### Example 3
Let's say you have a server that is connected to Azure Arc the entire month, and you have a schedule for patching. You have also implemented Defender for Cloud Plan 2 to the subscription that hold the Azure Arc-enabled servers. You will not be charged for this server.

### Example 4
Let's say you have a server that is connected to Azure Arc the entire month, and you have a schedule for patching. You have also implemented Defender for Cloud Plan 1 to the subscription that hold the Azure Arc-enabled servers. You will be charged for this server at the maximum price of $5 per month.

### Example 5
Let's say you have a server that is connected to Azure Arc for 15 days, and you have a schedule for patching. You have also implemented Defender for Cloud Plan 1 to the subscription that hold the Azure Arc-enabled servers. You will be charged for this server at the rate of $0.167 per day, which is $2.50 per month.

# Summary
Azure Update Manager (AUM) is now GA and is a new Patch Management tool in Azure that can be used to patch Windows and Linux systems in Azure, on-premises, and other clouds. In this post we looked at the cost of AUM. We learned that the cost is based on the number of days a server is connected to Azure Arc, if you have a schedule associated to the server or will be using the on-demand commands for patching, and if you have Defender for Cloud Plan 1 or 2 implemented in the subscription that hold the Azure Arc-enabled servers.

Plan you cloud journey wisely, see if you already have Defender for Cloud activated in your subscription, and if you don't have that, see if you can implement that to save some money on the AUM cost. And do you have some old systems with Windows Server 2012/2012 R2? Then you can use AUM to patch those systems with ESU (Extended Security Updates) for free.
