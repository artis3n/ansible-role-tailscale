---
name: Bug report
about: Create a report to help us improve
title: "[BUG]"
labels: bug:needs-reproduction
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Target (please complete the following information):**
 - OS: [e.g. Ubuntu]
 - Ansible version:
 - `artis3n.tailscale` version:
 - Tailscale version (set `verbose` to true):

Output of `tailscale status` during role execution (set `verbose` to true):

```bash
ok: [instance] => {
        "tailscale_status": {
            ...
        }
    }

```

**Additional context**
Add any other context about the problem here.
