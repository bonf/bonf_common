defmodule Bonf.EnumTest do
  use ExUnit.Case

  test "use" do
    defmodule MyEctoTypes.UserRole do
      use Bonf.Enum, %{
        admin: 0,
        editor: 1,
        guest: 2
      }
    end

    assert MyEctoTypes.UserRole.all() == [:admin, :editor, :guest]

    assert MyEctoTypes.UserRole.all_map() == %{
             admin: 0,
             editor: 1,
             guest: 2
           }

    assert MyEctoTypes.UserRole.find_by_value(1) == :editor
  end
end
