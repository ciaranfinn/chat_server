# Author: Ciaran Finn

# References:
# https://thepugautomatic.com/2016/01/pattern-matching-complex-strings/
# http://elixir-lang.org/getting-started/mix-otp/task-and-gen-tcp.html
# http://elixir-lang.org/docs/stable/elixir/Supervisor.html#content
# http://elixir-lang.org/docs/stable/elixir/Task.html
# http://elixir-lang.org/getting-started/keywords-and-maps.html#maps
# https://elixirforum.com/t/is-there-a-simpler-way-to-generate-ids/2323

defmodule Server do

  use Application
  import Supervisor.Spec

  @maximun_clients_allowed 200
  @port Application.get_env(:server, :port)

  def start(_type, _args) do
    IO.puts "✓ Server Started"

    children = [
      worker(Task, [Server, :begin_listening, [String.to_integer(@port)]]),
      supervisor(Task.Supervisor, [[name: Server.TaskSupervisor]]),
      supervisor(Registry, [:duplicate, Server.ChatRoom])
    ]
    options = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, options)
  end

  # --------------------- OPEN PORT --------------------------

  def begin_listening(port) do
    IO.puts "Server listening on: #{port}"
    open_port(port)
  end

  # open a port for incomming connections
  def open_port(port) do
    case :gen_tcp.listen(port,[:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        receive_connection(socket)
      _ ->
        IO.puts "Error opening socket"
        System.halt
    end
  end

  # ----------------- LISTEN FOR CONNECTIONS -----------------

  defp receive_connection(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        handle_client(socket,client)
       _ ->
        IO.puts "Server socket is closed"
        System.halt
    end
  end

  # spawn new worker for every client connection
  defp handle_client(socket, client_socket) do
    %{:workers => count} = Supervisor.count_children(Server.TaskSupervisor)
    if count <= @maximun_clients_allowed do
      case Task.Supervisor.start_child(Server.TaskSupervisor, fn -> serve(client_socket) end) do
        {:ok, pid} ->
              :gen_tcp.controlling_process(client_socket, pid)
              socket |> receive_connection
         _ ->
          IO.puts "Error spawning new worker"
          System.halt
      end
    else
      :gen_tcp.close(client_socket)
      socket |> receive_connection
    end
  end

# ------------ COMPlETE ACTION FOR REQUEST TYPE ------------

  defp serve(client_socket) do
    client_socket |> Server.Message.read_line
    serve(client_socket)
  end

end
