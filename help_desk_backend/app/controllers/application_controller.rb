class ApplicationController < ActionController::API
    private

    def authorize_jwt
        token = request.headers['Authorization']&.split(' ')&.last
        payload = JwtService.decode(token)

        unless payload
            render json: { error: 'No session found' }, status: :unauthorized
            return
        end

        @current_user = User.find_by(id: payload[:user_id])
        unless @current_user
            render json: { error: 'User missing' }, status: :not_found
            return
        end
    end

end
    