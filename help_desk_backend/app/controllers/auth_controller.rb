class AuthController < ApplicationController
  def register
    if User.find_by(username: user_params[:username])
      render json: {error: "Username has already been taken"}, status: 422
    else
      user = User.new(user_params)
      user.last_active_at = Time.current
      
      if user.save
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
    token = request.headers['Authorization']&.split(' ')&.last
    user_payload = JwtService.decode(token)
    if user_payload
      user = User.find_by(id: user_payload[:user_id])
      if user
        new_token = JwtService.encode(user)
        render json: { user: user_json(user), token: new_token }, status: :ok
      else
        render json: { error: 'User missing' }, status: 404 #should not happen
      end
    else
      render json: { error: 'No session found' }, status: 401
    end
  end

  def me
    token = request.headers['Authorization']&.split(' ')&.last
    user_payload = JwtService.decode(token)
    if user_payload = JwtService.decode(token)
      user = User.find_by(id: user_payload[:user_id])
      if user
        render json: { user: user_json(user) }, status: :ok
      else
        render json: { error: 'User missing' }, status: 404 #should not happen
      end
    else
      render json: { error: 'No session found' }, status: 401
    end
  end

  private
  def user_params
    params.fetch(:auth, params).permit(:username, :password)
  end

  def user_json(user)
    {
      id: user.id,
      username: user.username,
      created_at: user.created_at,
      last_active_at: user.last_active_at
    }
  end
end

