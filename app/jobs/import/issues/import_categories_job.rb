module Import
  class Issues::ImportCategoriesJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name("alerts_categories")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          find_or_create_category_with_parent(legacy_record)
        end
      end
    end

    private

    def find_or_create_category_with_parent(legacy_record)
      legacy_parent_record = if legacy_record.parent.present?
        load_parent_record_data(legacy_record.parent)
      end

      find_or_create_category(legacy_record, legacy_parent_record)
    end

    def load_parent_record_data(record_id)
      return ::Issues::Category.find_by_id(record_id) if ::Issues::Category.find_by_id(record_id)

      record = Legacy::GenericModel.find_by_id(record_id)

      find_or_create_category_with_parent(record) if record
    end

    def find_or_create_category(legacy_record, legacy_parent_record)
      ::Issues::Category.find_or_initialize_by(
        id: legacy_record.id,
        catch_all: legacy_record.catch_all,
        category: legacy_record.kategoria,
        category_hu: legacy_record.kategoria_hu,
        category_alias: legacy_record.kategoria_alias,
        parent: legacy_parent_record
      ).tap do |issues_category|
        issues_category.description = legacy_record.popis.presence
        issues_category.description_hu = legacy_record.popis_hu.presence,
        issues_category.weight = legacy_record.weight,
        issues_category.save!
      end
    end
  end
end
