defmodule Lorx.Collector.Monitor do
  use GenServer
  alias Lorx.Repo
  alias Lorx.Collector.TemperatureEntry

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}, {:continue, :setup}}
  end

  def handle_continue(:setup, state) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard")
    {:noreply, state}
  end

  def handle_info(
        %Lorx.NotifyTemp{} = data,
        state
      ) do
    t = %TemperatureEntry{
      device_id: data.device_id,
      temp: data.temp,
      device_status: data.status,
      target_temp: data.target_temp,
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    Repo.insert!(t)

    {:noreply, state}
  end
end
