---
title: Manual Microsoft Sentinel incident from an Azure Workbook
date: '2023-03-14T09:00:00+02:00'
excerpt: "Perhaps not an ordinary use case but the ability to create a manual Microsoft Sentinel incident from an Azure Workbook, it's that even possible?"
tags: 
  - Sentinel
toc: true
---
# Introduction
This idea did come from an internal talk where some logs flooding in to Microsoft Sentinel will be just sitting there with no Analytic Rule created (or other security use case attached) but we want to visualize the data and take action on that if we want to. Just recently Microsoft did add the ability to manually create incidents and there's an API for that as well.

# REST API - Create or Update Incident
[Incidents - Create Or Update - REST API | Microsoft Learn](https://learn.microsoft.com/rest/api/securityinsights/preview/incidents/create-or-update?tabs=HTTP&WT.mc_id=AZ-MVP-5004683)

``` http
PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/providers/Microsoft.SecurityInsights/incidents/{incidentId}?api-version=2022-12-01-preview
```

## Sample request
``` json
{
  "properties": {
    "title": "My incident",
    "description": "This is a demo incident",
    "severity": "High",
    "status": "New",
    "owner": {
      "objectId": null,
      "email": null,
      "assignedTo": null,
      "userPrincipalName": "email@domain.com",
      "ownerType": null
    }
  }
}
```

There are other properties as well that you can add to your request. But for example "classification" needs the "status" to be "closed" and the other values "new", or "active" are allowed if you want to have the "classification" property. 
The "owner" property have I only a value in the "userPrincipalName" because that's easier to remember than the "objectId"... You can absolutly add the capability to browse the Azure AD to the workbook if you want to (via Graph API, but need to register some apps etc.).

# Getting started


## Create the Azure Workbook
[](/assets/Az_Workbook_Incident.png)

To create the workbook, simply copy the code below or click the "Deploy to Azure" button.

### Deploy to Azure
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpthoor%2FMS_Sentinel%2Fmain%2FWorkbooks%2FManualSentinelIncident_ARM.json)

If you deployed the workbook via the button, after successful deployment you will find the workbook within Azure Monitor -> Workbooks -> My templates.

[](/assets/DeployedTemplates.png)

### Code (manual deployment)
Copy the code and paste it to your workbook via "Advanced Editor" and choose "Gallery Template" as "Template Type".

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "# How this workbook works\r\nMicrosoft Sentinel Incident creation. Manual incident created with ARM Action.\r\n\r\n- Choose correct Azure Subscription and Log Analytics workspace\r\n- Insert incident title\r\n- Insert incident description\r\n- Choose incident severity\r\n\t- High, Medium, Low, or Informational\r\n- Choose incident status\r\n\t- New, Active, or Closed\r\n- Insert owner for the incident in UPN format\r\n- Incident GUID will be created automatically\r\n\r\n",
        "style": "upsell"
      },
      "name": "text - 3"
    },
    {
      "type": 9,
      "content": {
        "version": "KqlParameterItem/1.0",
        "crossComponentResources": [
          "{Subscription}"
        ],
        "parameters": [
          {
            "id": "1ca69445-60fc-4806-b43d-ac7e6aad630a",
            "version": "KqlParameterItem/1.0",
            "name": "Subscription",
            "type": 6,
            "isRequired": true,
            "query": "summarize by subscriptionId\r\n| project value = strcat(\"/subscriptions/\", subscriptionId), label = subscriptionId\r\n",
            "crossComponentResources": [
              "value::selected"
            ],
            "typeSettings": {
              "additionalResourceOptions": [],
              "showDefault": false
            },
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources",
            "value": "/subscriptions/c2e2775e-c57d-44ce-a020-22ac16dd5705"
          },
          {
            "id": "ccd5adcd-8d59-4cfe-99ec-98075de2e253",
            "version": "KqlParameterItem/1.0",
            "name": "DefaultSubscription_Internal",
            "type": 1,
            "query": "resources\r\n| limit 1\r\n| project subscriptionId",
            "crossComponentResources": [
              "{Subscription}"
            ],
            "isHiddenWhenLocked": true,
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
          },
          {
            "id": "e94aafa3-c5d9-4523-89f0-4e87aa754511",
            "version": "KqlParameterItem/1.0",
            "name": "Workspace",
            "type": 5,
            "query": "where type =~ 'microsoft.operationalinsights/workspaces'\n| project id",
            "crossComponentResources": [
              "{Subscription}"
            ],
            "value": null,
            "typeSettings": {
              "resourceTypeFilter": {
                "microsoft.operationalinsights/workspaces": true
              },
              "additionalResourceOptions": []
            },
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
          },
          {
            "id": "eafaa0ec-7c3a-4ee5-babe-9850080c909d",
            "version": "KqlParameterItem/1.0",
            "name": "resourceGroup",
            "type": 1,
            "query": "resources\r\n| where type =~ 'microsoft.operationalinsights/workspaces'\r\n| where id == \"{Workspace}\"\r\n| project resourceGroup",
            "crossComponentResources": [
              "value::selected"
            ],
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
          },
          {
            "id": "ba423df4-f83c-495f-8d57-b3b828f8f11c",
            "version": "KqlParameterItem/1.0",
            "name": "WorkspaceName",
            "type": 1,
            "query": "resources\r\n| where type =~ 'microsoft.operationalinsights/workspaces'\r\n| where id == \"{Workspace}\"\r\n| project name",
            "crossComponentResources": [
              "{Subscription}"
            ],
            "isHiddenWhenLocked": true,
            "queryType": 1,
            "resourceType": "microsoft.resourcegraph/resources"
          }
        ],
        "style": "above",
        "queryType": 1,
        "resourceType": "microsoft.resourcegraph/resources"
      },
      "name": "parameters - 1"
    },
    {
      "type": 12,
      "content": {
        "version": "NotebookGroup/1.0",
        "groupType": "editable",
        "items": [
          {
            "type": 9,
            "content": {
              "version": "KqlParameterItem/1.0",
              "crossComponentResources": [
                "{Workspace}"
              ],
              "parameters": [
                {
                  "id": "dbf0e49f-26e6-476c-8677-a22fdbc4b527",
                  "version": "KqlParameterItem/1.0",
                  "name": "incidentTitle",
                  "label": "Incident title",
                  "type": 1,
                  "isRequired": true,
                  "timeContext": {
                    "durationMs": 86400000
                  },
                  "value": ""
                },
                {
                  "id": "ba44db8f-cbf0-475b-ace4-fb514612df8a",
                  "version": "KqlParameterItem/1.0",
                  "name": "description",
                  "label": "Description",
                  "type": 1,
                  "isRequired": true,
                  "value": ""
                },
                {
                  "id": "a5ccb2a6-3330-444f-86d0-d771fe234340",
                  "version": "KqlParameterItem/1.0",
                  "name": "severity",
                  "label": "Severity",
                  "type": 2,
                  "isRequired": true,
                  "query": "{\"version\":\"1.0.0\",\"content\":\"[\\\"High\\\", \\\"Medium\\\", \\\"Low\\\", \\\"Informational\\\"]\",\"transformers\":null}",
                  "typeSettings": {
                    "additionalResourceOptions": []
                  },
                  "queryType": 8,
                  "value": "High"
                },
                {
                  "id": "607f84eb-4528-4763-8ca9-d4900c669b02",
                  "version": "KqlParameterItem/1.0",
                  "name": "status",
                  "label": "Status",
                  "type": 2,
                  "isRequired": true,
                  "query": "{\"version\":\"1.0.0\",\"content\":\"[\\\"New\\\", \\\"Active\\\", \\\"Closed\\\"]\",\"transformers\":null}",
                  "typeSettings": {
                    "additionalResourceOptions": []
                  },
                  "queryType": 8,
                  "value": "New"
                },
                {
                  "id": "0163c733-ee70-4061-92ce-6ed1761a038d",
                  "version": "KqlParameterItem/1.0",
                  "name": "UserUPN",
                  "label": "UserPrincipalName",
                  "type": 1,
                  "description": "Fill in your UPN",
                  "isRequired": true,
                  "value": ""
                },
                {
                  "id": "580ed3d7-6a63-4a53-95c2-2e127e0b51d4",
                  "version": "KqlParameterItem/1.0",
                  "name": "GUID",
                  "label": "ID for Sentinel Incident",
                  "type": 1,
                  "isRequired": true,
                  "query": "print guid=new_guid()",
                  "crossComponentResources": [
                    "{Workspace}"
                  ],
                  "typeSettings": {
                    "paramValidationRules": [
                      {
                        "regExp": "^{?([0-9a-fA-F]){8}(-([0-9a-fA-F]){4}){3}-([0-9a-fA-F]){12}}?$",
                        "match": true,
                        "message": ""
                      }
                    ]
                  },
                  "timeContext": {
                    "durationMs": 86400000
                  },
                  "queryType": 0,
                  "resourceType": "microsoft.operationalinsights/workspaces"
                }
              ],
              "style": "formVertical",
              "queryType": 0,
              "resourceType": "microsoft.operationalinsights/workspaces"
            },
            "name": "parameters - 4"
          },
          {
            "type": 11,
            "content": {
              "version": "LinkItem/1.0",
              "style": "list",
              "links": [
                {
                  "id": "0ce7d423-77f7-4221-b79b-787164bb4935",
                  "linkTarget": "ArmAction",
                  "linkLabel": "Create Incident",
                  "preText": "❗",
                  "postText": "at {WorkspaceName}",
                  "style": "primary",
                  "icon": "Alert",
                  "linkIsContextBlade": true,
                  "templateRunContext": {
                    "componentIdSource": "parameter",
                    "templateUriSource": "static",
                    "templateUri": "https://management.azure.com/subscriptions/d0cfe6b2-9ac0-4464-9919-dccaee2e48c0/resourceGroups/myRg/providers/Microsoft.OperationalInsights/workspaces/myWorkspace/providers/Microsoft.SecurityInsights/incidents/73e01a99-5cd7-4139-a149-9f2736ff2ab5?api-version=2022-12-01-preview",
                    "templateParameters": [
                      {
                        "name": "subscriptionid",
                        "source": "parameter",
                        "value": "Subscription",
                        "kind": "stringValue"
                      },
                      {
                        "name": "workspaces",
                        "source": "parameter",
                        "value": "Sentinel",
                        "kind": "stringValue"
                      },
                      {
                        "name": "resourcegroup",
                        "source": "parameter",
                        "value": "Sentinel",
                        "kind": "stringValue"
                      }
                    ],
                    "titleSource": "static",
                    "descriptionSource": "static",
                    "runLabelSource": "static"
                  },
                  "armActionContext": {
                    "path": "/subscriptions/{DefaultSubscription_Internal}/resourceGroups/{resourceGroup}/providers/Microsoft.OperationalInsights/workspaces/{WorkspaceName}/providers/Microsoft.SecurityInsights/incidents/{GUID}",
                    "headers": [],
                    "params": [
                      {
                        "key": "api-version",
                        "value": "2022-07-01-preview"
                      }
                    ],
                    "body": "{\r\n  \"properties\": {\r\n    \"title\": \"{incidentTitle}\",\r\n    \"description\": \"{description}\",\r\n    \"severity\": \"{severity}\",\r\n    \"status\": \"{status}\",\r\n    \"owner\": {\r\n      \"objectId\": null,\r\n      \"email\": null,\r\n      \"assignedTo\": null,\r\n      \"userPrincipalName\": \"{UserUPN}\",\r\n      \"ownerType\": null\r\n    }\r\n  }\r\n}",
                    "httpMethod": "PUT",
                    "title": "Create new Microsoft Sentinel incident",
                    "description": "# Actions can potentially modify resources.\n## Please use caution and include a confirmation message in this description when authoring this command.\n\n<span style= \"font-size:15px;\"> You are creating a new Microsoft Sentinel incident in **{WorkspaceName}** Log Analytics workspace!</span>\n\nThe current information that will be created with the incident:\n\n- Incident Title: {incidentTitle}\n- Incident ID: {GUID}\n- Incident description: {description}\n- Incident severity: {severity}\n- Assigned to: {UserUPN}\n- Incident status: {status}",
                    "actionName": "CreateIncident-{GUID}",
                    "runLabel": "Create Incident"
                  }
                },
                {
                  "id": "78dba565-43a6-449e-892c-b8e9d1e9a5c9",
                  "cellValue": "https://portal.azure.com/#view/Microsoft_Azure_Security_Insights/MainMenuBlade/~/6/id/%2Fsubscriptions%2F{DefaultSubscription_Internal}%2Fresourcegroups%2F{resourceGroup}%2Fproviders%2Fmicrosoft.securityinsightsarg%2Fsentinel%2F{WorkspaceName}",
                  "linkTarget": "Url",
                  "linkLabel": "Go to Sentinel Incident pane",
                  "subTarget": "Incidents",
                  "preText": "👆",
                  "postText": "at {WorkspaceName}",
                  "style": "link"
                },
                {
                  "id": "eaa6eea1-bfa8-479b-bb79-53e91341756d",
                  "cellValue": "https://portal.azure.com/#asset/Microsoft_Azure_Security_Insights/Incident/subscriptions/{DefaultSubscription_Internal}/resourceGroups/{resourceGroup}/providers/Microsoft.OperationalInsights/workspaces/{WorkspaceName}/providers/Microsoft.SecurityInsights/Incidents/{GUID}",
                  "linkTarget": "Url",
                  "linkLabel": "Go to newly created incident",
                  "preText": "⚠️",
                  "postText": "at {WorkspaceName} (only works if the incident is created)",
                  "style": "link"
                }
              ]
            },
            "name": "links - 4"
          }
        ]
      },
      "name": "group - 4"
    }
  ],
  "fallbackResourceIds": [
    "azure monitor"
  ],
  "fromTemplateId": "community-Workbooks/Azure Resources/Alerts",
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
```

# Summary
This workbook can be added to existing workbook or added as an tab as well within existing workbook. I hope some of you can find this useful.

I see you at the next post!

**Happy hunting!**

![Ninja Cat](/assets/ninja-cat.png)