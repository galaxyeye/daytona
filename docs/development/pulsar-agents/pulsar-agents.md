# Suna

```python
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
        resources=Resources(cpu=2, memory=4, disk=5),
        auto_stop_interval=5,
        auto_archive_interval=60,
    )
```

```shell
root@bc1c7550-75a2-403e-b958-2a42fcf88ac7:/# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 08:07 ?        00:00:00 sleep infinity
root         7     0  0 08:07 pts/0    00:00:00 sh -c /usr/local/bin/daytona
root        13     7  0 08:07 pts/0    00:00:00 /usr/local/bin/daytona
root        24    13  0 08:07 pts/0    00:00:00 /usr/local/lib/daytona-computer-use
root        48    13  0 08:07 pts/0    00:00:00 /usr/bin/python3 /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
root        49    48  0 08:07 pts/0    00:00:00 Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset
root        51    48  0 08:07 pts/0    00:00:00 x11vnc -display :99 -forever -shared -rfbauth /root/.vnc/passwd -rfbport 5901 -o /var/log/x11vnc.log
root        52    48  0 08:07 pts/0    00:00:00 tail -f /var/log/x11vnc.log
root        53    48  0 08:07 pts/0    00:00:00 bash ./utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:6080 --web /opt/novnc
root        57    48  1 08:07 pts/0    00:00:00 python /app/browser_api.py
root        63    48  1 08:07 pts/0    00:00:00 python /app/server.py
root        69    63  0 08:07 pts/0    00:00:00 /usr/local/bin/python -c from multiprocessing.resource_tracker import main;main(4)
root        70    63  1 08:07 pts/0    00:00:00 /usr/local/bin/python -c from multiprocessing.spawn import spawn_main; spawn_main(tracker_fd=5, pipe_handle=7) --multiprocessing-fork
root        71    57  1 08:07 pts/0    00:00:00 /usr/local/lib/python3.11/site-packages/playwright/driver/node /usr/local/lib/python3.11/site-packages/playwright/driver/package/cli.js run-driver
root        83    71  1 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --disable-field-trial-config --disable-background-networking --disable-background-timer-throttling --disable-backgrounding-occluded-windows 
root        85     1  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome_crashpad_handler --monitor-self --monitor-self-annotation=ptype=crashpad-handler --database=/root/.config/chromium/Crash Reports --annotatio
root        87     1  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome_crashpad_handler --no-periodic-tasks --monitor-self-annotation=ptype=crashpad-handler --database=/root/.config/chromium/Crash Reports --anno
root        90    83  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=zygote --no-zygote-sandbox --no-sandbox --crashpad-handler-pid=85 --enable-crash-reporter=, --user-data-dir=/tmp/playwright_chromiumd
root        91    83  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=zygote --no-sandbox --crashpad-handler-pid=85 --enable-crash-reporter=, --user-data-dir=/tmp/playwright_chromiumdev_profile-1AxxCE --
root       115    83  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=utility --utility-sub-type=network.mojom.NetworkService --lang=en-US --service-sandbox-type=none --no-sandbox --disable-dev-shm-usage
root       124    91  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=utility --utility-sub-type=storage.mojom.StorageService --lang=en-US --service-sandbox-type=utility --no-sandbox --disable-dev-shm-us
root       191    90  1 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=gpu-process --no-sandbox --disable-dev-shm-usage --disable-breakpad --crashpad-handler-pid=85 --enable-crash-reporter=, --user-data-d
root       223    91  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=renderer --crashpad-handler-pid=85 --enable-crash-reporter=, --user-data-dir=/tmp/playwright_chromiumdev_profile-1AxxCE --change-stac
root       225    91  2 08:07 ?        00:00:01 /ms-playwright/chromium-1179/chrome-linux/chrome --type=renderer --crashpad-handler-pid=85 --enable-crash-reporter=, --user-data-dir=/tmp/playwright_chromiumdev_profile-1AxxCE --change-stac
root       249    57  1 08:07 pts/0    00:00:00 /usr/local/lib/python3.11/site-packages/playwright/driver/node /usr/local/lib/python3.11/site-packages/playwright/driver/package/cli.js run-driver
root       263   249  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --disable-field-trial-config --disable-background-networking --disable-background-timer-throttling --disable-backgrounding-occluded-windows 
root       265     1  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome_crashpad_handler --monitor-self --monitor-self-annotation=ptype=crashpad-handler --database=/root/.config/chromium/Crash Reports --annotatio
root       267     1  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome_crashpad_handler --no-periodic-tasks --monitor-self-annotation=ptype=crashpad-handler --database=/root/.config/chromium/Crash Reports --anno
root       270   263  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=zygote --no-zygote-sandbox --no-sandbox --crashpad-handler-pid=265 --enable-crash-reporter=, --user-data-dir=/tmp/playwright_chromium
root       271   263  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=zygote --no-sandbox --crashpad-handler-pid=265 --enable-crash-reporter=, --user-data-dir=/tmp/playwright_chromiumdev_profile-ogodfi -
root       296   263  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=utility --utility-sub-type=network.mojom.NetworkService --lang=en-US --service-sandbox-type=none --no-sandbox --disable-dev-shm-usage
root       297   271  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=utility --utility-sub-type=storage.mojom.StorageService --lang=en-US --service-sandbox-type=utility --no-sandbox --disable-dev-shm-us
root       375   270  0 08:07 ?        00:00:00 /ms-playwright/chromium-1179/chrome-linux/chrome --type=gpu-process --no-sandbox --disable-dev-shm-usage --disable-breakpad --crashpad-handler-pid=265 --enable-crash-reporter=, --user-data-
root       412    53  0 08:07 pts/0    00:00:00 python3 -m websockify --web /opt/novnc 0.0.0.0:6080 localhost:5901
root       420    13  0 08:08 pts/1    00:00:00 /usr/bin/bash
root       422   420  0 08:08 pts/1    00:00:00 ps -ef
```
