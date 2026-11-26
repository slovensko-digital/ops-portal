module EditableWithinEditingWindow
  extend ActiveSupport::Concern

  included do
    validate :edited_within_editing_window, on: :edit

    before_update -> { self.last_edited_at = Time.current }, if: :content_changed?
  end

  def self.editing_window_seconds
    ENV.fetch("COMMENT_EDITING_WINDOW_SECONDS", 300).to_i
  end

  def content_changed?
    will_save_change_to_text? || attachment_changes["attachments"].present?
  end

  def editing_window_end
    created_at + EditableWithinEditingWindow.editing_window_seconds
  end

  def within_editing_window?
    Time.now < editing_window_end
  end

  def edited_within_editing_window
    errors.add(:base, I18n.t("errors.messages.outside_editing_window", duration: editing_window_duration)) unless within_editing_window?
  end

  private

  def editing_window_duration
    seconds = EditableWithinEditingWindow.editing_window_seconds

    if seconds % 60 == 0
      I18n.t("errors.editing_window.minutes", count: seconds / 60)
    else
      I18n.t("errors.editing_window.seconds", count: seconds)
    end
  end
end
