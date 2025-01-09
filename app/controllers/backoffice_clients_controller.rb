class BackofficeClientsController < ApplicationController
  before_action :set_backoffice_client, only: %i[ show edit update destroy ]

  # GET /backoffice_clients or /backoffice_clients.json
  def index
    @backoffice_clients = BackofficeClient.all
  end

  # GET /backoffice_clients/1 or /backoffice_clients/1.json
  def show
  end

  # GET /backoffice_clients/new
  def new
    @backoffice_client = BackofficeClient.new
  end

  # GET /backoffice_clients/1/edit
  def edit
  end

  # POST /backoffice_clients or /backoffice_clients.json
  def create
    @backoffice_client = BackofficeClient.new(backoffice_client_params)

    respond_to do |format|
      if @backoffice_client.save
        format.html { redirect_to @backoffice_client, notice: "Backoffice client was successfully created." }
        format.json { render :show, status: :created, location: @backoffice_client }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @backoffice_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /backoffice_clients/1 or /backoffice_clients/1.json
  def update
    respond_to do |format|
      if @backoffice_client.update(backoffice_client_params)
        format.html { redirect_to @backoffice_client, notice: "Backoffice client was successfully updated." }
        format.json { render :show, status: :ok, location: @backoffice_client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @backoffice_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /backoffice_clients/1 or /backoffice_clients/1.json
  def destroy
    @backoffice_client.destroy!

    respond_to do |format|
      format.html { redirect_to backoffice_clients_path, status: :see_other, notice: "Backoffice client was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_backoffice_client
      @backoffice_client = BackofficeClient.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def backoffice_client_params
      params.expect(backoffice_client: [ :name, :url, :api_token_public_key, :webhook_private_key, :responsible_subject_zammad_identifier ])
    end
end
