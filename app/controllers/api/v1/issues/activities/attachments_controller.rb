class Api::V1::Issues::Activities::AttachmentsController < ApiController
  # no token, the signed link was handed out by an authenticated request
  def show
    return render_forbidden unless ApiAttachmentSigner.valid?(params[:issue_id], params[:activity_id], params[:id], expires: params[:expires], signature: params[:signature])

    attachment = @zammad_client.download_attachment(params[:issue_id], params[:activity_id], params[:id])
    return render_not_found unless attachment

    # content type and disposition as triage sends them, send_data adds no charset
    response.headers["Content-Disposition"] = attachment[:content_disposition]
    send_data attachment[:body], type: attachment[:content_type], disposition: nil
  end
end
