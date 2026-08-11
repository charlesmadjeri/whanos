freeStyleJob('link-project') {
    parameters {
        stringParam('GIT_URL', '', 'Git repository URL (HTTPS or SSH)')
        stringParam('PROJECT_NAME', '', 'Name of the project')
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
        dsl {
            // Outer """ interpolates link-project params. Shell bodies use ''' so bash
            // ${...} is not parsed as Groovy (\\${ → ${ in the generated DSL).
            text("""
                job("Projects/${PROJECT_NAME}") {
                    scm {
                        git {
                            remote {
                                url("${GIT_URL}")
                                if ("${GIT_CREDENTIALS}") {
                                    credentials("${GIT_CREDENTIALS}")
                                }
                                if ("${GIT_SSH_KEY}") {
                                    credentials("${GIT_SSH_KEY}")
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
                        shell('''#!/bin/bash
set -euo pipefail
ROOT="\${PROJECT_ROOT:-}"
if [ -z "\${ROOT}" ]; then
  ROOT="."
fi
case "\${ROOT}" in
  /*|~*)
    echo "PROJECT_ROOT must be a relative path within the workspace"
    exit 1
    ;;
  *..*)
    echo "PROJECT_ROOT must not contain .."
    exit 1
    ;;
esac
cd "\${ROOT}"
echo "Step 1: Building from:"
pwd
/opt/whanos/jenkins/scripts/build_project.sh
''')
                        shell('''#!/bin/bash
set -euo pipefail
ROOT="\${PROJECT_ROOT:-}"
if [ -z "\${ROOT}" ]; then
  ROOT="."
fi
case "\${ROOT}" in
  /*|~*|*..*)
    echo "Invalid PROJECT_ROOT"
    exit 1
    ;;
esac
cd "\${ROOT}"
echo "Step 2: Processing Kubernetes deployment from:"
pwd
if [ -f whanos.yml ]; then
  set -a
  . whanos.env
  set +a
  /opt/whanos/jenkins/scripts/apply_k8s.sh
else
  echo "No whanos.yml found, skipping deployment"
fi
''')
                    }
                }
            """.stripIndent())
        }
    }
}
