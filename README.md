# GitHub Actions for CTF

To create CTF challenges for github workflows, we need an environment to run GitHub workflow privately for a user.

Steps:

1. Create an organization
2. Add challenges as repository. If possible, use one repository for all challenges, since each user will generate one repository and a limit of 500 repository per org will quickly come.
3. Set the challenge as a template in `settings/Template repository`.
4. Define flags as Organization secrets.
5. Use the github_challenge.sh script to generate a user challenge. It will create a repository and add the username as a outside collaborator.

Challenges should set timeout to not bust the 2000 min / month github action. https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idtimeout-minutes
