class ConvertAgentAndResponsibleSubjectHtmlCommentsToPlainText < ActiveRecord::Migration[8.0]
  def up
    target_types = %w[Issues::AgentComment Issues::AgentPrivateComment Issues::ResponsibleSubjectComment]

    Issues::Comment.where(type: target_types).where(legacy_data: nil).find_each do |comment|
      next if comment.text.blank?
      next unless comment.text.include?('<') && comment.text.include?('>')

      comment.update_column(:text, Html2Text.convert(comment.text))
    end
  end
end
