defmodule Server.Message do

  @system_ip "178.62.97.9"
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
    IO.inspect Server.ChatRoom.all_members(String.strip(room_ref))
  end

  def process(  _ , "DISCONNECT:" <> chatroom ) do
    IO.puts chatroom
  end

  def process(  socket , "CHAT:" <> room_ref ) do
    IO.inspect Server.ChatRoom.all_members(String.strip(room_ref))
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

  def process(  _ , "LEAVE_CHATROOM:" <> room_ref ) do
    String.strip(room_ref)
    # handle_leave(socket, String.strip(room_ref))
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

    Server.ChatRoom.join(chatroom_name, 1, socket)
    payload = "JOINED_CHATROOM: #{chatroom_name}\nSERVER_IP: #{ip_address}\nPORT: #{@port}\n"
    :gen_tcp.send(socket,payload)
  end

  defp handle_error(socket) do
    payload = "ERROR_CODE:1\nERROR_DESCRIPTION:Unknown Message Format\n"
    :gen_tcp.send(socket,payload)
    :gen_tcp.close(socket)
  end

  defp handle_chat_message(socket,room_ref) do
    join_id = read_line(socket)
    client_name = read_line(socket)
    message = read_line(socket)


    IO.puts join_id
    IO.puts client_name
    IO.puts message

    notify_all(client_name, room_ref, message)
  end



  def notify_all(client_name, room_ref, data) do
    payload = "CHAT: #{room_ref}\nCLIENT_NAME: #{client_name}\nMESSAGE: #{data}\n\n"
    Server.ChatRoom.broadcast(room_ref, fn members ->
      for { _, { _, socket} } <- members do
        :gen_tcp.send(socket,payload)
      end
    end)

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
