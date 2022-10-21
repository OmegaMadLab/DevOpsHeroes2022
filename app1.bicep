@description('The prefix used to compose the name of the resources')
param namePrefix string

@allowed([
  'PROD'
  'TEST'
])
@description('The target environment for the deployment')
param environment string

var environmentRegion = {
  TEST: [
    'westeurope'
  ]
  PROD: [
    'westeurope'
    'northeurope'
  ]
}

module webApp 'br:acr43208.azurecr.io/modules/webapp-module:v0.3.0' = [for region in environmentRegion[environment]: {
  name: '${namePrefix}-webApp-${environment}-${region}'
  params: {
    webAppNamePrefix: namePrefix
    environment: environment
    location: region
  }
}]

resource trafficManager 'Microsoft.Network/trafficmanagerprofiles@2018-08-01' = if (environment == 'PROD' ? bool('true') : bool('false')) {
  name: '${namePrefix}-trafficManager-${environment}'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Weighted'
    dnsConfig: {
      relativeName: 'TrafficManager${uniqueString(resourceGroup().id)}'
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
      intervalInSeconds: 30
      toleratedNumberOfFailures: 3
      timeoutInSeconds: 10
    }
    endpoints: [for (region, i) in environmentRegion[environment]: {
      name: '${region}-Endpoint'
      type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
      properties: {
        endpointStatus: 'Enabled'
        endpointMonitorStatus: 'Stopped'
        targetResourceId: webApp[i].outputs.webAppId
        weight: 1
        priority: (i + 1)
        endpointLocation: region
      }
    }]
  }
}

output tfUri string = trafficManager.properties.dnsConfig.fqdn

