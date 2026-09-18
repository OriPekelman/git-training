---
title: What is Git?
slug: "what-is-git"
weight: 1
---
# What is Git?

Hello and welcome. This course begins with a very simple observation: if you want to have a job in IT, no matter which one, knowing Git is not optional; Git is used everywhere.

First, a word on the subject, then a little explanation on the "why".

At the highest level, we can say that Git is a software that allows saving code. This is the absolute standard in the field: the one and only way to do your ctrl-s (or cmd-s).

You can learn HTML and CSS (to create web pages), scripting languages like Python, Ruby or PHP (to build web applications), C or Rust (to create your own operating system)... But without a minimum knowledge of Git, you have not really learned how to save your work.

Of course, if all it could do was backup, it would be the weirdest, most complicated backup function in the world, and you'd be right in deciding that computing is for lunatics after all.

In reality, it's something much more powerful: Git allows you to save your work, keeping all the intermediate steps of its development. Imagine a "ctrl-z" that works forever, after turning off one's machine... that works even when you switch to another computer. That's powerful.

> We will come back to this... but keep in mind a first technical word: "commit". It is the recording of a state of your code, of a version, of a single change.

But Git is of course much stronger than that, it not only allows us to have a full history of changes and how to restore any time in the past.. it also allows us to have multiple different versions of the same work, at the same time. To have two, three, a thousand avenues of exploration, to be able to switch from one to the other, to borrow a piece of idea from here, then a piece from there and thus compose your main version.

> Two other technical words. First the "branch": a version of your work, of your code which can live in the same way as other versions. Then "merge", the ability to bring or "mix" changes made in one branch into another.

Finally — and this is perhaps the most wonderful thing about Git, the deep reason why you should take this course seriously — Git does not only save your own work, it also gives you access to everyone else's. It lets you have not just multiple versions of your code, but multiple people each with their own versions, their own tracks... and to build out of all that a single `main` version.

> :information_source:
> Historically this branch was called **master**. GitHub and GitLab now name it **main** in new repositories, for cultural reasons, and most projects started in the last few years follow suit. Your own `git init`, however, still creates **master** unless you configure it otherwise — we'll show you how in [Playing with our revisions](7-play-with-git-revisions.md "Playing with our revisions").

Git enables collaboration on an unprecedented scale; thousands, if not hundreds of thousands of contributors who work together to create a unique work. Indeed Git is what is called a "distributed version control system". Basically you can save your work locally, but also push your code to another computer which will then have its own independent copy of the same project.

> Last four technical words for this introduction: the **repository** is the warehouse, the directory that will contain the project code, then the "remote", which is the address of a remote repository (on a server on the internet for example, like GitHub) which will contain a separate copy of the same project. To **push** is to send our code to the **remote**. The **pull** command allows us, conversely, to download code from a remote repository to our local machine.

At the very beginning, I stated that knowledge of Git is not optional, and here's why: nobody works alone in their own corner. And the way we work together today in the IT industry is entirely centred on this system that lets us collaborate on building our creations.

Git is young: it was created in 2005, so as of today it is about twenty years old. In those two decades it has established itself as the major source code management system, THE standard. Of course, there were similar systems before it (CVS, Subversion, Visual SourceSafe); they have largely disappeared — SourceSafe has not been supported by Microsoft for well over a decade, and CVS is a museum piece. Subversion is still alive in a few corners, mostly where very large binary assets are involved.

Some non-Git systems are still genuinely in use: Mercurial never died, and it still runs at a few very large shops — Meta's **Sapling** grew out of that lineage. Bazaar, on the other hand, is effectively finished. And there is real new work happening: **Jujutsu** (`jj`) and **Pijul** are the interesting modern challengers, and tellingly Jujutsu can use an ordinary Git repository as its storage, so you can try it on a real project without converting anything. We come back to all of this in [Things inspired by Git](../4-beyond-the-basics/6-inspired-by-git.md "Things inspired by Git").

Then there are people who tinker with their own little systems (copying and renaming code directories into backup1, backup2, bk17 using Dropbox, why not a little FTP file server) but these can no longer hope to find a job in the field or advance in their career.