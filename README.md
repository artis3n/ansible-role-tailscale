# artis3n.tailscale

[![Ansible Role](https://img.shields.io/ansible/role/d/51664)](https://galaxy.ansible.com/artis3n/tailscale)
[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/artis3n/ansible-role-tailscale?include_prereleases)](https://github.com/artis3n/ansible-role-tailscale/releases)
[![Molecule Tests](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/pull_request_target.yml/badge.svg)](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/pull_request_target.yml)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/6312/badge)](https://bestpractices.coreinfrastructure.org/projects/6312)
![GitHub last commit](https://img.shields.io/github/last-commit/artis3n/ansible-role-tailscale)
![GitHub](https://img.shields.io/github/license/artis3n/ansible-role-tailscale)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/artis3n)](https://github.com/sponsors/artis3n)
[![GitHub followers](https://img.shields.io/github/followers/artis3n?style=social)](https://github.com/artis3n/)
[![Twitter Follow](https://img.shields.io/twitter/follow/artis3n?style=social)](https://twitter.com/Artis3n)

This role installs and configures [Tailscale][] on a Linux target.

Supported operating systems:
- Debian / Ubuntu
- CentOS / RedHat
- Rocky Linux / AlmaLinux
- Amazon Linux 2
- Oracle Linux
- Fedora
- Arch Linux
- Raspbian (untested but should work through Debian support)

See the [CI worfklow](https://github.com/artis3n/ansible-role-tailscale/blob/main/.github/workflows/ci.yml#L15) for the list of distribution versions actively tested in each pull request.

<div align="center">
  <a href="https://asciinema.org/a/g8P2DT45oedUaxXSKGBKpU2Dl"><img src="docs/demo.gif" width=650 height=450></a>
</div>

This role uses Ansible fully qualified collection names (FQCN) and therefore requires Ansible 2.11+.
Ansible 2.12 is set as the minimum required version as this was the version tested for compatibility during the FQCN refactor.

# V3 Breaking Changes

- `tailscale_auth_key` is now `tailscale_authkey`
- `insecurely_log_auth_key` is now `insecurely_log_authkey`
- `force` is no longer a role variable

# State Tracking

This role will create a `.artis3n-tailscale` directory in the target's home directory in order to maintain a concept of state from the configuration of the arguments passed to `tailscale up`.
This allows the role to idempotently update a Tailscale node's configuration when needed.
Deleting this directory will lead to this role re-configuring Tailscale when it is not needed, but will not otherwise break anything.
However, it is recommended that you let this Ansible role manage this directory and its contents.

Note that:

> Flags are not persisted between runs; you must specify all flags each time.
>
> ...
>
> In Tailscale v1.8 or greater, if you forget to specify a flag you added before, the CLI will warn you and provide a copyable command that includes all existing flags.

<small>

\- [docs: tailscale up][tailscale up docs]

</small>

This role will bubble up any stderr messages from the Tailscale binary to resolve any end-user configuration errors with `tailscale up` arguments.
The `--authkey=` value will be redacted unless [`insecurely_log_authkey`](#insecurely_log_authkey) is set to `true`.

![logged stderr](docs/images/printed_stderr.png)

# Role Variables

## Required

One of `tailscale_authkey` or `tailscale_up_skip` must be present.
In most cases you will use `tailscale_authkey`.

If you are uninstalling Tailscale (`state: absent`), neither `tailscale_authkey` nor `tailscale_up_skip` is required.

### tailscale_authkey

Is **not** required if `tailscale_up_skip` is set to `true`.

A Tailscale Node Authorization auth key.

A Node Authorization auth key can be generated under your Tailscale account at <https://login.tailscale.com/admin/authkeys>.
Note that reusable authorization keys now expire 90 days after they are generated.

This value should be treated as a sensitive secret.
You are encouraged to use [ansible-vault][] to encrypt this value in your playbook.

### tailscale_up_skip

**If set to true, `tailscale_authkey` is not required.**

**Default**: `false`

Whether to install and configure Tailscale as a service but skip running `tailscale up`.
Helpful when packaging up a Tailscale installation into a build process such as AMI creation when the server should not yet authenticate to your Tailscale network.

## Optional

### insecurely_log_authkey

**Default**: `false`

If set to `true`, the "Bring Tailscale Up" command will include the raw value of the Tailscale authkey when logging any errors encountered during `tailscale up`.
The authkey is not logged in successful task completions and is redacted in the `stderr` output by this role if an error occurs.

![redacted authkey](docs/images/redacted_authkey.png)

If you are encountering an error bringing Tailscale up and want the "Bring Tailscale Up" task to _not_ redact the value of the authkey, set this variable to `true`.

If the authkey is invalid, the role will relay Tailscale's error message on that fact:

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

This role uses `latest` by default to help ensure your software remains up-to-date and incorporates the latest security and product features.
For users who desire more control over configuration drift, `present` will not update Tailscale if it is already installed.
Changes to [`tailscale_args`](#tailscale_args) will be applied under both `latest` and `present`; this parameter only impacts the version of Tailscale installed to the target system.

If set to `absent`, this role will de-register the Tailscale node (if already authenticated)
and clean up or disable all Tailscale artifacts added to the system.

Note that neither `tailscale_authkey` nor `tailscale_up_skip` is required if `state` is set to `absent`.

### tailscale_args

Pass any additional command-line arguments to `tailscale up`.

Note that the [command][ansible.builtin.command] module is used, which does not support subshell expressions (`$()`) or bash operations like `;` and `&`.
Only `tailscale up` arguments can be passed in.

**Do not use this for `--authkey`.**
Use the `tailscale_authkey` variable instead.

Any stdout/stderr output from the `tailscale` binary will be printed. Since the tasks move quickly in this section, a 5 second pause is introduced to grant more time for users to realize a message was printed.

![printed stdout](docs/images/printed_stdout.png)

Stderrs will continue to fail the role's execution.
The sensitive `--authkey` value will be redacted by default.
If you need to view the unredacted value, see [`insecurely_log_authkey`](#insecurely_log_authkey).

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

Pass arbitrary command-line arguments:

```yaml
- name: Servers
  hosts: all
  tasks:
    - name: Get AZ subnets
      ec2_vpc_subnet_facts:
        region: "{{ placement.region }}"
        filters:
          vpc-id: "{{ vpc_id }}"
          availability-zone: "{{ placement.availability_zone }}"
      register: subnet_info

    - name: Set Subnet list
      set_fact:
        subnet_blocks: "{{ subnet_info.subnets | map(attribute='cidr_block') | list  }}"

    - name: Configure Sysctl
      sysctl:
        name: net.ipv4.ip_forward
        value: 1
        state: present
        ignoreerrors: true
        sysctl_set: true

    - name: Iptables Masquerade
      iptables:
        table: nat
        chain: POSTROUTING
        jump: MASQUERADE

    - name: Configure Tailscale
      include_role:
        name: artis3n.tailscale
      vars:
        tailscale_args: "--accept-routes=false --advertise-routes={{ subnet_blocks | join(',') }}"
        tailscale_authkey: "{{ lookup('env', 'TAILSCALE_KEY') }}"
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
The machines are authorized with [ephemeral auth keys][] and are automatically cleaned up within 30 minutes-48 hours.

This value is stored in a [GitHub Action secret][] with the name `TAILSCALE_CI_KEY`.
To test this role locally, store the Tailscale ephemeral auth key in a `TAILSCALE_CI_KEY` env var.
If you are a Collaborator on this repository, you can open a GitHub CodeSpace and the `TAILSCALE_CI_KEY` will be populated for you.

[ansible-vault]: https://docs.ansible.com/ansible/latest/user_guide/vault.html#encrypt-string-for-use-in-yaml
[ansible.builtin.command]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html
[auth key]: https://login.tailscale.com/admin/authkeys
[ephemeral auth keys]: https://tailscale.com/kb/1111/ephemeral-nodes/
[github action secret]: https://docs.github.com/en/actions/reference/encrypted-secrets
[tailscale]: https://tailscale.com/
[tailscale account]: https://login.tailscale.com/start
[tailscale up docs]: https://tailscale.com/kb/1080/cli/#up
