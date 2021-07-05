#!/bin/bash
#set -o nounset
#set -x

help ()
{ 
  echo "Usage: 
  Will submit a PR for all Globalization Partners Nextgen services and UI's.  Good for use when needing to prep merges to various environments.
  Make sure you have the Github CLI installed: https://cli.github.com/
  Flags below follow the same flags as the Github CLI but will
  -d,--dry-run  Dry run the command
  -t,--title    The title of the PR
  -b,--body     The body of the PR
  -r,--reviewer The reviewers for the PR in a comma separated list (no spaces).  A default list will be used if none is provided
  -B,--base     The base (destination) branch of the PR
  -H,--head     The head (source) branch of the PR
  example command: ./submit-prs.sh --title \"test script\" --body \"test body\" --head env/nextgen-dev --base develop --dry-run
  Check the output and remove `--dry-run` to execute creating the PR's.
  "
  exit 0
}

# default list of reviewers
reviewer='lshaw-gp'

repo_prefix='nuncnihil'
repos=(
  # you can add more repos here!
  'test-repo'
)

while [ $# -gt 0 ] ; do
  case $1 in
    -h | --help) help ;;
    -r | --reviewer) reviewer="$2" ;;
    -t | --title) title="$2" ;;
    -b | --body) body="$2" ;;
    -B | --base) base="$2" ;;
    -H | --head) head="$2" ;;
    -d | --dry-run) dry_run="true" ;;
  esac
  shift
done

if [[ -z "$title" || -z "$body" || -z "$base" || -z "$head" ]]; then
  echo "Must provide a title, body, base and head argument.  See --help for details."
  exit 1
fi

if ! command -v gh &> /dev/null
then
    echo "Github CLI could not be found. Please install it: https://cli.github.com"
    exit
fi


echo "Submitting Pull Requests from ${head} to ${base} for repos ..."
for repo in ${repos[@]}; do
  echo -e "${repo}"
  command="gh pr create --title \"${title}\" --body \"${body}\" --base ${base} --head ${head} --repo ${repo_prefix}/${repo} --reviewer ${reviewer}"
  if [[ $dry_run == "true" ]]; then
    echo -e "\tCommand to be run: "
    echo -e "\t\t ${command}"
  else
    echo -e "\tRunning: "
    echo -e "\t\t ${command}"
    eval $command
  fi
done