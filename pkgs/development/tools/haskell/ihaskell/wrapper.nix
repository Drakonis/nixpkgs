{
  lib,
  stdenv,
  writeScriptBin,
  makeWrapper,
  buildEnv,
  ghcWithPackages,
  jupyter,
  packages,
}:
let
  ihaskellEnv = ghcWithPackages (
    self:
    [
      self.ihaskell
      self.ihaskell-blaze
      # Doesn't work with latest ihaskell versions missing an unrelated change
      # https://github.com/IHaskell/IHaskell/issues/1378
      # self.ihaskell-diagrams
    ]
    ++ packages self
  );
  ihaskellSh = writeScriptBin "ihaskell-notebook" ''
    #! ${stdenv.shell}
    export GHC_PACKAGE_PATH="$(${ihaskellEnv}/bin/ghc --print-global-package-db):$GHC_PACKAGE_PATH"
    export PATH="${
      lib.makeBinPath ([
        ihaskellEnv
        jupyter
      ])
    }''${PATH:+:}$PATH"
    ${ihaskellEnv}/bin/ihaskell install -l $(${ihaskellEnv}/bin/ghc --print-libdir) && ${jupyter}/bin/jupyter notebook
  '';
in
buildEnv {
  name = "ihaskell-with-packages";
  nativeBuildInputs = [ makeWrapper ];
  paths = [
    ihaskellEnv
    jupyter
  ];
  postBuild = ''
    ln -s ${ihaskellSh}/bin/ihaskell-notebook $out/bin/
    for prg in $out/bin"/"*;do
      if [[ -f $prg && -x $prg ]]; then
        wrapProgram $prg --set PYTHONPATH "$(echo ${jupyter}/lib/*/site-packages)"
      fi
    done
  '';
}
