
OLD=$1
NEW=$2

git grep -l "$OLD" | xargs sed -i "s/$OLD/$NEW/"
