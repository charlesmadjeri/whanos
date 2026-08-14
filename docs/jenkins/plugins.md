# Jenkins plugins

Pinned in `jenkins/plugins.txt`:

| Plugin | Why |
|---|---|
| configuration-as-code | Casc YAML (`jenkins/casc/`) |
| job-dsl | Folders, base-image jobs, link-project |
| authorize-project | Run sandboxed Job DSL as the triggering user (not SYSTEM) |
| workflow-aggregator | Pipeline support |
| git | SCM checkout |
| role-strategy | Admin RBAC |
| credentials / credentials-binding | Secrets for Git + registry |
| cloudbees-folder | **Whanos base images** / **Projects** |
| parameterized-trigger | **Build all base images** |
| envinject / kubernetes-cli | Available helpers |

[Jenkins hub](jenkins-hub.md)
