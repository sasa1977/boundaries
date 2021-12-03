defmodule Mix.Tasks.Boundary.ExDocGroups do
  @shortdoc "Creates a boundary.exs holding ex_doc module group defintions."
  @moduledoc """
  Creates a `boundary.exs` holding ex_doc module group defintions.

  ## Integration with ExDoc

  The `boundary.exs` file can be integrated with ex_doc in your mix.exs:

        def project do
          [
            …,
            aliases: aliases(),
            docs: docs()
          ]
        end

        defp aliases do
          [
            …,
            docs: ["boundary.ex_doc_groups", "docs"]
          ]
        end

        defp docs do
          [
            …,
            groups_for_modules: groups_for_modules()
          ]
        end

        defp groups_for_modules do
          {list, _} = Code.eval_file("boundary.exs")
          list
        end

  """

  # credo:disable-for-this-file Credo.Check.Readability.Specs

  use Boundary, classify_to: Boundary.Mix
  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("compile")
    Boundary.Mix.load_app()

    app = Boundary.Mix.app_name()
    modules = Boundary.View.app_modules(app)
    view = Boundary.view(app)

    mapping =
      for module <- modules,
          boundary = Boundary.for_module(view, module),
          boundary.check.in or boundary.check.out do
        {module_name_to_group_key(boundary.name), module}
      end
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {boundary, modules} ->
        modules = Enum.sort_by(modules, &Module.split/1)
        {boundary, modules}
      end)

    header = """
    # Generated by `mix boundary.ex_doc_groups`
    """

    File.write("boundary.exs", file_contents(header, mapping))

    Mix.shell().info("\n* creating boundary.exs")
  end

  defp file_contents(header, data) do
    [Code.format_string!(header <> inspect(data, limit: :infinity)), "\n"]
  end

  defp module_name_to_group_key(name) do
    :"#{inspect(name)}"
  end
end
