class AddDuplicateIssueState < ActiveRecord::Migration[8.0]
  def up
    Issues::State.find_or_create_by!(key: 'duplicate').tap do |issues_state|
      issues_state.update(name: "Duplicitný")
    end
  end

  def down
    Issues::State.find_by(key: 'duplicate')&.destroy
  end
end
