/*
 * Copyright 2025 Daytona Platforms Inc.
 * SPDX-License-Identifier: AGPL-3.0
 */

import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common'
import { DockerRegistryService } from './docker-registry/services/docker-registry.service'
import { RegistryType } from './docker-registry/enums/registry-type.enum'
import { OrganizationService } from './organization/services/organization.service'
import { UserService } from './user/user.service'
import { ApiKeyService } from './api-key/api-key.service'
import { EventEmitterReadinessWatcher } from '@nestjs/event-emitter'
import { SnapshotService } from './sandbox/services/snapshot.service'
import { SystemRole } from './user/enums/system-role.enum'
import { TypedConfigService } from './config/typed-config.service'

const DAYTONA_ADMIN_USER_ID = 'admin'

@Injectable()
export class AppService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AppService.name)

  constructor(
    private readonly dockerRegistryService: DockerRegistryService,
    private readonly configService: TypedConfigService,
    private readonly userService: UserService,
    private readonly organizationService: OrganizationService,
    private readonly apiKeyService: ApiKeyService,
    private readonly eventEmitterReadinessWatcher: EventEmitterReadinessWatcher,
    private readonly snapshotService: SnapshotService,
  ) {}

  async onApplicationBootstrap() {
    await this.initializeAdminUser()
    await this.initializeTransientRegistry()
    await this.initializeInternalRegistry()
    await this.initializeDefaultSnapshot()
  }

  private async initializeAdminUser(): Promise<void> {
    const existingUser = await this.userService.findOne(DAYTONA_ADMIN_USER_ID)
    if (existingUser) {
      // If admin user already exists, ensure their personal organization is not suspended
      const personalOrg = await this.organizationService.findPersonal(existingUser.id)
      if (personalOrg.suspended) {
        this.logger.log(
          `Admin user's personal organization is suspended with reason: ${personalOrg.suspensionReason}. Unsuspending...`,
        )
        await this.organizationService.unsuspend(personalOrg.id)
        this.logger.log("Admin user's personal organization has been unsuspended")
      }
      return
    }

    await this.eventEmitterReadinessWatcher.waitUntilReady()

    // Create admin user with email verified to prevent suspension
    const user = await this.userService.create({
      id: DAYTONA_ADMIN_USER_ID,
      name: 'Daytona Admin',
      personalOrganizationQuota: {
        totalCpuQuota: 100,
        totalMemoryQuota: 100,
        totalDiskQuota: 100,
        maxCpuPerSandbox: 100,
        maxMemoryPerSandbox: 100,
        maxDiskPerSandbox: 100,
        snapshotQuota: 100,
        maxSnapshotSize: 100,
        volumeQuota: 100,
      },
      email: 'dev@daytona.io',
      emailVerified: true,
      role: SystemRole.ADMIN,
    })

    // Ensure the personal organization is not suspended after creation
    const personalOrg = await this.organizationService.findPersonal(user.id)
    if (personalOrg.suspended) {
      this.logger.log("Admin user's personal organization was created as suspended. Unsuspending...")
      await this.organizationService.unsuspend(personalOrg.id)
      this.logger.log("Admin user's personal organization has been unsuspended")
    }

    await this.apiKeyService.createApiKey(personalOrg.id, user.id, DAYTONA_ADMIN_USER_ID, [])
    this.logger.log('Admin user initialized successfully')
  }

  private async initializeTransientRegistry(): Promise<void> {
    const existingRegistry = await this.dockerRegistryService.getDefaultTransientRegistry()
    if (existingRegistry) {
      return
    }

    let registryUrl = this.configService.getOrThrow('transientRegistry.url')
    const registryAdmin = this.configService.getOrThrow('transientRegistry.admin')
    const registryPassword = this.configService.getOrThrow('transientRegistry.password')
    const registryProjectId = this.configService.getOrThrow('transientRegistry.projectId')

    if (!registryUrl || !registryAdmin || !registryPassword || !registryProjectId) {
      this.logger.warn('Registry configuration not found, skipping transient registry setup')
      return
    }

    registryUrl = registryUrl.replace(/^(https?:\/\/)/, '')

    this.logger.log('Initializing default transient registry...')

    await this.dockerRegistryService.create({
      name: 'Transient Registry',
      url: registryUrl,
      username: registryAdmin,
      password: registryPassword,
      project: registryProjectId,
      registryType: RegistryType.TRANSIENT,
      isDefault: true,
    })

    this.logger.log('Default transient registry initialized successfully')
  }

  private async initializeInternalRegistry(): Promise<void> {
    const existingRegistry = await this.dockerRegistryService.getDefaultInternalRegistry()
    if (existingRegistry) {
      return
    }

    let registryUrl = this.configService.getOrThrow('internalRegistry.url')
    const registryAdmin = this.configService.getOrThrow('internalRegistry.admin')
    const registryPassword = this.configService.getOrThrow('internalRegistry.password')
    const registryProjectId = this.configService.getOrThrow('internalRegistry.projectId')

    if (!registryUrl || !registryAdmin || !registryPassword || !registryProjectId) {
      this.logger.warn('Registry configuration not found, skipping internal registry setup')
      return
    }

    registryUrl = registryUrl.replace(/^(https?:\/\/)/, '')

    this.logger.log('Initializing default internal registry...')

    await this.dockerRegistryService.create({
      name: 'Internal Registry',
      url: registryUrl,
      username: registryAdmin,
      password: registryPassword,
      project: registryProjectId,
      registryType: RegistryType.INTERNAL,
      isDefault: true,
    })

    this.logger.log('Default internal registry initialized successfully')
  }

  private async initializeDefaultSnapshot(): Promise<void> {
    const adminPersonalOrg = await this.organizationService.findPersonal(DAYTONA_ADMIN_USER_ID)

    // Additional safety check to ensure the organization is not suspended
    if (adminPersonalOrg.suspended) {
      this.logger.warn(
        `Admin personal organization is suspended during default snapshot initialization. Reason: ${adminPersonalOrg.suspensionReason}`,
      )
      this.logger.log('Attempting to unsuspend admin personal organization...')
      await this.organizationService.unsuspend(adminPersonalOrg.id)

      // Re-fetch the organization to ensure it's updated
      const updatedOrg = await this.organizationService.findPersonal(DAYTONA_ADMIN_USER_ID)
      if (updatedOrg.suspended) {
        this.logger.error('Failed to unsuspend admin personal organization. Skipping default snapshot creation.')
        return
      }
      this.logger.log('Admin personal organization has been unsuspended successfully')
    }

    try {
      const existingSnapshot = await this.snapshotService.getSnapshotByName(
        this.configService.getOrThrow('defaultSnapshot'),
        adminPersonalOrg.id,
      )
      if (existingSnapshot) {
        return
      }
    } catch {
      this.logger.log('Default snapshot not found, creating...')
    }

    const defaultSnapshot = this.configService.getOrThrow('defaultSnapshot')

    try {
      await this.snapshotService.createSnapshot(
        adminPersonalOrg,
        {
          name: defaultSnapshot,
          imageName: defaultSnapshot,
          cpu: 2,
          memory: 4,
          disk: 10,
        },
        true,
      )
      this.logger.log('Default snapshot created successfully')
    } catch (error) {
      this.logger.error('Failed to create default snapshot:', error.message)
      throw error
    }
  }
}
