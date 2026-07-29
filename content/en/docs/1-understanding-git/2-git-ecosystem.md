---
title: Git and its ecosystem
slug: "git-ecosystem"
weight: 2
---

# Git and its ecosystem

To be able to do all these wonders, Git had to reach a certain level of complexity. One could spend years learning and mastering its idiosyncrasies. Git has many layers and there are many ways to use it: the majority of its users will use the command line (and we will encourage you in this way), but others use it with the many graphical software (GUI, for Graphical User Interface) that exist, through integrated development environments (IDEs), or even simply by using their web browser through one of the many source code hosting systems on the web (first GitHub, the major reference we are going to talk about again, but also GitLab, Bitbucket, Codeberg or a Forgejo you host yourself).

An incredibly rich ecosystem has also developed around Git. Everything is integrated today with Git. With a single command, you can push your code to a first system that will automatically measure its quality, then to others allowing it to be reviewed and validated, which in turn will pass it to a system that does automated tests... to yet another that will deploy it, without human intervention, on test servers and all the way to glorious production.

I'm sure after all that, you're totally convinced that you _must_ learn Git, but maybe now you're hesitating, discouraged by the apparent complexity of it all.

Cheer up! In this course we are not going to explore all that Git has to offer us: if it is always possible to complicate our lives with this powerful beast, we can also learn to use it in a simple, robust and productive way.

With only a few commands and a few concepts that we have already mentioned (the **commit**, the **branch**, the **remote**, **push**, **pull** and **merge**), we will not only quickly succeed in working and collaborating as a team... we are going to end up deploying a real website to a real server, hands-free, by doing nothing more than `git push`. And we will build that deployment ourselves, out of a bare repository and a twenty-line hook, so that no part of it is magic.

There is one other thing worth telling you now, because it is what makes this course different from most.

We are going to look inside. Constantly. Every time you type a command, we will open `.git` and read what changed — the actual files, the actual forty-character names. You will see that a **commit** is a few lines of text you can `cat`. You will see that a **branch** is a file containing one line. You will find your own deleted work still sitting in the object store.

This costs a little more effort in the first hour than memorising six commands would. It is worth it, and here is the honest reason: Git's interface is a historical accident, full of commands that do several unrelated jobs and error messages that presuppose you already know the answer. If all you have is memorised incantations, the first time one of them fails you are stuck and frightened. If you understand the handful of ideas underneath — content addressing, an immutable graph of snapshots, and some movable pointers into it — then the incantations become obvious, the error messages become readable, and you can reason your way out of trouble you have never seen before.

That understanding is also the part that does not expire. The commands have changed over twenty years and will change again; `git switch` did not exist when this course was first written. The object model has not changed at all.

Enough talking, here we go!