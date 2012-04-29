class Rails::InfoController < ActionController::Base
  before_filter :require_local!

  def properties
    render :inline => Rails::Info.to_html
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
