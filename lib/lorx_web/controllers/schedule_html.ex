defmodule LorxWeb.ScheduleHTML do
  use LorxWeb, :html

  embed_templates "schedule_html/*"

  @doc """
  Renders a schedule form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :devices, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def schedule_form(assigns)
end
