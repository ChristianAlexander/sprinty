defmodule SprintyWeb.PageController do
  use SprintyWeb, :controller

  defp random_game_id() do
    System.unique_integer([:positive])
    |> Integer.to_string()
  end

  def home(conn, _params) do
    render(conn, :home, layout: false, game_id: random_game_id())
  end
end
