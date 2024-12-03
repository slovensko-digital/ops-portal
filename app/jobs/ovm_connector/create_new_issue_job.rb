class OvmConnector::CreateNewIssueJob < ApplicationJob
  def perform(tenant, issue_id, zammad_client: OvmConnector::ApiEnvironment.zammad_client, ops_api_client: OvmConnector::OpsApiClient)
    client = ops_api_client.new(tenant)

    puts "------------ Hello World! ----------------------"
    # TODO
    # issue = client.get_issue(issue_id)

    # tmp_body = {
    #   state: issue[:state],
    #   # group: "Bratislava::Karlova ves",
    #   group: "Sečovce",
    #   title: ticket.title,
    #   customer_id: 11,
    #   triage_id: ticket.id,
    #   # anonymous: true, TODO: handle anonymous issues - email and name visible to triage zammad, invisible for municipality
    #   article: {
    #       internal: false,
    #       triage_id: 32,
    #       from: article.from,
    #       content_type: article.content_type,
    #       body: article.body,
    #       attachments: article.attachments
    #     }
    # }

    # new_ticket = zammad_client.ticket.create(
    #   tmp_body
    # )
  end
end
