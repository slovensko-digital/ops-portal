class Issues::SystemResponsibleSubjectChangeActivity < Issues::Activity
  has_one :activity_object, class_name: "Issues::SystemResponsibleSubjectChange", foreign_key: :activity_id, dependent: :destroy
end
