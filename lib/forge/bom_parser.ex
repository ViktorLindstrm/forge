defmodule Forge.BomParser do
  @moduledoc """
  Parsar :::bom-annoterade block ur markdown-text.

  Format:
    :::bom
    - [ ] Komponent ×2 | Leverantör | 99 SEK
    - [x] Annan del ×1 | AliExpress | 45 SEK
    :::

  Returnerar en lista av segment:
    {:text, "vanlig markdown-text"}
    {:bom, [%{name: _, qty: _, supplier: _, price: _, done: _}]}
  """

  @bom_pattern ~r/:::bom\n([\s\S]*?):::/

  @spec parse(String.t()) :: [{:text, String.t()} | {:bom, list(map())}]
  def parse(body) when is_binary(body) do
    split_body(body)
  end

  defp split_body(text) do
    case Regex.split(@bom_pattern, text, include_captures: true, parts: :infinity) do
      [single] ->
        [{:text, single}]

      parts ->
        parts
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&classify_segment/1)
    end
  end

  defp classify_segment(":::bom\n" <> _ = segment) do
    items =
      Regex.run(@bom_pattern, segment, capture: :all_but_first)
      |> List.first("")
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_bom_line/1)
      |> Enum.reject(&is_nil/1)

    {:bom, items}
  end

  defp classify_segment(text), do: {:text, text}

  defp parse_bom_line(line) do
    case Regex.run(~r/^- \[([ x])\] (.+)$/, String.trim(line)) do
      [_, done_char, rest] ->
        [namepart | cols] = String.split(rest, "|") |> Enum.map(&String.trim/1)
        [name, qty] =
          case String.split(namepart, "×", parts: 2) do
            [n, q] -> [String.trim(n), String.trim(q)]
            [n]    -> [String.trim(n), "1"]
          end

        %{
          name:     name,
          qty:      qty,
          supplier: Enum.at(cols, 0, "–"),
          price:    Enum.at(cols, 1, "–"),
          done:     done_char == "x"
        }

      _ ->
        nil
    end
  end
end
