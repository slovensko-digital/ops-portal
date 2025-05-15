class AddResolvedPrivateIssuesType < ActiveRecord::Migration[8.0]
  def up
    Issues::State.find_or_initialize_by(key: "resolved_private").tap do |state|
      state.name = "Vyriešený (skrytý)"
      state.color = "#4BA50A"
    end.save!
  end

  def down
    Issues::State.find_by(key: "resolved_private")&.destroy
  end
end
