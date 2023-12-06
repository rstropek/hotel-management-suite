param location string = resourceGroup().location

@allowed([
  'dev'
  'test'
  'prod'
])
param env string = 'dev'

param sqlAdminLogin string = 'AzureAdmins'
param sqlAdminSid string = 'd768187a-e61f-4848-807a-8b6055ce4162'

var tags = {
  Project: 'HMS'
  Environment: env
}
var telemetryTags = { 'Data Category': 'Telemetry' }
var dbName = 'sqldb-hms-${env}-${location}-001'

resource dbServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'sql-hms-${env}-${location}-001'
  location: location
  tags: tags

  properties: {
    administrators: {
      azureADOnlyAuthentication: true
      login: sqlAdminLogin
      sid: sqlAdminSid
      principalType: 'Group'
      tenantId: subscription().tenantId
    }
  }

  resource elasticsDbPool 'elasticPools@2022-05-01-preview' = {
    name: 'sqlep-hms-${env}-${location}-001'
    location: location
    tags: tags
    
    sku: {
      name: 'StandardPool'
      tier: 'Standard'
      capacity: 50
    }
  }
  
  resource database 'databases@2022-05-01-preview' = {
    name: dbName
    location: location
    tags: tags

    properties: {
      elasticPoolId: elasticsDbPool.id
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-hms-${env}-${location}-001'
  location: location
  tags: union(tags, telemetryTags)
  properties: {
    features: {
      disableLocalAuth: false
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-hms-${env}-${location}-001'
  location: location
  tags: union(tags, {
    'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${dotNetBackend.name}': 'Resource'
  }, telemetryTags)
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-hms-${env}-${location}-001'
  location: location
  tags: tags
  sku: {
    name: 'P0v3'
    capacity: 2
  }
  properties: {
    reserved: true // Linux App service plan 
  }
}

resource dotNetBackend 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-hms-${env}-${location}-001'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: true
      cors: {
        allowedOrigins: ['*']
      }
      linuxFxVersion: 'DOTNETCORE|8.0'
      
    }
  }
  resource settings 'config@2022-09-01' = {
    name: 'appsettings'
    properties: {
      APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
      AzureWebJobsDisableHomepage: 'true'
      ConnectionStrings__Database: 'Server=tcp:${dbServer.name}.${environment().suffixes.sqlServerHostname};Authentication=Active Directory Managed Identity; Database=${dbName};'
    }
  }
}
