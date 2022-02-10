##!/bin/angel_db_machine
# echo "\n---Start---\n"
rm -rf ~/projects/my_first_git_project/
#-------------------------------------------------------------------------------
#begin: p1c3_1
echo "\n---P1C3 - Create empty directory---\n"
mkdir -p ~/projects/my_first_git_project
cd ~/projects/my_first_git_project
git status
#expect: not a git repository
#-------------------------------------------------------------------------------
#begin: p1c4_1
echo "\n---P1C4 - Init repository---\n"
git init
git status
#begin: p1c4_2
echo "\n---P1C4 -  Create file---\n"
echo "# Mon premier projet Git" > readme.md
git status
#begin: p1c4_3
echo "\n--- P1C4 - Add file to index---\n"
git add readme.md
git status
#begin: p1c4_4
echo "\n---P1C4 - Current directory structure of .git---\n"
tree -C .git
#begin: p1c4_5
echo "\n--- P1C4 -  Commit file---\n"
GIT_AUTHOR_DATE="2018-10-11T06:06:51+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m"Added readme.md"
git status
#begin: p1c4_6
echo "\n-- P1C4 - Modify file---\n"
echo "\nNous avons appris aujourd'hui les commandes Git suivantes:\n\n1. \`git init\` - initialiser un nouveau dépôt git\n2. \`git status\` - connaître l'état du répeetoire de travail par rapport au dépôt git\n3. \`git add\` - ajouter des fichiers à l'index git pour préparer un commit\n4. \`git commit -m\"{message de commit}\"\` - sauvegarder un point d'étape dans le dépôt git\n" >> readme.md
git status
#begin: p1c4_7
echo "\n---  P1C4 - Add and commit file---\n"
git add readme.md
git status
GIT_AUTHOR_DATE="2018-10-11T06:10:30+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m"Add the list of commands we learned today."
git status
#begin: p1c4_8
echo "\n--- P1C4 -  Create LICENSE file---\n"
echo "Git Example by OpenClassRooms\n\nTo the extent possible under law, the person who associated CC0 with\nGit Example  has waived all copyright and related or neighboring rights\nto Git Example.\n\nYou should have received a copy of the CC0 legalcode along with this\nwork.  If not, see <http://creativecommons.org/publicdomain/zero/1.0/>." > LICENSE
git add LICENSE
GIT_AUTHOR_DATE="2018-10-11T06:15:42+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -am"Adding a license file"
git status
#begin: p1c4_9
echo "\n--- P1C4 - Current directory structure of .git---\n"
tree -C .git
#begin: p1c4_10
echo "\n--- P1C4 - All the objects in .git---\n"
git cat-file --batch-check --batch-all-objects
#begin: p1c4_11
echo "\n--- P1C4 - All the objects in .git with their contents---\n"
git-objects-print-all
#begin: p1c5_1
echo "\n--- P1C5 - Look at the tree---\n"
git ls-tree 563449f
#begin: p1c5_2
echo "\n--- P1C5 -  Create a sub directory---\n"
mkdir files
git status
touch files/.gitkeep
git add files/.gitkeep
GIT_AUTHOR_DATE="2018-10-11T06:17:22+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m'Add .gitkeep so files will be added to the repository'
git-objects-print-all
tree -C .git
git log --graph --pretty=format:'%C(yellow)%d%Creset %C(cyan)%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short --all
git ls-tree ea2abd3
git-object-read  97ebb0c791d8e7de9ce096a320ba9de098651719
#begin: p1c6_2
echo "\n--- P1C6 -  Modify  README.MD file---\n"
git status
echo "\n---Add and commit file---\n"
echo "\n5. \`git log\` voir toutes les révisions" >> readme.md
GIT_AUTHOR_DATE="2018-10-11T06:15:30+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -am"Add git log to the list of commands we learned today."
#begin: p1c7_1
echo "\n--- P1C6 -  Delete file---\n"
rm LICENSE
git status
git add LICENSE
GIT_AUTHOR_DATE="2018-10-11T06:15:35+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m"Remove license file"
echo "\n--- P1C6 -  Delete file with git rm---\n"
#begin: p1c6_2
git reset --hard HEAD~1
git rm LICENSE
GIT_AUTHOR_DATE="2018-10-11T06:15:35+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE  git commit -m"Remove license file"
#begin: p1c6_3
git mv files media
GIT_AUTHOR_DATE="2018-10-11T06:15:40+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m'Rename files to media'

echo "\n--- P1C7 -  See the past---\n"
#begin: p1c7_1
alias lg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%<(45,trunc)%s%C(reset) %C(dim white)- %<(20,trunc)%an %C(reset)%C(bold yellow)%d%C(reset)' --all"
sleep 1
clear
#git reset --hard 5e8354a; lg; sleep 1; clear
#git reset --hard ee67d49; lg; sleep 1; clear
#git reset --hard 20f8655; lg; sleep 1; clear
#git reset --hard 08452bf; lg; sleep 1; clear
#git reset --hard 4283beb; lg; sleep 1; clear
#git reset --hard b46b3c3; lg; sleep 1; clear
#git reset --hard 1d51e3f; lg; sleep 1; clear
lg
echo "\n--- P1C7 -  git reset ---\n"
git reset HEAD~5
git add readme.md
GIT_AUTHOR_DATE="2018-10-11T06:15:40+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m'Add git log to the list of commands we learned'
git add media
GIT_AUTHOR_DATE="2018-10-11T06:15:45+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m'Add media diretory with .gitkeep'

echo "\n--- P2C1 -  git checkout ---\n"
#begin: p2c1_1
git checkout -b"shopping_cart"
#begin: p2c1_2
git reflog
#begin: p2c1_3
git checkout "shopping_cart"
mkdir -p lib
touch lib/shopping_cart.js
git add .
git commit -am'Initial shopping cart code'
git checkout -b "shopping_cart_template"
mkdir -p views
touch views/shopping_cart.html
git add .
git commit -am'Implement shopping cart template'
git checkout "master"
git checkout -b "homepage"
mkdir -p views
touch views/homepage.html
git add .
git commit -am'Implement homepage template'