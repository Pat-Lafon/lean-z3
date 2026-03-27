import Lake
open Lake DSL System

package z3 where
  preferReleaseBuild := true

/-! ## Z3 Configuration -/

def z3.version := "4.16.0"

def z3.url := "https://github.com/Z3Prover/z3/releases/download"

def z3.os :=
  if Platform.isWindows then "x64-win"
  else if Platform.isOSX then
    if Platform.target.startsWith "aarch64" || Platform.target.startsWith "arm64"
    then "arm64-osx-15.7.3"
    else "x64-osx-15.7.3"
  else
    if Platform.target.startsWith "aarch64" || Platform.target.startsWith "arm64"
    then "arm64-glibc-2.38"
    else "x64-glibc-2.39"

def z3.targetName := s!"z3-{z3.version}-{z3.os}"

/-! ## Z3 Download Target -/

target z3Download pkg : Unit := do
  let traceFile := pkg.buildDir / "z3Download.trace"
  let z3Dir := pkg.dir / z3.targetName
  let zipPath := z3Dir.addExtension "zip"
  let url := s!"{z3.url}/z3-{z3.version}/{z3.targetName}.zip"
  addPureTrace #["url"] url
  return pure <| ← buildUnlessUpToDate traceFile (← getTrace) traceFile do
    download url zipPath
    if ← z3Dir.pathExists then
      IO.FS.removeDirAll z3Dir
    if Platform.isWindows then
      Lake.untar zipPath pkg.dir
    else
      proc (quiet := true) {
        cmd := "unzip"
        args := #["-o", "-d", pkg.dir.toString, zipPath.toString]
      }
    IO.FS.removeFile zipPath

/-! ## Z3 Library

On macOS, we statically link libz3.a (Lean's clang/libc++ toolchain is compatible).
On Linux and Windows, we dynamically link against libz3.so / libz3.dll to avoid
ABI conflicts between Lean's libc++ toolchain and Z3's libstdc++ build.
At runtime, LD_LIBRARY_PATH (Linux) or PATH (Windows) must include the Z3 bin dir. -/

def z3.linkLibName :=
  if Platform.isOSX then nameToStaticLib "z3"
  else if Platform.isWindows then "libz3.lib"
  else "libz3.so"

input_file libz3 where
  path := z3.targetName / "bin" / z3.linkLibName

/-! ## FFI C Library -/

target z3_ffi_o pkg : FilePath := do
  let ffiDir := pkg.dir / "ffi"
  let z3Inc := pkg.dir / z3.targetName / "include"
  let oFile := pkg.irDir / "ffi" / "z3_ffi.o"
  let srcJob ← inputTextFile <| ffiDir / "z3_ffi.c"
  let weakArgs := #[
    "-I", ffiDir.toString,
    "-I", z3Inc.toString,
    "-I", (← getLeanIncludeDir).toString
  ]
  buildO oFile srcJob weakArgs #["-fPIC", "-O2"] "cc"

extern_lib z3ffi pkg := do
  let ffiO ← z3_ffi_o.fetch
  let name := nameToStaticLib "z3ffi"
  buildStaticLib (pkg.staticLibDir / name) #[ffiO]

/-! ## Build Configuration -/

@[default_target]
lean_lib Z3 where
  -- On Windows, precompileModules builds a shared z3ffi.dll which requires all Z3
  -- symbols resolved at DLL link time. Disabling avoids this complexity on Windows.
  precompileModules := !Platform.isWindows
  needs := #[z3Download]
  moreLinkObjs := #[libz3]
  moreLeancArgs := #[
    s!"-I{z3.targetName}/include",
    "-Iffi"
  ]

lean_lib Z3Test where
  globs := #[.submodules `Z3Test]

@[test_driver]
lean_exe z3test where
  root := `Z3Test.Main
