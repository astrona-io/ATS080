---
draft: true
---
# Get Your Machine Ready

You need the `astrona` command-line tool, a container engine that kind can use (Podman or Docker) with about 4 GiB of free memory, `kubectl` and `jq`. The clusters pull images and manifests from the internet, so the machine needs internet access. Run `astrona check` to see whether the machine is ready.

The commands used every day are these. `astrona run -c <directory>` starts a playground or lab. `astrona submit -c <directory>` grades a lab. `astrona destroy <name>` removes the environment. `astrona docs` shows the lab text in the terminal.

If a start fails, run `astrona destroy` for the environment and start again. Check that the container engine is running and has enough memory. If a pod stays pending, read its events with `kubectl describe pod`.

Labs and playgrounds in this course are untested until a maintainer runs them. If a step fails in a way the text does not explain, report it.
