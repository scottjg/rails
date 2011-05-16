<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  # GET <%= route_url %>
<% unless skip_respond_to -%>
  # GET <%= route_url %>.json
<% end -%>
  def index
    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>
<% unless skip_respond_to -%>

    respond_to do |format|
      format.html # index.html.erb
      format.json { render <%= key_value :json, "@#{plural_table_name}" %> }
    end
<% end -%>
  end

  # GET <%= route_url %>/1
<% unless skip_respond_to -%>
  # GET <%= route_url %>/1.json
<% end -%>
  def show
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
<% unless skip_respond_to -%>

    respond_to do |format|
      format.html # show.html.erb
      format.json { render <%= key_value :json, "@#{singular_table_name}" %> }
    end
<% end -%>
  end

  # GET <%= route_url %>/new
<% unless skip_respond_to -%>
  # GET <%= route_url %>/new.json
<% end -%>
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
<% unless skip_respond_to -%>

    respond_to do |format|
      format.html # new.html.erb
      format.json { render <%= key_value :json, "@#{singular_table_name}" %> }
    end
<% end -%>
  end

  # GET <%= route_url %>/1/edit
  def edit
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
  end

  # POST <%= route_url %>
<% unless skip_respond_to -%>
  # POST <%= route_url %>.json
<% end -%>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "params[:#{singular_table_name}]") %>

<% if skip_respond_to -%>
    if @<%= orm_instance.save %>
      redirect_to @<%= singular_table_name %>, <%= key_value :notice, "'#{human_name} was successfully created.'" %>
    else
      render <%= key_value :action, '"new"' %>
    end
<% else -%>
    respond_to do |format|
      if @<%= orm_instance.save %>
        format.html { redirect_to @<%= singular_table_name %>, <%= key_value :notice, "'#{human_name} was successfully created.'" %> }
        format.json { render <%= key_value :json, "@#{singular_table_name}" %>, <%= key_value :status, ':created' %>, <%= key_value :location, "@#{singular_table_name}" %> }
      else
        format.html { render <%= key_value :action, '"new"' %> }
        format.json { render <%= key_value :json, "@#{orm_instance.errors}" %>, <%= key_value :status, ':unprocessable_entity' %> }
      end
    end
<% end -%>
  end

  # PUT <%= route_url %>/1
<% unless skip_respond_to -%>
  # PUT <%= route_url %>/1.json
<% end -%>
  def update
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>

<% if skip_respond_to -%>
    if @<%= orm_instance.update_attributes("params[:#{singular_table_name}]") %>
      redirect_to @<%= singular_table_name %>, <%= key_value :notice, "'#{human_name} was successfully updated.'" %>
    else
      render <%= key_value :action, '"edit"' %>
    end
<% else -%>
    respond_to do |format|
      if @<%= orm_instance.update_attributes("params[:#{singular_table_name}]") %>
        format.html { redirect_to @<%= singular_table_name %>, <%= key_value :notice, "'#{human_name} was successfully updated.'" %> }
        format.json { head :ok }
      else
        format.html { render <%= key_value :action, '"edit"' %> }
        format.json { render <%= key_value :json, "@#{orm_instance.errors}" %>, <%= key_value :status, ':unprocessable_entity' %> }
      end
    end
<% end -%>
  end

  # DELETE <%= route_url %>/1
<% unless skip_respond_to -%>
  # DELETE <%= route_url %>/1.json
<% end -%>
  def destroy
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    @<%= orm_instance.destroy %>

<% if skip_respond_to -%>
    redirect_to <%= index_helper %>_url
<% else -%>
    respond_to do |format|
      format.html { redirect_to <%= index_helper %>_url }
      format.json { head :ok }
    end
<% end -%>
  end
end
<% end -%>
