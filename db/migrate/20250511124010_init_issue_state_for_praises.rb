class InitIssueStateForPraises < ActiveRecord::Migration[8.0]
  def up
    waiting_state = Issues::State.find_by!(key: "waiting")

    Praise.where(state_id: nil).update_all(state_id: waiting_state.id)
  end

  def down
  end
end
