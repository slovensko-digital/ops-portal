module Import
  class Issues::ImportCategoriesJob < ApplicationJob
    def perform
      import_categories!
      import_subcategories!
      import_subtypes!
    end

    private

    def import_categories!
      Legacy::Alerts::Category.where(parent: nil).find_in_batches do |group|
        group.each do |legacy_record|
          ::Issues::Category.find_or_create_by!(
            legacy_id: legacy_record.id,
            catch_all: legacy_record.catch_all == true,
            description: legacy_record.popis.presence,
            description_hu: legacy_record.popis_hu.presence,
            name: legacy_record.kategoria,
            name_hu: legacy_record.kategoria_hu,
            weight: legacy_record.weight,
            alias: legacy_record.kategoria_alias
          )
        end
      end
    end

    def import_subcategories!
      Legacy::Alerts::Category.joins("INNER JOIN alerts_categories AS pc ON alerts_categories.parent = pc.id")
        .where("pc.parent IS NULL")
        .where.not(parent: nil)
        .find_in_batches do |group|
        group.each do |legacy_record|
          ::Issues::Subcategory.find_or_create_by!(
            legacy_id: legacy_record.id,
            catch_all: legacy_record.catch_all,
            description: legacy_record.popis.presence,
            description_hu: legacy_record.popis_hu.presence,
            name: legacy_record.kategoria,
            name_hu: legacy_record.kategoria_hu,
            weight: legacy_record.weight,
            alias: legacy_record.kategoria_alias,
            category: ::Issues::Category.find_by(legacy_id: legacy_record.parent)
          )
        end
      end
    end

    def import_subtypes!
      Legacy::Alerts::Category.joins("INNER JOIN alerts_categories AS pc ON alerts_categories.parent = pc.id")
        .where("pc.parent IS NOT NULL")
        .find_in_batches do |group|
        group.each do |legacy_record|
          ::Issues::Subtype.find_or_create_by!(
            legacy_id: legacy_record.id,
            catch_all: legacy_record.catch_all,
            description: legacy_record.popis.presence,
            description_hu: legacy_record.popis_hu.presence,
            name: legacy_record.kategoria,
            name_hu: legacy_record.kategoria_hu,
            weight: legacy_record.weight,
            alias: legacy_record.kategoria_alias,
            subcategory: ::Issues::Subcategory.find_by(legacy_id: legacy_record.parent)
          )
        end
      end
    end
  end
end
