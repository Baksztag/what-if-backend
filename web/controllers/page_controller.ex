defmodule WhatIf.PageController do
  use WhatIf.Web, :controller
  alias WhatIf.TermParser
  require Logger

  
  def index(conn, _params) do
    render conn, "index.html"
  end

  def test(conn, _params) do
    json conn, %{test: "ok"}
  end

  def set_display_name(conn, %{"name" => name}) do
    fun = fn user_id ->
      register(user_id, name, conn)
      {201, "ok"}
    end
    maybe_do(conn, fun)
  end

  def register(user_id, name, conn) do
    changeset = 
      WhatIf.User.registration_changeset(%WhatIf.User{}, %{display_name: name, user_id: user_id})
    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
      {:error, _changeset} ->
        Logger.error "Error at inserting to db"
    end
  end

  def get_games(conn, _params) do
    fun = fn user_id ->
      games = WhatIf.Game.get_user_games_list(user_id)
              |> Enum.map(fn {id, name, date} ->
                %{"id" => id, "room_name" => name, "date" => date} end)
                {200, %{"games" => games}}
    end
    maybe_do(conn, fun)
  end

  def get_game_details(conn, %{"game_id" => game_id}) do
    fun = fn _user_id ->
      game = WhatIf.Game.get_game_by_id(game_id)
      case game do
        nil ->
          {404, "Game not found"}
        _ ->
          users = game.users
                  |> Enum.map(fn %{display_name: name} -> name end)
          {:ok, json_q} = TermParser.parse(game.questions)
          {200, %{"q_and_a" => json_q, "players" => users}}
      end
    end
    maybe_do(conn, fun)
  end

  defp maybe_do(%{assigns: %{user_id: user_id}} = conn, fun) do
    {code, response} = fun.(user_id)
    case is_map(response) do
      true ->
        json conn, response
      false ->
        conn
        |> put_status(code)
        |> send_resp(code, response)
    end
  end
  defp maybe_do(conn, _) do
    conn |> put_status(401) |> send_resp(401, "Unauthorized") |> halt
  end
end
