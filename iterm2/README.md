# iTerm2 preferences

iTerm2's preferences live in `com.googlecode.iterm2.plist`. The cleanest
way to keep them in sync between machines is to let iTerm2 itself read
and write the plist directly from this folder.

## One-time setup on each machine

1. Open iTerm2.
2. **Preferences → General → Preferences**.
3. Check **Load preferences from a custom folder or URL**.
4. Click **Browse…** and choose `~/.dotfiles/iterm2`.
5. Set **Save changes** to **Automatic** (or "When Quitting").

iTerm2 will now read its config from this folder and write changes back
here. Commit and push from one machine, pull on the other.

## Exporting current preferences (first time only)

If this folder is empty and you already have iTerm2 set up the way you
like it on one machine, do this on that machine first:

```sh
defaults export com.googlecode.iterm2 ~/.dotfiles/iterm2/com.googlecode.iterm2.plist
```

Then commit:

```sh
cd ~/.dotfiles
git add iterm2/com.googlecode.iterm2.plist
git commit -m "iterm2: snapshot current preferences"
git push
```

After that, follow the "One-time setup" steps above on each machine.
