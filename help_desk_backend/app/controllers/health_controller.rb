class HealthController < ApplicationController
  def index
    render json: { status: "ok", timestamp: Time.now }
  end
end
