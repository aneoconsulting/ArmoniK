
OLD=$1
NEW=$2

git grep -l "" | xargs sed -i "s/$OLD/$NEW/"
