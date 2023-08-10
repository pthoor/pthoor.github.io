---
title: "Microsoft Sentinel and Azure OpenAI"
date: '2023-08-09T16:00:00+02:00'
excerpt: 'In this first of many posts we will activate the power of Azure OpenAI together with Microsoft Sentinel, this dynamic duo will for sure empower security teams.'
tags: 
  - Sentinel
  - OpenAI
  - AI
toc: true
header:
  og_image: /assets/SOC_AI_Dalle-generated.png
---
# Introduction
The leading cloud-native SIEM solution, Microsoft Sentinel, are absolutely getting more and more attention from the security community. The reason for this is that Microsoft are investing heavily in the solution and are releasing new features and connectors on a regular basis. In this blog post we will take a look at how we can use Azure OpenAI together with Microsoft Sentinel to empower security teams.

# AI overall use cases
Think about it, what can AI do now and in the future? Looking at the different services that for instance Microsoft are providing, we can see that AI are used in many different areas. And combining services and solutions, well, are making AI even more powerful - and it's just the beginning.

If we take a look at what Microsoft are offering today, we can for sure in the future see:
- No more classroom lectures, because why do we need that? We have AI that can teach us everything we need to know, and we can learn at our own pace, in our own time, and in our own way. And when we need to do an exam, well then we have for example the Form Recognizer service, OpenAI, Translater service, and the Speech service to help us out, one by one or combined. 
- Faster doctors appointments, because why do we need to go to the doctor? We can just use our phone and the Computer Vision service to take a picture of our body, and the service will tell us what's wrong and what we need to do. And if we need to talk to the doctor, well then we have the Speech service, and if we need to translate the conversation, well then we have the Translater service to help us out. Microsoft's project [Health Insight](https://azure.microsoft.com/en-us/blog/announcing-project-health-insights-preview-advancing-ai-for-health-data/) have an AI model that can rapidly identify key cancer attributes. Take a second to think about that, how many lives can we save with that?
- Looking at typical maintenance of IoT devices, we can use the Anomaly Detector service to detect anomalies in the data, and then use the Form Recognizer service to detect the type of device, and then use the Custom Vision service to detect the type of error, and then use the Speech service to tell us what to do, and then use the Translater service to translate the instructions to the language we understand.

I mean, this is so cool, and we are just scratching the surface here. I do belive that AI together with data will change the world. But I do also belive that we need to be careful, and that we need to think about the ethical aspects, and the security aspects of AI. In US they have the FDA, Food and Drug Administration, that are responsible for the safety of food, drugs, cosmetics, and much more. In the future we will need something similar for AI, to make sure that we are using AI in a responsible way. Because think about it, if we have advanced AI models that can do everything, and we are using them in a bad way, well then we are in trouble, big trouble.

# Microsoft Sentinel Automation
As of today, Microsoft Sentinel are supporting the following automation features:
- Logic Apps
- and other, that Logic Apps can talk to through built-in connectors or API, for instance Azure Functions

We will focus on Logic Apps in this post to call Azure OpenAI API, and more specific the Chat Completion API. The Chat Completion API are used to generate text based on a prompt, and this is exactly what we want to do in this blog post. We want to generate text based on our questions regarding specific alerts and incidents in Microsoft Sentinel.

# Azure OpenAI
Azure OpenAI are a service that are built on top of OpenAI, and are currently limited to use because of high demand and that Microsoft are working very hard for the [Responsible AI practices](https://learn.microsoft.com/legal/cognitive-services/openai/overview?context=%2Fazure%2Fai-services%2Fopenai%2Fcontext%2Fcontext&WT.mc_id=AZ-MVP-5004683). The service are built to make it easier to use the OpenAI API, and to make it easier to integrate with other Azure services. The service are currently supporting the following OpenAI [language models](https://learn.microsoft.com/azure/ai-services/openai/concepts/models?WT.mc_id=AZ-MVP-5004683):

- GPT-4 (required to request access - https://aka.ms/oai/get-gpt4)
- GPT-35-Turbo
- Embeddings model series

In our solution we will use the GPT-35-Turbo model, due to I have not until to date been able to get access to the GPT-4 model (still on the waitlist) 

## Azure AI services & Azure OpenAI Setup
Yes, Microsoft have been renaming stuff here. Cognitive Services and AppliedAI Services are now Azure AI services. 

The apps and services that are available in [Azure AI services](https://learn.microsoft.com/azure/ai-services/?WT.mc_id=AZ-MVP-5004683) are:
- Azure OpenAI
- Cognitive search
- Computer vision
- Face API
- Custom vision
- Speech service
- Form recognizer
- Video analyzer
- Translator
- Anomaly detector
and much more!

If you have access and permission to create OpenAI resources, you can create a new resource in the Azure portal. 

1. Search for OpenAI and select the OpenAI resource
2. Click Create
3. Select the subscription, resource group, region, name the resource, and choose [pricing tier](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/)
![](/assets/OAI_Create.png)
4. Click on Next and configure network security, here you can configure private endpoint connection
5. Click on Next and configure tags (so important for FinOps)
6. Click Review + create

When the resource are created, we will access OpenAI in the [Azure AI Studio](https://oai.azure.com/).

![](/assets/AI_Studio.png)

Now we need to do a deployment of a OpenAI base model, or your own fine-tuned model. In this blog post we will use the GPT-35-Turbo model.

1. In Azure AI Studio, click on Deployments
2. Click on Create new deployment
3. Select the model that you want to deploy, in this case we will use the GPT-35-Turbo model (gpt-35-turbo)
4. Type in the deployment name

> Give your deployment a memorable name to make it easier to find later. You’ll use this name to select the deployed model in Playground or to specify the deployment in your code. The name can only include alphanumeric characters, _ character and - character. Can't end with '_' or '-'

5. Click on Create

## Azure OpenAI Chat Completion API
> The GPT-35-Turbo and GPT-4 models are language models that are optimized for conversational interfaces. The models behave differently than the older GPT-3 models. Previous models were text-in and text-out, meaning they accepted a prompt string and returned a completion to append to the prompt. However, the GPT-35-Turbo and GPT-4 models are conversation-in and message-out. The models expect input formatted in a specific chat-like transcript format, and return a completion that represents a model-written message in the chat. While this format was designed specifically for multi-turn conversations, you'll find it can also work well for non-chat scenarios too.

Working with the [Chat Completion API](https://learn.microsoft.com/azure/ai-services/openai/how-to/chatgpt?pivots=programming-language-chat-completions&WT.mc_id=AZ-MVP-5004683#working-with-the-chat-completion-api) are very easy, and we will test the API in Postman before we use it in Logic Apps.

The Chat Completion API do have the format:

```json
{"role": "system", "content": "Provide some context and/or instructions to the model"},
{"role": "user", "content": "The users messages goes here"}
```

First we need to give the system role some context and/or instructions. This could be personality traits, instructions or data needed (for example an FAQ).

Example of system role message:

```json
{"role": "system", "content": "Assistant is a large language model trained by OpenAI."}
```

```json
{"role": "system", "content": "Assistant is an intelligent chatbot designed to help security team in questions about Microsoft Sentinel and Kusto Query Language."}
```

Here comes a new technique and skilling that we must learn if we want to optimize our prompting to AI, and that's [Prompt Engineering](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/prompt-engineering?WT.mc_id=AZ-MVP-5004683) and prompt construction.

> it's more of an art than a science, often requiring experience and intuition to craft a successful prompt...

Then we need to give the user role the message that we want to generate. And in Logic Apps we will build our variables first so we can call them during the flow.

In this test we will ask the AI to describe the tactics of Initial Access, and we will use the following message:

```json
{"role": "user", "content": "Describe the following MITRE ATT&CK tactic: Initial Access"}
```

![](/assets/AI_Describe_InitialAccess.png)

The hole message will look like this:

```json
{
  messages: [
    {
      "role": "system",
      "content": "Assistant is a large language model trained by OpenAI."
    },
    {
      "role": "user",
      "content": "Describe the following MITRE ATT&CK tactic: Initial Access"
    }
  ]
}
```

First, grab the API key from the Azure OpenAI resource in the Azure Portal. You will find it under Keys and Endpoint menu. You will have two different keys that you can use and also regenerate if needed. Recommended to have the keys in Azure Key Vault.

The API call will look like this:

**URL:**

https://"AzureOpenAIResourceName".openai.azure.com/openai/deployments/"OpenAIDeploymentName"/chat/completions?api-version=2023-03-15-preview

**Method:**

POST

**Params:**

* api-version=2023-03-15-preview or another version, [see docs](https://learn.microsoft.com/azure/ai-services/openai/reference?WT.mc_id=AZ-MVP-5004683#chat-completions).
* api-key="The Key You Copied Before"
* Content-Type=application/json

The API call works, now heading over to Logic Apps.

# Logic Apps
![](/assets/OAI_LogicApps.png)

This is the Logic Apps flow that we will build. Starting with the Sentinel connector and then build the variables of the URI to the Azure OpenAI Chat Completion API, and the API Key. Then we will build the prompt that we want to ask the AI model and then we will call the API via the HTTP connector. Important to parse the JSON response. Then we will add the comment or task to the incident in Sentinel.

**Tactics question:**

Describe the following MITRE ATT&CK tactic: @{triggerBody()?['object']?['properties']?['additionalData']?['tactics']}

**HTTP Body:**

```json
{
  "messages": [
    {
      "content": "Assistant is a large language model trained by OpenAI.",
      "role": "system"
    },
    {
      "content": "@{variables('Tactics_question')}",
      "role": "user"
    }
  ]
}
```

**Parse JSON will look like this:**

```json
{
    "properties": {
        "choices": {
            "items": {
                "properties": {
                    "finish_reason": {
                        "type": "string"
                    },
                    "index": {
                        "type": "integer"
                    },
                    "message": {
                        "properties": {
                            "content": {
                                "type": "string"
                            },
                            "role": {
                                "type": "string"
                            }
                        },
                        "type": "object"
                    }
                },
                "required": [
                    "index",
                    "finish_reason",
                    "message"
                ],
                "type": "object"
            },
            "type": "array"
        },
        "created": {
            "type": "integer"
        },
        "id": {
            "type": "string"
        },
        "model": {
            "type": "string"
        },
        "object": {
            "type": "string"
        },
        "usage": {
            "properties": {
                "completion_tokens": {
                    "type": "integer"
                },
                "prompt_tokens": {
                    "type": "integer"
                },
                "total_tokens": {
                    "type": "integer"
                }
            },
            "type": "object"
        }
    },
    "type": "object"
}
```

**Task question:**

In less than total of 2,000 characters, what types of tasks would need to be done to investigate a security incident titled @{triggerBody()?['object']?['properties']?['title']} together with Microsoft Sentinel?

**HTTP Body for Sentinel Task:**

```json
{
  "messages": [
    {
      "content": "Assistant is a large language model trained by OpenAI.",
      "role": "system"
    },
    {
      "content": "@{variables('sentinel-task')}",
      "role": "user"
    }
  ]
}
```

We can even ask the AI to build a KQL for us to further investigate the incident. We will grab the content of the first answer so the AI understand what type of incident we want to create a KQL for. The question will look like this:

(Be aware that we must train the AI to use tables that we have and what columns we have in the tables, and also what data we have in the tables. This is a very important step to get the best result from the AI. Very often we do get KQL that have the right syntax, but the KQL are not working because the AI do not understand the data that we have in the tables.)

```json
{
  "messages": [
    {
      "content": "Assistant is a large language model trained by OpenAI.",
      "role": "system"
    },
    {
      "content": "Generate Microsoft Sentinel KQL query to implement your suggestion: @{items('KQL')?['message']?['content']}",
      "role": "user"
    }
  ]
}
```

Try it for yourself, and see what you get. I have been testing this for a while now, and I'm very impressed by the results. And I'm sure that the results will be even better when we get access to the GPT-4 model and are activly training the AI to understand our data and our questions.

The entire Logic App in code:

```json
{
    "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "actions": {
            "API_Key_OpenAI": {
                "inputs": {
                    "variables": [
                        {
                            "name": "apikey_OpenAI",
                            "type": "string",
                            "value": "AddYourKey"
                        }
                    ]
                },
                "runAfter": {
                    "URI_OpenAI": [
                        "Succeeded"
                    ]
                },
                "type": "InitializeVariable"
            },
            "Ask_OpenAI_for_Tasks": {
                "inputs": {
                    "body": {
                        "messages": [
                            {
                                "content": "Assistant is a large language model trained by OpenAI.",
                                "role": "system"
                            },
                            {
                                "content": "@{variables('sentinel-task')}",
                                "role": "user"
                            }
                        ]
                    },
                    "headers": {
                        "Content-Type": "application/json",
                        "api-key": "@variables('apikey_OpenAI')"
                    },
                    "method": "POST",
                    "uri": "@variables('URI_OpenAI')"
                },
                "runAfter": {
                    "Sentinel_Task": [
                        "Succeeded"
                    ]
                },
                "type": "Http"
            },
            "For_each": {
                "actions": {
                    "For_each_2": {
                        "actions": {
                            "Add_comment_to_incident_(V3)": {
                                "inputs": {
                                    "body": {
                                        "incidentArmId": "@triggerBody()?['object']?['id']",
                                        "message": "<p>The tactics and techniques related to this incident:<br>\n<br>\n@{items('For_each_2')?['message']?['content']}</p>"
                                    },
                                    "host": {
                                        "connection": {
                                            "name": "@parameters('$connections')['azuresentinel_1']['connectionId']"
                                        }
                                    },
                                    "method": "post",
                                    "path": "/Incidents/Comment"
                                },
                                "runAfter": {},
                                "type": "ApiConnection"
                            }
                        },
                        "foreach": "@body('Parse_JSON')?['choices']",
                        "runAfter": {
                            "Parse_JSON": [
                                "Succeeded"
                            ]
                        },
                        "type": "Foreach"
                    },
                    "HTTP": {
                        "inputs": {
                            "body": {
                                "messages": [
                                    {
                                        "content": "Assistant is a large language model trained by OpenAI.",
                                        "role": "system"
                                    },
                                    {
                                        "content": "@{variables('Tactics_question')}",
                                        "role": "user"
                                    }
                                ]
                            },
                            "headers": {
                                "Content-Type": "application/json",
                                "api-key": "@variables('apikey_OpenAI')"
                            },
                            "method": "POST",
                            "uri": "@variables('URI_OpenAI')"
                        },
                        "runAfter": {},
                        "type": "Http"
                    },
                    "Parse_JSON": {
                        "inputs": {
                            "content": "@body('HTTP')",
                            "schema": {
                                "properties": {
                                    "choices": {
                                        "items": {
                                            "properties": {
                                                "finish_reason": {
                                                    "type": "string"
                                                },
                                                "index": {
                                                    "type": "integer"
                                                },
                                                "message": {
                                                    "properties": {
                                                        "content": {
                                                            "type": "string"
                                                        },
                                                        "role": {
                                                            "type": "string"
                                                        }
                                                    },
                                                    "type": "object"
                                                }
                                            },
                                            "required": [
                                                "index",
                                                "finish_reason",
                                                "message"
                                            ],
                                            "type": "object"
                                        },
                                        "type": "array"
                                    },
                                    "created": {
                                        "type": "integer"
                                    },
                                    "id": {
                                        "type": "string"
                                    },
                                    "model": {
                                        "type": "string"
                                    },
                                    "object": {
                                        "type": "string"
                                    },
                                    "usage": {
                                        "properties": {
                                            "completion_tokens": {
                                                "type": "integer"
                                            },
                                            "prompt_tokens": {
                                                "type": "integer"
                                            },
                                            "total_tokens": {
                                                "type": "integer"
                                            }
                                        },
                                        "type": "object"
                                    }
                                },
                                "type": "object"
                            }
                        },
                        "runAfter": {
                            "HTTP": [
                                "Succeeded"
                            ]
                        },
                        "type": "ParseJson"
                    }
                },
                "foreach": "@triggerBody()?['object']?['properties']?['additionalData']?['tactics']",
                "runAfter": {
                    "Prompt_Tactics_question": [
                        "Succeeded"
                    ]
                },
                "type": "Foreach"
            },
            "KQL": {
                "actions": {
                    "Ask_for_KQL_examples": {
                        "inputs": {
                            "body": {
                                "messages": [
                                    {
                                        "content": "Assistant is a large language model trained by OpenAI.",
                                        "role": "system"
                                    },
                                    {
                                        "content": "Generate Microsoft Sentinel KQL query to implement your suggestion: @{items('KQL')?['message']?['content']}",
                                        "role": "user"
                                    }
                                ]
                            },
                            "headers": {
                                "api-key": "@variables('apikey_OpenAI')",
                                "content-type": "application/json"
                            },
                            "method": "POST",
                            "uri": "@variables('URI_OpenAI')"
                        },
                        "runAfter": {},
                        "type": "Http"
                    },
                    "For_each_query": {
                        "actions": {
                            "Add_task_to_incident_2": {
                                "inputs": {
                                    "body": {
                                        "incidentArmId": "@triggerBody()?['object']?['id']",
                                        "taskDescription": "<p>(Change according!)<br>\n<br>\nKQL:<br>\n@{items('For_each_query')?['message']?['content']}</p>",
                                        "taskTitle": "KQL to run"
                                    },
                                    "host": {
                                        "connection": {
                                            "name": "@parameters('$connections')['azuresentinel_1']['connectionId']"
                                        }
                                    },
                                    "method": "post",
                                    "path": "/Incidents/CreateTask"
                                },
                                "runAfter": {},
                                "type": "ApiConnection"
                            }
                        },
                        "foreach": "@body('Parse_JSON_-_KQL')?['choices']",
                        "runAfter": {
                            "Parse_JSON_-_KQL": [
                                "Succeeded"
                            ]
                        },
                        "type": "Foreach"
                    },
                    "Parse_JSON_-_KQL": {
                        "inputs": {
                            "content": "@body('Ask_for_KQL_examples')",
                            "schema": {
                                "properties": {
                                    "choices": {
                                        "items": {
                                            "properties": {
                                                "finish_reason": {
                                                    "type": "string"
                                                },
                                                "index": {
                                                    "type": "integer"
                                                },
                                                "message": {
                                                    "properties": {
                                                        "content": {
                                                            "type": "string"
                                                        },
                                                        "role": {
                                                            "type": "string"
                                                        }
                                                    },
                                                    "type": "object"
                                                }
                                            },
                                            "required": [
                                                "index",
                                                "finish_reason",
                                                "message"
                                            ],
                                            "type": "object"
                                        },
                                        "type": "array"
                                    },
                                    "created": {
                                        "type": "integer"
                                    },
                                    "id": {
                                        "type": "string"
                                    },
                                    "model": {
                                        "type": "string"
                                    },
                                    "object": {
                                        "type": "string"
                                    },
                                    "usage": {
                                        "properties": {
                                            "completion_tokens": {
                                                "type": "integer"
                                            },
                                            "prompt_tokens": {
                                                "type": "integer"
                                            },
                                            "total_tokens": {
                                                "type": "integer"
                                            }
                                        },
                                        "type": "object"
                                    }
                                },
                                "type": "object"
                            }
                        },
                        "runAfter": {
                            "Ask_for_KQL_examples": [
                                "Succeeded"
                            ]
                        },
                        "type": "ParseJson"
                    }
                },
                "foreach": "@body('Parse_JSON_-_Tasks')?['choices']",
                "runAfter": {
                    "Parse_JSON_-_Tasks": [
                        "Succeeded"
                    ]
                },
                "type": "Foreach"
            },
            "Parse_JSON_-_Tasks": {
                "inputs": {
                    "content": "@body('Ask_OpenAI_for_Tasks')",
                    "schema": {
                        "properties": {
                            "choices": {
                                "items": {
                                    "properties": {
                                        "finish_reason": {
                                            "type": "string"
                                        },
                                        "index": {
                                            "type": "integer"
                                        },
                                        "message": {
                                            "properties": {
                                                "content": {
                                                    "type": "string"
                                                },
                                                "role": {
                                                    "type": "string"
                                                }
                                            },
                                            "type": "object"
                                        }
                                    },
                                    "required": [
                                        "index",
                                        "finish_reason",
                                        "message"
                                    ],
                                    "type": "object"
                                },
                                "type": "array"
                            },
                            "created": {
                                "type": "integer"
                            },
                            "id": {
                                "type": "string"
                            },
                            "model": {
                                "type": "string"
                            },
                            "object": {
                                "type": "string"
                            },
                            "usage": {
                                "properties": {
                                    "completion_tokens": {
                                        "type": "integer"
                                    },
                                    "prompt_tokens": {
                                        "type": "integer"
                                    },
                                    "total_tokens": {
                                        "type": "integer"
                                    }
                                },
                                "type": "object"
                            }
                        },
                        "type": "object"
                    }
                },
                "runAfter": {
                    "Ask_OpenAI_for_Tasks": [
                        "Succeeded"
                    ]
                },
                "type": "ParseJson"
            },
            "Prompt_Tactics_question": {
                "inputs": {
                    "variables": [
                        {
                            "name": "Tactics_question",
                            "type": "string",
                            "value": "Describe the following MITRE ATT&CK tactic: @{triggerBody()?['object']?['properties']?['additionalData']?['tactics']}"
                        }
                    ]
                },
                "runAfter": {
                    "API_Key_OpenAI": [
                        "Succeeded"
                    ]
                },
                "type": "InitializeVariable"
            },
            "Sentinel_Task": {
                "inputs": {
                    "variables": [
                        {
                            "name": "sentinel-task",
                            "type": "string",
                            "value": "In less than total of 2,000 characters, what types of tasks would need to be done to investigate a security incident titled @{triggerBody()?['object']?['properties']?['title']} together with Microsoft Sentinel?"
                        }
                    ]
                },
                "runAfter": {
                    "API_Key_OpenAI": [
                        "Succeeded"
                    ]
                },
                "type": "InitializeVariable"
            },
            "Tasks": {
                "actions": {
                    "Add_task_to_incident": {
                        "inputs": {
                            "body": {
                                "incidentArmId": "@triggerBody()?['object']?['id']",
                                "taskDescription": "<p>Azure OpenAI example of Sentinel tasks to do:<br>\n<br>\n@{items('Tasks')?['message']?['content']}</p>",
                                "taskTitle": "Task from AI"
                            },
                            "host": {
                                "connection": {
                                    "name": "@parameters('$connections')['azuresentinel_1']['connectionId']"
                                }
                            },
                            "method": "post",
                            "path": "/Incidents/CreateTask"
                        },
                        "runAfter": {},
                        "type": "ApiConnection"
                    }
                },
                "foreach": "@body('Parse_JSON_-_Tasks')?['choices']",
                "runAfter": {
                    "Parse_JSON_-_Tasks": [
                        "Succeeded"
                    ]
                },
                "type": "Foreach"
            },
            "URI_OpenAI": {
                "inputs": {
                    "variables": [
                        {
                            "name": "URI_OpenAI",
                            "type": "string",
                            "value": "https://<AzureResourceName>.openai.azure.com/openai/deployments/<DeploymentName>/chat/completions?api-version=2023-03-15-preview"
                        }
                    ]
                },
                "runAfter": {},
                "type": "InitializeVariable"
            }
        },
        "contentVersion": "1.0.0.0",
        "outputs": {},
        "parameters": {
            "$connections": {
                "defaultValue": {},
                "type": "Object"
            }
        },
        "triggers": {
            "Microsoft_Sentinel_incident": {
                "inputs": {
                    "body": {
                        "callback_url": "@{listCallbackUrl()}"
                    },
                    "host": {
                        "connection": {
                            "name": "@parameters('$connections')['azuresentinel']['connectionId']"
                        }
                    },
                    "path": "/incident-creation"
                },
                "type": "ApiConnectionWebhook"
            }
        }
    },
    "parameters": {
        "$connections": {
            "value": {
                "azuresentinel": {
                    "connectionId": "",
                    "connectionName": "",
                    "id": ""
                },
                "azuresentinel_1": {
                    "connectionId": "",
                    "connectionName": ""
                }
            }
        }
    }
}
```