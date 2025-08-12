// Copyright 2025 Daytona Platforms Inc.
// SPDX-License-Identifier: AGPL-3.0

package git_test

import (
	"testing"

	"github.com/galaxyeye/daemon/pkg/git"
	"github.com/galaxyeye/daemon/pkg/gitprovider"
	"github.com/go-git/go-git/v5/plumbing/transport/http"
	"github.com/stretchr/testify/suite"
)

var repoHttp = &gitprovider.GitRepository{
	Id:     "123",
	Url:    "http://localhost:3000/galaxyeye/daytona",
	Name:   "daytona",
	Branch: "main",
	Target: gitprovider.CloneTargetBranch,
}

var repoHttps = &gitprovider.GitRepository{
	Id:     "123",
	Url:    "https://github.com/galaxyeye/daytona",
	Name:   "daytona",
	Branch: "main",
	Target: gitprovider.CloneTargetBranch,
}

var repoWithoutProtocol = &gitprovider.GitRepository{
	Id:     "123",
	Url:    "github.com/galaxyeye/daytona",
	Name:   "daytona",
	Branch: "main",
	Target: gitprovider.CloneTargetBranch,
}

var repoWithCloneTargetCommit = &gitprovider.GitRepository{
	Id:     "123",
	Url:    "https://github.com/galaxyeye/daytona",
	Name:   "daytona",
	Branch: "main",
	Sha:    "1234567890",
	Target: gitprovider.CloneTargetCommit,
}

var creds = &http.BasicAuth{
	Username: "galaxyeye",
	Password: "Daytona123",
}

type GitServiceTestSuite struct {
	suite.Suite
	gitService git.IGitService
}

func NewGitServiceTestSuite() *GitServiceTestSuite {
	return &GitServiceTestSuite{}
}

func (s *GitServiceTestSuite) SetupTest() {
	s.gitService = &git.Service{
		ProjectDir: "/workdir",
	}
}

func TestGitService(t *testing.T) {
	suite.Run(t, NewGitServiceTestSuite())
}

func (s *GitServiceTestSuite) TestCloneRepositoryCmd_WithCreds() {
	cloneCmd := s.gitService.CloneRepositoryCmd(repoHttps, creds)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "https://galaxyeye:Daytona123@github.com/galaxyeye/daytona", "/workdir"}, cloneCmd)

	cloneCmd = s.gitService.CloneRepositoryCmd(repoHttp, creds)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "http://galaxyeye:Daytona123@localhost:3000/galaxyeye/daytona", "/workdir"}, cloneCmd)

	cloneCmd = s.gitService.CloneRepositoryCmd(repoWithoutProtocol, creds)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "https://galaxyeye:Daytona123@github.com/galaxyeye/daytona", "/workdir"}, cloneCmd)

	cloneCmd = s.gitService.CloneRepositoryCmd(repoWithCloneTargetCommit, creds)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "https://galaxyeye:Daytona123@github.com/galaxyeye/daytona", "/workdir", "&&", "cd", "/workdir", "&&", "git", "checkout", "1234567890"}, cloneCmd)
}

func (s *GitServiceTestSuite) TestCloneRepositoryCmd_WithoutCreds() {
	cloneCmd := s.gitService.CloneRepositoryCmd(repoHttps, nil)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "https://github.com/galaxyeye/daytona", "/workdir"}, cloneCmd)

	cloneCmd = s.gitService.CloneRepositoryCmd(repoHttp, nil)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "http://localhost:3000/galaxyeye/daytona", "/workdir"}, cloneCmd)

	cloneCmd = s.gitService.CloneRepositoryCmd(repoWithoutProtocol, nil)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "https://github.com/galaxyeye/daytona", "/workdir"}, cloneCmd)

	cloneCmd = s.gitService.CloneRepositoryCmd(repoWithCloneTargetCommit, nil)
	s.Require().Equal([]string{"git", "clone", "--single-branch", "--branch", "\"main\"", "https://github.com/galaxyeye/daytona", "/workdir", "&&", "cd", "/workdir", "&&", "git", "checkout", "1234567890"}, cloneCmd)
}
