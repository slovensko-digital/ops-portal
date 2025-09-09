# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def new_issue_user_comment
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).new_issue_user_comment(Issues::UserComment.last)
  end

  def new_issue_agent_comment
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).new_issue_user_comment(Issues::AgentComment.last)
  end

  def new_issue_responsible_subject_comment
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).new_issue_responsible_subject_comment(Issues::ResponsibleSubjectComment.last)
  end

  def new_issue_update
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).new_issue_update
  end

  def new_issue_verification
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).new_issue_verification
  end

  def issue_accepted
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).issue_accepted
  end

  def issue_marked_as_duplicate
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).issue_marked_as_duplicate
  end

  def issue_unresolved
    issue = Issue.publicly_visible.last
    subscription = issue.subscriptions.where.not(subscriber: issue.author).first
    NotificationMailer.with(
      subscription: subscription
    ).issue_unresolved
  end

  def issue_unresolved_owner
    issue = Issue.publicly_visible.last
    issue.author.subscribe_to(issue) unless issue.author.subscribed_to?(issue)
    NotificationMailer.with(
      subscription: issue.author.issue_subscriptions.where(issue: issue).first
    ).issue_unresolved
  end

  def issue_resolved
    issue = Issue.publicly_visible.last
    subscription = issue.subscriptions.where.not(subscriber: issue.author).first
    NotificationMailer.with(
      subscription: subscription
    ).issue_resolved
  end

  def issue_resolved_owner
    issue = Issue.publicly_visible.last
    issue.author.subscribe_to(issue) unless issue.author.subscribed_to?(issue)
    NotificationMailer.with(
      subscription: issue.author.issue_subscriptions.where(issue: issue).first
    ).issue_resolved
  end

  def issue_referred
    issue = Issue.publicly_visible.last
    subscription = issue.subscriptions.where.not(subscriber: issue.author).first
    NotificationMailer.with(
      subscription: subscription
    ).issue_referred
  end

  def issue_referred_owner
    issue = Issue.publicly_visible.last
    issue.author.subscribe_to(issue) unless issue.author.subscribed_to?(issue)
    NotificationMailer.with(
      subscription: issue.author.issue_subscriptions.where(issue: issue).first
    ).issue_referred
  end

  def issue_closed
    issue = Issue.publicly_visible.last
    subscription = issue.subscriptions.where.not(subscriber: issue.author).first
    NotificationMailer.with(
      subscription: subscription
    ).issue_closed
  end

  def issue_closed_owner
    issue = Issue.publicly_visible.last
    issue.author.subscribe_to(issue) unless issue.author.subscribed_to?(issue)
    NotificationMailer.with(
      subscription: issue.author.issue_subscriptions.where(issue: issue).first
    ).issue_closed
  end

  def issue_rejected
    NotificationMailer.with(
      subscription: IssueSubscription.last
    ).issue_rejected
  end

  def praise_accepted
    issue = Praise.last
    subscription = issue.subscriptions.first
    NotificationMailer.with(
      subscription: subscription
    ).praise_accepted
  end

  def praise_rejected
    issue = Praise.last
    subscription = issue.subscriptions.first
    NotificationMailer.with(
      subscription: subscription
    ).issue_rejected
  end
end
