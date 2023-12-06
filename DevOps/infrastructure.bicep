param location string = resourceGroup().location

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

param sqlAdminLogin string = 'AzureAdmins'
param sqlAdminSid string = 'd768187a-e61f-4848-807a-8b6055ce4162'

var tags = {
  Project: 'HMS'
  Environment: environment
}

resource dbServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'sql-hms-${environment}-${location}-001'
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
    name: 'sqlep-hms-${environment}-${location}-001'
    location: location
    tags: tags

    sku: {
      name: 'StandardPool'
      tier: 'Standard'
      capacity: 50
    }
  }
}

