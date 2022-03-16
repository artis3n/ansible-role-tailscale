# artis3n-tailscale/

This directory is used to manage idempotency checks in the [artis3n.tailscale](https://github.com/artis3n/ansible-role-tailscale) Ansible role. The state file holds the SHA256 hash of the `tailscale up` arguments so the role knows when state has changed and to re-run `up` if the configuration has changed.

Please do not modify files in this repository manually unless you want to purge this role from your system.
If you are trying to uninstall, I recommend running the role with `state: absent`.

_Note: `state: absent` is not yet supported. It will be implemented in <https://github.com/artis3n/ansible-role-tailscale/issues/176>._
