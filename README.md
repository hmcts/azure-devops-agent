# azure-devops-agent

- Docker images for running self-hosted ADO agents on Linux and Windows.

## Linux Agent (Ubuntu 24.04)

The Linux agent uses Ubuntu 24.04 as the base image and includes common build tools.

### Building

```bash
docker build -t azure-devops-agent:linux -f Dockerfile .
```

### Running

```bash
docker run -e AZURE_FEDERATED_TOKEN_FILE=<path-to-token-file> \
           -e AZURE_CLIENT_ID=<client-id> \
           -e AZURE_TENANT_ID=<tenant-id> \
           -e AZP_URL=<azure-devops-url> \
           -e AZP_POOL=<pool-name> \
           -e AZP_AGENT_NAME=<agent-name> \
           azure-devops-agent:linux
```

## Windows Agent (Windows Server Core 2022)

The Windows agent uses Windows Server Core LTSC 2022 as the base image and includes Windows-specific build tools.

### Building

```powershell
docker build -t azure-devops-agent:windows -f Dockerfile.windows .
```

### Running

```powershell
docker run -e AZURE_FEDERATED_TOKEN_FILE=<path-to-token-file> `
           -e AZURE_CLIENT_ID=<client-id> `
           -e AZURE_TENANT_ID=<tenant-id> `
           -e AZP_URL=<azure-devops-url> `
           -e AZP_POOL=<pool-name> `
           -e AZP_AGENT_NAME=<agent-name> `
           azure-devops-agent:windows
```

## Environment Variables

Both Linux and Windows agents support the following environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `AZURE_FEDERATED_TOKEN_FILE` | Path to the file containing the federated token | Yes |
| `AZURE_CLIENT_ID` | Azure service principal client ID | Yes |
| `AZURE_TENANT_ID` | Azure tenant ID | Yes |
| `AZP_URL` | Azure DevOps organization URL | Yes |
| `AZP_POOL` | Agent pool name | No (default: "Default") |
| `AZP_AGENT_NAME` | Agent name | No (default: hostname) |
| `AZP_WORK` | Work directory | No (default: "_work") |

## Installed Tools

### Linux Agent
- Git
- curl, jq, wget, unzip, zip
- Azure CLI
- PowerShell Core
- Node.js 20.x with Yarn
- Python 3
- Java OpenJDK 11 and 17
- Docker
- Ansible
- kubectl
- SQLPackage
- MSSQL Tools
- yq

### Windows Agent
- Git
- curl, jq, unzip, zip
- Azure CLI
- PowerShell Core
- Node.js 20.x with Yarn
- Java OpenJDK 11 and 17
- .NET Framework 4.8 Developer Pack
- Visual Studio Build Tools 2022 (includes MSBuild)
- NuGet CLI

**Note:** Docker access for Windows containers is typically provided by mounting the host's Docker socket, similar to the Linux implementation.
