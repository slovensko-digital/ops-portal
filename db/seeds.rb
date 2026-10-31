require_relative "seeds/categories"
require_relative "seeds/issue_states"

# start after legacy data
last_id = ActiveRecord::Base.connection.select_value("SELECT last_value FROM issues_id_seq")
if last_id < 300000
  ActiveRecord::Base.connection.execute "ALTER SEQUENCE issues_id_seq RESTART WITH 300000;"
end

if Rails.env.development?
  require_relative "seeds/ai_prompts"
  require_relative "seeds/cms_pages"
  require_relative "seeds/districts"
  require_relative "seeds/municipalities"
  require_relative "seeds/responsible_subjects"

  require_relative "seeds/users"
  require_relative "seeds/issues"
end
