// targetScope = 'subscription'

targetScope = 'resourceGroup'

// Parameters
param deploymentParams object
param identityParams object
param appConfigParams object
param storageAccountParams object
param logAnalyticsWorkspaceParams object
param funcParams object
param serviceBusParams object

param brandTags object

param dateNow string = utcNow('yyyy-MM-dd-hh-mm')

param tags object = union(brandTags, {last_deployed:dateNow})


// Create Identity
module r_usr_mgd_identity 'modules/identity/create_usr_mgd_identity.bicep' = {
  name: '${deploymentParams.enterprise_name_suffix}_${deploymentParams.global_uniqueness}_usr_mgd_identity'
  params: {
    deploymentParams:deploymentParams
    identityParams:identityParams
    tags: tags
  }
}

//Create App Config
module r_app_config 'modules/app_config/create_app_config.bicep' = {
  name: '${appConfigParams.appConfigNamePrefix}_${deploymentParams.global_uniqueness}_Config'
  params: {
    deploymentParams:deploymentParams
    appConfigParams: appConfigParams
    tags: tags
  }
}

// Create the Log Analytics Workspace
module r_logAnalyticsWorkspace 'modules/monitor/log_analytics_workspace.bicep' = {
  name: '${logAnalyticsWorkspaceParams.workspaceName}_${deploymentParams.global_uniqueness}_La'
  params: {
    deploymentParams:deploymentParams
    logAnalyticsWorkspaceParams: logAnalyticsWorkspaceParams
    tags: tags
  }
}


// Create Storage Account
module r_sa 'modules/storage/create_storage_account.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Sa'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    funcParams: funcParams
    tags: tags
  }
}


// Create Storage Account - Blob container
module r_blob 'modules/storage/create_blob.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.global_uniqueness}_Blob'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    storageAccountName: r_sa.outputs.saName
    storageAccountName_1: r_sa.outputs.saName_1
    logAnalyticsWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
    enableDiagnostics: false
  }
  dependsOn: [
    r_sa
  ]
}

// Create the function app & Functions
module r_fn_app 'modules/functions/create_function.bicep' = {
  name: '${funcParams.funcNamePrefix}_${deploymentParams.global_uniqueness}_Fn_App'
  params: {
    deploymentParams:deploymentParams
    r_usr_mgd_identity_name: r_usr_mgd_identity.outputs.usr_mgd_identity_name
    funcParams: funcParams
    funcSaName: r_sa.outputs.saName_1
    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName

    // appConfigName: r_appConfig.outputs.appConfigName

    svc_bus_ns_name: r_svc_bus.outputs.svc_bus_ns_name
    svc_bus_q_name: r_svc_bus.outputs.svc_bus_q_name

    logAnalyticsWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
    enableDiagnostics: true
    tags: tags
  }
  dependsOn: [
    r_sa
  ]
}

// Create the Service Bus & Queue
module r_svc_bus 'modules/integration/create_svc_bus.bicep' = {
  // scope: resourceGroup(r_rg.name)
  name: '${serviceBusParams.serviceBusNamePrefix}_${deploymentParams.global_uniqueness}_Svc_Bus'
  params: {
    deploymentParams:deploymentParams
    serviceBusParams:serviceBusParams
    tags: tags
  }
}

// Create Service Bus Subscription Filter
module r_svc_bus_sub_filter 'modules/integration/create_queue_subscription.bicep' = {
  name: '${serviceBusParams.serviceBusNamePrefix}_${deploymentParams.global_uniqueness}_svc_bus_sub_filter'
  params: {
    deploymentParams:deploymentParams
    serviceBusParams:serviceBusParams
    tags: tags
  }
  dependsOn: [
    r_svc_bus
  ]
}
