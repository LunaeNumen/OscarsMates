class UserPicksController < ApplicationController
  before_action :require_login
  before_action :check_picking_allowed, only: [:create, :update]

  def create
    @user_pick = current_user.user_picks.find_or_initialize_by(
      category_id: params[:category_id],
      year: params[:year]
    )

    @user_pick.movie_id = params[:movie_id]

    if @user_pick.save
      render json: { success: true, movie_title: @user_pick.movie.title }
    else
      render json: { success: false, errors: @user_pick.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def check_picking_allowed
    # Allow picking until the ceremony date
    # For now, this is a placeholder - you can add ceremony date logic later
    ceremony_date = Date.new(params[:year].to_i, 3, 10) # Example: March 10th of the year

    if Date.today > ceremony_date
      render json: { success: false, errors: ["Picking is closed after the ceremony"] }, status: :forbidden
    end
  end
end
