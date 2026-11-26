# Snapshots of the prompt edited in the prompt playground, see Admin::PromptTestCasesController.
class Admin::PromptSnapshotsController < ApplicationController
  def create
    snapshot = Ai::PromptSnapshot.take(
      # browsers send textarea newlines as CRLF in form data, the prompt box uses LF
      content: params.require(:content).gsub("\r\n", "\n"),
      reason: params.require(:reason),
      note: params[:note],
      author: (current_user if current_user.is_a?(User))
    )
    return head :no_content unless snapshot

    render turbo_stream: turbo_stream.prepend("prompt_snapshots", partial: "admin/prompt_test_cases/snapshot", locals: { snapshot: })
  end

  def show
    snapshot = Ai::PromptSnapshot.find(params[:id])

    render json: { content: snapshot.content, label: helpers.prompt_snapshot_label(snapshot) }
  end
end
