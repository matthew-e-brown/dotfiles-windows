# Windows Dotfiles

These are my Windows dotfiles. There won't be many of them, but syncing them and
version-tracking them can't hurt.

This configuration comes from a [tutorial from Atlassian][atlassian].


## Scripts

The `Scripts` folder contains little scripts for repetitive tasks that I found
myself doing often. Since I don't have a whole organizational structure or
anything like that, and some scripts may end up being whole programs or may
require folders, this folder is **not** on my `PATH`. Instead, each script is
given an alias or function in `.bashrc`.


## Setup

To set up, run this on a new system (before creating conflicting files, like a
`.gitconfig`):

```
git clone [URL] --bare $HOME/.dots
git --git-dir=$HOME/.dots/ --work-tree=$HOME checkout
```

This will create `.bashrc` and thus add the `dots` alias.


### Windows Terminal

Because of where Windows Terminal stores its `settings.json`, a hard-link has to
be used.

1.  Find the Windows Terminal settings directory. If installed from the Windows
    Store, it should be inside `C:\Users\Matthew\AppData\Local\Packages\` and
    called `Microsoft.WindowsTerminal_[some junk]`. You want the `LocalState`
    folder.
2.  Delete the `settings.json` that's already there,
3.  Replace it with a symlink using the following command:  
    ```
    mklink /H "[path to WindowsTerminal]\LocalState\settings.json" "C:\Users\Matthew\.terminal-settings.json"
    ```
    - You need to use a full path for this to work
    - It's probably best to close Windows Terminal and do this with `cmd` while
      you're messing with settings, just so Windows Terminal doesn't regenerate
      the file.



[atlassian]: https://www.atlassian.com/git/tutorials/dotfiles
