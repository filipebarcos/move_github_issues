require "move_github_issues/version"
require "octokit"
require "pry"

class MoveGithubIssues

  def initialize(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    @client = Octokit::Client.new(access_token: access_token)
    @user = @client.user
    @user.login
    @issues = []
  end

  def from(org:, repo:)
    page = 1
    begin
      issues = @client.list_issues("#{org}/#{repo}", page: page)
      @issues << issues
      page += 1
    end while !issues.empty?
    @issues.flatten!
    self
  end

  def to(org:, repo:)
    @issues.each do |issue|
      create_issue(org, repo, issue)
    end
  end

  def create_issue(org, repo, issue)
    @client.create_issue(
      "#{org}/#{repo}",
      issue.title,
      "#{issue.body}\r\n\r\n This issue replaces issue: #{issue.html_url}",
      {
        assignee: issue.assignee && issue.assignee.login,
        labels: issue.labels.map(&:name).join(',')
      }
    )
  end
end
