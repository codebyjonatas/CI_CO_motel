class RoomsController < ApplicationController
  before_action :set_room, only: %i[
    show edit update destroy
    start_cleaning finish_cleaning release_quarantine history
  ]

  def index
    @rooms = Room.order(:number)
    @summary = Room.dashboard_summary
    authorize @rooms
  end

  def show
    authorize @room
    @recent_stays = @room.stays.includes(:user).order(check_in: :desc).limit(10)
    @active_tab = @room.current_tab
    @active_cleaning_log = @room.active_cleaning_log
  end

  def history
    authorize @room
    @timeline = RoomHistoryQuery.new(@room).call
  end

  def start_cleaning
    authorize @room

    if @room.may_start_cleaning?
      @room.start_cleaning!
      redirect_to @room, notice: "Limpeza iniciada."
    else
      redirect_to @room, alert: "Quarto não está aguardando limpeza (status: #{@room.status})."
    end
  end

  def finish_cleaning
    authorize @room

    unless @room.may_finish_cleaning?
      redirect_to @room, alert: "Quarto não está em limpeza (status: #{@room.status})."
      return
    end

    log = @room.active_cleaning_log || @room.cleaning_logs.create!(
      cleaned_by: current_user,
      started_at: Time.current,
      status: :started
    )
    log.finish!(user: current_user)

    redirect_to @room, notice: "Limpeza finalizada. Quarto em quarentena por #{RoomCleaningConfig.quarantine_minutes} minutos."
  end

  def release_quarantine
    authorize @room

    unless @room.status_quarantine?
      redirect_to @room, alert: "Quarto não está em quarentena (status: #{@room.status})."
      return
    end

    unless @room.quarantine_expired?
      minutes = (@room.time_until_available / 60.0).ceil
      redirect_to @room, alert: "Quarentena ainda não expirou (faltam #{minutes} min)."
      return
    end

    log = @room.active_cleaning_log
    if log
      log.approve!(user: current_user)
    else
      @room.release_from_quarantine!
    end

    redirect_to @room, notice: "Quarto liberado para uso."
  end

  def new
    @room = Room.new
    authorize @room
  end

  def edit
    authorize @room
  end

  def create
    @room = Room.new(room_params)
    authorize @room

    if @room.save
      redirect_to @room, notice: "Quarto criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @room
    if @room.update(room_params)
      redirect_to @room, notice: "Quarto atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @room
    @room.destroy!
    redirect_to rooms_url, notice: "Quarto removido com sucesso."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to @room, alert: destroy_error_message(@room)
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    # O status pelo formulário é um override administrativo; as transições
    # operacionais continuam passando por AASM nos endpoints dedicados.
    params.require(:room).permit(:number, :floor, :daily_rate, :status)
  end

  def destroy_error_message(record)
    record.errors.full_messages.to_sentence.presence ||
      "Não é possível remover este quarto porque existem estadias ou comandas vinculadas."
  end
end
