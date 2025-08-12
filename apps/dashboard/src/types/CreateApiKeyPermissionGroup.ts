/*
 * Copyright 2025 Daytona Platforms Inc.
 * SPDX-License-Identifier: AGPL-3.0
 */

import { CreateApiKeyPermissionsEnum } from '@galaxyeye/api-client'

export interface CreateApiKeyPermissionGroup {
  name: string
  permissions: CreateApiKeyPermissionsEnum[]
}
