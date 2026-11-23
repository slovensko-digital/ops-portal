class FixTypoInNefunkcneSubtype < ActiveRecord::Migration[8.1]
  # The current "Osvetlenie → osvetlenie" subtype was seeded as "nefunknčné" (ops#1346).
  # Triage matches subtypes by name, so ops-triage-zammad renames its option and tickets too.
  def up
    rename_subtype from: "nefunknčné", to: "nefunkčné"
  end

  def down
    rename_subtype from: "nefunkčné", to: "nefunknčné"
  end

  private

  def rename_subtype(from:, to:)
    execute <<~SQL
      UPDATE issues_subtypes
      SET name = #{quote(to)}, updated_at = NOW()
      WHERE name = #{quote(from)}
        AND legacy_id IS NULL
        AND subcategory_id IN (
          SELECT issues_subcategories.id
          FROM issues_subcategories
          JOIN issues_categories ON issues_categories.id = issues_subcategories.category_id
          WHERE issues_subcategories.name = 'osvetlenie'
            AND issues_categories.name = 'Osvetlenie'
            AND issues_categories.legacy_id IS NULL
        );
    SQL
  end
end
