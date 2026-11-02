# The portal setup of a new municipality shared by BasicActivation and ProActivation: the municipality at its boundary
# in its district (kraj) and its responsible subject, both created inactive.
#
# use_existing_municipality, for local development only, takes the inactive municipality and responsible subject named
# NAME that the dev seeds create instead of creating them. The boundary and the district default to the municipality's own.
#
# Expects name, district_name, @boundary_id and @use_existing_municipality.
module ResponsibleSubjects::MunicipalitySetup
  RESPONSIBLE_SUBJECT_TYPE = "Mesto"

  def boundary
    @boundary ||= if @boundary_id.blank? && @use_existing_municipality
      MunicipalityBoundary.municipalities.find_by(municipality: existing_municipality) if existing_municipality
    else
      MunicipalityBoundary.find_by(id: @boundary_id)
    end
  end

  def district
    @district ||= if district_name.blank? && @use_existing_municipality
      existing_municipality&.district
    elsif district_name.present?
      District.where("lower(name) = lower(?)", district_name).first
    end
  end

  private

  def municipality_errors
    errors = []
    errors << "NAME is missing" if name.blank?

    if boundary.nil? && @boundary_id.blank? && @use_existing_municipality
      errors << "Municipality #{name} has no boundary, run municipality_boundaries:import_all or pass BOUNDARY_ID" if existing_municipality
    elsif boundary.nil?
      errors << "Municipality boundary #{@boundary_id.inspect} does not exist, find it in /admin/municipality_boundaries"
    elsif boundary.boundary_kind != "municipality"
      errors << "Municipality boundary #{boundary.id} is a #{boundary.boundary_kind}, only municipality boundaries are supported"
    elsif boundary.municipality.present? && !(@use_existing_municipality && boundary.municipality == existing_municipality)
      errors << "Municipality boundary #{boundary.id} already belongs to municipality #{boundary.municipality.name} (#{boundary.municipality_id})"
    end

    if name.present? && @use_existing_municipality
      errors.concat(existing_municipality_errors)
    elsif name.present?
      Municipality.where(name: name).find_each do |municipality|
        errors << "Municipality #{name} already exists (#{municipality.id}, active: #{municipality.active}, archived: #{municipality.archived}), " \
                  "activating it needs its archived issues restored, which this task does not do"
      end
      errors << "Responsible subject #{name} already exists" if ResponsibleSubject.exists?(subject_name: name)
    end
    errors << "Responsible subject type #{RESPONSIBLE_SUBJECT_TYPE} does not exist" unless responsible_subjects_type
    errors << "District #{district_name.inspect} does not exist, use one of: #{District.order(:name).pluck(:name).join(", ")}" unless district

    errors
  end

  def existing_municipality_errors
    return [ "Municipality #{name} does not exist, EXISTING_MUNICIPALITY activates only an existing one" ] unless existing_municipality

    errors = []
    errors << "Municipality #{name} is already active" if existing_municipality.active?
    errors << "Municipality #{name} is archived" if existing_municipality.archived?
    if district && existing_municipality.district != district
      errors << "Municipality #{name} is in district #{existing_municipality.district&.name}, not #{district.name}"
    end

    if existing_responsible_subject.nil?
      errors << "Responsible subject #{name} of municipality #{name} does not exist"
    else
      errors << "Responsible subject #{name} is already active" if existing_responsible_subject.active?
      errors << "Responsible subject #{name} already has Triage user #{existing_responsible_subject.external_id}" if existing_responsible_subject.external_id.present?
    end

    errors
  end

  def existing_municipality
    @existing_municipality ||= Municipality.find_by(name: name) if name.present?
  end

  def existing_responsible_subject
    @existing_responsible_subject ||= ResponsibleSubject.find_by(subject_name: name, municipality: existing_municipality, municipality_district: nil) if existing_municipality
  end

  # the inactive municipality and responsible subject, existing or created
  def prepare_portal_records(email:, pro:)
    @use_existing_municipality ? prepare_existing_portal_records(email:, pro:) : create_portal_records(email:, pro:)
  end

  def prepare_existing_portal_records(email:, pro:)
    ActiveRecord::Base.transaction do
      boundary.update!(municipality: existing_municipality)
      existing_responsible_subject.update!(email: email, pro: pro)
      @log.call("Portal: existing municipality #{existing_municipality.id} and responsible subject #{existing_responsible_subject.id}, both inactive")

      [ existing_municipality, existing_responsible_subject ]
    end
  end

  def create_portal_records(email:, pro:)
    ActiveRecord::Base.transaction do
      latitude, longitude = point_on_boundary
      municipality = Municipality.create!(name: name, district: district, latitude: latitude, longitude: longitude, active: false)
      boundary.update!(municipality: municipality)

      responsible_subject = ResponsibleSubject.create!(
        subject_name: name,
        email: email,
        municipality: municipality,
        responsible_subjects_type: responsible_subjects_type,
        pro: pro,
        active: false
      )
      @log.call("Portal: municipality #{municipality.id} at #{latitude}, #{longitude}, responsible subject #{responsible_subject.id}, both inactive")

      [ municipality, responsible_subject ]
    end
  end

  # a point inside the boundary, unlike its centroid, which lies outside of a C shaped municipality
  def point_on_boundary
    MunicipalityBoundary.where(id: boundary.id)
      .pick(Arel.sql("ST_Y(ST_PointOnSurface(boundary))"), Arel.sql("ST_X(ST_PointOnSurface(boundary))"))
  end

  def responsible_subjects_type
    @responsible_subjects_type ||= ResponsibleSubjects::Type.find_by(name: RESPONSIBLE_SUBJECT_TYPE)
  end
end
