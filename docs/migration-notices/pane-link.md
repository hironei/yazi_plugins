# Draft: migration notice for hironei/yazi_split_pane_link

Draft only. Prepend the text below near the top of the README of `hironei/yazi_split_pane_link`. It has not been applied.

---

> **This repository has moved.** `pane-link.yazi` is now maintained in [hironei/yazi_plugins](https://github.com/hironei/yazi_plugins), at [`pane-link.yazi`](https://github.com/hironei/yazi_plugins/tree/main/pane-link.yazi). New development happens there.
>
> Install the plugin from its new location:
>
> ```bash
> ya pkg add hironei/yazi_plugins:pane-link
> ```
>
> If you installed from this repository, replace the old package:
>
> ```bash
> ya pkg delete hironei/yazi_split_pane_link:pane-link
> ya pkg add hironei/yazi_plugins:pane-link
> ```
>
> Your keymap does not need to change.
