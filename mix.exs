defmodule ABNF.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_abnf,
      name: "ex_abnf",
      source_url: "https://github.com/marcelog/ex_abnf",
      version: "0.3.0",
      elixir: ">= 1.0.0",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 1.3", only: :dev},
      {:ex_doc, "~> 0.20", only: :dev}
    ]
  end

  defp description do
    """
    A parser and interpreter for ABNF grammars. This is not a parser generator, but an interpreter.
    It will load up an ABNF grammar, and generate an AST for it. Then one can apply any of the rules to an input and the interpreter will parse the input according to the rule.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Marcelo Gornstein"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/marcelog/ex_abnf"
      }
    ]
  end
end
