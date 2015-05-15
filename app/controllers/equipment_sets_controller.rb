class EquipmentSetsController < ApplicationController

  load_and_authorize_resource :equipment_set

  def index
  end

  def show
    @events = @equipment_set.events.not_past
  end

  def new
    @equipment_set = EquipmentSet.new
  end

  def edit
  end

  def create
    @equipment_set = EquipmentSet.new(equipment_set_params)
    if @equipment_set.save
      render :show
    else
      render :index
    end
  end

  def update
    @equipment_set.update(equipment_set_params)
    respond_with(@equipment_set)
  end

  def destroy
    @equipment_set.destroy
    respond_with(@equipment_set)
  end

  private
    def set_equipment_set
      @equipment_set = EquipmentSet.find(params[:id])
    end

    def equipment_set_params
      params.require(:equipment_set).permit(:title, :description)
    end
end
