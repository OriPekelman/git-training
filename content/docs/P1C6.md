---
title: We know how to save... but how to modify? to delete ? to cancel?
slug: "modify-delete-files-with-git"
weight: 6
---
# We know how to save... but how to modify? to delete ? to cancel?

Let's remember two important things: the **commit** points to a **tree-id**, so to a tree structure and file content in a specific state, and it also points to **parents**, so to previous **commit**s (which naturally point to **tree-id**s of their own). Deleting is therefore simple: if a file is in the **tree** of the parent **commit** but not in the **tree** of our current **commit**, then that file has been deleted.

## Deleting a file with Git

We can test that. Let's say we no longer wish to have the file LICENSE.

```console
rm LICENSE
```

Now `git status` will tell us:

```console
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    LICENSE

no changes added to commit (use "git add" and/or "git commit -a")
```
This means that the LICENSE file exists in the **index** but does not exist in the working area. To delete it we will have to add the deletion to the index. So `git add LICENSE`. Then we will apply this change with a `git commit -m"Remove license file"`.

```console
[master f2c06df] Remove license file
 1 file changed, 8 deletions(-)
 delete mode 100644 LICENSE
```
The file is gone.

> :information_source: As we understand... everything remains in the history, our current commit points to a **tree** object whose tree does not contain this file. But the previous **commit** points to a **tree** that contains it.

But all this is tedious, and Git gives us a single command that removes the file from both the working directory and the index at once. Don't run it now — our LICENSE is already gone, so it would only complain — but this is what we could have typed instead of the `rm` plus `git add` above:

```console
git rm LICENSE
```

It answers, laconically:

```console
rm 'LICENSE'
```

and leaves the deletion already staged, so a `git status` would show:

```console
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	deleted:    LICENSE

```

So this pair:

```console
git rm LICENSE
git commit -m"Remove license file"
```

is perfectly equivalent to what we just did — provided the file hasn't been modified (otherwise Git will complain and refuse, which is a kindness: it is refusing to throw away work you have not saved anywhere).

## Changing file and directory names

In exactly the same way we can proceed with renaming. But there, it is in our best interest to always use the integrated command instead.

To change the name of our `files` directory to `media` nothing could be simpler:

```console
git mv files media
```

Here is a small `git status` will tell us:

```console
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	renamed:    files/.gitkeep -> media/.gitkeep

```
As always to apply the changes, a **commit**:

```console
git commit -m'Rename files to media'
```

Who will tell us:
```console
[master 2937bcc] Rename files to media
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename {files => media}/.gitkeep (100%)
```

> :information_source:
> Notice that Git says *rename*, but there is no such thing as a rename in a Git object. `git mv` is a convenience: it moves the file on disk and updates the index, and that is all. The commit simply records a **tree** in which `.gitkeep` sits under `media` instead of `files`. The word "rename" in that output is Git's rename *detection*, computed on the fly by comparing the two trees and noticing that a blob with the same content disappeared from one path and appeared at another. This is why Git can spot renames you performed with your editor, too — as long as you also told it about both halves.

> :warning: Small subtlety: Git usually ignores empty directories (remember, that's why we created the little hidden file `.gitkeep`). But here, if the media directory already existed (whether it exists in our **index** or not) the result of the command will be different and our `files` will end up inside `media` with a tree structure like this: `media/files/.gitkeep`.

We could obviously have used the commands of our operating system to do the renaming, but our history would then have been less beautiful.

```console
mv files media
git status
```

```console
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	deleted:    files/.gitkeep

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	media/

no changes added to commit (use "git add" and/or "git commit -a")
```

Indeed, at this point Git cannot see that `files` has changed name. It sees a tracked file disappear, and an untracked directory appear. We would have to stage *both* halves — `git add files media`, or simply `git add -A` — before Git could pair them up and call it a rename.

> :information_source: We will come back to this but our ambition in using Git is to keep a "clean" history. This greatly facilitates collaboration. So when it comes to renaming files and directories in a Git repository **always use `git mv` rather than `mv`.**


## Summary `git rm` `git mv`

* `git rm` allows us to remove files and directories
* `git mv` allows us to rename files and directories