class RoomsController < ApplicationController
  before_action :set_room, only: %i[show edit update destroy]

  def index
    @rooms = Room.order(:number)
    authorize @rooms
  end

  def show
    authorize @room
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
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:number, :floor, :daily_rate, :status)
  end
end
