# artis3n.tailscale

[![Ansible Role](https://img.shields.io/ansible/role/d/51664)](https://galaxy.ansible.com/artis3n/tailscale)
[![CI Tests](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/ci.yml)
[![Security Scans](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/security.yml/badge.svg?branch=main&event=push)](https://github.com/artis3n/ansible-role-tailscale/actions/workflows/security.yml)
[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/artis3n/ansible-role-tailscale?include_prereleases)](https://github.com/artis3n/ansible-role-tailscale/releases)
![GitHub last commit](https://img.shields.io/github/last-commit/artis3n/ansible-role-tailscale)
![GitHub](https://img.shields.io/github/license/artis3n/ansible-role-tailscale)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/artis3n)](https://github.com/sponsors/artis3n)
[![GitHub followers](https://img.shields.io/github/followers/artis3n?style=social)](https://github.com/artis3n/)
[![Twitter Follow](https://img.shields.io/twitter/follow/artis3n?style=social)](https://twitter.com/Artis3n)

This role initializes a [Tailscale][] node. If Tailscale is already installed, this role will update Tailscale to the latest version.

Supported operating systems:
- Debian
- Ubuntu
- CentOS / RedHat
- Amazon Linux 2
- Oracle Linux
- Fedora
- Arch Linux
- Raspbian (untested but should work through Debian support)

See the [CI worfklow](https://github.com/artis3n/ansible-role-tailscale/blob/main/.github/workflows/ci.yml#L15) for the list of distribution versions actively tested in each pull request.

This role uses Ansible fully qualified collection names (FQCN) and therefore requires Ansible 2.11+.
Ansible 2.12 is set as the minimum required version as this was the version tested for compatibility during the FQCN refactor.

## Requirements

You must supply a `tailscale_auth_key` variable, which can be generated under your Tailscale account at <https://login.tailscale.com/admin/authkeys>.

## Role Variables

## Required

One of `tailscale_auth_key` or `tailscale_up_skip` must be present.
In most cases you will use `tailscale_auth_key`.

### tailscale_auth_key

Is **not** required if `tailscale_up_skip` is set to `true`.

A Tailscale Node Authorization auth key.

A Node Authorization auth key can be generated under your Tailscale account at <https://login.tailscale.com/admin/authkeys>.
Note that reusable authorization keys now expire 90 days after they are generated.

This value should be treated as a sensitive secret.
You are encouraged to use [ansible-vault][] to encrypt this value in your playbook.

### tailscale_up_skip

**If set to true, `tailscale_auth_key` is not required.**

**Default**: `false`

Whether to install and configure Tailscale as a service but skip running `tailscale up`.
Helpful when packaging up a Tailscale installation into a build process such as AMI creation when the server should not yet authenticate to your Tailscale network.

## Optional

### insecurely_log_authkey

**Default**: `false`

If set to `true`, the "Bring Tailscale Up" command will not mask any failing output message.
The authkey is not logged in successful task completions.
Since the authkey is printed to the console if the task fails, [no_log](https://docs.ansible.com/ansible/latest/reference_appendices/logging.html#protecting-sensitive-data-with-no-log) is enabled by default on the task.

If you are encountering an error bringing Tailscale up and want the "Bring Tailscale Up" task to log details on the error, set this variable to `true`.

### force

**Default**: `false`

If set to `true`, `tailscale up` will always run.
This can be beneficial if tailscale has already been configured on a host but you want to re-run `up` with different arguments.

### release_stability

**Default**: `stable`

Whether to use the Tailscale stable or unstable track.

`stable`:

> Stable releases. If you're not sure which track to use, pick this one.

`unstable`:

> The bleeding edge. Pushed early and often. Expect rough edges!

### tailscale_args

Pass any additional command-line arguments to `tailscale up`.

Note that this parameter does not support bash piping or command extensions like `&` or `;`.
Only `tailscale up` arguments can be passed.

Do not use this for `--authkey`.
Use the `tailscale_auth_key` variable instead.

### verbose

**Default**: `false`

Whether to output additional information during role execution.
Helpful for debugging and collecting information to submit in a GitHub issue on this repository.

## Dependencies

### Collections

- [`community.general`](https://docs.ansible.com/ansible/latest/collections/community/general/index.html)

## Example Playbook

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        # Fake example encrypted by ansible-vault
        tailscale_auth_key: !vault |
          $ANSIBLE_VAULT;1.2;AES256;tailscale
          32616238303134343065613038383933333733383765653166346564363332343761653761646363
          6637666565626333333664363739613366363461313063640a613330393062323161636235383936
          37373734653036613133613533376139383138613164323661386362376335316364653037353631
          6539646561373535610a643334396234396332376431326565383432626232383131303131363362
          3537
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
        # Pulled from the env vars on the host running Ansible
        tailscale_auth_key: "{{ lookup('env', 'TAILSCALE_KEY') }}"
```

Get verbose output:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        verbose: true
        # Pulled from the env vars on the host running Ansible
        tailscale_auth_key: "{{ lookup('env', 'TAILSCALE_KEY') }}"
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

Run `tailscale up` on a host that has been previously configured:

```yaml
- name: Servers
  hosts: all
  roles:
    - role: artis3n.tailscale
      vars:
        force: true
        # Pulled from the env vars on the host running Ansible
        tailscale_auth_key: "{{ lookup('env', 'TAILSCALE_KEY') }}"
```

## License

MIT

## Author Information

Ari Kalfus ([@artis3n](https://www.artis3nal.com/)) <dev@artis3nal.com>

## Development and Contributing

This GitHub repository uses a dedicated "test" Tailscale account to authenticate Tailscale during CI runs.
Each Docker container creates a new authorized machine in that test account.
The machines are authorized with [ephemeral auth keys][] and are automatically cleaned up within 30 minutes-48 hours.

This value is stored in a [GitHub Action secret][] with the name `TAILSCALE_CI_KEY`.
If you are interested in contributing to this repository, you must create a [Tailscale account][] and generate a [Node Authorization ephemeral auth key][auth key].
Fork this repo and add an ephemeral auth key to the fork's secrets under the name `TAILSCALE_CI_KEY`.

To test this role locally, store the Tailscale ephemeral auth key in a `TAILSCALE_CI_KEY` env var.

If you are a Collaborator on this repository, you can open a GitHub Codespace and the `TAILSCALE_CI_KEY` will be populated for you.

[ansible-vault]: https://docs.ansible.com/ansible/latest/user_guide/vault.html#encrypt-string-for-use-in-yaml
[auth key]: https://login.tailscale.com/admin/authkeys
[ephemeral auth keys]: https://tailscale.com/kb/1111/ephemeral-nodes/
[github action secret]: https://docs.github.com/en/actions/reference/encrypted-secrets
[tailscale]: https://tailscale.com/
[tailscale account]: https://login.tailscale.com/start
