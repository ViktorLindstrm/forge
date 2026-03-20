defmodule ForgeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "application starts and basic types are valid" do
    check all int <- integer() do
      assert is_integer(int)
    end
  end

  property "string generator produces valid strings" do
    check all str <- string(:alphanumeric, min_length: 1) do
      assert is_binary(str)
      assert String.length(str) >= 1
    end
  end
end
