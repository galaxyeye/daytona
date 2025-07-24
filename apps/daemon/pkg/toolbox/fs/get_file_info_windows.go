//go:build windows
// +build windows

// Copyright 2025 Daytona Platforms Inc.
// SPDX-License-Identifier: AGPL-3.0

package fs

import (
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/user"

	"github.com/gin-gonic/gin"
)

func GetFileInfo(c *gin.Context) {
	path := c.Query("path")
	if path == "" {
		c.AbortWithError(http.StatusBadRequest, errors.New("path is required"))
		return
	}

	info, err := getFileInfo(path)
	if err != nil {
		if os.IsNotExist(err) {
			c.AbortWithError(http.StatusNotFound, err)
			return
		}
		if os.IsPermission(err) {
			c.AbortWithError(http.StatusForbidden, err)
			return
		}
		c.AbortWithError(http.StatusBadRequest, err)
		return
	}

	c.JSON(http.StatusOK, info)
}

func getFileInfo(path string) (FileInfo, error) {
	info, err := os.Stat(path)
	if err != nil {
		return FileInfo{}, err
	}

	// Windows-specific file information handling
	// Windows doesn't have the same UID/GID concept as Unix
	owner := "unknown"
	group := "unknown"

	// Try to get the current user as a fallback
	if currentUser, err := user.Current(); err == nil {
		owner = currentUser.Username
		if currentUser.Gid != "" {
			group = currentUser.Gid
		}
	}

	return FileInfo{
		Name:        info.Name(),
		Size:        info.Size(),
		Mode:        info.Mode().String(),
		ModTime:     info.ModTime().String(),
		IsDir:       info.IsDir(),
		Owner:       owner,
		Group:       group,
		Permissions: fmt.Sprintf("%04o", info.Mode().Perm()),
	}, nil
}
