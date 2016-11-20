defmodule Server.Message do

  @system_ip "138.68.168.23"
  @port Application.get_env(:server, :port)

  def read_line(client_socket) do
    { _ , data} = :gen_tcp.recv(client_socket, 0)
    action(client_socket,data)
  end

  # handle different types of chat message
  defp action( socket, data ) do
    process(socket, data)
  end

  # ---------------- PROCESS MESSAGE TYPE -----------------------

  def process( socket, "HELO" <> " " <> text ) do
    handle_hello_message(socket, String.strip(text))
  end

  def process(  _ , "KILL_SERVICE" <> _ ) do
    System.halt
  end

  def process(  socket , "JOIN_CHATROOM:" <> room_ref ) do
    handle_new_member(socket,String.strip(room_ref))
  end

  def process(  socket , "DISCONNECT:" <> _ ) do
    handle_socket_terminate(socket)
  end

  def process(  socket , "CHAT:" <> room_ref ) do
    handle_chat_message(socket,String.strip(room_ref))
  end

  def process(  _ , "CLIENT_IP:" <> ip ) do
    String.strip(ip)
  end

  def process(  _ , "JOIN_ID:" <> join_id ) do
    String.strip(join_id)
  end

  def process(  _ , "PORT:" <> port ) do
    String.strip(port)
  end

  def process(  _ , "CLIENT_NAME:" <> name ) do
    String.strip(name)
  end

  def process(  _ , "MESSAGE:" <> message ) do
    String.strip(message)
  end

  def process( socket , "LEAVE_CHATROOM:" <> room_ref ) do
    handle_chatroom_leave(socket,String.strip(room_ref))
  end

  def process( socket , _ ) do
    handle_error(socket)
  end


  # --------------------- HANDLERS -------------------------

  defp handle_hello_message(socket,text) do
    payload = "HELO #{text}IP:#{ip_address}\nPort:#{@port}\nStudentID:13320900\n"
    :gen_tcp.send(socket,payload)
    :gen_tcp.close(socket)
  end

  defp handle_new_member(socket,chatroom_name) do
    read_line(socket) #ignore CLIENT_IP (TCP)
    read_line(socket) #ignore PORT (TCP)
    client_name = read_line(socket)

    room_ref = gen_chatroom_id(chatroom_name)
    join_id = :erlang.unique_integer
    Server.ChatRoom.join(room_ref, join_id, socket)

    payload = "JOINED_CHATROOM: #{chatroom_name}\nSERVER_IP: #{ip_address}\nPORT: #{@port}\nROOM_REF: #{room_ref}\nJOIN_ID: #{join_id}\n"
    :gen_tcp.send(socket,payload)

    chatroom_payload ="#{client_name} has joined this chatroom\n"
    notify_all(chatroom_name, chatroom_payload)
  end

  defp handle_error(socket) do
    payload = "ERROR_CODE:1\nERROR_DESCRIPTION:Unknown Message Format\n"
    :gen_tcp.send(socket,payload)
    :gen_tcp.close(socket)
  end

  defp handle_chatroom_leave(socket, room_ref) do
    join_id = read_line(socket)
    client_name = read_line(socket)
    # deregister PID from ChatRoom
    Server.ChatRoom.leave(room_ref)
    payload = "LEAVE_CHATROOM: #{room_ref}\nJOIN_ID: #{join_id}\n"
    :gen_tcp.send(socket,payload)
    chatroom_payload ="#{client_name} has left this chatroom\n"
    notify_all(room_ref, chatroom_payload)
  end

  defp handle_chat_message(socket,room_ref) do
    read_line(socket)
    client_name = read_line(socket)
    message = read_line(socket)
    payload = "CHAT: #{room_ref}\nCLIENT_NAME: #{client_name}\nMESSAGE: #{message}\n\n"
    notify_all(room_ref, payload)
  end

  defp handle_socket_terminate(socket) do
    read_line(socket) #ignore port
    client_name = read_line(socket)
    chatrooms_of_client = Server.ChatRoom.part_of
    notify_all_of_disconnect(chatrooms_of_client,client_name)
    :gen_tcp.close(socket)
  end


  defp notify_all(room_ref, data) do
    Server.ChatRoom.broadcast(room_ref, fn members ->
      for { _, { _, socket} } <- members do
        :gen_tcp.send(socket,data)
      end
    end)
  end

  defp notify_all_of_disconnect(chatrooms,client_name) do
    chatrooms |> Enum.map(fn(room) -> Server.ChatRoom.leave(room)
    notify_all(room, "#{client_name} has left this chatroom\n")
    end)
  end


  # --------------------- NUM GENERATOR ----------------------

  defp gen_chatroom_id(chatroom) do
    Integer.to_string(Enum.sum(to_charlist(chatroom)))
  end


  # --------------------- GET LOCAL IP -----------------------

  defp ip_address do
    # Find ip else list it
    {:ok, [addr, _]} = :inet.ifget('en0',[:addr, :hwaddr])
    elem(addr,1) |> Tuple.to_list |> Enum.join(".")
    # or
    # @system_ip
  end

end
