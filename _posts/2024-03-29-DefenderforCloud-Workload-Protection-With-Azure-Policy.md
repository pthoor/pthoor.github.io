---
title: "Configure Defender for Cloud workload protections with Azure Policy"
date: '2024-03-29T09:00:00+02:00'
excerpt: 'This Azure Policy initiative enables and configures Defender for Cloud workload protections, including Defender for Storage Classic (per transaction) plan with a Managed Identity for remediation.'
tags: 
  - MDC
  - DefenderforCloud
  - CSPM
  - AzurePolicy
toc: true
header:
  og_image: /assets/MDC-Bicep-AzPolicy.png
---

![](/assets/MDC-Bicep-AzPolicy.png)

# Introduction
Azure Policy is a really powerful tool for cloud governance. It allows you to create, assign, and manage policies that enforce different rules and effects over your resources. In this post, we will create an Azure Policy initiative that enables and configures Defender for Cloud workload protections, including Defender for Storage Classic (per transaction) plan. But as per my blog post before this one, it is recommended and so important to understand the Defender for Cloud workload protection plans and their differences. Go in to Defender for Cloud and take a look at the default Workbooks so you get a grasp and better understanding how much you will pay per subscription and what you will get in return.

# Azure Policy Initiative - Cloud Workload Protection (CWP) plans
The following Azure Policy initiative enables and configures Defender for Cloud workload protections. The initiative includes the built-in policy definitions for each of the products. The initiative also includes parameters to enable or disable specific features of each product. The initiative is scoped to a management group. Just because I do belive you should have this type of governance for your entire Azure environment.

In the following bicep code, you can see the different policy definitions that are included in the initiative. The policy definitions are configured with parameters that enable or disable specific features of each product. The initiative is assigned to a management group. The initiative is also assigned to a managed identity that is used to apply the policies with Owner and Security Admin roles.

Do not forget to remediate the policies after you have assigned them. This is a really important step to make sure that the policies are applied to the resources in your environment.

## Bicep code

```bash
targetScope = 'managementGroup'

param managedidentityLocation string = 'swedencentral'

var securityadminId = 'fb1c8493-542b-48eb-b624-b4c8fea62acd'
var ownerId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

var arrayRolesId = [
  securityadminId
  ownerId
]

param definitionIdDefenderCSPMFullPlans string = '/providers/Microsoft.Authorization/policyDefinitions/72f8cee7-2937-403d-84a1-a4e3e57f3c21'
@allowed([
  'true'
  'false'])
param enableSensitiveDataDiscovery string = 'true'
@allowed([
  'true'
  'false'])
param enableContainerRegistriesVulnerabilityAssessments string = 'true'
@allowed([
  'true'
  'false'])
param enableAgentlessDiscoveryForKubernetes string = 'true'
@allowed([
  'true'
  'false'])
param enableAgentlessVmScanning string = 'true'
@allowed([
  'true'
  'false'])
param enableEntraPermissionsManagement string = 'true'

param definitionIdDefenderForContainers string = '/providers/Microsoft.Authorization/policyDefinitions/efd4031d-b232-4595-babf-ae817348e91b'
@allowed([
  'true'
  'false'])
param enableDefenderContainerRegistriesVulnerabilityAssessments string = 'true'

param definitionIdDefenderForStorageClassic string = '/providers/Microsoft.Authorization/policyDefinitions/74c30959-af11-47b3-9ed2-a26e03f427a3'

param definitionIdDefenderForServers string = '/providers/Microsoft.Authorization/policyDefinitions/5eb6d64a-4086-4d7a-92da-ec51aed0332d'
@allowed([
  'P1'
  'P2'])
param subplanDefenderForServers string = 'P1'
@allowed([
  'true'
  'false'])
param enableDefenderServersAgentlessVmScanning string = 'true'
@allowed([
  'true'
  'false'])
param enableMdeDesignatedSubscription string = 'false'

param definitionIdDefenderForSQLServers string = '/providers/Microsoft.Authorization/policyDefinitions/50ea7265-7d8c-429e-9a7d-ca1f410191c3'

param definitionIdDefenderForAzureSQLDB string = '/providers/Microsoft.Authorization/policyDefinitions/b99b73e7-074b-4089-9395-b7236f094491'

param definitionIdDefenderForOpenSourceDB string = '/providers/Microsoft.Authorization/policyDefinitions/44433aa3-7ec2-4002-93ea-65c65ff0310a'

param definitionIdDefenderForAzureCosmosDB string = '/providers/Microsoft.Authorization/policyDefinitions/82bf5b87-728b-4a74-ba4d-6123845cf542'

param definitionIdDefenderForAppService string = '/providers/Microsoft.Authorization/policyDefinitions/b40e7bcd-a1e5-47fe-b9cf-2f534d0bfb7d'

param definitionIdDefenderForKeyVault string = '/providers/Microsoft.Authorization/policyDefinitions/1f725891-01c0-420a-9059-4fa46cb770b7'

@allowed([
  'PerTransaction'
  'PerKeyVault'])
param subplanDefenderForKeyVault string = 'PerKeyVault'

param definitionIdDefenderArm string = '/providers/Microsoft.Authorization/policyDefinitions/b7021b2b-08fd-4dc0-9de7-3c6ece09faf9'

@allowed([
  'PerSubscription'
  'PerApiCall'])
param subplanDefenderArm string = 'PerApiCall'

param allpolicyIds array = [
  definitionIdDefenderCSPMFullPlans
  definitionIdDefenderForContainers
  definitionIdDefenderForStorageClassic
  definitionIdDefenderForServers
  definitionIdDefenderForSQLServers
  definitionIdDefenderForAzureSQLDB
  definitionIdDefenderForOpenSourceDB
  definitionIdDefenderForAzureCosmosDB
  definitionIdDefenderForAppService
  definitionIdDefenderForKeyVault
  definitionIdDefenderArm
]

resource policyInitiative 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: '[CUSTOM] Configure Defender for Cloud workload protections'
  properties: {
    displayName: '[CUSTOM] Configure Defender for Cloud workload protections'
    description: 'This initiative enables and configures Defender for Cloud workload protections.'
    metadata: {
      category: 'Security Center'
      version: '1.0.0'
    }
    policyDefinitions: [
      {
        policyDefinitionId: definitionIdDefenderCSPMFullPlans
        parameters: {
          isSensitiveDataDiscoveryEnabled: {
            value: enableSensitiveDataDiscovery
          }
          isContainerRegistriesVulnerabilityAssessmentsEnabled: {
            value: enableContainerRegistriesVulnerabilityAssessments
          }
          isAgentlessDiscoveryForKubernetesEnabled: {
            value: enableAgentlessDiscoveryForKubernetes
          }
          isAgentlessVmScanningEnabled: {
            value: enableAgentlessVmScanning
          }
          isEntraPermissionsManagementEnabled: {
            value: enableEntraPermissionsManagement
          }
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForContainers
        parameters: {
          isContainerRegistriesVulnerabilityAssessmentsEnabled: {
            value: enableDefenderContainerRegistriesVulnerabilityAssessments
          }
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForStorageClassic
        parameters: {
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForServers
        parameters: {
          subPlan: {
            value: subplanDefenderForServers 
          }
          isAgentlessVmScanningEnabled: {
            value: subplanDefenderForServers == 'P1' ? 'false' : enableDefenderServersAgentlessVmScanning
          }
          isMdeDesignatedSubscriptionEnabled:{
            value: subplanDefenderForServers == 'P1' ? 'false' : enableMdeDesignatedSubscription
          }
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForSQLServers
        parameters: {
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForAzureSQLDB
        parameters: {
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForOpenSourceDB
        parameters: {
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForAzureCosmosDB
        parameters: {
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForAppService
        parameters: {
        }
      }
      {
        policyDefinitionId: definitionIdDefenderForKeyVault
        parameters: {
          subPlan: {
            value: subplanDefenderForKeyVault
          }
        }
      }
      {
        policyDefinitionId: definitionIdDefenderArm
        parameters: {
          subPlan: {
            value: subplanDefenderArm
          }
        }
      }
    ]
  }
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2019-09-01' = {
  name: 'Configure MDC CWP'
  identity: {
    type: 'SystemAssigned'
  }
  location: managedidentityLocation
  properties: {
    enforcementMode: 'Default'
    policyDefinitionId: policyInitiative.id
    parameters: {
    }
  }
}

resource policyRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in arrayRolesId: {
  name: guid(role)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalType: 'ServicePrincipal'
    principalId: policyAssignment.identity.principalId
  }
}]
```

# Summary
Don't forget the remediation step.

Now you have a policy initiative to start with and you can start to configure the different Defender for Cloud workload protections. This is a really good start to get a better security posture in your Azure environment. But remember, this is just the beginning. You need to continue to monitor and improve your security posture. Defender for Cloud is a really good tool to help you with that.

It is very important to have a process of your Azure policies and to have a good governance process. So lets start with this policy initiative and continue to improve your security posture.