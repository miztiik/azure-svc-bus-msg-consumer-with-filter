// SET MODULE DATE
param module_metadata object = {
  module_last_updated : '2023-05-19'
  owner: 'miztiik@github'
}

param deploymentParams object
param serviceBusParams object
param tags object

param svc_bus_ns_name string
param svc_bus_q_name string
param r_usr_mgd_identity_name string


// Get Service Bus Namespace Reference
resource r_svc_bus_ns_ref 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: svc_bus_ns_name
}

resource r_svc_bus_q_ref 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' existing = {
  parent: r_svc_bus_ns_ref
  name: svc_bus_q_name
}


resource r_add_subscription_with_filter_to_q 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  parent: r_svc_bus_ns_ref
  name: svc_bus_q_name
  properties: {
    ...existingServiceBusQueue.properties
    messageFilters: [
      ...existingServiceBusQueue.properties.messageFilters
      {
        name: 'CustomPropertyFilter'
        type: 'SqlFilter'
        properties: {
          sqlExpression: "MyCustomProperty = 'FilterValue'"
        }
      }
    ]
  }
}

resource serviceBusSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-06-01-preview' = {
  parent: serviceBusTopic
  name: serviceBusSubscriptionName
  properties: {
    lockDuration: 'PT30S'
    defaultMessageTimeToLive: 'P7D'
    deadLetteringOnFilterEvaluationExceptions: true
    forwardDeadLetteredMessagesTo: null
    forwardTo: null
    enableBatchedOperations: true
    maxDeliveryCount: 10
    requiresSession: false
    userMetadata: ''
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    forwardTo: null
    forwardDeadLetteredMessagesTo: null
    enableDeadLetteringOnMessageExpiration: true
    enableSessionOrdering: false
    messageFilters: [
      {
        name: 'CustomPropertyFilter'
        type: 'SqlFilter'
        properties: {
          sqlExpression: "MyCustomProperty = 'FilterValue'"
        }
      }
    ]
  }
}


/*
resource emitEventGridNotificationTopicSubscriptionFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2021-06-01-preview' = {
  parent: emitEventGridNotificationTopicSubscription
  name: 'unfiltered'
  properties: {
    action: {
    }
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: '1=1'
      compatibilityLevel: 20
    }
  }
}

*/
// OUTPUTS
output module_metadata object = module_metadata
