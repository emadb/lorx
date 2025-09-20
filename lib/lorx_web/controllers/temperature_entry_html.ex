defmodule LorxWeb.TemperatureEntryHTML do
  use LorxWeb, :html

  embed_templates "temperature_entry_html/*"

  def format_timestamp(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end
end
