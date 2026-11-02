require "test_helper"

class EditableWithinEditingWindowTest < ActiveSupport::TestCase
  setup do
    @update = Issues::Update.new(text: "Pôvodný text", author: users(:one), published: true, legacy_id: 1)
    @update.build_activity(issue: issues(:two), type: Issues::UpdateActivity)
    @update.save!
  end

  test "changing the text marks the record as edited" do
    @update.update!(text: "Nový text")

    assert @update.edited?
    assert_not_nil @update.last_edited_at
  end

  test "changing something else than content does not mark the record as edited" do
    @update.update!(hidden: true)

    assert_not @update.edited?
  end

  test "editing is allowed only within the editing window" do
    assert @update.within_editing_window?
    @update.text = "Nový text"
    assert @update.valid?(:edit)

    travel 6.minutes do
      assert_not @update.within_editing_window?
      assert_not @update.valid?(:edit)
      assert_includes @update.errors[:base], "Komentár je možné upravovať len 5 minút od jeho vytvorenia."
    end
  end

  test "the error message reflects the configured editing window" do
    original_window = ENV["COMMENT_EDITING_WINDOW_SECONDS"]
    @update.text = "Nový text"

    travel 1.hour do
      { "60" => "1 minútu", "120" => "2 minúty", "10" => "10 sekúnd", "1" => "1 sekundu" }.each do |seconds, duration|
        ENV["COMMENT_EDITING_WINDOW_SECONDS"] = seconds

        assert_not @update.valid?(:edit)
        assert_includes @update.errors[:base], "Komentár je možné upravovať len #{duration} od jeho vytvorenia."
      end
    end
  ensure
    ENV["COMMENT_EDITING_WINDOW_SECONDS"] = original_window
  end
end
