/*
 * Copyright 2025 Daytona Platforms Inc.
 * SPDX-License-Identifier: AGPL-3.0
 */

const { composePlugins, withNx } = require('@nx/webpack')
const path = require('path')
const glob = require('glob')

// Only load migrations in production or when explicitly requested
const shouldLoadMigrations = process.env.NODE_ENV === 'production' || process.env.LOAD_MIGRATIONS === 'true'

const migrationEntries = shouldLoadMigrations ? (() => {
  const migrationFiles = glob.sync('apps/api/src/migrations/*')
  return migrationFiles.reduce((acc, migrationFile) => {
    const entryName = migrationFile.substring(migrationFile.lastIndexOf('/') + 1, migrationFile.lastIndexOf('.'))
    acc[entryName] = migrationFile
    return acc
  }, {})
})() : {}

module.exports = composePlugins(
  // Default Nx composable plugin
  withNx(),
  // Custom composable plugin
  (config) => {
    // `config` is the Webpack configuration object
    // `options` is the options passed to the `@nx/webpack:webpack` executor
    // `context` is the context passed to the `@nx/webpack:webpack` executor
    
    // Development optimizations
    if (process.env.NODE_ENV === 'development') {
      // Faster source maps for development
      config.devtool = 'eval-cheap-module-source-map'
      
      // Enable caching for faster rebuilds
      config.cache = {
        type: 'filesystem',
        buildDependencies: {
          config: [__filename],
        },
      }
      
      // Enable parallel processing
      config.parallelism = require('os').cpus().length
    } else {
      // Production optimizations
      config.cache = {
        type: 'filesystem',
        buildDependencies: {
          config: [__filename],
        },
      }
    }
    
    // Optimize source map paths
    config.output.devtoolModuleFilenameTemplate = function (info) {
      const rel = path.relative(process.cwd(), info.absoluteResourcePath)
      return `webpack:///./${rel}`
    }
    
    // Add typeorm migrations as entry points only when needed
    if (shouldLoadMigrations) {
      for (const key in migrationEntries) {
        config.entry[`migrations/${key}`] = migrationEntries[key]
      }
    }
    
    config.mode = process.env.NODE_ENV
    return config
  },
)
