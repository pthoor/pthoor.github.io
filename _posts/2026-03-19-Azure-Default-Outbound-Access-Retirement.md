---
title: "Azure Default Outbound Access Retirement: What It Actually Means (and What It Doesn't)"
date: '2026-03-19T23:00:00+02:00'
excerpt: 'Azure is retiring default outbound access for VNets. Here’s what it means for your workloads and how to prepare.'
tags:
  - Azure
  - Networking
  - Security
toc: true
mermaid: true
---

On March 31, 2026, Microsoft will change how new Azure Virtual Networks handle outbound internet connectivity. The announcements mostly talk about VMs — but I keep getting the same question from colleagues and customers who run primarily PaaS workloads: *does this affect us?*

I've spent a lot of time digging into the official docs, testing in lab environments, and talking this through with people who work on these things daily. This post is my attempt to lay it all out — from the networking fundamentals up to the per-service impact — so you can make your own assessment.

The short answer for most PaaS-heavy organizations: **probably not.** But the devil is in the details, and there are a few gotchas that will absolutely bite you if you're not paying attention.

## Quick Assessment: Am I Affected?

Before we go deep, here's the cheat sheet:

<pre class="mermaid">
flowchart TD
    Q1{"Your scenario?"} -->|"Existing VNets<br/>created before March 31, 2026"| A1["✅ NOT AFFECTED<br/>Nothing changes. Not now, not later."]
    Q1 -->|"New VNets + VMs<br/>without explicit outbound"| A2["❌ AFFECTED<br/>Subnets will be private by default."]
    Q1 -->|"PaaS services with<br/>delegated/managed subnets"| A3["✅ NOT AFFECTED<br/>Microsoft manages outbound for those."]
    Q1 -->|"Hub-and-spoke with<br/>UDR to Azure Firewall"| A4["✅ NOT AFFECTED<br/>You already have explicit outbound."]
    Q1 -->|AKS clusters| A5["⚠️ MOSTLY FINE<br/>AKS handles it, but read the details."]
    Q1 -->|"100% PaaS<br/>no VMs, no VMSS"| A6["✅ NOT AFFECTED<br/>Almost certainly no impact."]
</pre>

Now let's understand *why*.

## Azure Networking Fundamentals: It's All Software

### Does a VNet Actually "Exist"?

This trips up even experienced engineers. A VNet is **a software construct**. There's no physical switch, no VLAN, no dedicated cable in a datacenter that represents it. It's configuration metadata enforced by Azure's Software-Defined Networking (SDN) stack.

When you create a VNet with address space `10.0.0.0/16`, you're telling Azure: *"Enforce this address space as an isolation boundary. Let NICs placed here communicate within it, and make traffic crossing its boundaries follow my rules."*

The enforcement happens through something called the **Virtual Filtering Platform (VFP)** — think of it as an invisible programmable firewall and router sitting between every VM and the physical network. VFP runs on every Azure host inside the Hyper-V virtual switch, and every single packet from every VM passes through it. It checks NSG rules, evaluates route tables, handles VNET encapsulation, and decides whether a packet goes to the internet or gets dropped. If you've ever used Accelerated Networking, the fast path is VFP offloading its rules to the SmartNIC hardware — same logic, just faster [1] [2].

You don't need to know VFP exists to use Azure networking. But it helps to understand that when I say "Azure evaluates your route table" — it's VFP doing that work, per packet, on the host where your VM runs. There's no separate routing appliance somewhere.

### What Is a Subnet?

A subnet is a **logical partition** within a VNet — a range of IPs you use to organize and apply policy. What makes subnets meaningful is what you attach to them: NSGs, route tables, service endpoints, delegations, and — the star of this post — the `defaultOutboundAccess` property.

## How Azure Routing Works (and Which Route Wins)

Routing in Azure is evaluated **per subnet, per packet** [3]. When a packet leaves a NIC, Azure looks at the destination IP and consults the effective route table for that subnet. This table is built from multiple sources, and the selection logic matters when you're troubleshooting.

### Route Precedence

<pre class="mermaid">
flowchart TD
    pkt["Packet leaves VM NIC<br/>Destination: X.X.X.X"] --> lpm{"Step 1: Longest Prefix Match<br/>(LPM) — always wins first"}
    lpm -->|"Multiple routes<br/>same prefix length"| src{"Step 2: Route source<br/>precedence"}
    lpm -->|"Single longest<br/>match found"| done["✅ Use that route"]

    src -->|"1️⃣ User-Defined Route (UDR)"| udr["UDR wins<br/>(highest priority)"]
    src -->|"2️⃣ BGP route<br/>(from VPN/ER gateway)"| bgp["BGP wins<br/>(if no UDR)"]
    src -->|"3️⃣ System route"| sys["System route wins<br/>(lowest priority)"]
</pre>

A `/28` beats a `/16` beats a `/0`, regardless of source. Longest prefix match always wins first. Only when prefix lengths are equal does the source type matter.

**Two important exceptions** from the docs [3]:

1. System routes for **VNet traffic, VNet peering, and virtual network service endpoints** are *preferred routes* — they take precedence even if a BGP route has a more specific prefix.
2. Routes with a **service endpoint next-hop type** (`VirtualNetworkServiceEndpoint`) cannot be overridden even by UDRs. They sit at the absolute top of Azure's routing hierarchy. This matters when you're designing routing policies — you can't accidentally break service endpoint traffic with a UDR.

### Default System Routes

Every subnet gets these automatically [3]:

| Prefix | Next Hop | Purpose |
| -------- | ---------- | --------- |
| VNet address space (e.g. 10.0.0.0/16) | VNet | Traffic within the VNet stays in the VNet |
| 0.0.0.0/0 | Internet | Default route — anything not matched goes to the internet |
| 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 | None | RFC 1918 ranges not in your VNet are dropped |
| 100.64.0.0/10 | None | Shared address space (RFC 6598 / CGNAT) is dropped |

The `0.0.0.0/0 → Internet` system route is what gives VMs internet access. But *how* that access works depends on whether the VM has **explicit** outbound or relies on **default** outbound.

## What Default Outbound Access Actually Is

Here's what happens today when you deploy a VM with only a private IP — no public IP, no NAT Gateway, no load balancer, no UDR to a firewall:

<pre class="mermaid">
sequenceDiagram
    participant VM as VM (10.0.1.4) - Private IP only
    participant VFP as VFP on Host
    participant Azure as Azure Platform
    participant Internet as Internet

    VM->>VFP: Packet to 8.8.8.8
    VFP->>VFP: Route lookup: 0.0.0.0/0 → Internet
    VFP->>VFP: No explicit outbound method found
    VFP->>Azure: Apply "Default Outbound Access"

    Note over Azure: Assigns ephemeral public IP<br/>from Microsoft-owned pool:<br/>• NOT visible to you<br/>• NOT static (can change)<br/>• Shared with other tenants<br/>• ZERO control

    Azure->>Internet: Packet exits with source:<br/>20.x.x.x (ephemeral)
</pre>

This "hidden public IP" is what Microsoft calls **default outbound access** [4]. It was convenient — your VM just worked — but it was always a problem:

- **Security risk:** You can't see or control the IP. It contradicts Zero Trust.
- **Unreliable:** The IP can change without warning, breaking things that depend on a stable source IP.
- **Multi-NIC chaos:** VMs with multiple NICs can get different default outbound IPs, causing asymmetric routing.

### What Happens in a Private Subnet?

When `defaultOutboundAccess = false`, the same scenario plays out very differently:

<pre class="mermaid">
sequenceDiagram
    participant VM as VM (10.0.1.4) - Private IP only
    participant VFP as VFP on Host

    VM->>VFP: Packet to 8.8.8.8
    VFP->>VFP: Route lookup: 0.0.0.0/0 → Internet
    VFP->>VFP: No explicit outbound method found
    VFP->>VFP: Subnet is private<br/>(defaultOutboundAccess = false)

    Note over VFP: 🚫 DROP<br/>No ephemeral IP assigned.<br/>Packet silently dropped.<br/><br/>Windows Update fails.<br/>Defender can't phone home.<br/>KMS activation fails.

    VFP --x VM: No connectivity
</pre>

No safety net. No outbound. Period.

### The Azure Storage Same-Region Exception

There is one documented exception worth knowing about: VMs in a private subnet **can still reach Azure Storage accounts in the same region** without explicit outbound [4]. This is a platform-level behavior. Microsoft recommends using NSGs to control it. If your security posture requires *all* outbound through a firewall, you need to be aware that this path exists.

## What Changes on March 31, 2026

Let's be precise [4]:

### What Changes

- **New VNets** created using API versions released after March 31, 2026 will have `defaultOutboundAccess = false` on their subnets **by default**. The new API version is expected to be `2025-07-01`.
- This applies to all configuration methods: Azure Portal, ARM templates, Bicep, PowerShell, CLI — but **the Portal will adopt the new API first**, so Portal users will see the change before IaC users who pin older API versions.

### What Does NOT Change

- **Existing VNets** — completely unaffected. Both existing VMs and new VMs in these VNets continue to get default outbound IPs, unless the subnets are manually modified to become private [4].
- **Subnets with explicit outbound** (NAT Gateway, Public IP, Load Balancer outbound rules, UDR to firewall) — unaffected.
- **You can still opt out** — set `defaultOutboundAccess = true` explicitly if you need the old behavior.

### The API Version Detail

If you use Bicep or ARM templates and pin an older API version, the old behavior continues. The official FAQ confirms this includes Terraform: *"Earlier versions of ARM templates (or tools like Terraform that can specify older versions) will continue to set defaultOutboundAccess as null, which implicitly allows outbound access"* [4].

An important nuance here: the new default doesn't flip like a switch on April 1. It's tied to a specific new API version (likely `2025-07-01`) that will roll out after March 31. **The Azure Portal will adopt the new API version first**, so people creating VNets through the portal will see private subnets as the default. If you deploy via ARM/Bicep templates pinned to an older API version, nothing changes until you update the API version in your template. For the AzureRM Terraform provider, we don't know exactly when it will adopt the new API — but when it does, the default will flip. The AzAPI provider gives you explicit control over which API version to target.

In Bicep, I'd recommend being explicit regardless:

```bicep
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  properties: {
    addressPrefix: '10.0.1.0/24'
    defaultOutboundAccess: false  // Be explicit. Use NAT Gateway or UDR.
  }
}
```

## The Key Sentence Everyone Should Know

Buried in the Microsoft Learn documentation for default outbound access [4], there's one critical sentence that should be the headline of every discussion about this change:

> **"Private subnets aren't applicable to delegated or managed subnets used for hosting PaaS services. In these scenarios, outbound connectivity is managed by the individual service."**

If your subnet is delegated to a PaaS service, the `defaultOutboundAccess` property **does not apply**. The PaaS service manages its own connectivity. This eliminates the concern for most PaaS-heavy organizations.

But — and this is important — *"managed by the individual service"* doesn't mean the same thing for every service. Some services truly own their egress. Others expect you to provide it. Let me break this down.

## PaaS Services and Delegated Subnets — How They Actually Work

### Pattern A: Fully Managed by Microsoft (No Customer VNet)

Services like Azure SQL Database, Azure Storage, Cosmos DB, Key Vault — they run entirely in Microsoft's infrastructure. You connect to them via public endpoints, private endpoints, or service endpoints. You don't see a VNet. There's nothing for you to configure outbound on.

**Impact: None. Not even close.**

### Pattern B: Delegated Subnet (Microsoft Deploys Into Your VNet)

These services require a **delegated subnet** in your VNet [5]. You create the subnet, delegate it to the service, and Microsoft deploys its instances into it.

<pre class="mermaid">
flowchart TD
    subgraph vnet["Your VNet: 10.0.0.0/16"]
        sqlmi["snet-sqlmi · 10.0.1.0/24<br/>Delegation: Microsoft.Sql/managedInstances<br/>SQL MI Instance (Microsoft-managed NICs)"]
        vm["snet-workload · 10.0.2.0/24<br/>No delegation — your VMs"]
    end

    sqlmi -. "Delegated subnet:<br/>exempt from private<br/>subnet setting [4]" .-> note1["But check per-service<br/>support carefully!"]
    vm -. "Your subnet:<br/>IS affected<br/>in new VNets" .-> note2["Needs explicit outbound"]
</pre>

The important thing: **each service handles this differently.** The exemption from the private subnet setting is documented, but what "managed by the individual service" means varies:

- **Azure SQL Managed Instance** uses Network Intent Policies — automatically injected NSG rules and routes [6]. But here's the critical part: **SQL MI does not support private subnets.** The docs state deploying SQL MI in a private subnet (where default outbound access is disabled) is currently not supported. SQL MI still relies on default outbound access for management traffic, and NAT Gateway isn't supported on SQL MI subnets. If you're running SQL MI, **this is the service you need to watch most closely** as the deadline approaches. Monitor the docs for updates.
- **Azure NetApp Files** has no internet egress at all — it operates entirely within the VNet over NFS/SMB using private network interfaces. Not affected, and there's nothing to configure.
- **Azure DB for PostgreSQL Flexible Server** doesn't use Network Intent Policies. The service requires access to Azure Storage for WAL file archival — the recommended approach is adding a `Microsoft.Storage` service endpoint to the delegated subnet [7].
- **Azure Databricks** — customer owns egress on the data plane. Use Secure Cluster Connectivity.

### Pattern C: VNet Integration (Outbound-Only Delegation)

App Service and Azure Functions (Premium/Dedicated) use this model [8]. They delegate a subnet purely so that the service's outbound traffic can originate from your VNet.

<pre class="mermaid">
flowchart TD
    subgraph vnet["Your VNet"]
        vnics["snet-app-int<br/>Delegation: Microsoft.Web/serverFarms<br/>App Service mounts vNICs here<br/>for OUTBOUND traffic"]
    end

    subgraph appservice["App Service (Microsoft-managed)"]
        app["Your Web App"]
    end

    app -- "Outbound calls route<br/>through this subnet" --> vnics
    vnics -- "Follows your UDR<br/>and NAT Gateway" --> internet(("Internet /<br/>other services"))
</pre>

**One thing I got wrong initially and want to be clear about:** by default, App Service with VNet integration does **not** route all outbound traffic through your VNet. Internet-bound traffic still exits through App Service's own platform IPs unless you explicitly set `outboundVnetRouting.allTraffic = true` [8]. This catches people off guard — you think you're controlling egress because you configured VNet integration, but only RFC 1918 traffic goes through the VNet by default.

### Service Endpoints and Private Endpoints

Quick clarification since these come up in every conversation:

- **Service endpoints** modify the routing path at the platform level so traffic to Azure services stays on the backbone. They use the `VirtualNetworkServiceEndpoint` next-hop type, which is immune to UDR overrides [3]. No delegation, no injection, no impact from the default outbound change.
- **Private endpoints** place a NIC in your subnet with a private IP mapped to a PaaS resource. Traffic is VNet-internal. Not affected by the default outbound change because the traffic never goes outbound.

## Service-by-Service Impact Table

The "Egress Owner" column is the one that matters — if Microsoft owns egress, the retirement doesn't affect that service.

### No Customer VNet Involvement

| Service | Egress Owner | Impact |
| --------- | ------------- | -------- |
| Azure SQL Database | Microsoft | **None** |
| Azure Storage | Microsoft | **None** |
| Cosmos DB, Key Vault, Event Hubs, Service Bus | Microsoft | **None** |
| Azure Monitor / Log Analytics | Microsoft | **None** |
| Azure Functions (Consumption) | Microsoft | **None** |

### Delegated Subnet / VNet Injection

| Service | Delegation | Egress Owner | Impact |
| --------- | ----------- | ------------- | -------- |
| **Azure SQL Managed Instance** | `Microsoft.Sql/managedInstances` | **Microsoft** (Network Intent Policy) | **⚠️ HIGH RISK** — private subnets not supported; still relies on default outbound [6] |
| Azure Databricks | `Microsoft.Databricks/workspaces` | **Customer** (data plane) | Low — use Secure Cluster Connectivity |
| Azure NetApp Files | `Microsoft.NetApp/volumes` | N/A — no internet egress | **None** |
| Azure DB for PostgreSQL Flex | `Microsoft.DBforPostgreSQL/flexibleServers` | **Partially Microsoft** | Low — needs Storage service endpoint [7] |
| Azure DB for MySQL Flex | `Microsoft.DBforMySQL/flexibleServers` | **Partially Microsoft** | Low — similar to PostgreSQL |
| Azure Container Instances | `Microsoft.ContainerInstance/containerGroups` | **Customer** | Low — use NAT Gateway |
| Azure Spring Apps | `Microsoft.AppPlatform/Spring` | **Customer** | Low — use NAT Gateway or UDR |
| Power Platform | `Microsoft.PowerPlatform/enterprisePolicies` | **Customer** | Low — attach NAT Gateway |

### VNet Integration (Outbound Delegation)

| Service | Delegation | Egress Owner | Impact |
| --------- | ----------- | ------------- | -------- |
| App Service (VNet Integration) | `Microsoft.Web/serverFarms` | **Customer** | Low — provide NAT GW or UDR; remember to enable `allTraffic` [8] |
| Azure Functions (Premium/Dedicated) | `Microsoft.Web/serverFarms` | **Customer** | Low — same as App Service |
| Azure Machine Learning (managed VNet) | N/A (managed) | **Microsoft** | **None** |

### Compute (Directly Affected)

| Service | Egress Owner | Impact |
| --------- | ------------- | -------- |
| Virtual Machines | **Customer** | **YES** — must provide explicit outbound in new VNets [4] |
| Virtual Machine Scale Sets | **Customer** | **YES** — Flexible VMSS already defaults to private [4] |
| Azure Kubernetes Service | **Customer** (but AKS configures it) | **YES** — see next section |
| Azure Batch | **Customer** | **YES** — use NAT Gateway |
| Azure Update Manager | **Customer** (update downloads) / **Platform** (orchestration) | **PARTIAL** — orchestration works via WireServer, update downloads need explicit outbound [15] |
| Azure Virtual Desktop | **Customer** | **YES** — use NAT Gateway or Azure Firewall |
| Windows 365 (ANC) | **Customer** | **YES** — see dedicated section below |
| Windows 365 (Microsoft-hosted) | **Microsoft** | **None** — but see the trade-offs |

## AKS — The One That Catches People Off Guard

I'll be upfront: AKS is not my deepest area of expertise. My day-to-day is more on the network security and platform architecture side. But I've gone through the docs carefully and spoken with colleagues who live in the Kubernetes world, so here's what I can tell you with confidence.

AKS sits in a gray area — it's a PaaS service, but it deploys VMs (nodes) into a VNet. That might make you think it's affected, but the reality is simpler than it looks.

### What Changes for AKS

Starting March 31, 2026, AKS clusters using the **AKS-managed VNet option** will place cluster subnets into private subnets by default [9]. But here's the thing — **AKS has never used default outbound access**, and in fact already sets subnets as private for new deployments. AKS always configures an explicit outbound type. Every cluster gets one of these:

| Outbound Type | What It Does |
| --------------- | -------------- |
| `loadBalancer` (default) | AKS creates a Standard Load Balancer with outbound rules and a public IP |
| `managedNATGateway` | AKS provisions a NAT Gateway on the cluster subnet [10] |
| `userAssignedNATGateway` | You provide a NAT Gateway (BYO VNet only) [10] |
| `userDefinedRouting` | You provide a UDR pointing to your firewall/NVA (BYO VNet only) |
| `none` | No egress infrastructure — for network-isolated clusters only [9] |
| `block` (Preview) | Actively blocks all egress via NSG rules — for fully isolated clusters [9] |

Because AKS always configures one of these, the docs state: *"This setting doesn't impact AKS-managed cluster traffic, which uses explicitly configured outbound paths"* [9]. Clusters using BYO VNets are unaffected entirely.

### Where It Could Bite You

The risk is strictly in **unsupported scenarios** — and you'd have to be doing something fairly unusual. For example, deploying non-AKS resources (test VMs, sidecar workloads) into the AKS-managed subnet. Those resources would have relied on default outbound and will lose internet access. In any supported AKS configuration, this retirement is a non-event.

<pre class="mermaid">
flowchart TD
    start{"AKS VNet mode?"} -->|AKS-managed VNet| managed["AKS creates VNet"]
    start -->|BYO VNet| byo["You provide VNet + subnet"]

    managed --> out1{"Outbound type?"}
    byo --> out2{"Outbound type?"}

    out1 -->|loadBalancer / managedNATGateway| ok1["Explicit outbound ✅"]
    out2 -->|userAssignedNATGateway / userDefinedRouting / loadBalancer| ok2["Explicit outbound ✅"]

    ok1 --> safe["✅ Supported config: NOT impacted"]
    ok2 --> safe

    safe --> warning["⚠️ Do NOT deploy non-AKS resources<br/>into AKS-managed subnets"]
</pre>

**My recommendation (take it for what it's worth from a non-AKS-specialist):** for production, use BYO VNet with `userDefinedRouting` through your firewall. For dev/test, `managedNATGateway` is straightforward. And regardless — don't put non-AKS resources in AKS subnets.

## Windows 365 — Two Models, Very Different Security Postures

Windows 365 has two networking models [11], and they couldn't be more different in how they relate to this change — and to your security architecture.

### Microsoft-Hosted Network

With Microsoft-hosted network, your Cloud PC's NIC sits in a **Microsoft-managed VNet** that you never see or touch. Microsoft handles all egress. You don't configure a VNet, subnet, route table, or firewall. The retirement of default outbound access has **zero impact** on this model.

### Azure Network Connection (ANC)

With ANC, the Cloud PC's NIC is injected into **your VNet and subnet**. You own the routing, NSGs, firewall rules — everything. If you create a new VNet after March 31, 2026, and don't configure explicit outbound, **Cloud PC provisioning will fail** because the ANC health checks can't reach the required endpoints.

Microsoft published guidance for Windows 365 ANC customers specifically about this change in February 2026 [12] — they recommend NAT Gateway as the simplest fix.

<pre class="mermaid">
flowchart TD
    w365{"Windows 365<br/>network model?"} -->|"Microsoft-hosted<br/>network"| mhn["Microsoft manages everything<br/>No customer VNet"]
    w365 -->|"Azure Network<br/>Connection"| anc["Cloud PC NIC in<br/>YOUR VNet"]

    mhn --> mhn_impact["✅ Not affected<br/>by retirement"]
    anc --> anc_q{"New VNet<br/>after March 31?"}
    anc_q -->|Yes| anc_new["❌ Needs explicit outbound<br/>(NAT GW, Firewall, etc.)<br/>or provisioning fails"]
    anc_q -->|No| anc_existing["✅ Existing VNet<br/>continues working"]

    mhn_impact --> tradeoff["⚠️ But: no network-level<br/>visibility or control"]
</pre>

### My Take: ANC Is the Right Choice for Security-Conscious Organizations

Microsoft positions the Microsoft-hosted network as the recommended default, and I understand why — it's simpler. But from a Zero Trust perspective, I'd push back on that recommendation for any organization that takes network security seriously.

With Microsoft-hosted network, your **only visibility into Cloud PC traffic is at the endpoint level** — Microsoft Defender for Endpoint, Defender for Cloud Apps, Windows Firewall. That's not nothing, but it means you have no VNet flow logs (or still using NSG flow logs), no Azure Firewall logs, no network-level DLP, no way to inspect or control egress at the network layer. You're trusting Microsoft's managed infrastructure to handle traffic you can't see.

With ANC, your Cloud PCs are on your VNet. Their traffic flows through your Azure Firewall (or whatever NVA you run). You get full logging, full inspection, and full control — the same way you'd handle any other workload in your environment. Yes, it's more work. Yes, you need to manage the networking. But you also get to **actually see what your Cloud PCs are doing on the network**, which in my experience matters a lot when something goes wrong or when compliance asks for evidence.

The trade-off in a table:

| Capability | Microsoft-Hosted Network | ANC (Your VNet) |
| ----------- | ------------------------ | ----------------- |
| Network-level traffic inspection | ❌ No | ✅ Yes (Azure Firewall, NVA) |
| VNet flow logs | ❌ No | ✅ Yes |
| Azure Firewall / NVA logs | ❌ No | ✅ Yes |
| Network-level DLP | ❌ No | ✅ Yes |
| Endpoint-level visibility (MDE) | ✅ Yes | ✅ Yes |
| On-prem access via ExpressRoute/VPN | ❌ Requires VPN on Cloud PC | ✅ Native via VNet |
| Hybrid Entra join | ❌ Not supported | ✅ Supported |
| Operational complexity | Low | High |
| Affected by this retirement | No | Yes (new VNets only) |

If you're already running a hub-and-spoke with Azure Firewall, adding Windows 365 Cloud PCs via ANC is just another spoke. The pattern is the same. And if your organization requires that all outbound traffic is inspected and logged — and most regulated industries do — then Microsoft-hosted network simply doesn't meet the bar.

## Azure Update Manager — It Half-Works in Private Subnets

Azure Update Manager is a sneaky one because it spans **two distinct connectivity planes**, and they behave very differently when you cut off internet outbound.

### The Orchestration Plane (Works Without Internet)

Update Manager uses the Azure VM Agent to deploy its patch extensions (`Microsoft.CPlat.Core.WindowsPatchExtension` on Windows, `LinuxPatchExtension` on Linux). The VM Agent communicates with the Azure Fabric Controller via **WireServer at 168.63.129.16** — a virtual IP on the host node [13] [14].

Here's what makes this special: **168.63.129.16 is not subject to UDRs or NSGs**. It's platform-internal traffic between the guest VM and the host node. It doesn't traverse the VNet at all. This means:

- The Update Manager extension gets deployed successfully
- Orchestration commands (trigger assessment, trigger patching) reach the VM
- Results get reported back to Azure Resource Graph

With a supported VM Agent version, extension packages are also downloaded through the **HostGAPlugin** feature over 168.63.129.16 — no separate Azure Storage access needed [13]. However, there's an important caveat: HostGAPlugin only handles extension *package* delivery. If the extension itself needs to reach external resources (a script from GitHub, a backup to Azure Storage), those connections still need their own network path.

Ports **80/tcp** and **32526/tcp** must remain open in the **guest OS firewall** (Windows Firewall / iptables) for WireServer communication — but this is the guest firewall, not NSGs [14].

### The Update Download Plane (Breaks Without Internet)

Here's where it falls apart. **Azure Update Manager does not serve updates.** It orchestrates — it tells the VM *when* to patch and *what* to install — but the actual update content comes from somewhere else [15]:

- **Windows:** The Windows Update Agent (WUA) downloads patches from Microsoft Update or your WSUS server
- **Linux:** The native package manager (yum, apt, zypper) downloads from its configured repositories

These are internet endpoints. In a private subnet with `defaultOutboundAccess = false` and no explicit outbound, these connections get silently dropped.

And here's the part that surprises people: **assessment (scanning for available patches) also breaks**, not just installation. The WUA needs to contact its update source to get metadata about available patches. No connectivity to the update source = no scan results = Update Manager shows the VM as having no data, or assessments time out.

<pre class="mermaid">
sequenceDiagram
    participant VM as VM (Private Subnet)
    participant Agent as VM Agent / Extension
    participant WS as WireServer (168.63.129.16)
    participant Azure as Azure Resource Graph
    participant WUA as Windows Update Agent
    participant MU as Microsoft Update / WSUS

    Note over VM,Azure: Orchestration Plane — Works ✅
    Azure->>WS: Trigger assessment
    WS->>Agent: Execute patch extension
    Agent->>WS: Report orchestration status
    WS->>Azure: Results → Resource Graph

    Note over VM,MU: Update Download Plane — Fails ❌
    Agent->>WUA: Scan for available updates
    WUA-xMU: GET update metadata<br/>(*.update.microsoft.com)<br/>🚫 No outbound path — DROPPED
    WUA->>Agent: Scan failed / no data
    Agent->>WS: Report: assessment incomplete
</pre>

### Practical Result

| Operation | Needs Internet? | Works in Private Subnet? |
| --------- | --------------- | ------------------------ |
| Extension deployment | No — via HostGAPlugin / WireServer | ✅ Yes |
| Triggering assessment/patching | No — via WireServer | ✅ Yes |
| Assessment scan (getting update metadata) | Yes — WUA contacts update source | ❌ No |
| Downloading update payloads | Yes — WUA/package manager downloads | ❌ No |
| Reporting results to Azure | No — via WireServer | ✅ Yes |

So you'll see the extension installed, the VM shows up in Update Manager, orchestration commands succeed — but actual patch data is empty or stale, and installations fail silently or time out. It *looks* like it's working until you notice nothing is actually getting patched.

### Fix Options

- **NAT Gateway** on the subnet — simplest if you just need it to work
- **UDR to Azure Firewall** with application rules for update endpoints — gives you visibility and control
- **For Windows: point WUA at an internal WSUS server** — eliminates internet dependency entirely. This is the enterprise-grade answer
- **For Linux: use a local repository mirror** — same idea, keep update traffic internal

**Important gotcha:** the WUA and Linux package managers need specific FQDNs allowed, not just generic port 443. The Update Manager prerequisites page [15] links to the [Windows Update troubleshooting guide](https://learn.microsoft.com/en-us/troubleshoot/windows-client/installing-updates-features-roles/windows-update-issues-troubleshooting#issues-related-to-httpproxy) for the current FQDN list — endpoints like `*.update.microsoft.com`, `*.windowsupdate.com`, `*.dl.delivery.mp.microsoft.com`, and `emdl.ws.microsoft.com`. Some of these use HTTP (port 80), not HTTPS. Linux repos like `azure.archive.ubuntu.com` also use port 80. If you're writing Azure Firewall application rules, make sure you cover both ports and check the current endpoint list — Microsoft updates it periodically.

## Hub-and-Spoke with Azure Firewall — You're Already Fine

If you're running hub-and-spoke with a UDR sending `0.0.0.0/0` to Azure Firewall, **you already have explicit outbound** [3]. The retirement doesn't affect you.

<pre class="mermaid">
flowchart LR
    subgraph spoke["Spoke VNet"]
        vm["VM: 10.0.1.4<br/>snet-workload<br/>UDR: 0.0.0.0/0 → 10.100.0.4"]
    end

    subgraph hub["Hub VNet"]
        fw["Azure Firewall<br/>10.100.0.4<br/>SNAT → Public IP"]
    end

    vm -- "UDR match: 0.0.0.0/0<br/>→ Virtual Appliance<br/>(explicit outbound ✅)" --> fw
    fw --> internet(("Internet"))
</pre>

**Still, make subnets private as defense-in-depth.** If someone accidentally removes the route table, a non-private subnet falls back to default outbound — uncontrolled internet access through a random Microsoft IP. Private subnet = fail-closed.

To clear the Azure Advisor alert, you need to make the subnet private AND stop/deallocate the VMs [4]. Even with a UDR, Azure may still *assign* the default outbound IP in non-private subnets — it just won't be *used* unless your explicit method is removed.

## The UDR "Internet" Next-Hop Trap

This one has caught people I know personally. Some organizations use UDR service tag routes with next-hop type `Internet` to bypass the firewall for specific Azure services:

<pre class="mermaid">
flowchart TD
    vm["VM in spoke subnet"] --> rt{"Route table lookup"}
    rt -->|"AzureMonitor / Storage tag<br/>→ Internet"| bypass["Bypass firewall<br/>→ Direct to Azure"]
    rt -->|"0.0.0.0/0<br/>→ Virtual Appliance"| fw["Azure Firewall"]

    bypass --> problem{"Subnet is private?"}
    problem -->|"Yes"| drop["🚫 DROPPED<br/>'Internet' next-hop<br/>has no path"]
    problem -->|"No (legacy)"| works["✅ Works via<br/>default outbound"]

</pre>

In a private subnet, the `Internet` next-hop type **breaks** [4]. No default outbound means no path for that traffic.

The docs are explicit that **this doesn't apply to Service Endpoints**, which use a completely different next-hop type (`VirtualNetworkServiceEndpoint`) [4]. Service endpoints continue to work in private subnets — that's the proper replacement.

| Before (Non-Private Subnet) | After (Private Subnet) |
| ------------------------------ | ---------------------- |
| UDR: `AzureMonitor → Internet` | Use Service Endpoints or Private Endpoints |
| UDR: `Storage → Internet` | Use Service Endpoints or Private Endpoints |
| UDR: `AzureActiveDirectory → Internet` | Route through the firewall, or use Service Endpoints |

If you must keep the `Internet` next-hop type, attach a NAT Gateway to the subnet — it provides the explicit outbound that makes it work again.

## Practical Recommendations

### For Existing Environments

1. **Run Azure Advisor.** There are actually **two separate recommendations** under Operational Excellence: "Add explicit outbound method to disable default outbound" for VMs, and a separate one for VMSS uniform instances. Both are driven by a **NIC-level parameter** (`defaultOutboundConnectivityEnabled`) that tracks whether a default outbound IP is allocated — this is separate from the subnet-level `defaultOutboundAccess` property. A VM can have the NIC-level flag set even if the subnet has explicit outbound configured. To clear it, you need to make the subnet private AND stop/deallocate the VM [4].

2. **Audit your subnets:**

    ```powershell
    Get-AzVirtualNetwork | ForEach-Object {
        $vnet = $_
        $_.Subnets | Where-Object {
            $_.DefaultOutboundAccess -ne $false -and
            -not $_.Delegations
        } | Select-Object @{N='VNet';E={$vnet.Name}}, Name,
            @{N='DefaultOutbound';E={
                if ($null -eq $_.DefaultOutboundAccess) {'null (implicit allow)'}
                else {$_.DefaultOutboundAccess}
            }}
    }
    ```

3. **Make subnets private proactively** — even with a UDR to Azure Firewall. Defense-in-depth. Remember to stop/deallocate VMs for the change to take effect on their NICs [4].

4. **Check for UDR `Internet` next-hop bypasses.** If you use service tag bypass routes, migrate to Service Endpoints or Private Endpoints before making subnets private.

5. **If you run Azure SQL Managed Instance** — pay close attention. SQL MI doesn't support private subnets today [6]. Monitor the docs for updates.

### For New Deployments

1. **Be explicit in your IaC.** Don't rely on defaults:

   ```bicep
   resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
     name: 'vnet-spoke-001'
     location: location
     properties: {
       addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
       subnets: [
         {
           name: 'snet-workload'
           properties: {
             addressPrefix: '10.0.1.0/24'
             defaultOutboundAccess: false
             routeTable: { id: routeTable.id }
             networkSecurityGroup: { id: nsg.id }
           }
         }
       ]
     }
   }
   ```

2. **NAT Gateway is the simplest option** for workloads that just need outbound internet. ~$32/month plus data processing.

3. **Watch for Load Balancer backend pools configured by IP address.** There's a documented known issue: when configured by IP (not NIC), VMs still use default outbound access instead of the LB's outbound rules [4]. Associate a NAT Gateway as a workaround.

4. **Don't blanket-apply private subnets to delegated subnets.** Check delegations first:

   ```powershell
   Get-AzVirtualNetwork | ForEach-Object {
       $_.Subnets | Where-Object { $_.Delegations.Count -gt 0 } |
       Select-Object Name, @{N='Delegation';E={$_.Delegations[0].ServiceName}}
   }
   ```

5. **Watch your Terraform provider version.** We don't know exactly when the AzureRM provider will adopt the new API version (likely `2025-07-01`), but when it does, new VNets will default to private subnets. Set `default_outbound_access_enabled` explicitly in your configs now so you're not caught off guard. For full API version control, use the AzAPI provider [4].

## Summary

This retirement is a meaningful security improvement — it pushes Azure toward Zero Trust for network egress. But it's narrower than the announcements suggest:

- **Existing VNets:** Not affected.
- **PaaS services with delegated subnets:** Generally not affected — Microsoft manages their egress. **Except SQL MI**, which doesn't support private subnets yet.
- **Hub-and-spoke with Azure Firewall:** Not affected — you already have explicit outbound.
- **AKS in supported configurations:** Not affected — AKS always configures explicit outbound.
- **New VMs in new VNets without explicit outbound:** **Affected.** This is the target audience.

The organizations most at risk are those spinning up new VNets for dev/test, PoC, or lab environments where VMs are deployed quickly without proper networking. If you have established patterns — hub-and-spoke, NAT Gateway, load balancers — you're already compliant.

> **Update (March 24, 2026):** This post was reviewed by members of the Microsoft networking product team. Key corrections: AKS has never used default outbound access and already defaults to private subnets, the new API version is expected to be `2025-07-01`, and there are two separate Azure Advisor recommendations (VMs and VMSS uniform). Thanks to the PM team for the feedback.
>
> **Update (March 25, 2026):** Clarified that SQL MI still does not support private subnets — the [networking constraints docs](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/connectivity-architecture-overview?view=azuresql#networking-constraints) confirm this. NAT Gateway is also not supported on SQL MI subnets. This remains the service to watch most closely.

## References

### Ref 1

[1] D. Firestone et al., "VFP: A Virtual Switch Platform for Host SDN in the Public Cloud," *NSDI '17*, USENIX, 2017. [USENIX paper](https://www.usenix.org/conference/nsdi17/technical-sessions/presentation/firestone) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 2

[2] Microsoft Research, "Azure Virtual Filtering Platform (VFP)." [Microsoft Research article](https://www.microsoft.com/en-us/research/project/azure-virtual-filtering-platform/) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 3

[3] Microsoft Learn, "Azure virtual network traffic routing." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 4

[4] Microsoft Learn, "Default outbound access in Azure." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 5

[5] Microsoft Learn, "Subnet delegation overview." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 6

[6] Microsoft Learn, "Service-aided subnet configuration — Azure SQL Managed Instance." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/subnet-service-aided-configuration-enable) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 7

[7] Microsoft Learn, "Networking with Private Access — Azure Database for PostgreSQL Flexible Server." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking-private) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 8

[8] Microsoft Learn, "Integrate your app with an Azure virtual network — Azure App Service." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 9

[9] Microsoft Learn, "Customize cluster egress with outbound types in AKS." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 10

[10] Microsoft Learn, "Create a managed or user-assigned NAT gateway for your AKS cluster." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/aks/nat-gateway) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 11

[11] Microsoft Learn, "Deployment options for Windows 365." [Microsoft Learn article](https://learn.microsoft.com/en-us/windows-365/enterprise/windows-365-network-deployment-options) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 12

[12] Microsoft Tech Community, "Azure Default Outbound Access Changes: Guidance for Windows 365 ANC Customers." [Tech Community post](https://techcommunity.microsoft.com/discussions/windows365discussions/azure-default-outbound-access-changes-guidance-for-windows-365-anc-customers/4494460) [Back to text](#azure-networking-fundamentals-its-all-software)

### Ref 13

[13] Microsoft Learn, "Virtual machine extensions and features for Windows." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/features-windows) [Back to text](#azure-update-manager--it-half-works-in-private-subnets)

### Ref 14

[14] Microsoft Learn, "What is IP address 168.63.129.16?" [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16) [Back to text](#azure-update-manager--it-half-works-in-private-subnets)

### Ref 15

[15] Microsoft Learn, "Azure Update Manager prerequisites." [Microsoft Learn article](https://learn.microsoft.com/en-us/azure/update-manager/prerequisites) [Back to text](#azure-update-manager--it-half-works-in-private-subnets)

[1]: #ref-1
[2]: #ref-2
[3]: #ref-3
[4]: #ref-4
[5]: #ref-5
[6]: #ref-6
[7]: #ref-7
[8]: #ref-8
[9]: #ref-9
[10]: #ref-10
[11]: #ref-11
[12]: #ref-12
[13]: #ref-13
[14]: #ref-14
[15]: #ref-15

---

*If you find errors or services that behave differently than described here, I'd love to hear about it. This is a living document and I'll update it as Microsoft updates their docs.*
