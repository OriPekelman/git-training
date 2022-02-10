#### Initialize your first git repository: `git init`

We are now going to do something remarkable: we are going to create our first Git repository. And like me, I don't really like black magic, we will immediately try to understand what we have done. In a few minutes you will acquire some rare and amazing knowledge and you could go and show off with your friends.
 
On my computer, I store my projects in my user folder under `projects`, and since we are on OpenClassRooms I will create a sub-directory of this name. It's important to put things in order. We will create a directory inside for our first project, which we will name "my_first_git_project".

> :warning:
> Note, that even if this course is in French and I am very attached to our language, technical things (like file names) will be named in shopping_cart. This avoids "frshopping_cart" and French without accent. This too often allows us to collaborate more easily with others.

Open your terminal emulator.

We will type the command:
```console
mkdir -p ~/projects/my_first_git_project
```

`mkdir` is a command to create directories (we assume here that Windows users will have followed the installation guide noted above and opted for the _Windows Subsystem for Linux_). The little `~` tilde you see there represents the current user's home folder, in my case it's going to be `/Users/oripekelman/`). And we will create the `projects/my_first_git_project` subdirectory. The `-p` option assures us that the command will succeed even if `projects` does not exist.

We will change the current directory to reach the folder created above, so type:

```console
cd ~/projects/my_first_git_project
```

We have a very fine, very new, very clean repertoire. This will be our working directory. Remember in shopping_cart: **Working Directory**. If this was a real small code project our source code would live here.

Git, as you have been told, is software. To use it, you type `git` on the command line and then sub-commands (which quite often will themselves have arguments and options). But our first command is simple:

```console
git init
```

If life is good and you have successfully installed git the response should be:

`Initialized empty Git repository in /Users/oripekelman/projects/my_first_git_project/.git/`

And in French: "Empty Git repository initialized in /Users/oripekelman/projects/my_first_git_project/.git/"

> :information_source:
> If in the directory we type the command `ls` to list the files it will tell us that there is absolutely nothing. Indeed in systems like Linux and OS X the files and directories starting with `.` are hidden. You can type `ls -a`; you should see it.

Let's explain what just happened: The `git init` command created a hidden subdirectory named `.git` in our working directory. This will contain all the information Git will need to help us save our work, track releases, and collaborate with others.