defmodule SprintyWeb.PokerGameLive.Show do
  use SprintyWeb, :live_view

  alias Phoenix.PubSub
  alias Sprinty.PokerGameServer

  @names [
    "Rose Craig",
    "Alejandro Bates",
    "Jeremiah Larkin",
    "Sonja Coleman",
    "Christie Marsh",
    "Brandy Hale",
    "Barbara Simpson",
    "Alison Drake",
    "Merle Salazar",
    "Allen Davies",
    "Earl Holt",
    "Brendan Jarvis",
    "Judy Vaughn",
    "Malcolm Lyons",
    "Rickey Stevens"
  ]

  def mount(%{"game_id" => game_id}, _, socket) do
    # TODO: validate game ID
    if connected?(socket) do
      PubSub.subscribe(Sprinty.PubSub, PokerGameServer.topic(game_id))
    end

    PokerGameServer.ensure_started(game_id)

    user_id = Enum.random(@names)

    scale = PokerGameServer.scale(game_id)
    votes = PokerGameServer.votes(game_id)

    {:ok,
     assign(socket,
       game_id: game_id,
       user_id: user_id,
       scale: scale,
       votes: votes,
       my_vote: nil
     )}
  end

  def handle_event("vote", %{"scale-value" => scale_value}, socket) do
    %{game_id: game_id, user_id: user_id} = socket.assigns
    # TODO: validate value choice
    PokerGameServer.vote(game_id, user_id, scale_value)

    socket = assign(socket, my_vote: scale_value)

    {:noreply, socket}
  end

  def handle_event("reveal", _, socket) do
    PokerGameServer.reveal(socket.assigns.game_id)
    {:noreply, socket}
  end

  def handle_event("reset", _, socket) do
    PokerGameServer.reset(socket.assigns.game_id)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h3 class="mb-6 font-semibold">Hello, <%= @user_id %></h3>

    <div>
      <div class="flex items-center justify-between">
        <h2 class="text-sm font-medium text-gray-900">Select Your Estimate</h2>
      </div>
      <fieldset class="mt-2">
        <div class="grid grid-cols-4 gap-3 sm:grid-cols-8">
          <.estimate_button
            :for={value <- @scale}
            value={value}
            phx-value-scale-value={value}
            selected={@my_vote == value}
            phx-click="vote"
          />
        </div>
      </fieldset>
    </div>

    <div class="my-8 space-x-2">
      <.button
        phx-click="reveal"
        class="inline-flex items-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
      >
        Reveal
      </.button>

      <.button
        phx-click="reset"
        class="inline-flex items-center rounded-md border border-transparent bg-indigo-100 px-4 py-2 text-base font-medium text-indigo-700 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
      >
        Reset
      </.button>
    </div>

    <div class="mt-12">
      <dl class="mt-5 grid grid-cols-2 gap-5 sm:grid-cols-3 lg:grid-cols-4">
        <div
          :for={{name, value} <- @votes}
          class="relative overflow-hidden rounded-lg bg-white flex flex-col items-center space-y-4 px-4 py-5 shadow sm:px-6 sm:py-6"
        >
          <dt class="truncate text-sm font-medium text-gray-500">
            <%= name %>
          </dt>
          <dd :if={not is_nil(value)} class="flex items-baseline text-2xl font-semibold">
            <%= value %>
          </dd>
          <dd :if={is_nil(value)} class="flex items-baseline text-sm font-light text-gray-400">
            No Estimate
          </dd>
        </div>
      </dl>
    </div>
    """
  end

  def handle_info({:votes_updated, votes}, socket) do
    socket = assign(socket, votes: votes)

    {:noreply, socket}
  end

  def handle_info(:game_reset, socket) do
    socket = assign(socket, my_vote: nil)

    {:noreply, socket}
  end

  def handle_info(:server_stopping, socket) do
    PokerGameServer.ensure_started(socket.assigns.game_id)
    {:noreply, socket}
  end
end
