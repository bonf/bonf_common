defmodule Bonf.CustomAssertions do
  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)

    quote do
      import Bonf.CustomAssertions

      defmacro assert_difference(schema_deltas, run_fn) do
        repo = unquote(repo)

        quote do
          before =
            unquote(schema_deltas)
            |> Map.keys()
            |> Enum.map(&{&1, unquote(repo).count(&1)})
            |> Map.new()

          unquote(run_fn).()

          after_ =
            unquote(schema_deltas)
            |> Map.keys()
            |> Enum.map(&{&1, unquote(repo).count(&1)})
            |> Map.new()

          Enum.each(before, fn {schema, value1} ->
            delta = Map.get(unquote(schema_deltas), schema, 0)
            value2 = Map.get(after_, schema, 0)

            assert value2 == value1 + delta,
                   "expected #{inspect(schema)} count to change by #{delta}, but changed by #{value2 - value1}"
          end)
        end
      end

      defmacro assert_no_difference(schemas, run_fn) when is_list(schemas) do
        quote do
          schema_deltas =
            unquote(schemas)
            |> Enum.map(&{&1, 0})
            |> Map.new()

          assert_difference(schema_deltas, unquote(run_fn))
        end
      end

      defmacro assert_difference(count_fn, delta, run_fn) do
        quote do
          value1 = unquote(count_fn).()
          unquote(run_fn).()
          value2 = unquote(count_fn).()

          assert value2 == value1 + unquote(delta),
                 "expected count to change by #{unquote(delta)} but changed by #{value2 - value1}"
        end
      end

      defmacro assert_no_difference(count_fn, run_fn) do
        quote do
          assert_difference(unquote(count_fn), 0, unquote(run_fn))
        end
      end
    end
  end

  def assert_equal_dt(a, b) do
    a = a |> DateTime.truncate(:second)
    b = b |> DateTime.truncate(:second)
    DateTime.diff(a, b) <= 1
  end
end
