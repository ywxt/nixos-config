{
  lib,
  buildPythonApplication,
  buildPythonPackage,
  faiss,
  fastembed,
  fetchFromGitHub,
  fetchgit,
  hatchling,
  markitdown,
  mcp,
  numpy,
  python,
  pyyaml,
  requests,
  setuptools,
  tree-sitter,
  tree-sitter-python,
  tree-sitter-typescript,
  typing-extensions,
  watchdog,
}:

let
  mkTreeSitterGrammar =
    {
      pname,
      version,
      hash,
    }:
    buildPythonPackage (finalAttrs: {
      inherit pname version;
      pyproject = true;

      src = fetchFromGitHub {
        owner = "tree-sitter";
        repo = pname;
        tag = "v${finalAttrs.version}";
        inherit hash;
      };

      build-system = [ setuptools ];

      optional-dependencies.core = [ tree-sitter ];

      doCheck = false;
      pythonImportsCheck = [ (lib.replaceStrings [ "-" ] [ "_" ] pname) ];
    });

  tree-sitter-c = mkTreeSitterGrammar {
    pname = "tree-sitter-c";
    version = "0.24.2";
    hash = "sha256-Juuf57GQI7OAP6O03KtSzyKJAoXtGKjyYJ+sTM1A4mU=";
  };

  tree-sitter-cpp = mkTreeSitterGrammar {
    pname = "tree-sitter-cpp";
    version = "0.23.4";
    hash = "sha256-tP5Tu747V8QMCEBYwOEmMQUm8OjojpJdlRmjcJTbe2k=";
  };

  tree-sitter-rust = mkTreeSitterGrammar {
    pname = "tree-sitter-rust";
    version = "0.24.2";
    hash = "sha256-Ls6tB6IxXDQDWwx0BJ7RgbheelC4MH8z97E7wwhkDcY=";
  };
in
buildPythonApplication {
  pname = "project-brain";
  version = "0.6.0";
  pyproject = true;

  src = fetchgit {
    url = "https://gitcode.com/xuanwu/project-brain.git";
    rev = "d6eb57ef4cd613e5acdc23294dd105106eb072b2";
    # The bundled embedding model is stored in git LFS.
    fetchLFS = true;
    hash = "sha256-J6QuJdVBkXZtnXpW+cAO7ML8QWEe1qCw7WNDXZ+Eu2Y=";
  };

  build-system = [ hatchling ];

  dependencies = [
    faiss
    fastembed
    mcp
    numpy
    pyyaml
    requests
    tree-sitter
    tree-sitter-c
    tree-sitter-cpp
    tree-sitter-python
    tree-sitter-rust
    tree-sitter-typescript
    typing-extensions
    watchdog
  ]
  ++ mcp.optional-dependencies.cli
  ++ markitdown.optional-dependencies.docx
  ++ markitdown.optional-dependencies.pdf
  ++ markitdown.optional-dependencies.pptx
  ++ markitdown.optional-dependencies.xlsx;

  # The runtime-deps check compares PyPI metadata names and version pins
  # (faiss-cpu, numpy<2.3) that do not match the nixpkgs environment; the
  # import check below covers actual functionality.
  dontCheckRuntimeDeps = true;

  # The graph engine's test suite builds large tree-sitter fixtures and the
  # embedding stack; validate imports instead.
  doCheck = false;
  pythonImportsCheck = [
    "project_brain"
    "project_brain.build.languages.c"
    "project_brain.build.languages.cpp"
    "project_brain.build.languages.python"
    "project_brain.build.languages.rust"
    "project_brain.build.languages.typescript"
    "project_brain.mcp.server"
    "faiss"
    "fastembed"
  ];

  # semantic_index resolves the embedding model from <site-packages>/../model,
  # falling back to a download into that directory when missing. Ship the
  # repository's int8 model so no download is needed.
  postInstall = ''
    mkdir -p "$out/${python.sitePackages}/../model"
    cp -R model/. "$out/${python.sitePackages}/../model/"
  '';

  meta = {
    description = "Project knowledge graph engine for coding agents";
    homepage = "https://gitcode.com/xuanwu/project-brain";
    mainProgram = "project-brain";
    platforms = lib.platforms.all;
  };
}
