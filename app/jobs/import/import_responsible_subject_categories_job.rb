module Import
  class ImportResponsibleSubjectCategoriesJob < ApplicationJob
    include ImportHelper

    def perform(responsible_subject:)
      records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
        ActiveRecord::Base.connection.exec_query("SELECT * FROM zodpovednost_kategorie WHERE id_zodpovednost = #{responsible_subject.id}")
      end

      records_array.each do |record|
        responsible_subject.categories.find_or_create_by(
          id: record['id'],
          issue_category_id: record['id_kategoria'],
        )
      end
    end
  end
end
