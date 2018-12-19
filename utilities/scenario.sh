echo "\n---Start---\n"
rm -rf ~/projects/openclassrooms/my_first_git_project/.git
mkdir -p ~/projects/openclassrooms/my_first_git_project
cd ~/projects/openclassrooms/my_first_git_project
git status
echo "\n---P1C4 - Init repository---\n"
git init
git status
echo "\n---P1C4 -  Create file---\n"
echo "# Mon premier projet Git" > readme.md
git status
echo "\n--- P1C4 - Add file to index---\n"
git add readme.md
git status
echo "\n---P1C4 - Current directory structure of .git---\n"
tree -C .git
echo "\n--- P1C4 -  Commit file---\n"
GIT_AUTHOR_DATE="2018-10-11T06:06:51+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m"Added readme.md"
git status
echo "\n-- P1C4 - Modify file---\n"
echo "\nNous avons appris aujourd'hui les commandes Git suivantes:\n\n1. \`git init\` - initialiser un nouveau dépôt git\n2. \`git status\` - connaître l'état du répeetoire de travail par rapport au dépôt git\n3. \`git add\` - ajouter des fichiers à l'index git pour préparer un commit\n4. \`git commit -m\"{message de commit}\"\` - sauvegarder un point d'étape dans le dépôt git\n" >> readme.md
git status
echo "\n---  P1C4 - Add and commit file---\n"
git add readme.md
git status
GIT_AUTHOR_DATE="2018-10-11T06:10:30+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m"Add the list of commands we learnt today."
git status
echo "\n--- P1C4 -  Create LICENSE file---\n"
echo "Git Example by OpenClassRooms\n\nTo the extent possible under law, the person who associated CC0 with\nGit Example  has waived all copyright and related or neighboring rights\nto Git Example.\n\nYou should have received a copy of the CC0 legalcode along with this\nwork.  If not, see <http://creativecommons.org/publicdomain/zero/1.0/>." > LICENSE
git add LICENSE
GIT_AUTHOR_DATE="2018-10-11T06:15:42+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -am"Adding a license file"
git status
echo "\n--- P1C4 - Current directory structure of .git---\n"
tree -C .git
echo "\n--- P1C4 - All the objects in .git---\n"
git cat-file --batch-check --batch-all-objects
echo "\n--- P1C4 - All the objects in .git with their contents---\n"
git-objects-print-all

echo "\n--- P1C5 - Look at the tree---\n"

git ls-tree 563449f


echo "\n--- P1C5 -  Create a sub directory---\n"
mkdir files
git status
touch files/.gitkeep
git add files/.gitkeep
GIT_AUTHOR_DATE="2018-10-11T06:17:22+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m'add .gitkeep so files will be added to the repository'
git-objects-print-all


tree -C .git

git log --graph --pretty=format:'%C(yellow)%d%Creset %C(cyan)%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short --all

git ls-tree ea2abd3

git-object-read  97ebb0c791d8e7de9ce096a320ba9de098651719


echo "\n--- P1C6 -  Modify  README.MD file---\n"

git status
echo "\n---Add and commit file---\n"
echo "\n5. \`git log\` voir toutes les révisions" >> readme.md
GIT_AUTHOR_DATE="2018-10-11T06:15:30+01:00" GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE git commit -m"Add git log to the list of commands we learnt today."