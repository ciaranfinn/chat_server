defmodule Server.ChatRoom do

  def join(room_name, join_id,socket) do
    Registry.register(__MODULE__, room_name, {join_id,socket})
  end

  def all_members(room_name) do
    Registry.lookup(__MODULE__, room_name)
  end

  def broadcast(room_name, action) do
    Registry.dispatch(__MODULE__, room_name, action)
  end

  def leave(room_name) do
    Registry.unregister(__MODULE__, room_name)
  end

  def part_of do
    Registry.keys(__MODULE__, self())
  end

end
