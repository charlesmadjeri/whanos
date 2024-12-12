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
