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
    payload = "HELO #{text}IP:#{ip_address}\nPort:#{@port}\nStudentID:13320900\n"
    :gen_tcp.send(socket,payload)
    :gen_tcp.close(socket)
  end

  def process(  _ , "KILL_SERVICE" <> _ ) do
    System.halt
  end

  def process(  socket , "JOIN_CHATROOM:" <> room_ref ) do
    handle_new_member(socket,String.strip(room_ref))
  end

  def process(  _ , "DISCONNECT:" <> chatroom ) do
    IO.puts chatroom
  end

  def process(  _ , "CHAT:" <> room_ref ) do
    String.strip(room_ref)
  end

  def process(  _ , "CLIENT_IP:" <> ip ) do
    String.strip(ip)
  end

  def process(  _ , "PORT:" <> port ) do
    String.strip(port)
  end

  def process(  _ , "CLIENT_NAME:" <> name ) do
    String.strip(name)
  end

  def process(  _ , "LEAVE_CHATROOM:" <> room_ref ) do
    String.strip(room_ref)
  end

  def process( socket , _ ) do
    payload = "ERROR_CODE:1\nERROR_DESCRIPTION:Unknown Message Format\n"
    :gen_tcp.send(socket,payload)
    :gen_tcp.close(socket)
  end

  defp handle_new_member(socket,chatroom_name) do
    read_line(socket)
    read_line(socket)
    read_line(socket)

    payload = "JOINED_CHATROOM: #{chatroom_name}\nSERVER_IP: #{ip_address}\nPORT: #{@port}\n"
    :gen_tcp.send(socket,payload)
    ChatRoom.new(chatroom_name)
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
