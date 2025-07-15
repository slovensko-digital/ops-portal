module EditableWithinEditingWindow
  extend ActiveSupport::Concern

  included do
    validate :edited_within_editing_window, on: :edit
  end

  def editing_window_end
    created_at + ENV.fetch("COMMENT_EDITING_WINDOW_SECONDS", 300).to_i # TODO
  end

  def within_editing_window?
    Time.now < editing_window_end
  end

  def edited_within_editing_window
    errors.add(:base, "Komentár je možné upravovať len 5 minút od jeho vytvorenia.") unless within_editing_window?
  end
end
