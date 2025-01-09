module ImportHelper
  def self.with_another_db(db_config)
    original_connection = ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(db_config)
    yield
  ensure
    ActiveRecord::Base.establish_connection(original_connection)
  end
end
