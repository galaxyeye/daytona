//go:build windows
// +build windows

// Copyright 2025 Daytona Platforms Inc.
// SPDX-License-Identifier: AGPL-3.0

package common

import (
	"fmt"
	"io"
	"os"
	"os/exec"
)

type TTYSize struct {
	Height int
	Width  int
}

type SpawnTTYOptions struct {
	Dir    string
	StdIn  io.Reader
	StdOut io.Writer
	Term   string
	Env    []string
	SizeCh <-chan TTYSize
}

func SpawnTTY(opts SpawnTTYOptions) error {
	// Windows implementation - simplified TTY handling
	// Windows doesn't use the same ioctl system as Unix

	shell := GetShell()
	cmd := exec.Command(shell)

	cmd.Dir = opts.Dir

	// Set up environment variables
	cmd.Env = append(cmd.Env, os.Environ()...)
	if opts.Term != "" {
		cmd.Env = append(cmd.Env, fmt.Sprintf("TERM=%s", opts.Term))
	}
	cmd.Env = append(cmd.Env, fmt.Sprintf("SHELL=%s", shell))
	cmd.Env = append(cmd.Env, opts.Env...)

	// Set up pipes for stdin/stdout
	cmd.Stdin = opts.StdIn
	cmd.Stdout = opts.StdOut
	cmd.Stderr = opts.StdOut // Merge stderr with stdout

	// Start the command
	err := cmd.Start()
	if err != nil {
		return err
	}

	// Handle window size changes in a Windows-compatible way
	if opts.SizeCh != nil {
		go func() {
			for range opts.SizeCh {
				// On Windows, we can't directly set terminal size via syscalls
				// The terminal emulator handles this automatically
				// This is a no-op for Windows compatibility
			}
		}()
	}

	// Wait for the command to complete
	return cmd.Wait()
}
