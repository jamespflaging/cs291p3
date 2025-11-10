class AuthController < ApplicationController
  before_action :authorize_jwt, except: [:register, :login, :logout]

  def register
    if User.find_by(username: user_params[:username])
      render json: {error: "Username has already been taken"}, status: 422
    else
      user = User.new(user_params)
      user.last_active_at = Time.current
      
      if user.save
        ExpertProfile.create!(user: user)
        token = JwtService.encode(user)
        render json: {
          user: user_json(user), token: token 
        }, status: :created
      else
        render json: { errors: user.errors.full_messages}, status: 500
      end
    end
  end

  def login
    user = User.find_by(username: user_params[:username])

    if user&.authenticate(user_params[:password])
      token = JwtService.encode(user)
      render json: { user: user_json(user), token: token } #add token
    else
      render json: { error: "Invalid username or password"}, status: 401
    end
  end

  def logout
    render json: { message: "Logged out successfully" }, status: 200
  end

  def refresh
    new_token = JwtService.encode(@current_user)
    render json: { user: user_json(@current_user), token: new_token }, status: :ok
  end

  def me
    render json: user_json(@current_user), status: :ok
  end

  private
  def user_params
    params.fetch(:auth, params).permit(:username, :password)
  end

  def user_json(user)
    {
      id: user.id,
      username: user.username,
      created_at: user.created_at&.iso8601,
      last_active_at: user.last_active_at&.iso8601
    }
  end
end

