# Windows Dotfiles

These are my Windows dotfiles. There won't be many of them, but syncing them and
version-tracking them can't hurt.

This configuration comes from a [tutorial from Atlassian][atlassian].


## Setup

To set up, run this on a new system (before creating conflicting files, like a
`.gitconfig`):

```console
$ git clone [URL] --bare $HOME/.dots
$ git --git-dir=$HOME/.dots/ --work-tree=$HOME checkout
```

This will create `.bashrc` and thus add the `dots` alias.


## Windows Terminal

Because of where Windows Terminal stores its `settings.json`, a hard-link has to
be used.

1.  Navigate to the Windows Terminal settings directory,  
    `C:\Users\Matthew\AppData\Local\Packages\Microsoft.WindowsTerminal_[a bunch of chars]\LocalState`,
2.  Delete the `settings.json` that's already there,
3.  Replace it with a symlink using the following command:  
    ```
    > mklink /H "settings.json" "C:\Users\Matthew\.terminal-settings.json"
    ```
    (Probably best to do it in Command Prompt so we aren't messing with Terminal
    settings while using it)



[atlassian]: https://www.atlassian.com/git/tutorials/dotfiles