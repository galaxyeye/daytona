from daytona import CreateSandboxFromImageParams, Daytona, DaytonaConfig, Resources


def main():
    config = DaytonaConfig(
        api_key="dtn_1431fcd3abf038d1098de554c0bba0a4ec1366186128049f6d39306f4039d5a8",
        api_url="http://localhost:3000/api",
    )
    daytona = Daytona(config)

    params = CreateSandboxFromImageParams(
        image="python:3.9.23-slim",
        language="python",
        resources=Resources(
            cpu=1,
            memory=1,
            disk=3,
        ),
    )

    sandbox = daytona.create(params, timeout=150, on_snapshot_create_logs=print)

    # Run the code securely inside the sandbox
    response = sandbox.process.code_run('print("Hello World!")')
    if response.exit_code != 0:
        print(f"Error: {response.exit_code} {response.result}")
    else:
        print(response.result)

    # Execute an os command in the sandbox
    response = sandbox.process.exec('echo "Hello World from exec!"', timeout=10)
    if response.exit_code != 0:
        print(f"Error: {response.exit_code} {response.result}")
    else:
        print(response.result)

    daytona.delete(sandbox)


if __name__ == "__main__":
    main()
