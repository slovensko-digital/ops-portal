module Import
  class ImportIssueCategoriesJob < ApplicationJob
    include ImportHelper

    def perform(batch_size: 100)
      0.step do |offset|
        records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
          ActiveRecord::Base.connection.exec_query("SELECT * FROM alerts_categories LIMIT #{batch_size} OFFSET #{offset * batch_size}")
        end

        records_array.each do |record|
          find_or_create_category_with_parent(record)
        end

        break if records_array.count < batch_size
      end
    end

    private

    def find_or_create_category_with_parent(record)
      parent_record = if record['parent'].present?
        load_parent_record_data(record['parent'])
      end

      find_or_create_category(record, parent_record)
    end

    def load_parent_record_data(record_id)
      return Issue::Category.find_by_id(record_id) if Issue::Category.find_by_id(record_id)

      record = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
        ActiveRecord::Base.connection.exec_query("SELECT * FROM alerts_categories WHERE id = #{record_id}")
      end.first

      find_or_create_category_with_parent(record) if record
    end

    def find_or_create_category(record, parent_record)
      ::Issue::Category.find_or_create_by(
        id: record['id'],
        catch_all: record['catch_all'],
        category: record['kategoria'],
        category_hu: record['kategoria_hu'],
        category_alias: record['kategoria_alias'],
        description: record['popis'].presence,
        description_hu: record['popis_hu'].presence,
        weight: record['weight'],
        parent: parent_record
      )
    end
  end
end
