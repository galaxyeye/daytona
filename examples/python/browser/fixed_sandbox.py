import os
import time

from daytona import CreateSandboxFromImageParams, Daytona, DaytonaConfig, Resources, SessionExecuteRequest


def main():
    config = DaytonaConfig(
        api_key="dtn_7f8818a4d63cbd3ab1f582ec5919a6aca3abb70264d453e99bacda8f329712a7",
        api_url="http://localhost:3000/api",
    )
    daytona = Daytona(config)

    params = CreateSandboxFromImageParams(
        image="galaxyeye88/suna:0.1.3",
        public=True,
        labels={"id": "example-browser"},
        env_vars={
            "CHROME_PERSISTENT_SESSION": "true",
            "RESOLUTION": "1024x768x24",
            "RESOLUTION_WIDTH": "1024",
            "RESOLUTION_HEIGHT": "768",
            "VNC_PASSWORD": "password",
            "ANONYMIZED_TELEMETRY": "false",
            "CHROME_PATH": "",
            "CHROME_USER_DATA": "",
            "CHROME_DEBUGGING_PORT": "9222",
            "CHROME_DEBUGGING_HOST": "localhost",
            "CHROME_CDP": "",
        },
        resources=Resources(
            cpu=2,
            memory=4,
            disk=5,
        ),
        auto_stop_interval=24 * 60,
        auto_archive_interval=24 * 60,
    )

    # Create a sandbox from the image if not exists
    # Read the sandbox id from the file if it exists
    sandbox_id = None
    sandbox = None

    if os.path.exists("sandbox_id.txt"):
        with open("sandbox_id.txt", "r") as f:
            sandbox_id = f.read().strip()
        if sandbox_id:
            try:
                sandbox = daytona.get(sandbox_id)
            except Exception:
                sandbox = None
                print(f"Sandbox {sandbox_id} not found, creating new sandbox...")
                # delete the file
                os.remove("sandbox_id.txt")

    if sandbox is None:
        print("Creating sandbox...")
        sandbox = daytona.create(params, timeout=300, on_snapshot_create_logs=print)
        # Save the sandbox id to a file
        with open("sandbox_id.txt", "w") as f:
            f.write(sandbox.id)
        print(f"Created sandbox with ID: {sandbox.id}")
    else:
        print(f"Using existing sandbox with ID: {sandbox.id}")

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

    session_id = "supervisord-session"
    existing_session = None
    try:
        existing_session = sandbox.process.get_session(session_id)
    except Exception:
        pass  # Session does not exist

    if existing_session is None:
        sandbox.process.create_session(session_id)
    else:
        print(f"Session '{session_id}' already exists, reusing it.")

    # Execute supervisord command
    sandbox.process.execute_session_command(
        session_id,
        SessionExecuteRequest(
            command="exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf", run_async=True
        ),
    )

    time.sleep(10)

    response = sandbox.process.exec("ps -ef", timeout=10)
    print(response.result)

    session = sandbox.process.get_session(session_id)
    print(session)

    vnc_link = sandbox.get_preview_link(6080)
    website_link = sandbox.get_preview_link(8080)
    vnc_url = vnc_link.url if hasattr(vnc_link, "url") else str(vnc_link).split("url='")[1].split("'")[0]
    website_url = (
        website_link.url if hasattr(website_link, "url") else str(website_link).split("url='")[1].split("'")[0]
    )

    print(f"VNC URL: {vnc_url}")
    print(f"Website URL: {website_url}")

    # Open the VNC URL in the default browser
    # webbrowser.open(vnc_url)

    # Open the website URL in the default browser
    # webbrowser.open(website_url)

    time.sleep(10)
    # daytona.delete(sandbox)


if __name__ == "__main__":
    main()
