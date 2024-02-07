# artis3n.tailscale

[![Ansible Role](https://img.shields.io/ansible/role/d/artis3n/tailscale)](https://galaxy.ansible.com/ui/standalone/roles/artis3n/tailscale/)
[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/artis3n/ansible-role-tailscale?include_prereleases)](https://github.com/artis3n/ansible-role-tailscale/releases)
[![Molecule Tests](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/pull_request_target.yml/badge.svg)](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/pull_request_target.yml)
[![Codespaces Prebuilds](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/codespaces/create_codespaces_prebuilds/badge.svg)](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/codespaces/create_codespaces_prebuilds)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/6312/badge)](https://bestpractices.coreinfrastructure.org/projects/6312)
![GitHub last commit](https://img.shields.io/github/last-commit/artis3n/ansible-role-tailscale)
![GitHub](https://img.shields.io/github/license/artis3n/ansible-role-tailscale)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/artis3n)](https://github.com/sponsors/artis3n)
[![GitHub followers](https://img.shields.io/github/followers/artis3n?style=social)](https://github.com/artis3n/)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/artis3n/ansible-role-tailscale?quickstart=1)

This role installs and configures [Tailscale][] on a Linux target.

Supported operating systems:
- Debian / Ubuntu
- CentOS / RedHat
- Rocky Linux / AlmaLinux
- Amazon Linux 2023 / Amazon Linux 2
- Fedora
- Arch Linux
- OpenSUSE
- Oracle Linux
- Raspbian

See the [CI worfklow](https://github.com/artis3n/ansible-role-tailscale/blob/main/.github/workflows/pull_request_target.yml) for the list of distribution versions actively tested in each pull request.

<div align="center">
  <a href="https://asciinema.org/a/g8P2DT45oedUaxXSKGBKpU2Dl"><img src="docs/demo.gif" width=650 height=450></a>
</div>

> [!TIP]
> This role uses Ansible fully qualified collection names (FQCN) and therefore requires Ansible 2.11+.
> Ansible 2.12 is set as the minimum required version as this was the version tested for compatibility during the FQCN refactor.

# State Tracking

This role will create an `artis3n-tailscale` directory in the target's [`XDG_STATE_HOME`](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) directory,
or `$HOME/.local/state` if the variable is not present,
in order to maintain a concept of state from the configuration of the arguments passed to `tailscale up`.
This allows the role to idempotently update a Tailscale node's configuration when needed.
Deleting this directory will lead to this role re-configuring Tailscale when it is not needed,
but will not otherwise break anything.
However, it is recommended that you let this Ansible role manage this directory and its contents.

Note that:

> Flags are not persisted between runs; you must specify all flags each time.
>
> ...
>
> In Tailscale v1.8 or later, if you forget to specify a flag you added before,
> the CLI will warn you and provide a copyable command that includes all existing flags.

<small>

\- [docs: tailscale up][tailscale up docs]

</small>

This role will bubble up any stderr messages from the Tailscale binary
to resolve any end-user configuration errors with `tailscale up` arguments.
The `--authkey=` value will be redacted unless [`insecurely_log_authkey`](#insecurely_log_authkey) is set to `true`.

![logged stderr](docs/images/printed_stderr.png)

# Role Variables

## Required

One of `tailscale_authkey` or `tailscale_up_skip` must be present.
In most cases you will use `tailscale_authkey`.

If you are uninstalling Tailscale (`state: absent`),
neither `tailscale_authkey` nor `tailscale_up_skip` is required.

If you are authenticating with an OAuth key, you must also set `tailscale_tags` (see below).

### tailscale_authkey

Is **not** required if `tailscale_up_skip` is set to `true`.

A Tailscale Node Authorization auth key.

A Node Authorization key can be generated under your Tailscale account. The role supports two type of keys:

- Auth key (`tskey-auth-XXX-YYYYY`) <https://login.tailscale.com/admin/authkeys>
- OAuth key (`tskey-client-XXX-YYYY`) <https://login.tailscale.com/admin/settings/oauth>

> [!IMPORTANT]
> Using an OAuth key requires additionally setting the following variables:
> `tailscale_tags` (must be provided),
> `tailscale_oauth_ephemeral` (defaults to `true`),
> and `tailscale_oauth_preauthorized` (defaults to `false`).

Note that auth keys expire up to a maximum of 90 days after they are generated.
OAuth secrets do not expire unless revoked,
and the generated OAuth access token expires after 1 hour.

For more information, see Tailscale's [OAuth clients](https://tailscale.com/kb/1215/oauth-clients) page, especially [Generating long-lived auth keys](https://tailscale.com/kb/1215/oauth-clients#generating-long-lived-auth-keys).

If an OAuth key is used, be sure to grant the `write` Devices scope to the OAuth client.

<img src="https://raw.githubusercontent.com/artis3n/ansible-role-tailscale/main/docs/images/oauth_scopes.png" alt="OAuth scopes" width="40%" height="40%">

This value should be treated as a sensitive secret.

### tailscale_oauth_ephemeral

> [!NOTE]
> Used only when `tailscale_authkey` is an OAuth key.

**Default**: `true`

Register as an [ephemeral node](https://tailscale.com/kb/1111/ephemeral-nodes), if `true`.

### tailscale_oauth_preauthorized

> [!NOTE]
> Used only when `tailscale_authkey` is an OAuth key.

**Default**: `false`

Skip [manual device approval](https://tailscale.com/kb/1099/device-approval), if `true`.

### tailscale_tags

**Default**: `[]`

Apply supplied tags to the Tailscale nodes configured by this role
(via the `--advertise-tags` flag to `tailscale up`).
For more information, see [What are tags?](https://tailscale.com/kb/1068/acl-tags?q=acl%20tag#what-are-acl-tags)

> [!NOTE]
> Tags are required for OAuth clients (`tailscale_authkey` OAuth key).

Entries should not include `tag:`.
For example, `tailscale_args: ['worker']` translates to `--advertise-tags=tag:worker`.

> Auth keys generated by this OAuth client must assign tags (or tags managed by these tags) to devices they authorize.

### tailscale_up_skip

**If set to true, `tailscale_authkey` is not required.**

**Default**: `false`

Whether to install and configure Tailscale as a service but skip running `tailscale up`.
Helpful when packaging up a Tailscale installation into a build process, such as AMI creation,
when the server should not yet authenticate to your Tailscale network.

## Optional

### insecurely_log_authkey

**Default**: `false`

If set to `true`, the "Bring Tailscale Up" command will include the raw value of the Tailscale authkey
when logging any errors encountered during `tailscale up`.
By default, the authkey is not logged in successful task completions
and is redacted in the `stderr` output by this role if an error occurs.

![redacted authkey](docs/images/redacted_authkey.png)

If you are encountering an error bringing Tailscale up
and want the "Bring Tailscale Up" task to _not_ redact the value of the authkey,
set this variable to `true`.

Regardless, if the authkey is invalid, the role will relay Tailscale's error message on that fact:

![invalid authkey](docs/images/invalid_authkey.png)

### release_stability

**Default**: `stable`

Whether to use the Tailscale stable or unstable track.

`stable`:

> Stable releases. If you're not sure which track to use, pick this one.

`unstable`:

> The bleeding edge. Pushed early and often. Expect rough edges!

### state

**Default**: `latest`

Whether to install or uninstall Tailscale.
If defined, `state` must be either `latest`, `present`, or `absent`.

This role uses `latest` by default to help ensure your software remains up-to-date
and incorporates the latest security and product features.
For users who desire more control over configuration drift,
`present` will not update Tailscale if it is already installed.
Changes to [`tailscale_args`](#tailscale_args) will be applied under both `latest` and `present`;
this parameter only impacts the version of Tailscale installed to the target system.

If set to `absent`, this role will de-register the Tailscale node (if already authenticated)
and clean up or disable all Tailscale artifacts added to the system.

Note that neither `tailscale_authkey` nor `tailscale_up_skip` is required if `state` is set to `absent`.

### tailscale_args

Pass any additional command-line arguments to `tailscale up`.

Note that the [command][ansible.builtin.command] module is used,
which does not support subshell expressions (`$()`) or bash operations like `;` and `&`.
Only `tailscale up` arguments can be passed in.

> [!CAUTION]
> **Do not use this for `--authkey`.**
> Use the `tailscale_authkey` variable instead.
>
> **Do not use this for `--advertise-tags`.**
> Use the `tailscale_tags` variable instead.
>
> **Do not use this for `--timeout`.**
> Use the `tailscale_up_timeout` variable instead.

Any stdout/stderr output from the `tailscale` binary will be printed.
Since the tasks move quickly in this section, a 5 second pause is introduced
to grant more time for users to realize a message was printed.

![printed stdout](docs/images/printed_stdout.png)

Stderrs will continue to fail the role's execution.
The sensitive `--authkey` value will be redacted by default.
If you need to view the unredacted value, see [`insecurely_log_authkey`](#insecurely_log_authkey).

### tailscale_up_timeout

**Default**: `120`

Defines the timeout duration for the `tailscale up` command in seconds.

>   --timeout duration
>
>    	maximum amount of time to wait for tailscaled to enter a Running state

### verbose

**Default**: `false`

Whether to output additional information during role execution.
Helpful for debugging and collecting information to submit in a GitHub issue on this repository.

# Dependencies

## Collections

- [`community.general`](https://docs.ansible.com/ansible/latest/collections/community/general/index.html)

# Example Playbook

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        # Example pulling the API key from the env vars on the host running Ansible
        tailscale_authkey: "{{ lookup('env', 'TAILSCALE_KEY') }}"
```

Enable Tailscale SSH:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        # Example pulling the API key from the env vars on the host running Ansible
        tailscale_authkey: "{{ lookup('env', 'TAILSCALE_KEY') }}"
        tailscale_args: "--ssh"
```

Pass arbitrary command-line arguments:

```yaml
- name: Servers
  hosts: all
  tasks:
    - name: Use Headscale
      include_role:
        name: artis3n.tailscale
      vars:
        tailscale_args: "--login-server='http://localhost:8080'"
        tailscale_authkey: "{{ lookup('env', 'HEADSCALE_KEY') }}"
```

Get verbose output:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        verbose: true
        tailscale_authkey: "{{ lookup('env', 'TAILSCALE_KEY') }}"
```

Connect using an OAuth client secret:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        verbose: true
        tailscale_authkey: "{{ lookup('env', 'TAILSCALE_OAUTH_CLIENT_SECRET') }}"
        tailscale_tags:
          - "oauth"
        # Optionally, also include:
        tailscale_oauth_ephemeral: true
        tailscale_oauth_preauthorized: false
```

Install Tailscale, but don't authenticate to the network:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        tailscale_up_skip: true
```

De-register and uninstall a Tailscale node:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        state: absent
```

# License

MIT

# Author Information

Ari Kalfus ([@artis3n](https://www.artis3nal.com/)) <dev@artis3nal.com>

# Development and Contributing

This GitHub repository uses a dedicated "test" Tailscale account to authenticate Tailscale during CI runs.
Each Docker container creates a new authorized machine in that test account.
The machines are authorized with [ephemeral auth keys][]
and are automatically cleaned up within 30 minutes-48 hours.

This value is stored in a [GitHub Action secret][] with the name `TAILSCALE_CI_KEY`.
To test OAuth authkey compatibility, a Tailscale OAuth client secret is stored as `TAILSCALE_OAUTH_CLIENT_SECRET`.
If you are a Collaborator on this repository,
you can open a GitHub CodeSpace and these secrets will be pre-populated for you into the environment.

To test this role locally, store the Tailscale ephemeral auth key in a `TAILSCALE_CI_KEY` env var
and, if running the `oauth` Molecule scenario,
add an OAuth client secret in a `TAILSCALE_CI_KEY` env var.

Alternatively for Molecule testing,
you can use a [Headscale][] container that is spun up as part of the create/prepare steps.
To do this, set a `USE_HEADSCALE` env variable.
For example:

```bash
USE_HEADSCALE=true molecule test
```

[ansible.builtin.command]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html
[ephemeral auth keys]: https://tailscale.com/kb/1111/ephemeral-nodes/
[github action secret]: https://docs.github.com/en/actions/reference/encrypted-secrets
[tailscale]: https://tailscale.com/
[tailscale up docs]: https://tailscale.com/kb/1080/cli/#up
[headscale]: https://github.com/juanfont/headscale/
