class UpdateIssuesIdSequence < ActiveRecord::Migration[8.0]
  def up
    execute "ALTER SEQUENCE issues_id_seq RESTART WITH 300000;"
  end
end
