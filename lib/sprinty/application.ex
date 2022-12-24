defmodule Sprinty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SprintyWeb.Telemetry,
      # Start the Ecto repository
      Sprinty.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sprinty.PubSub},
      # Start Finch
      {Finch, name: Sprinty.Finch},
      # Start the Endpoint (http/https)
      SprintyWeb.Endpoint,
      # Start the presence service
      SprintyWeb.Presence,
      # Temporary registry / supervisor for testing
      {Registry, keys: :unique, name: Sprinty.PokerGameRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Sprinty.PokerGameSupervisor}
      # Start a worker by calling: Sprinty.Worker.start_link(arg)
      # {Sprinty.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sprinty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SprintyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
