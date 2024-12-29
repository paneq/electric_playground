class ElectricAuthorizationController < ApplicationController
  def index
    path = request.headers['X-Forwarded-Uri']
    uri = URI.parse(path)
    electric_params = URI.decode_www_form(uri.query).to_h
    Rails.logger.info(electric_params.inspect)
    
    authorized = case electric_params['table']
    when 'tasks'
      electric_params['where'] == "user_id = #{current_user.id}"
    else
      false
   end

   if authorized
     head :no_content
   else
     head :forbidden
   end
  end
end
