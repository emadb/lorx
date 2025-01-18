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
        %{device_id: device_id, temp: temp, status: status, target_temp: target_temp},
        state
      ) do
    t = %TemperatureEntry{
      device_id: device_id,
      temp: temp,
      device_status: status,
      target_temp: target_temp,
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    Repo.insert!(t)

    {:noreply, state}
  end
end
