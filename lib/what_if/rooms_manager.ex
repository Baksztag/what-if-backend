defmodule WhatIf.RoomsManager do
  use GenServer

  alias WhatIf.Room

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_all_rooms() do
    GenServer.call(__MODULE__, :get_all_rooms)
  end

  def get_all_nonstarted_rooms_names() do
    GenServer.call(__MODULE__, :get_all_nonstarted_rooms)
    |> Enum.map(fn %{room_name: name} -> name end)
  end

  def get_all_rooms_names() do
    GenServer.call(__MODULE__, :get_all_rooms_names)
  end

  @spec add_room(String.t) :: {:error, :exists} | :ok
  def add_room(name) do
    case name_valid?(name) do
      false ->
        {:error, :name_invalid}
      true ->
        create_with_valid_name(name)
    end
  end


  ## probably unnecessary
  def delete_room(name) do
    case room_exists?(name) do
      false ->
        {:error, :not_exists}
      true ->
        {:ok, pid} = get_room_by_name(name)
        Room.delete_room(pid)
    end
  end

  def get_room_by_name(name) do
    GenServer.call(__MODULE__, {:get_room_by_name, name})
  end

  ## GenServer callbacks

  def init([]) do
    {:ok, []}
  end

  def handle_call(:get_all_rooms, _from, rooms) do
    {:reply, rooms, rooms}
  end
  def handle_call(:get_all_nonstarted_rooms, _from, rooms) do
    available_rooms = rooms |> Enum.filter(fn %{pid: pid} -> not Room.game_started?(pid) end)
    {:reply, available_rooms, rooms}
  end
  def handle_call(:get_all_rooms_names, _from, rooms) do
    room_names = rooms |> Enum.map(fn %{room_name: name} -> name end)
    {:reply, room_names, rooms}
  end
  def handle_call({:add_room, name}, _from, rooms) do
    spec = %{id: name, start: {WhatIf.Room, :start_link, [name]}}
    {:ok, pid} = DynamicSupervisor.start_child(WhatIf.RoomsSupervisor, spec)
    ref = Process.monitor(pid)
    {:reply, {:ok, pid}, 
      [%{room_name: name, pid: pid, ref: ref} | rooms]}
  end
  def handle_call({:get_room_by_name, name}, _from, rooms) do
    result = rooms
         |> Enum.filter(fn %{room_name: room_name} -> room_name == name end)
         |> Enum.map(fn %{pid: pid} -> pid end)
    case result do
      [result_pid] ->
        {:reply, {:ok, result_pid}, rooms}
      _ ->
        {:reply, {:error, :not_exists}, rooms}
    end
  end
  
  def handle_info({:DOWN, dead_room_ref, :process, _object, _reason}, rooms) do
    new_rooms = rooms
                |> Enum.filter(fn %{ref: ref} -> dead_room_ref != ref end)
    {:noreply, new_rooms}
  end
  
  ## Helpers

  defp name_valid?(""), do: false
  defp name_valid?(name) do
    String.length(name) < 16
    and String.trim(name) == name
    and not String.contains?(name, "  ")
  end

  defp create_with_valid_name(name) do
    case room_exists?(name) do
      true ->
        {:error, :exists}
      false ->
        GenServer.call(__MODULE__, {:add_room, name})
    end
  end

  defp room_exists?(name) do
    get_all_rooms()
    |> Enum.any?(fn %{room_name: room_name} -> name == room_name end)
  end

end
