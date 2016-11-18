defmodule Server.ChatRoom do

  def join(room_name, join_id) do
    Registry.register(__MODULE__, room_name, join_id)
  end

  def all_members(room_name) do
    Registry.lookup(__MODULE__, room_name)
  end

  def broadcast(message, room_name, action) do
    Registry.dispatch(__MODULE__, room_name, action)
  end

  def leave(room_name) do
    Registry.unregister(__MODULE__, room_name)
  end

end
