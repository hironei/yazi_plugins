# Draft: migration notice for hironei/yazi_split_pane_diff

Draft only. Prepend the text below near the top of the README of `hironei/yazi_split_pane_diff`. It has not been applied.

---

> **This repository has moved.** `pane-diff.yazi` is now maintained in [hironei/yazi_plugins](https://github.com/hironei/yazi_plugins), at [`pane-diff.yazi`](https://github.com/hironei/yazi_plugins/tree/main/pane-diff.yazi). New development happens there.
>
> Install the plugin from its new location:
>
> ```bash
> ya pkg add hironei/yazi_plugins:pane-diff
> ```
>
> If you installed from this repository, replace the old package:
>
> ```bash
> ya pkg delete hironei/yazi_split_pane_diff:pane-diff
> ya pkg add hironei/yazi_plugins:pane-diff
> ```
>
> Your keymap does not need to change.
