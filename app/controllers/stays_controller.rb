class StaysController < ApplicationController
  before_action :set_stay, only: %i[show edit update destroy check_out cancel]

  def index
    @stays = Stay.includes(:room, :user, :price_period).ordered
    @stays = @stays.where(room_id: params[:room_id]) if params[:room_id].present?
    @stays = @stays.where(status: params[:status]) if params[:status].present?
    authorize @stays
  end

  def show
    authorize @stay
  end

  def new
    @stay = Stay.new
    @stay.check_in = Time.current.beginning_of_hour
    authorize @stay
  end

  def edit
    authorize @stay
  end

  def create
    @stay = Stay.new(stay_params)
    @stay.user = current_user
    authorize @stay

    unless current_user.valid_password?(params[:stay][:password])
      @stay.errors.add(:password, "incorreta")
      render :new, status: :unprocessable_entity
      return
    end

    if @stay.save
      @stay.room.update!(status: :occupied)
      redirect_to @stay, notice: "Check-in realizado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @stay
    if @stay.update(stay_update_params)
      redirect_to @stay, notice: "Estadia atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def cancel
     authorize @stay
     @stay.update!(status: :cancelled)
     @stay.room.update!(status: :available) if @stay.room.present?
     redirect_to stays_url, notice: "Estadia cancelada."
  end

  def destroy
     authorize @stay
     @stay.destroy!
     redirect_to stays_url, notice: "Registro excluído permanentemente."
  end

  def check_out
  authorize @stay
  @stay.update!(check_out: Time.current, status: :completed)
  @stay.room.update!(status: :available)
  redirect_to @stay, notice: "Check-out realizado com sucesso."
end

  private

  def set_stay
    @stay = Stay.find(params[:id])
  end

  def stay_params
    params.require(:stay).permit(:room_id, :price_period_id, :check_in, :observation)
  end

  def stay_update_params
    params.require(:stay).permit(:total_value, :observation, :status)
  end
end
