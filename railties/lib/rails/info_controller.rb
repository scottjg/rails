require 'rails/application/route_inspector'

class Rails::InfoController < ActionController::Base
  self.view_paths = File.join(File.dirname(__FILE__), 'info_controller')

  before_filter :require_local!

  def show
    case params[:id].to_sym
    when :properties
      @info = Rails::Info.to_html
    when :routes
      @info = Rails::Application::RoutePresenter.display_routes
    end
     render "templates/#{params[:id]}", :layout => 'layout'
  end

  protected

  def require_local!
    unless local_request?
      render :text => '<p>For security purposes, this information is only available to local requests.</p>', :status => :forbidden
    end
  end

  def local_request?
    Rails.application.config.consider_all_requests_local || request.local?
  end
end
