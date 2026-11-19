class StaysController < ApplicationController
  before_action :set_stay, only: %i[show edit update destroy check_out cancel info]

  def index
    @stays = Stay.includes(:room, :user).ordered
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
    authorize @stay

    result = Stays::CheckInService.call(
      stay: @stay,
      user: current_user,
      password: params[:stay][:password]
    )

    if result.success?
      redirect_to result.data, notice: "Check-in realizado com sucesso."
    else
      @stay.errors.add(:base, result.error)
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

    result = Stays::CancelService.call(
      stay: @stay,
      user: current_user,
      reason: params[:reason]
    )

    if result.success?
      redirect_to stays_url, notice: "Estadia cancelada."
    else
      redirect_to @stay, alert: result.error
    end
  end

  def destroy
    authorize @stay
    @stay.destroy!
    redirect_to stays_url, notice: "Registro excluído permanentemente."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to @stay, alert: destroy_error_message(@stay)
  end

  def check_out
    authorize @stay
    result = Stays::CheckOutService.call(stay: @stay, user: current_user)

    if result.success?
      redirect_to @stay, notice: "Check-out realizado com sucesso."
    else
      redirect_to @stay, alert: result.error
    end
  end

  def info
    authorize @stay
    render json: {
      room_number: @stay.room.number,
      guest_name: @stay.main_guest&.full_name || @stay.user.name,
      check_in: @stay.check_in.strftime("%d/%m/%Y %H:%M"),
      price_period: @stay.price_period_name
    }
  end

  private

  def set_stay
    @stay = Stay.find(params[:id])
  end

  def stay_params
    params.require(:stay).permit(:room_id, :price_period_id, :check_in, :observation)
  end

  def stay_update_params
    permitted = [ :observation ]
    # Valor total é ajuste administrativo (extras); status só muda pelos fluxos
    # de check-out/cancelamento para não burlar o ciclo do quarto.
    permitted << :total_value if current_user.admin?

    params.require(:stay).permit(*permitted)
  end

  def destroy_error_message(record)
    record.errors.full_messages.to_sentence.presence ||
      "Não é possível excluir este registro porque existem vínculos ativos."
  end
end
