echo "\n---Start---\n"
rm -rf ~/projects/openclassrooms/my_first_git_project/.git
mkdir -p ~/projects/openclassrooms/my_first_git_project
cd ~/projects/openclassrooms/my_first_git_project
git status
echo "\n---Init repository---\n"
git init
git status
echo "\n---Create file---\n"
echo "# Mon premier projet Git" > readme.md
git status
echo "\n---Add file to index---\n"
git add readme.md
git status
echo "\n---Current directory structure of .git---\n"
tree -C .git
echo "\n---Commit file---\n"
git commit -m"Added readme.md"
git status
echo "\n---Modify file---\n"
echo "\nNous avons appris aujourd'hui les commandes Git suivantes:\n\n1. `git init` - initialiser un nouveau dépôt git\n2. `git status` - connaître l'état du répeetoire de travail par rapport au dépôt git\n3. `git add` - ajouter des fichiers à l'index git pour préparer un commit\n4. `git commit -m"{message de commit}"` - sauvegarder un point d'étape dans le dépôt git\n" >> readme.md
git status
echo "\n---Add and commit file---\n"
git add readme.md
git status
git commit -m"Add the list of commands we learnt today."
git status
echo "\n---Create a second file---\n"
echo "Git Example by OpenClassRooms\n\nTo the extent possible under law, the person who associated CC0 with\nGit Example  has waived all copyright and related or neighboring rights\nto Git Example.\n\nYou should have received a copy of the CC0 legalcode along with this\nwork.  If not, see <http://creativecommons.org/publicdomain/zero/1.0/>." > LICENSE
git add LICENSE
git commit -am"Adding a license file"
git status
echo "\n---Current directory structure of .git---\n"
tree -C .git
echo "\n---All the objects in .git---\n"
git cat-file --batch-check --batch-all-objects
echo "\n---All the objects in .git with their contents---\n"
git-objects-print-all

echo "\n---Create a sub directory---\n"
mkdir files
git status
touch files/.gitkeep
git add files/.gitkeep
git commit -m'add .gitkeep so files will be added to the repository'
git-objects-print-all