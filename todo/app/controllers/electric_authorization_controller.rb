class ElectricAuthorizationController < ApplicationController
  def index
    Rails.logger.info(electric_params.inspect)

    authorized = case table
    when 'tasks', 'comments'
      where == "user_id = #{current_user.id}" ||
        SqlConditionValidator.new(current_user.id).validate_where_clause(where)
    else
      false
   end

   if authorized
     head :no_content
   else
     head :forbidden
   end
  end

  private

  def table
    electric_params['table']
  end

  def where
    electric_params['where']
  end

  def electric_params
    @electric_params ||= begin
      path = request.headers['X-Forwarded-Uri']
      uri = URI.parse(path)
      URI.decode_www_form(uri.query).to_h
    end
  end
end
