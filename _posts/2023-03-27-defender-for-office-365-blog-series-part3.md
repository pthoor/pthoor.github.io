---
title: Defender for Office 365 Blog Series - Part 3
date: '2023-03-31T09:00:00+02:00'
excerpt: "🛡️Blog series about Microsoft Defender for Office 365 (MDO), how to get started with threat hunting"
tags: 
  - Defender
toc: true
---
# Introduction
Threat hunting is the process of proactively searching for signs of malicious activity in your organization's network or systems. It is a way of finding and stopping attackers before they can cause damage or steal data. Threat hunting can also help you improve your security posture and reduce your attack surface.

In this blog post, we will show you how to use Defender for Office 365 to perform threat hunting in your organization. We will cover the following topics:

- How to access the threat hunting dashboard and explore its features
- How to create and run custom queries to find suspicious activity
- How to investigate and remediate threats using the threat explorer
- How to use advanced hunting to write complex queries and automate actions
- How to use threat intelligence to enrich your analysis and response

# Microsoft Defender for Office 365 - Part 3 - Hunting


## How to access the threat hunting dashboard and explore its features

To access the threat hunting dashboard, you need to have a Defender for Office 365 plan 2 license and be assigned one of the following roles:

- Global administrator
- Security administrator
- Security reader
- Security operator

You can access the threat hunting dashboard from the Microsoft 365 security center (https://security.microsoft.com), then to go to Threat management > Dashboard.

The threat hunting dashboard provides you with an overview of the current threat landscape in your organization. It shows you key metrics such as:

- The number of detected threats in the last 30 days
- The top malware families and attack techniques used by attackers
- The top targeted users and domains in your organization
- The top sources of malicious emails and files
- The top actions taken by Defender for Office 365 to protect your organization

You can also drill down into each metric to see more details and filter by various criteria such as date range, severity, detection source, action type, etc.

The threat hunting dashboard also allows you to access other features such as:

- The threat explorer, which lets you investigate and remediate threats in real time
- The real-time detections report, which shows you the latest threats detected by Defender for Office 365
- The email entity page, which shows you detailed information about a specific email message
- The file entity page, which shows you detailed information about a specific file
- The URL entity page, which shows you detailed information about a specific URL
- The user entity page, which shows you detailed information about a specific user
- The domain entity page, which shows you detailed information about a specific domain

## How to create and run custom queries to find suspicious activity

One of the ways to perform threat hunting is to create and run custom queries using the query builder in the threat explorer. The query builder allows you to specify various criteria such as:

- Date range: You can choose from predefined options such as last 24 hours, last 7 days, last 30 days, etc., or specify a custom date range.
- Detection source: You can choose from various sources such as Exchange Online Protection (EOP), Microsoft Defender for Endpoint (MDE), Microsoft Cloud App Security (MCAS), etc.
- Detection technology: You can choose from various technologies such as anti-spam, anti-malware, anti-phishing, safe links, safe attachments, etc.
- Severity: You can choose from low, medium, high, or unknown severity levels.
- Action: You can choose from various actions taken by Defender for Office 365 such as block, quarantine, move to junk, allow delivery with malware warning, etc.
- Delivery location: You can choose from various delivery locations such as inbox, junk email folder, quarantine folder,


# Summary of MDO Part 3

Now we can start with our hunting and explore the insights. Time to jump into the world of Kusto (KQL) in the next post to see if we can look into which emails have been ZAP'ed, which have been sent to quarantine, and which emails have redirect URLs. 

I see you at the next post!

**Happy hunting!**

![Ninja Cat](/assets/ninja-cat.png)