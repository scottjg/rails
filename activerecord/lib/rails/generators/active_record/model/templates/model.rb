<% module_namespacing do -%>
class <%= class_name %> < <%= parent_class_name.classify %>
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %>
<% end -%>
<% attributes.select{|at| at.name.end_with?('_id')}.each do |attr| -%>
  belongs_to :<%= attr.name.split('_id').first.pluralize %>
<% end -%>
end
<% end -%>
