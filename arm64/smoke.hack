function sum_squares(int $n): int {
  $sum = 0;
  for ($i = 0; $i < $n; ++$i) {
    $sum += $i * $i;
  }
  return $sum;
}

<<__EntryPoint>>
function main(): void {
  for ($i = 0; $i < 1000; ++$i) {
    invariant(sum_squares(100) === 328350, 'Arithmetic failed');
  }
  $values = vec[1, 2, 3];
  invariant(array_sum($values) === 6, 'Collections failed');
  invariant(json_encode(dict['answer' => 42]) === '{"answer":42}', 'JSON failed');
  invariant(preg_match('/arm[0-9]+/', 'arm64') === 1, 'PCRE failed');
  echo "HHVM ARM64 smoke test passed\n";
}
