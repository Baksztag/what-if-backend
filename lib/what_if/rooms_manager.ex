defmodule WhatIf.RoomsManager do

  def get_all_rooms() do
    DynamicSupervisor.which_children(WhatIf.RoomsSupervisor)
    |> Enum.map(fn({:undefined, pid, _, _}) -> pid end)
    |> Enum.map(fn(pid) -> WhatIf.Room.get_name(pid) end)
  end

  @spec add_room(String.t) :: {:error, :exists} | :ok
  def add_room(name) do
    case room_exists?(name) do
      true ->
        {:error, :exists}
      false ->
        spec = %{id: name, start: {WhatIf.Room, :start_link, [name]}}
        DynamicSupervisor.start_child(WhatIf.RoomsSupervisor, spec)
        :ok
    end
  end

  def room_exists?(name) do
    get_all_rooms()
    |> Enum.any?(fn room_name -> name == room_name end)
  end

end