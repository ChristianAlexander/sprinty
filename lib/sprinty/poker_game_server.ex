defmodule Sprinty.PokerGameServer do
  alias Phoenix.PubSub
  use GenServer, restart: :transient

  require Logger

  @timeout 300_000

  defmodule State do
    defstruct [
      :id,
      revealed?: false,
      votes: %{},
      scale: ["0", "1", "2", "3", "5", "8", "13", "☕️"]
    ]
  end

  # Client Interface

  def ensure_started(game_id) do
    DynamicSupervisor.start_child(
      Sprinty.PokerGameSupervisor,
      {__MODULE__, name: via_tuple(game_id), game_id: game_id}
    )
  end

  def scale(game_id) do
    GenServer.call(via_tuple(game_id), :scale)
  end

  def votes(game_id) do
    GenServer.call(via_tuple(game_id), :votes)
  end

  def vote(game_id, user_id, value) do
    GenServer.cast(via_tuple(game_id), {:vote, user_id, value})
  end

  def reveal(game_id) do
    GenServer.cast(via_tuple(game_id), :reveal)
  end

  def topic(game_id) do
    "poker-game:#{game_id}:updates"
  end

  def reset(game_id) do
    GenServer.cast(via_tuple(game_id), :reset)
  end

  # System Interface

  def start_link(options) do
    game_id = Keyword.get(options, :game_id)

    GenServer.start_link(__MODULE__, %State{id: game_id}, options)
  end

  @impl GenServer
  def init(game) do
    Logger.info("Started game #{game.id}")
    PubSub.broadcast!(Sprinty.PubSub, topic(game.id), :game_reset)
    {:ok, game, @timeout}
  end

  @impl GenServer
  def handle_cast(:reset, game) do
    game = %{game | id: game.id, revealed?: false} |> nilify_votes()

    PubSub.broadcast!(Sprinty.PubSub, topic(game.id), {:votes_updated, votes_for_display(game)})
    PubSub.broadcast!(Sprinty.PubSub, topic(game.id), :game_reset)

    {:noreply, game, @timeout}
  end

  @impl GenServer
  def handle_cast(:reveal, game) do
    game = %{game | revealed?: true}

    PubSub.broadcast!(Sprinty.PubSub, topic(game.id), {:votes_updated, votes_for_display(game)})

    {:noreply, game, @timeout}
  end

  @impl GenServer
  def handle_cast({:vote, _, _}, %{revealed?: true} = game), do: {:noreply, game, @timeout}

  @impl GenServer
  def handle_cast({:vote, user_id, value}, game) do
    votes = Map.put(game.votes, user_id, value)
    game = %{game | votes: votes}

    PubSub.broadcast!(Sprinty.PubSub, topic(game.id), {:votes_updated, votes_for_display(game)})

    {:noreply, game, @timeout}
  end

  @impl GenServer
  def handle_call(:scale, _from, game) do
    {:reply, game.scale, game, @timeout}
  end

  @impl GenServer
  def handle_call(:votes, _from, game) do
    {:reply, votes_for_display(game), game, @timeout}
  end

  @impl GenServer
  def handle_info(:timeout, game) do
    Logger.info("Stopping game #{game.id}")
    PubSub.broadcast!(Sprinty.PubSub, topic(game.id), :server_stopping)

    {:stop, :normal, game}
  end

  defp votes_for_display(%State{revealed?: false, votes: votes}) do
    votes
    |> Enum.map(fn
      {k, nil} -> {k, nil}
      {k, _v} -> {k, "…"}
    end)
    |> Enum.into(%{})
  end

  defp votes_for_display(%State{votes: votes}), do: votes

  defp nilify_votes(%State{votes: votes} = state) do
    votes =
      votes
      |> Enum.map(fn {k, _v} -> {k, nil} end)
      |> Enum.into(%{})

    %{state | votes: votes}
  end

  defp via_tuple(name) do
    {:via, Registry, {Sprinty.PokerGameRegistry, name}}
  end
end
