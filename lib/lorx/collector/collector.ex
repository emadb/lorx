defmodule Lorx.Collector.Monitor do
  use GenServer
  alias Lorx.Repo
  alias Lorx.Collector.TemperatureEntry

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{last_saved: DateTime.utc_now()}, {:continue, :setup}}
  end

  def handle_continue(:setup, state) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard")
    {:noreply, state}
  end

  def handle_info(
        %Lorx.NotifyTemp{} = data,
        state
      ) do
    saving_interval = Application.get_env(:lorx, :device)[:saving_interval]

    delta = DateTime.add(state.last_saved, saving_interval, :minute)

    if DateTime.before?(delta, DateTime.utc_now()) do
      t = %TemperatureEntry{
        device_id: data.device_id,
        temp: data.temp,
        device_status: data.status,
        target_temp: data.target_temp,
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      Repo.insert!(t)
      new_state = %{state | last_saved: DateTime.utc_now()}
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
end
