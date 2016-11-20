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
    System.halt(0)
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

  def process( _ , error ) do
    handle_error(error)
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

    notify_all(room_ref, client_name, "#{client_name} has joined this chatroom.")
  end

  defp handle_error(error) do
    IO.puts error
  end

  defp handle_chatroom_leave(socket, room_ref) do
    join_id = read_line(socket)
    client_name = read_line(socket)
    Server.ChatRoom.leave(room_ref)
    # deregister PID from ChatRoom
    payload = "LEFT_CHATROOM: #{room_ref}\nJOIN_ID: #{join_id}\n"
    :gen_tcp.send(socket,payload)

    notify_all(room_ref, client_name, "#{client_name} has left this chatroom.")

    payload = "CHAT: #{room_ref}\nCLIENT_NAME: #{client_name}\nMESSAGE: #{client_name} has left this chatroom.\n\n"
    :gen_tcp.send(socket,payload)

  end

  defp handle_chat_message(socket,room_ref) do
    read_line(socket)
    client_name = read_line(socket)
    message = read_line(socket)
    notify_all(room_ref, client_name, message)
  end

  defp handle_socket_terminate(socket) do
    read_line(socket) #ignore port
    client_name = read_line(socket)
    chatrooms_of_client = Server.ChatRoom.part_of
    notify_all_of_disconnect(chatrooms_of_client,client_name)
  end

  defp notify_all_of_disconnect(chatrooms,client_name) do
    chatrooms |> Enum.map(fn(room) -> notify_all(room, client_name, "#{client_name} has left this chatroom.")
    Server.ChatRoom.leave(room)
    end)
  end

  defp notify_all(room_ref, client_name, message) do
    payload = "CHAT: #{room_ref}\nCLIENT_NAME: #{client_name}\nMESSAGE: #{message}\n\n"
    Server.ChatRoom.broadcast(room_ref, fn members ->
      for { _, { _, socket} } <- members do
        :gen_tcp.send(socket,payload)
      end
    end)
  end


  # --------------------- NUM GENERATOR ----------------------

  defp gen_chatroom_id(chatroom) do
    Integer.to_string(Enum.sum(to_charlist(chatroom)))
  end


  # --------------------- GET LOCAL IP -----------------------

  defp ip_address do
    # Find ip else list it
    # {:ok, [addr, _]} = :inet.ifget('en0',[:addr, :hwaddr])
    # elem(addr,1) |> Tuple.to_list |> Enum.join(".")
    # or
    @system_ip
  end

end
