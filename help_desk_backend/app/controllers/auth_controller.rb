class AuthController < ApplicationController
  def register
    user = User.new(username: params[:username ], password: params[:password])
    if user.save:
      render_json(status: :created)
  end

  def login
  end

  def logout
  end

  def refresh
  end

  def me
  end
end
