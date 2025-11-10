class ApplicationController < ActionController::API
    private

    def authorize_jwt
        auth_header = request.headers['Authorization']
        unless auth_header
            render json: { error: 'No session found' }, status: :unauthorized
            return
        end
        
        # Handle both "Bearer token" and just "token" formats
        token = auth_header.start_with?('Bearer ') ? auth_header.split(' ', 2).last : auth_header
        
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
    