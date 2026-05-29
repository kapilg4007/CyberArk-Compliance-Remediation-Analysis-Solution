# IBM ICA Integration Guide for CyberArk Compliance Remediation

## Overview

This guide explains how to integrate the CyberArk Compliance Remediation Analysis solution with IBM ICA (IBM Concert Automation) using the Model Context Protocol (MCP).

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PowerShell Analysis Script                    │
│                  (Compliance Analysis Engine)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP/REST API
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        MCP Server                                │
│                    (Node.js/TypeScript)                          │
├─────────────────────────────────────────────────────────────────┤
│  • Tool Handlers (analyze_compliance, trigger_remediation)       │
│  • Resource Providers (latest analysis, metrics)                 │
│  • Prompt Templates (summaries, plans)                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ OAuth 2.0 / REST API
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         IBM ICA Platform                         │
├─────────────────────────────────────────────────────────────────┤
│  • Workflow Orchestration                                        │
│  • Event Management                                              │
│  • Integration Hub                                               │
│  • Analytics & Reporting                                         │
│  • Notification Services                                         │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Software Requirements
- Node.js 18+ (for MCP server)
- npm or yarn package manager
- PowerShell 5.1+
- IBM ICA access with API credentials
- CyberArk PVWA access

### IBM ICA Requirements
- IBM ICA instance (v1.0+)
- API access enabled
- OAuth 2.0 client credentials
- Workflow creation permissions
- Integration hub access

### Network Requirements
- Outbound HTTPS access to IBM ICA endpoint
- Inbound access to MCP server (if remote)
- CyberArk PVWA API access

## Installation

### Step 1: Install MCP Server Dependencies

```bash
cd cybeark-compliance-remediation/mcp-integration
npm init -y
npm install @modelcontextprotocol/sdk express body-parser axios dotenv winston
```

### Step 2: Create MCP Server Implementation

Create `server.js`:

```javascript
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const winston = require('winston');
require('dotenv').config();

// Initialize logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'logs/mcp-server.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

// Initialize MCP Server
const server = new Server(
  {
    name: 'cybeark-compliance-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
      resources: {},
      prompts: {}
    },
  }
);

// IBM ICA Configuration
const ICA_CONFIG = {
  endpoint: process.env.IBM_ICA_ENDPOINT || 'https://ica.company.com/api/v1',
  clientId: process.env.IBM_ICA_CLIENT_ID,
  clientSecret: process.env.IBM_ICA_CLIENT_SECRET,
  tokenEndpoint: process.env.IBM_ICA_TOKEN_ENDPOINT
};

// In-memory storage for analysis results
const analysisCache = new Map();

// IBM ICA Authentication
async function getICAToken() {
  try {
    const response = await axios.post(ICA_CONFIG.tokenEndpoint, {
      grant_type: 'client_credentials',
      client_id: ICA_CONFIG.clientId,
      client_secret: ICA_CONFIG.clientSecret
    });
    return response.data.access_token;
  } catch (error) {
    logger.error('Failed to get ICA token:', error.message);
    throw error;
  }
}

// Tool: Analyze Compliance
server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'analyze_compliance') {
    logger.info('Executing analyze_compliance tool', { args });
    
    // Store analysis request
    const correlationId = args.correlationId || generateCorrelationId();
    analysisCache.set(correlationId, {
      status: 'in_progress',
      startTime: new Date().toISOString(),
      args
    });

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            status: 'initiated',
            correlationId,
            message: 'Compliance analysis initiated. Results will be available shortly.'
          })
        }
      ]
    };
  }

  if (name === 'trigger_remediation_workflow') {
    logger.info('Executing trigger_remediation_workflow tool', { args });
    
    try {
      const token = await getICAToken();
      
      // Trigger IBM ICA workflow
      const workflowResponse = await axios.post(
        `${ICA_CONFIG.endpoint}/workflows/execute`,
        {
          workflowId: 'compliance-remediation-workflow',
          parameters: {
            accountIds: args.accountIds,
            workflowType: args.workflowType,
            priority: args.priority || 'medium',
            correlationId: args.correlationId
          }
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      );

      logger.info('Workflow triggered successfully', { 
        workflowId: workflowResponse.data.workflowInstanceId 
      });

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              status: 'success',
              workflowInstanceId: workflowResponse.data.workflowInstanceId,
              message: 'Remediation workflow triggered successfully'
            })
          }
        ]
      };
    } catch (error) {
      logger.error('Failed to trigger workflow:', error.message);
      throw error;
    }
  }

  throw new Error(`Unknown tool: ${name}`);
});

// Resource: Latest Analysis
server.setRequestHandler('resources/read', async (request) => {
  const { uri } = request.params;

  if (uri === 'compliance://analysis/latest') {
    const latestAnalysis = Array.from(analysisCache.values())
      .sort((a, b) => new Date(b.startTime) - new Date(a.startTime))[0];

    return {
      contents: [
        {
          uri,
          mimeType: 'application/json',
          text: JSON.stringify(latestAnalysis || {})
        }
      ]
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});

// Prompt: Compliance Summary
server.setRequestHandler('prompts/get', async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'compliance_summary') {
    const analysis = analysisCache.get(args.correlationId);
    
    if (!analysis) {
      throw new Error('Analysis not found');
    }

    return {
      messages: [
        {
          role: 'user',
          content: {
            type: 'text',
            text: `Generate an executive summary for compliance analysis ${args.correlationId}`
          }
        }
      ]
    };
  }

  throw new Error(`Unknown prompt: ${name}`);
});

// Express API for PowerShell integration
const app = express();
app.use(bodyParser.json());

app.post('/api/compliance-analysis', async (req, res) => {
  try {
    const { correlationId, metrics, analysisResults, remediableCount } = req.body;
    
    logger.info('Received compliance analysis', { 
      correlationId, 
      remediableCount 
    });

    // Store analysis results
    analysisCache.set(correlationId, {
      status: 'completed',
      completionTime: new Date().toISOString(),
      metrics,
      analysisResults,
      remediableCount
    });

    // Trigger IBM ICA workflows if remediable accounts found
    if (remediableCount > 0) {
      const token = await getICAToken();
      
      // Send notification
      await axios.post(
        `${ICA_CONFIG.endpoint}/notifications/send`,
        {
          channel: 'slack',
          message: `CyberArk Compliance Analysis Complete: ${remediableCount} remediable accounts found`,
          data: { correlationId, metrics }
        },
        {
          headers: { 'Authorization': `Bearer ${token}` }
        }
      );

      logger.info('Notification sent to IBM ICA');
    }

    res.json({
      status: 'success',
      message: 'Analysis results received and processed',
      correlationId
    });
  } catch (error) {
    logger.error('Error processing analysis:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Start servers
const PORT = process.env.MCP_SERVER_PORT || 3000;

app.listen(PORT, () => {
  logger.info(`MCP HTTP API listening on port ${PORT}`);
});

// Start MCP stdio transport
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  logger.info('MCP Server started with stdio transport');
}

main().catch((error) => {
  logger.error('Server error:', error);
  process.exit(1);
});

function generateCorrelationId() {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}
```

### Step 3: Create Environment Configuration

Create `.env` file:

```bash
# IBM ICA Configuration
IBM_ICA_ENDPOINT=https://ica.company.com/api/v1
IBM_ICA_CLIENT_ID=your-client-id
IBM_ICA_CLIENT_SECRET=your-client-secret
IBM_ICA_TOKEN_ENDPOINT=https://ica.company.com/oauth/token

# MCP Server Configuration
MCP_SERVER_PORT=3000

# Slack Integration (Optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Logging
LOG_LEVEL=info
```

### Step 4: Create package.json

```json
{
  "name": "cybeark-compliance-mcp-server",
  "version": "1.0.0",
  "description": "MCP Server for CyberArk Compliance with IBM ICA Integration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.5.0",
    "express": "^4.18.2",
    "body-parser": "^1.20.2",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0"
  }
}
```

## IBM ICA Workflow Configuration

### Create Remediation Workflow in IBM ICA

1. **Login to IBM ICA Console**
2. **Navigate to Workflows → Create New Workflow**
3. **Configure Workflow:**

```yaml
name: compliance-remediation-workflow
version: 1.0.0
description: Automated CyberArk account remediation workflow

triggers:
  - type: api
    endpoint: /workflows/execute
    authentication: oauth2

parameters:
  - name: accountIds
    type: array
    required: true
  - name: workflowType
    type: string
    enum: [reconcile, verify, change]
    required: true
  - name: priority
    type: string
    enum: [low, medium, high, critical]
    default: medium

steps:
  - name: validate_accounts
    type: validation
    action: validate_cybeark_accounts
    inputs:
      accountIds: ${parameters.accountIds}
    
  - name: check_prerequisites
    type: conditional
    condition: ${steps.validate_accounts.status == 'success'}
    actions:
      - check_network_connectivity
      - verify_reconcile_accounts
      - validate_permissions
    
  - name: execute_remediation
    type: action
    action: cybeark_password_reconcile
    inputs:
      accountIds: ${parameters.accountIds}
      method: reconcile
      priority: ${parameters.priority}
    retry:
      maxAttempts: 3
      backoff: exponential
    
  - name: verify_remediation
    type: verification
    action: verify_account_status
    inputs:
      accountIds: ${parameters.accountIds}
      expectedStatus: compliant
    
  - name: send_notification
    type: notification
    channels:
      - email
      - slack
    template: remediation_complete
    data:
      accountCount: ${parameters.accountIds.length}
      status: ${steps.execute_remediation.status}

error_handling:
  on_failure:
    - log_error
    - send_alert
    - create_incident
```

## Usage Examples

### Example 1: Run Analysis with MCP Integration

```powershell
# Start MCP server first
cd mcp-integration
npm start

# In another terminal, run analysis
.\scripts\Invoke-CyberArkComplianceAnalysis.ps1 `
    -ConfigPath ".\config\config.json" `
    -EnableMCP $true
```

### Example 2: Trigger Remediation via MCP

```javascript
// Using MCP client
const client = new MCPClient('http://localhost:3000');

await client.callTool('trigger_remediation_workflow', {
  accountIds: ['ACC002', 'ACC003', 'ACC007'],
  workflowType: 'reconcile',
  priority: 'high',
  correlationId: 'analysis-12345'
});
```

### Example 3: Query Analysis Results

```javascript
const results = await client.readResource('compliance://analysis/latest');
console.log(results);
```

## Integration Benefits

### 1. **Automated Workflow Orchestration**
- Automatic triggering of remediation workflows
- Priority-based execution
- Retry logic and error handling

### 2. **Real-time Notifications**
- Slack/Teams/Email alerts
- Customizable notification templates
- Event-driven updates

### 3. **Enterprise Integration**
- ITSM ticket creation
- CMDB synchronization
- Audit trail integration

### 4. **Advanced Analytics**
- Trend analysis
- Compliance dashboards
- Predictive insights

### 5. **Scalability**
- Distributed execution
- Load balancing
- High availability

## Monitoring and Troubleshooting

### Check MCP Server Status

```bash
curl http://localhost:3000/api/health
```

### View MCP Server Logs

```bash
tail -f logs/mcp-server.log
```

### Test IBM ICA Connectivity

```bash
curl -X POST https://ica.company.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "your-client-id",
    "client_secret": "your-client-secret"
  }'
```

### Common Issues

1. **MCP Server Won't Start**
   - Check Node.js version (18+)
   - Verify all dependencies installed
   - Check port 3000 availability

2. **IBM ICA Authentication Fails**
   - Verify client credentials
   - Check token endpoint URL
   - Ensure OAuth2 permissions

3. **Workflow Not Triggering**
   - Verify workflow exists in IBM ICA
   - Check workflow permissions
   - Review IBM ICA logs

## Security Best Practices

1. **Credential Management**
   - Use environment variables
   - Never commit secrets to git
   - Rotate credentials regularly

2. **Network Security**
   - Use HTTPS for all communications
   - Implement rate limiting
   - Enable CORS restrictions

3. **Access Control**
   - Implement authentication
   - Use role-based access
   - Audit all API calls

4. **Data Protection**
   - Encrypt sensitive data
   - Implement data retention policies
   - Secure log files

## Support

For issues or questions:
- IBM ICA Documentation: https://www.ibm.com/docs/ica
- MCP Protocol: https://modelcontextprotocol.io
- Internal Support: cybeark-automation-team@company.com

## Version History

- **v1.0.0** (2026-05-27): Initial IBM ICA MCP integration
  - Basic workflow orchestration
  - Notification support
  - Resource and tool handlers