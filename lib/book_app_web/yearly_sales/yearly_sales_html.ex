defmodule BookAppWeb.YearlySalesHTML do
  use BookAppWeb, :html

  import BookAppWeb.CoreComponents

  embed_templates "templates/*"

  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  def format_number(number), do: to_string(number)

  def calculate_growth(current_sales, previous_sales) when previous_sales > 0 do
    ((current_sales - previous_sales) / previous_sales) * 100
  end

  def calculate_growth(_, _), do: 0
end
