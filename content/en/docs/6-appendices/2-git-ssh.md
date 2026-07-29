---
title: Configure Git with an SSH key
slug: "git-ssh"
weight: 52
---
# Configure Git with an SSH key

> :information_source:
> Most Git servers authenticate you with an SSH public key. SSH is a protocol for talking to remote machines securely. To use it you create an "identity" made of two files: one public, one private. The private one must be protected really well — it is a bit like your password, except that unlike a password it never leaves your computer. If you want the long version, GitHub's own guide is a good one: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

SSH is not strictly required to use Git. But without it you will quickly feel limited, and we have already, potentially, suffered a little bit to install Git. A little more. Like that afterwards it's a long calm river.

## Do you already have a key?

By default a user's SSH keys live in the `~/.ssh` directory. Let's look:

```console
ls -la ~/.ssh
```

```console
total 16
drwx------ 6 oripekelman staff 192 Jul 29 23:41 .
drwxr-xr-x 3 oripekelman staff  96 Jul 29 23:41 ..
-rw------- 1 oripekelman staff  28 Jul 29 23:41 config
-rw------- 1 oripekelman staff 411 Jul 29 23:41 id_ed25519
-rw-r--r-- 1 oripekelman staff  97 Jul 29 23:41 id_ed25519.pub
-rw-r--r-- 1 oripekelman staff  92 Jul 29 23:41 known_hosts
```

> :information_source:
> It has to be `ls -la`, not `ls -a`. The `-a` shows hidden entries; it is the `-l` that gives you the long format with permissions, which is the whole point here. We want to see the left-hand column.

What you are looking for is a pair: a file with no extension, and the same name with `.pub` on the end. The `.pub` is your **public** key, the other one is your **private** key. Older machines will have `id_rsa` and `id_rsa.pub`; a fresh one will have nothing at all, or no `~/.ssh` directory.

Read the permissions column, because they matter more than beginners expect:

* `drwx------` on the directory itself — mode `700`. Only you may even list it.
* `-rw-------` on `id_ed25519` — mode `600`. Only you may read it. This is not decoration; SSH enforces it.
* `-rw-r--r--` on `id_ed25519.pub` — mode `644`. Everyone may read it. That is fine. That is what "public" means.

> :warning:
> If the private key is readable by anyone else, SSH will refuse to use it. Not warn — refuse. Here is exactly what that looks like when a key has ended up at mode `644`, which is the usual result of copying a key onto a USB stick and back, or of unzipping one:
>
> ```console
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> Permissions 0644 for '/Users/oripekelman/.ssh/id_ed25519' are too open.
> It is required that your private key files are NOT accessible by others.
> This private key will be ignored.
> ```
>
> The fix is one line:
>
> ```console
> chmod 700 ~/.ssh
> chmod 600 ~/.ssh/id_ed25519
> ```
>
> The last line of that warning — `This private key will be ignored` — is why the symptom you actually notice is `Permission denied (publickey)`. SSH did not fail to authenticate; it never tried.

## Create your key pair

If you have no key, or you have an old `id_rsa` and would like a modern one, run `ssh-keygen`. It ships with SSH on Linux and macOS, and inside Git for Windows.

```console
ssh-keygen -t ed25519 -C "you@example.com"
```

```console
Generating public/private ed25519 key pair.
Enter file in which to save the key (/Users/oripekelman/.ssh/id_ed25519):
Enter passphrase for "/Users/oripekelman/.ssh/id_ed25519" (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/oripekelman/.ssh/id_ed25519
Your public key has been saved in /Users/oripekelman/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E you@example.com
The key's randomart image is:
+--[ED25519 256]--+
|          . o=O.o|
|           + OoE.|
|          o o.O o|
|           o o.o.|
|        S .   ..=|
|         .   + *O|
|            .+=+X|
|             .O=o|
|            .=*+o|
+----[SHA256]-----+
```

Three prompts. The first asks where to save it — press enter, take the default. The second and third ask for a passphrase, twice; we come back to that in a moment.

The `-C` is just a comment, stored in the public key file. Put your email in it, because that comment is what you will see in the list of keys on GitHub in two years when you are trying to remember which laptop a key belongs to. `"you@example.com — work laptop"` is even better.

The result is two files and one thing worth understanding: that `SHA256:F7Ft0e...` line is the key's **fingerprint**, a hash of the public key. It is how humans compare keys without reading 68 characters of base64. You can ask for it again at any time:

```console
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```

```console
256 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E you@example.com (ED25519)
```

And the public key itself is one line of text:

```console
cat ~/.ssh/id_ed25519.pub
```

```console
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHRDpUquRUZV8YB+JS7Smjvv2ewxGIkeoyu8eIpWUq5 you@example.com
```

### Why `ed25519`, and what about the other kinds

The older version of this chapter said `ssh-keygen -o`, which gave you an RSA key. That advice has aged. Here is the current state of the world.

**Ed25519 is what you want.** It is an elliptic-curve signature scheme with one fixed, well-chosen parameter set, which means there is nothing to get wrong: no key size to choose, no "is 2048 still enough". The keys are tiny — one short line — signing and verifying are fast, and both GitHub and GitLab recommend it. GitLab's documentation calls it "more secure and performant than RSA".

**The `-o` flag is obsolete.** It used to mean "write the private key in OpenSSH's own format instead of the old PEM format". Since OpenSSH 7.8, released in 2018, that is the default for every key type — and it was *always* the case for Ed25519 keys, which have no other format. `-o` is now literally a no-op in the source code and is no longer even documented. Drop it.

**RSA is acceptable, at 4096 bits, if something ancient requires it.**

```console
ssh-keygen -t rsa -b 4096 -C "you@example.com"
```

There are still appliances and old enterprise Git servers that do not speak Ed25519. If you are talking to one, this is the fallback, and both GitHub and GitLab recommend 4096 bits when you do. Do not generate a 1024-bit or 2048-bit RSA key in 2026. And note that GitHub has required RSA keys created since November 2021 to use SHA-2 signatures, and stopped accepting the old SHA-1 `ssh-rsa` signature algorithm entirely on 15 March 2022 — an RSA key from an old machine may simply stop working.

**DSA is dead.** Not deprecated — gone. OpenSSH disabled it by default in 2015, disabled it at compile time in 9.8, and removed the code entirely in OpenSSH 10.0 in April 2025. GitHub stopped accepting new DSA keys on 15 March 2022. If you ask for one now:

```console
ssh-keygen -t dsa -f ~/.ssh/id_dsa
```

```console
unknown key type dsa
```

If you find an `id_dsa` in your `~/.ssh`, it is a fossil. Generate an Ed25519 key and delete it.

> :information_source:
> **The strongest option, in one sentence:** if you have a hardware security key (a YubiKey, or a phone that can act as one), `ssh-keygen -t ed25519-sk` creates a FIDO2-backed key whose private half physically cannot be copied off the device, and which requires you to touch it to authenticate. Both GitHub and GitLab accept `ed25519-sk` (and `ecdsa-sk` if your device is older). It needs OpenSSH 8.2 or newer on both ends. It is the best answer to "what if my laptop is stolen".

## The passphrase, and how to stop typing it

`ssh-keygen` offers to encrypt the private key with a passphrase. You should say yes.

The reasoning is simple. Without a passphrase, the file `~/.ssh/id_ed25519` *is* your credential: anyone who gets a copy of that file can push as you, and copying a file is the easiest thing in the world. With a passphrase, they need the file *and* the passphrase.

The obvious objection is that you do not want to type a passphrase forty times a day. You don't have to. That is what `ssh-agent` is for: a small program that holds the decrypted key in memory, so you type the passphrase once per session.

```console
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

```console
Identity added: /Users/oripekelman/.ssh/id_ed25519 (you@example.com)
```

And to see what the agent is currently holding:

```console
ssh-add -l
```

```console
256 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E you@example.com (ED25519)
```

On most Linux desktops an agent is already running when you log in, so the `eval` line is unnecessary and `ssh-add` is all you need.

**On macOS you can do better**, because the system keychain can hold the passphrase for you across reboots:

```console
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

And then you never think about it again, if you write the whole thing down once in `~/.ssh/config`:

```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

* `AddKeysToAgent yes` — when a key is used, add it to the agent automatically. Type the passphrase on first use, not on every use.
* `UseKeychain yes` — macOS only: look for the passphrase in the keychain, and store it there.
* `IdentityFile` — which key to offer.

> :warning:
> `UseKeychain` and `--apple-use-keychain` are Apple's additions, not part of upstream OpenSSH. Two consequences. First, on Linux, `UseKeychain yes` in your config is an error, so keep it in the macOS block if you share dotfiles between machines. Second, if you have installed OpenSSH from Homebrew or MacPorts and it comes first in your `PATH`, you will get `ssh-add: illegal option -- apple-use-keychain` — you are running the non-Apple `ssh-add`. Before macOS Monterey the flags were spelled `-K` and `-A`; you will see those in older tutorials.

`~/.ssh/config` is a plain text file you create yourself if it does not exist. SSH insists that nobody but you can write to it, so `chmod 600 ~/.ssh/config` and stop worrying. We are going to keep coming back to this file, because it is where every SSH problem is eventually solved.

## Give the public key to the server

The key pair exists. Now the server needs to know the public half.

### GitHub

Go to https://github.com/settings/keys, click **New SSH key**, give it a title that will mean something later ("MacBook Air, 2026"), leave the type as **Authentication key**, and paste the contents of `~/.ssh/id_ed25519.pub`.

Paste the whole line, including the `ssh-ed25519 ` prefix and the trailing comment. Copy it with `pbcopy < ~/.ssh/id_ed25519.pub` on macOS, `xclip -sel clip < ~/.ssh/id_ed25519.pub` on Linux, or `clip < ~/.ssh/id_ed25519.pub` in Git Bash — anything rather than selecting it by hand in a terminal, where you will lose a character or gain a line break.

> :warning:
> **Never oh never.** The private key — `id_ed25519`, the one with no `.pub` — should never leave your computer. Do not paste it into a web form. Do not email it. Do not commit it. Do not put it in a Dockerfile. Do not even back it up: a lost key costs you five minutes to regenerate and re-upload, while a leaked key costs you your account. Only the `.pub` file gets sent anywhere, ever. If you are ever unsure which file you are about to paste, `head -1` it: a public key starts with `ssh-ed25519` and fits on one line, a private key starts with `-----BEGIN OPENSSH PRIVATE KEY-----`.

### GitLab

The same thing at https://gitlab.com/-/user_settings/ssh_keys → **Add new key**. GitLab additionally lets you give a key an expiry date and choose its usage — "Authentication", "Signing", or both.

### Any other Git server

There is nothing magic about the forges. On a plain server that you can log into, SSH authentication means one thing: your public key is a line in the file `~/.ssh/authorized_keys` of the account you want to log in as.

```console
ssh-copy-id -i ~/.ssh/id_ed25519.pub git@myserver.example.com
```

`ssh-copy-id` appends the key for you, creating `~/.ssh` with the right permissions if needed. If it is not available, do it by hand:

```console
cat ~/.ssh/id_ed25519.pub | ssh git@myserver.example.com 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

Note the `>>`. Appending, not overwriting — `>` would delete every other key that account uses, including possibly your own from another machine. That single line in `authorized_keys` is the whole of what a self-hosted Git server needs from you; see [Git hosting](../3-tooling-ecosystem/2-git-hosting.md "Git hosting").

## Test it

Do not discover that your key does not work in the middle of your first push. Ask directly:

```console
ssh -T git@github.com
```

```console
Hi yourname! You've successfully authenticated, but GitHub does not provide shell access.
```

That message is a success, despite reading like a refusal. GitHub is telling you the key worked and that there is no shell on the other end — there is only Git. The `-T` means "don't ask for a terminal", which is why you get one line instead of an error about ptys.

For GitLab:

```console
ssh -T git@gitlab.com
```

```console
Welcome to GitLab, @yourname!
```

### The first-connection question

The very first time you talk to a host, SSH does not know it, and asks:

```console
The authenticity of host 'github.com (140.82.121.4)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Everyone types `yes`. Let's do slightly better, because this prompt is the one moment where you can actually detect somebody impersonating GitHub.

The **fingerprint** is a hash of the server's own public key — the host key. SSH is asking "the machine answering on this address showed me this key; is it the machine you meant?" It cannot answer that for you the first time. It can afterwards, because it writes the answer into `~/.ssh/known_hosts` and compares on every subsequent connection.

So compare it against what the service publishes. GitHub's fingerprints are at https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints and, at the time of writing, are:

| Type | Fingerprint |
| --- | --- |
| Ed25519 | `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` |
| ECDSA | `SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM` |
| RSA | `SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s` |

GitLab.com publishes theirs at https://docs.gitlab.com/user/gitlab_com/ — the Ed25519 one is `SHA256:eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8`. Check the live page rather than trusting a table in a course, because these do change. Notice too that the prompt accepts the fingerprint itself instead of `yes`: paste it in and SSH will only continue if it matches.

### When the host key changes

Sooner or later you will see this, and it is designed to frighten you:

```console
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:VMZ3w9UoUE/XAQ3xAWmnC63MOBWzHZzqhSPyKg9nG2I.
Please contact your system administrator.
Add correct host key in /Users/oripekelman/.ssh/known_hosts to get rid of this message.
Offending ED25519 key in /Users/oripekelman/.ssh/known_hosts:1
Host key for github.com has changed and you have requested strict checking.
Host key verification failed.
```

It means what it says: the key stored in `known_hosts` is not the key the server just presented. Usually the boring explanation is right — the server was rebuilt, or you are reaching a different machine behind the same name. Occasionally it is not.

It happened to GitHub itself. On **24 March 2023** GitHub replaced its RSA host key, because the RSA private key had been briefly exposed in a public repository. Their Ed25519 and ECDSA host keys were unaffected. Millions of people saw exactly the block above, and the correct response was to check the new fingerprint against GitHub's published list, then remove the stale entry.

That is the fix. Do not edit `known_hosts` by hand; there is a command:

```console
ssh-keygen -R github.com
```

```console
# Host github.com found: line 1
/Users/oripekelman/.ssh/known_hosts updated.
Original contents retained as /Users/oripekelman/.ssh/known_hosts.old
```

Then reconnect and answer the first-connection prompt again — **verifying the fingerprint this time**, which is the whole point. To look at an entry without removing it, `ssh-keygen -F github.com`.

> :warning:
> The wrong fix, which you will find all over the internet, is `StrictHostKeyChecking no`. That turns off the only protection this mechanism provides, permanently, for every host. If you find yourself reaching for it, you have decided you do not care whether you are talking to GitHub. You do care.

## When it doesn't work

### Read what SSH is actually doing: `ssh -vT`

The single most useful debugging command in this chapter:

```console
ssh -vT git@github.com
```

`-v` makes SSH narrate. It is a wall of text, but you only care about a handful of lines. Here is the interesting part of a real run against a server that rejected everything:

```console
debug1: Will attempt key: work ED25519 SHA256:vC2t2ZA3kGLEJ0CwMrjK4KOxfIn0xBUkwaV4qsmlfzk agent
debug1: Will attempt key: you@example.com ED25519 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E agent
debug1: Will attempt key: /Users/oripekelman/.ssh/id_rsa RSA SHA256:cF77DnrCT1YmJ9tJ3bDvT68SLrNakRAO+NXiOHex/UM
debug1: Will attempt key: /Users/oripekelman/.ssh/id_ecdsa
debug1: Offering public key: work ED25519 SHA256:vC2t2ZA3kGLEJ0CwMrjK4KOxfIn0xBUkwaV4qsmlfzk agent
debug1: Authentications that can continue: publickey,password,keyboard-interactive
debug1: Offering public key: you@example.com ED25519 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E agent
debug1: Authentications that can continue: publickey,password,keyboard-interactive
```

Read it like this:

* **`Will attempt key:`** — the list of identities SSH found, from the agent and from `~/.ssh`. If your key is not in this list, the problem is upstream of the server: wrong filename, wrong permissions, not added to the agent.
* **`Offering public key:`** — it actually sent that one to the server.
* **`Authentications that can continue:`** appearing *after* an offer means the server said no to that key.
* **`Server accepts key:`** followed by `Authentication succeeded (publickey)` is what success looks like.

Compare the fingerprint on the line SSH offers with the fingerprint shown next to the key in your GitHub settings page. If they do not match, you uploaded a different key than the one you are using — which is, honestly, the most common cause of the next error.

### `Permission denied (publickey)`

```console
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

The checklist, in the order that finds the problem fastest:

1. **Is the key uploaded, and is it *this* key?** Compare fingerprints: `ssh-keygen -lf ~/.ssh/id_ed25519.pub` against the list on the settings page.
2. **Are the permissions right?** `ls -la ~/.ssh`. A private key at `644` is silently ignored — see the warning at the top of this chapter.
3. **Is SSH even offering it?** `ssh -vT git@github.com` and look for your fingerprint in the `Offering public key` lines.
4. **Is the agent holding a stale key?** `ssh-add -l`. If it lists nothing useful, `ssh-add ~/.ssh/id_ed25519`.
5. **Is the username `git`?** For every forge the SSH user is `git`, not your account name. `ssh -T yourname@github.com` will fail no matter what your key is.
6. **Are you offering too many keys?** See just below.
7. **Is this actually a permissions problem on the repository** rather than on the key? If `ssh -T git@github.com` greets you by name, your key is fine and the problem is that you do not have push access to that particular repository.

### Too many keys

SSH offers its identities one after another, and servers give up after a handful of failures — you get `Too many authentication failures` or a plain `Permission denied` even though the right key was in the list, just too far down it. In the `-v` output above there are six candidates before we even get started.

The cure is to tell SSH to use exactly the key you name and nothing else:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

`IdentitiesOnly yes` is the important line: without it, `IdentityFile` *adds* to the list rather than replacing it, and the agent's keys still get offered first. With it, exactly one key is offered:

```console
debug1: Offering public key: /Users/oripekelman/.ssh/id_ed25519 ED25519 SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E explicit agent
```

### Two accounts on the same host

This is a real and common need: a personal GitHub account and a work one. Both live at `github.com`, and a key can only belong to one account, so SSH needs to be told which to use per repository.

The trick is to invent hostnames. In `~/.ssh/config`:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

`github-work` is not a real hostname — it is a label. `HostName github.com` is where it actually connects. So the two entries reach the same server with different keys.

Then a work repository's **remote** URL uses the alias:

```console
git remote set-url origin git@github-work:workorg/project.git
```

```console
git remote -v
```

```console
origin	git@github-work:workorg/project.git (fetch)
origin	git@github-work:workorg/project.git (push)
```

And when you clone, clone through the alias: `git clone git@github-work:workorg/project.git`. Test either one with `ssh -T git@github-work`, which will greet you as whichever account owns that key.

> :information_source:
> Pair this with the conditional includes from [Installing and configuring Git](1-git-install.md "Installing and configuring Git") and the whole thing becomes automatic: `~/work/` gets the work email in commits, and `github-work` gets the work key for pushes. Two settings, and you stop committing to your employer's repository under your personal address.

### Port 22 is blocked

Plenty of corporate networks, hotels and university guest networks allow outbound HTTP and HTTPS and nothing else. SSH's port 22 is simply dropped, and your `git push` hangs and eventually says `Connection timed out`.

GitHub runs an SSH endpoint on port 443, which every firewall lets through because it looks like HTTPS traffic. In `~/.ssh/config`:

```
Host github.com
  HostName ssh.github.com
  Port 443
  User git
```

Note it is a *different hostname*, `ssh.github.com`, not `github.com` on a different port. Test with `ssh -T git@github.com` as usual; you will be asked to accept a host key for the new name, so check the fingerprint against the published list again.

GitLab.com offers the same thing at `altssh.gitlab.com` on port 443. For a self-hosted server, ask whoever runs it.

If even that is blocked, HTTPS is your answer, and it is next.

## HTTPS: the other way in

SSH is not mandatory. Every forge also serves Git over HTTPS, and for some situations HTTPS is simply the better choice.

**Prefer HTTPS when** you are on a locked-down network, on a machine that is not yours, or in ephemeral CI where a short-lived token is easier to manage — and safer — than a deploy key.

**Prefer SSH when** it is your own machine and you push all day. No token to rotate, no credential helper to configure, and a passphrase-protected key in an agent is a genuinely strong credential.

The one thing that does *not* work is your password:

> :warning:
> **GitHub stopped accepting account passwords for Git operations on 13 August 2021.** If you are typing your GitHub password at a `Password for 'https://github.com':` prompt, it will fail, and the error message will not be obvious about why. What goes in that field is a **personal access token**. GitLab is the same: with MFA enabled, Git over HTTPS needs a token, not your password.

### Credential helpers

Typing a forty-character token on every push is not a workflow. A credential helper stores it in your operating system's keychain and hands it to Git automatically.

```console
git config --global credential.helper osxkeychain
```

That is macOS. Elsewhere:

* **Windows** — Git Credential Manager ships with Git for Windows and is usually already configured. If not: `git config --global credential.helper manager`.
* **Linux** — the `libsecret` helper talks to GNOME Keyring or KWallet. On Debian and Ubuntu it is shipped as source and has to be built once; look in `/usr/share/doc/git/contrib/credential/libsecret`. Other distributions package it directly.
* **Anywhere, temporarily** — `git config --global credential.helper 'cache --timeout=3600'` keeps the token in memory for an hour and never writes it to disk. Git's own documentation advises against using this one for long-lived tokens.
* **`store`** writes the token to `~/.git-credentials` in **plain text**. It is better than nothing on a headless box; it is not good.

The first time you push, Git asks for your username and token, and the helper remembers.

### Or let `gh` do it

If you have GitHub's CLI installed, the whole dance is one command:

```console
gh auth login
```

It opens a browser, authenticates you, stores the token in your system credential store, offers to configure Git to use it, and will even generate and upload an SSH key if you pick SSH instead of HTTPS. `gh auth setup-git` configures `gh` as Git's credential helper on its own if you already have a token. GitLab's `glab auth login` is the equivalent.

More about tokens — classic versus fine-grained, scopes, expiry — is in [Create and configure your GitHub or GitLab account](3-github-gitlab.md "Create and configure your GitHub or GitLab account").

## Signing your commits

Now that we have a key, there is a second thing it is good for, and it belongs here because it repairs something you may not have noticed was broken.

### An unsigned commit's author is a claim, not a fact

Two commands. In a scratch repository:

```console
printf 'hello\n' > a.txt
git add a.txt
git -c user.name="Linus Torvalds" -c user.email="torvalds@linux-foundation.org" commit -m"Definitely written by me"
git log --pretty=fuller
```

```console
commit 3c2f0489a55d67840b96e6af1a195b77350b9bb6
Author:     Linus Torvalds <torvalds@linux-foundation.org>
AuthorDate: Wed Jul 29 23:32:03 2026 +0200
Commit:     Linus Torvalds <torvalds@linux-foundation.org>
CommitDate: Wed Jul 29 23:32:03 2026 +0200

    Definitely written by me
```

There. The `Author` field of a **commit** is a string you type. Git never verifies it, because Git has no way to: it is a distributed system with no central notion of who you are. Every `git log` you have ever read, every "who wrote this line" in `git blame`, rests on everyone having filled in their own name honestly.

That is usually fine. It stops being fine when the commit is a dependency you are about to run, or a release tag, or evidence in an incident review.

A signature fixes it. It attaches a cryptographic proof that the holder of a particular private key produced this exact commit — the tree, the parents, the message, the author line, all of it.

### SSH signing: the easy modern way

Since Git 2.34 you can sign with the SSH key you already have. No new tooling, no keyservers.

```console
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

> :information_source:
> Yes, `gpg.format` and `commit.gpgsign` are the config names even when there is no GPG anywhere in sight. The settings predate SSH signing and Git kept them for compatibility. And note `user.signingkey` points at the **public** key file here — Git passes it to `ssh-keygen`, which finds the private half or asks the agent.

To *verify* signatures, Git needs to know whose keys to trust. That is a file mapping identities to public keys, in the same format as SSH's own `allowed_signers`:

```
ori@pekelman.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHRDpUquRUZV8YB+JS7Smjvv2ewxGIkeoyu8eIpWUq5
```

```console
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

Now commit, and look:

```console
git commit -m"A signed commit"
git log --show-signature -1
```

```console
commit d5416dd130411ebcff88f0c3ce79f8882f3b89b3
Good "git" signature for ori@pekelman.com with ED25519 key SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E
Author: Ori Pekelman <ori@pekelman.com>
Date:   Wed Jul 29 23:32:12 2026 +0200

    A signed commit
```

Or ask about one commit specifically — this one exits non-zero if the signature is bad, which makes it usable in a script:

```console
git verify-commit HEAD
```

```console
Good "git" signature for ori@pekelman.com with ED25519 key SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E
```

And to see the state of a whole range at a glance, `%G?` in a pretty format prints one letter per commit:

```console
git log --format='%h %G? %aN'
```

```console
d5416dd G Ori Pekelman
3c2f048 N Linus Torvalds
```

`G` for a good signature, `N` for none. There are six other letters — `B` bad, `U` good but unknown validity, `X` expired, `Y` expired key, `R` revoked key, `E` cannot be checked — and they are worth knowing about because `E` (usually "I don't have that person's key") looks alarming and means almost nothing.

### Signed tags

Everything above applies to **tag**s, and for tags it matters more, because a tag is how you say "this is release 1.0" and releases are what people install.

```console
git tag -s v1.0 -m"Version 1.0"
git tag -v v1.0
```

```console
Good "git" signature for ori@pekelman.com with ED25519 key SHA256:F7Ft0eRDNNJ+e31qdZ/jGjNXp9x4L9rrhVgU5l3Bi3E
object d5416dd130411ebcff88f0c3ce79f8882f3b89b3
type commit
tag v1.0
tagger Ori Pekelman <ori@pekelman.com> 1785360732 +0200

Version 1.0
```

`-s` signs; the backend it uses is whatever `gpg.format` says, so having set `ssh` above we get an SSH signature. What tags are and why annotated ones are better than lightweight ones is in [A little structure please](../2-collaborating/4-git-repo-structure.md "A little structure please").

### Telling the forge about it

For GitHub or GitLab to show your commits as "Verified", they need the public key registered as a **signing** key.

* **GitHub** distinguishes authentication keys from signing keys when you upload. If you want one key to do both jobs, **you upload the same public key twice**, once with each type. This catches everyone out. GitHub has supported SSH commit signature verification since August 2022.
* **GitLab** lets a single key entry carry the usage "Authentication & Signing", so one upload suffices. It has supported SSH signature verification since GitLab 15.7/15.8.

In both cases the commit's email must be an address the forge knows is yours, or it will show the signature as unverified even though the maths is fine.

### GPG, the traditional way

The older mechanism is OpenPGP, and it is still what a lot of open-source projects use. The shape is the same:

```console
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
git config --global user.signingkey <THE_KEY_ID>
git config --global commit.gpgsign true
```

with `gpg.format` left at its default of `openpgp`, and then you export the public key (`gpg --armor --export <KEY_ID>`) and paste it into the forge's GPG keys page. GPG gives you things SSH signing does not — a web of trust, key expiry and revocation, signatures other tools already understand. It also gives you GPG, which is a famously unpleasant thing to administer. If you have no external requirement to use it, use SSH signing.

### What a signature does and does not prove

Be clear-eyed about this, because "Verified" badges invite over-reading.

A valid signature proves that **whoever controlled that private key produced exactly these bytes**. That is genuinely useful: it makes commits non-forgeable and non-modifiable-in-transit.

It does not prove:

* **that the key belongs to the person you think it does.** That is the trust problem, and signatures don't solve it — they relocate it into `allowed_signers`, or into the forge's account system, or into GPG's web of trust.
* **that the code is any good, or safe.** A signed commit can add a backdoor. The signature says who, not what.
* **that the author wrote it.** It says the signer signed it. Anyone with your unlocked laptop is your signer.
* **anything at all, if nobody checks.** An unverified signature is decoration. The value appears when something — a CI job, a release process, a reviewer — actually runs `git verify-commit` and fails when it doesn't pass.

Which is why the honest recommendation is modest: turn on `commit.gpgsign` because it costs you nothing once configured, and sign your tags because releases deserve it.

## Summary `ssh-keygen` `ssh-add` `git verify-commit`

* An SSH key pair is two files in `~/.ssh`: a **private** key that never leaves your machine, and a `.pub` public key you hand out freely.
* `ssh-keygen -t ed25519 -C "you@example.com"` is the command. Ed25519 is the current recommendation; RSA at 4096 bits is the fallback for old servers; DSA was removed from OpenSSH in version 10.0 and is not an option. The old `-o` flag has been a no-op since OpenSSH 7.8.
* `ed25519-sk` puts the private key in a hardware token that cannot be copied.
* Permissions are enforced, not advisory: `700` on `~/.ssh`, `600` on the private key, `644` on the public one. A loose private key is *ignored*, and shows up as `Permission denied (publickey)`.
* Use a passphrase, then use `ssh-agent` and `ssh-add` so you type it once — `ssh-add --apple-use-keychain` plus `UseKeychain yes` on macOS to type it never.
* `ssh -T git@github.com` tests the key. `ssh -vT` shows you which keys were offered and which the server refused.
* A host **fingerprint** is checkable: both GitHub and GitLab publish theirs. `REMOTE HOST IDENTIFICATION HAS CHANGED` means the stored key differs from the presented one; clear it with `ssh-keygen -R <host>` and verify the new one. GitHub itself rotated its RSA host key on 24 March 2023.
* `~/.ssh/config` solves most problems: `IdentitiesOnly yes` when too many keys are offered, `Host` aliases for two accounts on one forge, `HostName ssh.github.com` with `Port 443` when a firewall blocks port 22.
* HTTPS is a legitimate alternative. Passwords stopped working on GitHub in August 2021 — use a **personal access token** with a credential helper (`osxkeychain`, `manager`, `libsecret`), or `gh auth login`.
* The `Author` of an unsigned commit is a self-declared string that anyone can set. Commit signing is what makes it a fact.
* `gpg.format ssh` plus `user.signingkey` and `commit.gpgsign true` signs commits with the SSH key you already have (Git 2.34+). `git log --show-signature`, `git verify-commit` and `%G?` check them; `git tag -s` signs tags.
* A signature proves who produced the bytes. It says nothing about whether the code is good, and nothing at all if nobody verifies it.
