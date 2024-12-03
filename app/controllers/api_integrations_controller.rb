class ApiIntegrationsController < ApplicationController
  before_action :set_api_integration, only: %i[ show edit update destroy ]

  # GET /api_integrations or /api_integrations.json
  def index
    @api_integrations = ApiIntegration.all
  end

  # GET /api_integrations/1 or /api_integrations/1.json
  def show
  end

  # GET /api_integrations/new
  def new
    @api_integration = ApiIntegration.new
  end

  # GET /api_integrations/1/edit
  def edit
  end

  # POST /api_integrations or /api_integrations.json
  def create
    @api_integration = ApiIntegration.new(api_integration_params)

    respond_to do |format|
      if @api_integration.save
        format.html { redirect_to @api_integration, notice: "Api integration was successfully created." }
        format.json { render :show, status: :created, location: @api_integration }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @api_integration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_integrations/1 or /api_integrations/1.json
  def update
    respond_to do |format|
      if @api_integration.update(api_integration_params)
        format.html { redirect_to @api_integration, notice: "Api integration was successfully updated." }
        format.json { render :show, status: :ok, location: @api_integration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @api_integration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_integrations/1 or /api_integrations/1.json
  def destroy
    @api_integration.destroy!

    respond_to do |format|
      format.html { redirect_to api_integrations_path, status: :see_other, notice: "Api integration was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_integration
      @api_integration = ApiIntegration.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def api_integration_params
      params.expect(api_integration: [ :name, :url, :api_token_public_key, :webhook_private_key, :responsible_subject_zammad_identifier ])
    end
end
