class AgenciesController < ApplicationController

  load_and_authorize_resource :agency

  def index
  end
 
  def show
   @events = @agency.events.not_past
  end

  def new
  end

  def edit
  end

  def create
    @agency = Agency.new(agency_params)
    if @agency.save
      redirect_to @agency
    else 
      render :new 
    end
  end

  def update
    @agency.update(agency_params)
  end

  def destroy
    @agency.destroy
  end

  private
    def set_agency
      @agency = Agency.find(params[:id])
    end

    def agency_params
      params.require(:agency).permit(:title, :description)
    end
end
