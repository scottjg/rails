class <%= controller_class_name %>Controller < ApplicationController
  respond_to :html, :xml
  # GET <%= route_url %>
  # GET <%= route_url %>.xml
  def index
    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>

    respond_with(@<%= plural_table_name %>)
  end

  # GET <%= route_url %>/1
  # GET <%= route_url %>/1.xml
  def show
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>

    respond_with(@<%= singular_table_name %>)
  end

  # GET <%= route_url %>/new
  # GET <%= route_url %>/new.xml
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>

    respond_with(@<%= singular_table_name %>)
  end

  # GET <%= route_url %>/1/edit
  def edit
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
  end

  # POST <%= route_url %>
  # POST <%= route_url %>.xml
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "params[:#{singular_table_name}]") %>

    flash[:notice] = "<%= human_name %> was successfully created." if @<%= orm_instance.save %>
    respond_with(@<%= singular_table_name %>)
  end

  # PUT <%= route_url %>/1
  # PUT <%= route_url %>/1.xml
  def update
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>

    flash[:notice] = "<%= human_name %> was successfully updated." if @<%= orm_instance.update_attributes("params[:#{singular_table_name}]") %>
    respond_with(@<%= singular_table_name %>)
  end

  # DELETE <%= route_url %>/1
  # DELETE <%= route_url %>/1.xml
  def destroy
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    @<%= orm_instance.destroy %>

    respond_with(@<%= singular_table_name %>)
  end
end
