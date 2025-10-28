class Api::V1::ResponsibleSubjectsController < ActionController::API
  def index
    @responsible_subjects = ResponsibleSubject.active.all
  end

  def search
    @responsible_subjects = ResponsibleSubject.active.search(params[:q]).limit(5)
  end
end
