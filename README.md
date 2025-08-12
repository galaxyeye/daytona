<div align="center">

[![Documentation](https://img.shields.io/github/v/release/galaxyeye/docs?label=Docs&color=23cc71)](https://www.daytona.io/docs)
![License](https://img.shields.io/badge/License-AGPL--3-blue)
[![Go Report Card](https://goreportcard.com/badge/github.com/galaxyeye/daytona)](https://goreportcard.com/report/github.com/galaxyeye/daytona)
[![Issues - daytona](https://img.shields.io/github/issues/galaxyeye/daytona)](https://github.com/galaxyeye/daytona/issues)
![GitHub Release](https://img.shields.io/github/v/release/galaxyeye/daytona)

</div>

&nbsp;

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/galaxyeye/daytona/raw/main/assets/images/Daytona-logotype-white.png">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/galaxyeye/daytona/raw/main/assets/images/Daytona-logotype-black.png">
    <img alt="Daytona logo" src="https://github.com/galaxyeye/daytona/raw/main/assets/images/Daytona-logotype-black.png" width="50%">
  </picture>
</div>

<h3 align="center">
  Run AI Code.
  <br/>
  Secure and Elastic Infrastructure for
  Running Your AI-Generated Code.
</h3>

<p align="center">
    <a href="https://www.daytona.io/docs"> Documentation </a>·
    <a href="https://github.com/galaxyeye/daytona/issues/new?assignees=&labels=bug&projects=&template=bug_report.md&title=%F0%9F%90%9B+Bug+Report%3A+"> Report Bug </a>·
    <a href="https://github.com/galaxyeye/daytona/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.md&title=%F0%9F%9A%80+Feature%3A+"> Request Feature </a>·
    <a href="https://go.daytona.io/slack"> Join our Slack </a>·
    <a href="https://x.com/galaxyeye"> Connect on X </a>
</p>

<p align="center">
    <a href="https://www.producthunt.com/posts/daytona-2?embed=true&utm_source=badge-top-post-badge&utm_medium=badge&utm_souce=badge-daytona&#0045;2" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-badge.svg?post_id=957617&theme=neutral&period=daily&t=1746176740150" alt="Daytona&#0032; - Secure&#0032;and&#0032;elastic&#0032;infra&#0032;for&#0032;running&#0032;your&#0032;AI&#0045;generated&#0032;code&#0046; | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>
    <a href="https://www.producthunt.com/posts/daytona-2?embed=true&utm_source=badge-top-post-topic-badge&utm_medium=badge&utm_souce=badge-daytona&#0045;2" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/top-post-topic-badge.svg?post_id=957617&theme=neutral&period=monthly&topic_id=237&t=1746176740150" alt="Daytona&#0032; - Secure&#0032;and&#0032;elastic&#0032;infra&#0032;for&#0032;running&#0032;your&#0032;AI&#0045;generated&#0032;code&#0046; | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>
</p>

---

## Installation

### Python SDK

```bash
pip install daytona
```

### TypeScript SDK

```bash
npm install @galaxyeye/sdk
```

---

## Features

- **Lightning-Fast Infrastructure**: Sub-90ms Sandbox creation from code to execution.
- **Separated & Isolated Runtime**: Execute AI-generated code with zero risk to your infrastructure.
- **Massive Parallelization for Concurrent AI Workflows**: Fork Sandbox filesystem and memory state (Coming soon!)
- **Programmatic Control**: File, Git, LSP, and Execute API
- **Unlimited Persistence**: Your Sandboxes can live forever
- **OCI/Docker Compatibility**: Use any OCI/Docker image to create a Sandbox

---

## Quick Start

1. Create an account at https://app.daytona.io
1. Generate a [new API key](https://app.daytona.io/dashboard/keys)
1. Follow the [Getting Started docs](https://www.daytona.io/docs/getting-started/) to start using the Daytona SDK

## Creating your first Sandbox

### Python SDK

```py
from daytona import Daytona, DaytonaConfig, CreateSandboxParams

# Initialize the Daytona client
daytona = Daytona(DaytonaConfig(api_key="YOUR_API_KEY"))

# Create the Sandbox instance
sandbox = daytona.create(CreateSandboxParams(language="python"))

# Run code securely inside the Sandbox
response = sandbox.process.code_run('print("Sum of 3 and 4 is " + str(3 + 4))')
if response.exit_code != 0:
    print(f"Error running code: {response.exit_code} {response.result}")
else:
    print(response.result)

# Clean up the Sandbox
daytona.remove(sandbox)
```

### Typescript SDK

```jsx
import { Daytona } from '@galaxyeye/sdk'

async function main() {
  // Initialize the Daytona client
  const daytona = new Daytona({
    apiKey: 'YOUR_API_KEY',
  })

  let sandbox
  try {
    // Create the Sandbox instance
    sandbox = await daytona.create({
      language: 'python',
    })
    // Run code securely inside the Sandbox
    const response = await sandbox.process.codeRun('print("Sum of 3 and 4 is " + str(3 + 4))')
    if (response.exitCode !== 0) {
      console.error('Error running code:', response.exitCode, response.result)
    } else {
      console.log(response.result)
    }
  } catch (error) {
    console.error('Sandbox flow error:', error)
  } finally {
    if (sandbox) await daytona.remove(sandbox)
  }
}

main().catch(console.error)
```

---

## Docker Images

Daytona provides Docker images for all its services. You can use pre-built images from Docker Hub or build your own.

### Using Pre-built Images

```bash
# Use the official images
docker run -d --name daytona-api daytona/daytona-api:latest
docker run -d --name daytona-proxy daytona/daytona-proxy:latest
docker run -d --name daytona-runner daytona/daytona-runner:latest
```

### Building Images

To build Docker images from source, use the build tools in `docker/publish/`:

```bash
# Enter the build directory
cd docker/publish

# Quick development build
./build.bat dev          # Windows
make build-dev          # Linux/macOS

# Production build with push
./build.bat push         # Windows  
make build-push         # Linux/macOS

# Custom build
./build-and-push.sh --version v1.0.0 --services api,proxy
```

For detailed build instructions, see [`docker/publish/README.md`](docker/publish/README.md).

---

## Contributing

Daytona is Open Source under the [GNU AFFERO GENERAL PUBLIC LICENSE](LICENSE), and is the [copyright of its contributors](NOTICE). If you would like to contribute to the software, read the Developer Certificate of Origin Version 1.1 (https://developercertificate.org/). Afterwards, navigate to the [contributing guide](CONTRIBUTING.md) to get started.
