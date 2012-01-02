class <%= controller_class_name %>Controller < ApplicationController
  # GET /<%= table_name %>
  def index
    @<%= table_name %> = <%= class_name %>.all
  end

  # GET /<%= table_name %>/:id
  def show
    @<%= file_name %> = <%= class_name %>.find(params[:id])
  end

  # GET /<%= table_name %>/new
  def new
    @<%= file_name %> = <%= class_name %>.new
  end

  # GET /<%= table_name %>/1/edit
  def edit
    @<%= file_name %> = <%= class_name %>.find(params[:id])
  end

  # POST /<%= table_name %>
  def create
    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
    if @<%= file_name %>.save
      redirect_to({:action => "index"}, {:notice => '<%= class_name %> was successfully created.'})
    else
      render :action => "new"
    end
  end

  # PUT /<%= table_name %>/:id
  def update
    @<%= file_name %> = <%= class_name %>.find(params[:id])

    if @<%= file_name %>.update_attributes(params[:<%= file_name %>])
      redirect_to({:action => "index"}, {:notice => '<%= class_name %> was successfully updated.'})
    else
      render :action => "edit"
    end
  end

  # DELETE /<%= table_name %>/:id
  def destroy
    @<%= file_name %> = <%= class_name %>.find(params[:id])
    if @<%= file_name %>.destroy
      redirect_to({:action => "index"}, {:notice => '<%= class_name %> was successfully deleted.'})
    else
      redirect_to({:action => "index"}, {:notice => 'Delete failed'})
    end
  end
end