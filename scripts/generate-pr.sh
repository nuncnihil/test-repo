#!/bin/bash
#set -o nounset
#set -x

help ()
{ 
  echo "Usage: 
  Will submit a PR for all Globalization Partners Nextgen services and UI's.  Good for use when needing to prep merges to various environments.
  Make sure you have the Github CLI installed: https://cli.github.com/
  Flags below follow the same flags as the Github CLI but will
  -a,--auto     Aotogenerated PR message
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
  'AdvancedReactRedux'
  'bathtime'
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
    -a | --auto) auto="true" ;;
    -n | --release) release="$2" ;;
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
  gh api repos/${repo_prefix}/${repo}/labels -f name="sync-pr ${release}" -f color='FBCA04'
  command="gh pr create --title \"${title}\" --body \"${body}\" --head ${head} --base ${base} --repo ${repo_prefix}/${repo} --label \"sync-pr ${release}\""
  if [[ $dry_run == "true" ]]; then
    echo -e "\tCommand to be run: "
    echo -e "\t\t ${command}"
  else
    echo -e "\tRunning: "
    echo -e "\t\t ${command}"
    eval $command
    process_id=$!
    echo "PID: $process_id"

#   fi
# done

if [[ $auto == "true" ]]; then 
  allPR=()
 echo "Generating PRs for release: ${release}"
  echo "Listing Pull Requests for all repos from ${head} to ${base}"
  for repo in ${repos[@]}; do
    list="gh api -X GET search/issues -F per_page=100 --paginate -f q='repo:${repo_prefix}/${repo} is:open' --jq '.items[] | select(.labels[].name | endswith(\"sync-pr ${release}\")) | [.html_url] | @tsv'"
    pr_list=$(eval "$list")
    prNumber="$( echo "${pr_list}" |sed 's/.*\///')"
    reviewer="gh api /repos/${repo_prefix}/${repo}/pulls/${prNumber}/requested_reviewers --jq '.users[] | [.login] | @tsv'"
    pr_reviewer=$(eval "$reviewer")

    if [ -z "$pr_list" ]; then
      echo "Empty"
      message="${repo_prefix}/${repo} has no changes to merge\r"
      allPR+=(  "$message" ) 
      final_list=${allPR[@]}
    else
      message="<$( echo $pr_list)> codeOwners: $( echo $pr_reviewer) \r"
      allPR+=(  "$message" ) 
      final_list=${allPR[@]}
    fi
  done


  cmd=$(curl -X POST --data-urlencode "payload={
    "attachments":[
        {
          \"fallback\":\"@here\",
          \"pretext\":\"@here\",
          \"color\":\"#D00000\",
          \"fields\":[
              {
                \"title\":\"$body\",
                \"value\":\"$final_list\",
                \"short\":false
              }
          ]
        }
    ]
  }" ${SLACK})
fi

