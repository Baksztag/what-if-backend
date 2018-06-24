defmodule WhatIf.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "lobby:*", WhatIf.LobbyChannel
  channel "room:*", WhatIf.RoomChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    check_origin: false,
    transport_log: :debug
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) do
    {:ok, assign(socket, :user_id, WhatIf.User.get_user_id(token))}
  end
  def connect(_, _), do: :error

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     WhatIf.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
