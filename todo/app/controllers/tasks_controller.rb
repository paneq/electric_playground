class TasksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @tasks = Task.all
  end

  def create
    task = Task.new(task_params)
    task.user_id = current_user.id
    task.save!
    render json: task
  end

  def destroy
    task = Task.find(params[:id])
    raise ActiveRecord::RecordNotFound unless task.user_id == current_user.id
    task.destroy
    head :no_content
  end

  def update
    task = Task.find(params[:id])
    raise ActiveRecord::RecordNotFound unless task.user_id == current_user.id
    task.update!(task_params)
    render json: task
  end

  private

  def task_params
    params.require(:task).permit(:name, :done)
  end
end
