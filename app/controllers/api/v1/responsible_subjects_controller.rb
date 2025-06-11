class Api::V1::ResponsibleSubjectsController < ActionController::API
  def search
    @responsible_subjects = ResponsibleSubject.active.search(params[:q]).limit(5)
  end
end
