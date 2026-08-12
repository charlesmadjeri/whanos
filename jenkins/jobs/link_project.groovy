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
        // Params are validated + JSON-escaped into DSL by generate_link_dsl.py (no Groovy GStrings).
        shell('''
            set -euo pipefail
            export LINK_DSL_OUT="${WORKSPACE}/linked_project.dsl.groovy"
            /opt/whanos/jenkins/scripts/generate_link_dsl.py
        '''.stripIndent())

        dsl {
            external('linked_project.dsl.groovy')
        }
    }
}
