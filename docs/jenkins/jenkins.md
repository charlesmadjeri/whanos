# Whanos Jenkins Setup Documentation

## Overview

The Whanos Jenkins setup is a sophisticated CI/CD system designed to automatically build and deploy applications using standardized base images and Kubernetes. It supports multiple programming languages and provides both standardized and custom deployment options.

## Core Features

### 1. Base Images Support
The system supports five programming languages out of the box:
- JavaScript
- Python
- Java
- Befunge
- C

Each language has two build modes:
- **Standalone Mode**: Uses pre-configured Dockerfiles when no custom Dockerfile is present
- **Custom Mode**: Uses project-specific Dockerfile when present in the repository

### 2. Automated Project Building
The system automatically:
- Detects the programming language based on project structure
- Builds Docker images using appropriate base images
- Pushes built images to DigitalOcean Container Registry
- Deploys applications to Kubernetes (when configured)

### 3. Kubernetes Integration
- Automatic deployment to Kubernetes cluster
- Support for custom deployment configuration via `whanos.yml`
- LoadBalancer service creation for external access
- Resource management (memory limits, replicas)

## Key Components

### 1. Project Linking System
The `link-project` job allows users to:
- Connect Git repositories (HTTPS or SSH)
- Configure branch selection
- Set up authentication (username/password or SSH key)
- Create automated build pipelines

### 2. Base Image Management
- Dedicated folder for base image jobs
- Automated build process for all supported languages
- Integration with DigitalOcean Container Registry
- "Build all base images" convenience job

### 3. Configuration Management
- Jenkins Configuration as Code (JCasC) for automated setup
- Role-based access control
- Credential management for various services
- Folder organization for jobs

## Configuration Files

### whanos.yml
Optional configuration file for Kubernetes deployment: 

# Git Repository Authentication System

## Overview

The Whanos Jenkins setup includes a flexible authentication system for Git repositories through the `link-project` job. This system supports various authentication methods to work with both public and private repositories, whether they're hosted on popular platforms (GitHub, GitLab, Bitbucket) or self-hosted instances.

## Authentication Methods

### 1. Username/Password Credentials
- Suitable for HTTPS repository URLs
- Uses Jenkins' built-in credential store
- Supports:
  - Standard username/password combinations
  - Personal Access Tokens (PAT)
  - API tokens

### 2. SSH Key Authentication
- Ideal for SSH repository URLs
- Supports private key-based authentication
- Can include passphrase protection
- Works with self-hosted Git servers

# Jenkins Plugins Documentation

The following plugins are essential for the Whanos Jenkins instance to function properly:

## Core Functionality Plugins

### Configuration as Code (configuration-as-code)
- Allows Jenkins configuration to be defined in YAML format
- Used to configure security, jobs, and system settings automatically
- Essential for our `jenkins-config.yml` implementation

### Job DSL (job-dsl)
- Enables programmatic creation of Jenkins jobs
- Used in our base image jobs and link-project job definitions
- Provides a Groovy-based DSL for job configuration

### Workflow Aggregator (workflow-aggregator)
- Provides essential Pipeline functionality
- Includes core pipeline features and steps
- Required for running build pipelines and downstream jobs

## Source Control & Integration

### Git (git)
- Enables Git repository integration
- Required for checking out source code in our project jobs
- Handles Git credentials and repository operations

## Security & Organization

### Role Strategy (role-strategy)
- Implements role-based access control
- Used in our security configuration for admin roles
- Manages permissions and access levels

### Credentials (credentials)
- Manages secure credentials storage
- Required for Git authentication
- Used in the link-project job for repository access

### CloudBees Folder (cloudbees-folder)
- Enables organization of jobs into folders
- Used for our "Whanos base images" and "Projects" folders
- Provides better project organization and management

## Build Tools

### Parameterized Trigger (parameterized-trigger)
- Enables triggering of downstream jobs with parameters
- Used in the "Build all base images" job
- Manages dependencies between build jobs

# Go back to:

### [Documentation Hub](../documentation-hub.md)
