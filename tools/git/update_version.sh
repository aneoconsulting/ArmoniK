#! /bin/sh

# ArmoniK Version Update Script
#
# Purpose:
# This script performs a global search and replace operation across the entire
# git repository to update version strings. It uses git grep to find all files
# containing the old version string and sed to replace it with the new version.
#
# Usage:
# ./update_version.sh OLD_VERSION NEW_VERSION
#
# Parameters:
# - OLD_VERSION: The current version string to be replaced
# - NEW_VERSION: The new version string to replace with
#
# Process:
# 1. Uses git grep to find all files containing the old version string
# 2. Pipes the results to xargs and sed to perform in-place replacement
# 3. Updates all occurrences across the repository
#
# Requirements:
# - Must be run from within a git repository
# - sed command must be available
# - Proper file permissions for modification

OLD="$1"
NEW="$2"

git grep -l "$OLD" | xargs sed -i "s/$OLD/$NEW/"