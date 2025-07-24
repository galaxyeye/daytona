// Copyright 2025 Daytona Platforms Inc.
// SPDX-License-Identifier: AGPL-3.0

// download_xterm.go
package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"time"
)

const (
	XTERM_VERSION     = "5.3.0"
	XTERM_FIT_VERSION = "0.8.0"
)

// 多个CDN源，提高成功率
var cdnSources = []string{
	"https://unpkg.com",
	"https://cdn.jsdelivr.net",
	"https://cdn.skypack.dev",
	"https://esm.sh",
}

func downloadWithMultipleCDNs(filename, packageName, version, subPath string, maxRetries int) error {
	staticDir := getStaticDir()
	filePath := filepath.Join(staticDir, filename)

	// 检查文件是否已存在
	if _, err := os.Stat(filePath); err == nil {
		fmt.Printf("File %s already exists, skipping download\n", filename)
		return nil
	}

	for _, cdn := range cdnSources {
		var url string
		switch cdn {
		case "https://unpkg.com":
			url = fmt.Sprintf("%s/%s@%s/%s", cdn, packageName, version, subPath)
		case "https://cdn.jsdelivr.net":
			url = fmt.Sprintf("%s/npm/%s@%s/%s", cdn, packageName, version, subPath)
		case "https://cdn.skypack.dev":
			url = fmt.Sprintf("%s/%s@%s/%s", cdn, packageName, version, subPath)
		case "https://esm.sh":
			url = fmt.Sprintf("%s/%s@%s/%s", cdn, packageName, version, subPath)
		}

		fmt.Printf("Trying to download %s from %s...\n", filename, cdn)

		if err := downloadWithRetry(url, filePath, maxRetries); err == nil {
			fmt.Printf("Successfully downloaded %s from %s\n", filename, cdn)
			return nil
		} else {
			fmt.Printf("Failed to download from %s: %v\n", cdn, err)
		}
	}

	return fmt.Errorf("failed to download %s from all CDN sources", filename)
}

func downloadWithRetry(url, filePath string, maxRetries int) error {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	for attempt := 1; attempt <= maxRetries; attempt++ {
		fmt.Printf("Download attempt %d/%d for %s\n", attempt, maxRetries, filepath.Base(filePath))

		resp, err := client.Get(url)
		if err != nil {
			if attempt == maxRetries {
				return fmt.Errorf("failed after %d attempts: %v", maxRetries, err)
			}
			fmt.Printf("Attempt %d failed, retrying in 2 seconds: %v\n", attempt, err)
			time.Sleep(2 * time.Second)
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			if attempt == maxRetries {
				return fmt.Errorf("HTTP %d after %d attempts", resp.StatusCode, maxRetries)
			}
			fmt.Printf("HTTP %d, retrying in 2 seconds\n", resp.StatusCode)
			time.Sleep(2 * time.Second)
			continue
		}

		file, err := os.Create(filePath)
		if err != nil {
			return fmt.Errorf("error creating file %s: %v", filePath, err)
		}
		defer file.Close()

		_, err = io.Copy(file, resp.Body)
		if err != nil {
			return fmt.Errorf("error writing file %s: %v", filePath, err)
		}

		return nil
	}

	return fmt.Errorf("unexpected error")
}

func getStaticDir() string {
	_, filename, _, _ := runtime.Caller(0)
	projectRoot := filepath.Join(filepath.Dir(filename), "..")
	return filepath.Join(projectRoot, "pkg", "terminal", "static")
}

func main() {
	// Create static directory structure
	staticDir := getStaticDir()
	err := os.MkdirAll(staticDir, 0755)
	if err != nil {
		fmt.Printf("Error creating directory %s: %v\n", staticDir, err)
		os.Exit(1)
	}

	// Files to download
	files := []struct {
		filename    string
		packageName string
		version     string
		subPath     string
	}{
		{"xterm.js", "xterm", XTERM_VERSION, "lib/xterm.js"},
		{"xterm.css", "xterm", XTERM_VERSION, "css/xterm.css"},
		{"xterm-addon-fit.js", "xterm-addon-fit", XTERM_FIT_VERSION, "lib/xterm-addon-fit.js"},
	}

	// Download each file with multiple CDN fallback
	for _, file := range files {
		err := downloadWithMultipleCDNs(file.filename, file.packageName, file.version, file.subPath, 3)
		if err != nil {
			fmt.Printf("Error downloading %s: %v\n", file.filename, err)
			os.Exit(1)
		}
	}

	fmt.Println("All xterm files downloaded successfully!")
}
