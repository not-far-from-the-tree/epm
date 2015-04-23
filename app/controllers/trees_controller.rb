class TreesController < ApplicationController
  # before_action :set_tree, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource :tree, except: :create
  authorize_resource :tree, only: :create
  # authorize_resource :tree

  # GET /trees
  def index
    @trees = Tree.all().page(1).per(20)
  end

  # GET /trees/1
  def show
  end

  # GET /trees/new
  def new
    #render text: current_user.to_yaml
    #return
    @tree.owner = current_user
    #@tree.owner_id = current_user.id
  end

  # GET /trees/1/edit
  def edit
  end

  def closest 
    @add = true
    @page = 1
    if params['page'].present? && params['page'].to_i > 1
      @page = params['page'].to_i
    end
    puts params['ids']
    if params['ids'].blank?
      params['ids'] = []
    end
    @trees = Tree.getclosest([params['lat'],params['lng']], params['ids'], @page)
    render :_formlist, layout: false
  end

  # POST /trees
  def create
    # render text: params.to_yaml and return
    # puts '====in create method'
    @tree = Tree.new tree_params
      
    owner_params = params.require(:tree).permit(owner_attributes: [:id, :fname, :lname, :email, :phone, :ladder, :contactnotes, :propertynotes, :home_ward, :address, :lat, :lng])
    puts owner_params["owner_attributes"] 

    @tree.owner = User.find(owner_params["owner_attributes"]["id"].to_i)
    @tree.owner.attributes = owner_params["owner_attributes"]
    # render text: @tree.to_yaml and return
    #puts tree.to_yaml
    if @tree.save
      redirect_to @tree, notice: 'Tree was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /trees/1
  def update
    if @tree.update(tree_params)
      redirect_to @tree, notice: 'Tree was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /trees/1
  def destroy
    @tree.destroy
    redirect_to trees_url, notice: 'Tree was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # def set_tree
    #   @tree = Tree.find(params[:id])
    # end

    # Only allow a trusted parameter "white list" through.
    def tree_params
      params.require(:tree).permit(:height, :species, :species_other, :relationship, :treatment, :keep, :additional)
    end
end
