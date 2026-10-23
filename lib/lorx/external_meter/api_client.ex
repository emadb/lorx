defmodule Lorx.ExternalMeter.ApiClient do
  def get_temp(ip) do
    with {:ok, response} <- Tesla.get("http://#{ip}/temp"),
         200 <- response.status,
         {:ok, %{"temp" => temp}} <- Jason.decode(response.body),
         true <- is_number(temp) do
      {:ok, temp * 1.0}
    else
      _ -> {:error, :invalid_reading}
    end
  rescue
    _ -> {:error, :invalid_reading}
  end
end
