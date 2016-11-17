defmodule Server.ChatRoom do

  def new(room_name, join_id) do
    Registry.register(Registry.ChatRoom, room_name, join_id)
  end

  def all_members(room_name) do
    Registry.lookup(Registry.ChatRoom, room_name)
  end


  def broadcast(message, room_name) do

  end


end
