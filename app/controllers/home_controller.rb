class HomeController < ApplicationController
  skip_before_action :require_login, only: [ :index ]
  allow_unauthenticated_access only: :index
  def index
  end
end
