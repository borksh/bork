# frozen_string_literal: true

# Warn when a PR is classed as work in progress
warn 'PR is classed as Work in Progress' if github.pr_title.downcase.include? '(wip)'

# Note when a PR cannot be manually merged, which goes away when you can
can_merge = github.pr_json['mergeable']
warn('This PR cannot be merged yet.', sticky: false) unless can_merge

labels_to_add = []
labels_to_add << 'enhancement' if github.pr_title.include? '(feature)'
labels_to_add << 'types' if github.pr_title.include? '(types)'
labels_to_add << 'bug' if github.pr_title.include? '(bug)'
labels_to_add << 'core' if github.pr_title.include? '(core)'
labels_to_add << 'documentation' if github.pr_title.include? '(docs)'
labels_to_add << 'packages' if github.pr_title.include? '(pkg)'
github.api.add_labels_to_an_issue github.pr_json[:base][:repo][:full_name], github.pr_json[:number], labels_to_add

if github.pr_labels.include? 'bot'
  message 'This PR is from a bot, and should be reviewed by a human as well!', sticky: true
end

# Note when PRs don't reference a milestone, which goes away when it does
has_milestone = github.pr_json['milestone'] != nil
warn 'This PR does not refer to an existing milestone', sticky: false unless has_milestone

# GitHub Review section
github.review.start

# Ensure there is a summary for a PR
github.review.fail 'Please provide a summary in the Pull Request description' if github.pr_body.length < 5

# Check that there are both app and test code changes for the main app
CHANGED_FILES = (git.added_files + git.modified_files).freeze
changed_app_files = CHANGED_FILES.select { |path| path =~ /^(bin|lib|types)/ }
if changed_app_files.any?
  changed_test_files = CHANGED_FILES.select { |path| path =~ /^test/ }
  if changed_test_files.empty?
    github.review.warn "Are you sure we don't need to add/update tests?"
  end
end

github.review.submit