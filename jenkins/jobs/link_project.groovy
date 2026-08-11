freeStyleJob('link-project') {
    parameters {
        stringParam('GIT_URL', '', 'Git repository URL (HTTPS or SSH)')
        stringParam('PROJECT_NAME', '', 'Name of the project (alphanumeric, dash, underscore)')
        stringParam('GIT_BRANCH', 'main', 'Git branch to build (default: main)')
        stringParam('PROJECT_ROOT', '', 'Optional path inside the repo to the Whanos app (e.g. docs/example_apps/whanos_example_apps/ts-hello-world). Empty = repository root.')
        credentialsParam('GIT_CREDENTIALS') {
            type('com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl')
            required(false)
            defaultValue('')
            description('Credentials to use for private repository (username/password)')
        }
        credentialsParam('GIT_SSH_KEY') {
            type('com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey')
            required(false)
            defaultValue('')
            description('SSH key to use for private repository')
        }
    }

    steps {
        // Reject values that would break or inject into the Job DSL Groovy below.
        shell('''
            set -euo pipefail
            echo "Validating link-project parameters..."
            if [ -z "${PROJECT_NAME:-}" ]; then
              echo "PROJECT_NAME is required"
              exit 1
            fi
            echo "${PROJECT_NAME}" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9_-]{0,62}$' \
              || { echo "PROJECT_NAME must match [a-zA-Z0-9][a-zA-Z0-9_-]{0,62}"; exit 1; }
            echo "${GIT_URL:-}" | grep -Eq '^(https://|git@)' \
              || { echo "GIT_URL must start with https:// or git@"; exit 1; }
            echo "${GIT_BRANCH:-}" | grep -Eq '^[a-zA-Z0-9._/-]+$' \
              || { echo "GIT_BRANCH contains invalid characters"; exit 1; }
            if [ -n "${PROJECT_ROOT:-}" ]; then
              echo "${PROJECT_ROOT}" | grep -Eq '^[a-zA-Z0-9._/-]+$' \
                || { echo "PROJECT_ROOT contains invalid characters"; exit 1; }
              case "${PROJECT_ROOT}" in
                /*|*..*) echo "PROJECT_ROOT must be relative and must not contain .."; exit 1 ;;
              esac
            fi
            echo "Parameters OK"
        '''.stripIndent())

        dsl {
            // Use ''' so Casc can seed at boot without build params.
            // Keep generated shell free of $ so Groovy/Job DSL never interpolates bash.
            text('''
                job("Projects/$PROJECT_NAME") {
                    disabled(false)
                    concurrentBuild(false)
                    scm {
                        git {
                            remote {
                                url("${GIT_URL}")
                                if (GIT_CREDENTIALS) {
                                    credentials(GIT_CREDENTIALS)
                                }
                                if (GIT_SSH_KEY) {
                                    credentials(GIT_SSH_KEY)
                                }
                            }
                            branch("*/${GIT_BRANCH}")
                            extensions {
                                cloneOptions {
                                    timeout(10)
                                }
                            }
                        }
                    }

                    triggers {
                        scm('* * * * *')
                    }

                    wrappers {
                        credentialsBinding {
                            string('REGISTRY_TOKEN', 'do-registry-token')
                            string('REGISTRY_USERNAME', 'do-registry-username')
                        }
                        environmentVariables {
                            env('KUBECONFIG', '/var/lib/jenkins/kube/config')
                            env('PROJECT_ROOT', "${PROJECT_ROOT}")
                        }
                    }

                    steps {
                        shell('/opt/whanos/jenkins/scripts/run_linked_project.sh')
                    }
                }
            '''.stripIndent())
        }
    }
}
