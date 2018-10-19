#/bin/sh
# requirements: npm install -g markdown-toc
cat `find P*.md` | markdown-toc -
