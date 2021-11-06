defmodule MixFormulaTest do
  use ExUnit.Case
  doctest MixFormula

  setup do
    {:ok, %{root: File.cwd!()}}
  end

  test "rendering an invalid template returns an error" do
    {result, _msg} = MixFormula.render("test_templates/not_a_template")
    assert result == :error
  end

  @tag :tmp_dir
  test "passing bindings that don't exist in formula.json returns an error", %{
    tmp_dir: tmp_dir,
    root: root
  } do
    File.cd!(tmp_dir, fn ->
      {result, _msg} =
        MixFormula.render(Path.join(root, "test_templates/basic"), not_a_key: "foo")

      assert result == :error
    end)
  end

  @tag :tmp_dir
  test "render basic template returns :ok and uses default formula value", %{
    tmp_dir: tmp_dir,
    root: root
  } do
    File.cd!(tmp_dir, fn ->
      {result, msg} = MixFormula.render(Path.join(root, "test_templates/basic"))

      assert(result == :ok, msg)
      assert dir?([tmp_dir, "basic"])
    end)
  end

  @tag :tmp_dir
  test "render basic template", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, msg} =
        MixFormula.render(Path.join(root, "test_templates/basic"),
          name: "my_project"
        )

      assert(result == :ok, msg)
      assert dir?([tmp_dir, "my_project"])
    end)
  end

  @tag :tmp_dir
  test "render basic_nested template", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, msg} =
        MixFormula.render(Path.join(root, "test_templates/basic_nested"),
          name: "foo",
          src_name: "bar"
        )

      assert(result == :ok, msg)

      src_file = Path.join([tmp_dir, "foo", "src", "bar", "bar.ex"])
      assert File.exists?(src_file)

      assert file_contains?(src_file, [
               "defmodule Foo do",
               "# Doing stuff for project foo"
             ])
    end)
  end

  @tag :tmp_dir
  test "render basic_nested template with a field left as null", %{tmp_dir: tmp_dir, root: root} do
    # This also tests that file/folder names that evaluate to an empty
    # string are omitted from the project generation
    File.cd!(tmp_dir, fn ->
      {result, msg} =
        MixFormula.render(Path.join(root, "test_templates/basic_nested"),
          name: "foo"
        )

      assert(result == :ok, msg)

      assert dir?([tmp_dir, "foo"])
      src_file = Path.join([tmp_dir, "foo", "src", "bar", "bar.ex"])
      assert !File.exists?(src_file)
    end)
  end

  @tag :tmp_dir
  test "render with templates inside context", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, msg} =
        MixFormula.render(Path.join(root, "test_templates/templated_params"),
          name: "my_project",
          ext: "txt"
        )

      assert(result == :ok, msg)

      assert dir?([tmp_dir, "my_project"])
      assert exists?([tmp_dir, "my_project", "my_project.txt"])
    end)
  end

  @tag :tmp_dir
  test "pre and post hooks", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, msg} =
        MixFormula.render(Path.join(root, "test_templates/with_hooks"),
          name: "my_project"
        )

      assert(result == :ok, msg)

      assert dir?([tmp_dir, "my_project"])

      # No context
      assert exists?([tmp_dir, "my_project", "post"])
      assert exists?([tmp_dir, "my_project", "..", "pre"])

      # With context
      assert exists?([tmp_dir, "my_project", "project-my_post"])
      assert exists?([tmp_dir, "my_project_pre"])
    end)
  end

  @tag :tmp_dir
  test "hooks can modify context", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, msg} =
        MixFormula.render(Path.join(root, "test_templates/with_hooks_modifying_context"),
          name: "my_project"
        )

      assert(result == :ok, msg)

      # The Pre-hook modifies the name
      assert dir?([tmp_dir, "project-my"])
      assert exists?([tmp_dir, "project-my_pre"])

      # "other", which is not modified in any hook keeps the original value
      assert exists?([tmp_dir, "project-my", "other"])
    end)
  end

  @tag :tmp_dir
  test "failing post-hooks will generate clean up", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, _msg} =
        MixFormula.render(Path.join(root, "test_templates/with_failing_post_hook"),
          name: "my_project"
        )

      assert result == :error
      # The generated project should be removed because of the failing hook
      assert !dir?([tmp_dir, "my_project"])
    end)
  end

  @tag :tmp_dir
  test "extension modules are available inside templates", %{tmp_dir: tmp_dir, root: root} do
    File.cd!(tmp_dir, fn ->
      {result, _msg} =
        MixFormula.render(Path.join(root, "test_templates/with_extension"),
          name: "my_project_"
        )

      assert result == :ok
      # The template for the root directory calls the custom defined
      # `add_hello` function, which simply appends "hello"
      assert dir?([tmp_dir, "my_project_hello"])
    end)
  end

  # A helper that wraps File.dir? joining paths first
  defp dir?(args) do
    File.dir?(Path.join(args))
  end

  # A helper that wraps File.exists? joining paths first
  defp exists?(args) do
    File.exists?(Path.join(args))
  end

  # Check if a file in a path contains every string in the given
  # contents
  defp file_contains?(path, contents) when is_list(path) do
    file_contains?(Path.join(path), contents)
  end

  defp file_contains?(path, contents) do
    File.read!(path)
    |> String.contains?(contents)
  end
end
