<<__EntryPoint>>
function main(): void {
  invariant(Arm64Autoload\Example::answer() === 42, 'Class autoload failed');
  invariant(Arm64Autoload\answer() === 42, 'Function autoload failed');
  invariant(Arm64Autoload\ANSWER === 42, 'Constant autoload failed');
  invariant(HH\autoload_type_to_path(nameof Arm64Autoload\Example) !== null,
    'Native autoloader did not index the class');
  echo "Native ARM64 autoload test passed\n";
}
